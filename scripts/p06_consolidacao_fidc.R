# P06-MOD-001 | Consolidação temporal, flat sem produto cartesiano e cedentes.
# Dependências P02/P04/P05, data.table. source() não executa processamento.

# P06-FUN-011 | P06-RF-014: identidade histórica explícita, nunca inferida por PL.
chaves_posicoes_fidc <- function(d) {
  tipo <- if('TP_FUNDO_CLASSE' %in% names(d)) as.character(d$TP_FUNDO_CLASSE) else rep(NA_character_,nrow(d))
  historico <- is.na(tipo)|!nzchar(tipo)
  if('campo_identidade' %in% names(d)) tipo[historico & d$campo_identidade=='CNPJ_FUNDO'] <- 'Fundo legado'
  else if('CNPJ_FUNDO' %in% names(d)) tipo[historico & !is.na(d$CNPJ_FUNDO)] <- 'Fundo legado'
  tipo[is.na(tipo)|!nzchar(tipo)] <- 'Tipo não informado'
  cnpj <- if('cnpj' %in% names(d)) as.character(d$cnpj) else {
    campo <- if('CNPJ_FUNDO_CLASSE' %in% names(d)) 'CNPJ_FUNDO_CLASSE' else 'CNPJ_FUNDO'
    toupper(gsub('[./ -]','',d[[campo]]))
  }
  data <- if('dt_comptc' %in% names(d)) as.character(d$dt_comptc) else as.character(d$DT_COMPTC)
  if(anyNA(cnpj)||any(!nzchar(cnpj))||anyNA(data)||anyNA(as.Date(data))) stop('Chave analítica inválida.')
  data.table::data.table(cnpj=cnpj,tipo=tipo,data=data)
}

# P06-FUN-012 | P06-RF-014: leitura estreita de atributos antes das demais tabelas.
preparar_indice_filtros_fidc <- function(downloads,config,raiz='.') {
  f <- validar_filtros_fidc(if(is.null(config$filtros)) list() else config$filtros)
  ativo <- f$interesse!='Todos'||f$exclusivo!='Todos'||length(f$condominio)>0L||
    any(vapply(f[c('cotistas_igual','cotistas_min','cotistas_max')],Negate(is.null),logical(1)))
  if(!ativo) return(NULL)
  if(!'I' %in% config$tabelas) stop('Pré-filtros requerem tabela I.')
  precisa_cotistas <- any(vapply(f[c('cotistas_igual','cotistas_min','cotistas_max')],Negate(is.null),logical(1)))
  if(precisa_cotistas && !'X_1' %in% config$tabelas) stop('Filtro de cotistas requer X_1.')
  bases <- list(); cotistas <- list(); hashes <- list()
  for(r in downloads) {
    if(!identical(r$estado,'concluido')) stop('Pré-filtro exige originais concluídos.')
    membros <- extrair_zip_fidc(r,config,raiz)
    ids <- sub('^inf_mensal_fidc_tab_(.+)_[0-9]{4}([0-9]{2})?\\.csv$','\\1',membros$Name)
    for(j in which(ids %in% c('I',if(precisa_cotistas) 'X_1'))) {
      cab <- names(data.table::fread(membros$caminho[j],sep=';',nrows=0,showProgress=FALSE))
      campos <- intersect(c('CNPJ_FUNDO','CNPJ_FUNDO_CLASSE','TP_FUNDO_CLASSE','DT_COMPTC',
        'COTST_INTERESSE','FUNDO_EXCLUSIVO','CONDOM','TAB_X_NR_COTST','TAB_X_CLASSE_SERIE','ID_SUBCLASSE'),cab)
      d <- data.table::fread(membros$caminho[j],sep=';',select=campos,colClasses='character',
        encoding='Latin-1',na.strings=c('','NA'),showProgress=FALSE)
      d <- d[DT_COMPTC>=config$inicio & DT_COMPTC<=config$fim]
      k <- chaves_posicoes_fidc(d)
      d <- cbind(k,d[,setdiff(names(d),names(k)),with=FALSE])
      if(ids[j]=='I') bases[[length(bases)+1L]] <- d else cotistas[[length(cotistas)+1L]] <- d
      hashes[[membros$Name[j]]] <- membros$hash[j]
    }
  }
  atributos <- data.table::rbindlist(bases,fill=TRUE)
  campos <- intersect(c('COTST_INTERESSE','FUNDO_EXCLUSIVO','CONDOM'),names(atributos))
  repetidas <- duplicated(atributos,by=c('cnpj','tipo','data')) | duplicated(atributos,by=c('cnpj','tipo','data'),fromLast=TRUE)
  if(any(repetidas)) {
    conflitos <- atributos[repetidas,lapply(.SD,function(x)length(unique(x))),by=.(cnpj,tipo,data),.SDcols=campos]
    if(any(as.matrix(conflitos[,..campos])>1L)) stop('Atributos conflitantes na chave mensal.')
  }
  atributos <- unique(atributos,by=c('cnpj','tipo','data'))
  if(precisa_cotistas) {
    if(!length(cotistas)) stop('Quantidade de cotistas indisponível.')
    x <- data.table::rbindlist(cotistas,fill=TRUE)
    if(!'TAB_X_NR_COTST' %in% names(x)) stop('TAB_X_NR_COTST ausente.')
    # X_1 é por série/subclasse: somente posição com uma linha permite total direto.
    q <- x[,.(cotistas=if(.N==1L) suppressWarnings(as.numeric(TAB_X_NR_COTST[1])) else NA_real_),by=.(cnpj,tipo,data)]
    atributos <- merge(atributos,q,by=c('cnpj','tipo','data'),all.x=TRUE,sort=FALSE)
    if(all(is.na(atributos$cotistas))) stop('Cotistas distintos por entidade não confirmados: X_1 tem múltiplas séries ou relação de identidade ausente.')
  }
  selecao <- avaliar_filtros_fidc(atributos,f)
  atributos[, `:=`(elegivel=selecao$elegivel,motivo=selecao$motivo)]
  list(chaves=atributos[elegivel==TRUE,.(cnpj,tipo,data)],
    contagens=atributos[,.(antes=.N,depois=sum(elegivel),excluidas=sum(!elegivel),
      desconhecidas=sum(Reduce(`|`,lapply(.SD,is.na)))),by=.(data,tipo),.SDcols=c(campos,if(precisa_cotistas)'cotistas')],
    exclusoes=atributos[elegivel==FALSE,.(cnpj,tipo,data,motivo)],
    criterios=f,expressao=expressao_filtros_fidc(f),
    assinatura=calcular_hash_assinatura(list(filtros=f,entradas=hashes,regra='indice-mensal-v1')))
}

# P06-FUN-013 | P06-RF-014: semijoin mantém multiplicidade legítima sem produto cartesiano.
aplicar_indice_filtros_fidc <- function(dados,chaves) {
  k <- chaves_posicoes_fidc(dados)
  elegiveis <- paste(chaves$cnpj,chaves$tipo,chaves$data,sep='|')
  dados[paste(k$cnpj,k$tipo,k$data,sep='|') %in% elegiveis,]
}

# P06-FUN-001 | Identificadores textuais, datas/decimais por contrato e origem.
ler_padronizar_fidc <- function(arquivo, tabela, config, dicionario = NULL, zip_origem = '') {
  bytes <- readBin(arquivo, 'raw', n = file.info(arquivo)$size)
  texto <- rawToChar(bytes)
  utf8 <- !is.na(iconv(texto, from = 'UTF-8', to = 'UTF-8', sub = NA))
  encoding <- if (utf8) 'UTF-8' else 'Latin-1'
  dados <- data.table::fread(arquivo, sep = ';', encoding = encoding,
    colClasses = 'character', na.strings = c('', 'NA'), showProgress = FALSE)
  if (anyDuplicated(toupper(names(dados)))) stop('Colisão de nomes.')
  data.table::setnames(dados, toupper(names(dados)))
  qualidade <- relatar_qualidade_fidc(dados, tabela, dicionario)
  problema <- qualidade$tipo %in% c('conversao_invalida','data_invalida','identificador_vazio') &
    qualidade$quantidade > 0
  if (any(problema)) {
    erro <- structure(list(message = 'Decimal, data ou identificador incompatível com contrato.',
      call = NULL, qualidade = qualidade), class = c('fidc_erro_leitura','error','condition'))
    stop(erro)
  }
  if (!'DT_COMPTC' %in% names(dados)) stop('DT_COMPTC ausente.')
  data <- as.Date(dados$DT_COMPTC, format = '%Y-%m-%d')
  if (anyNA(data) || any(format(data, '%Y-%m-%d') != dados$DT_COMPTC)) stop('Data inválida no CSV.')
  identificador <- if ('CNPJ_FUNDO_CLASSE' %in% names(dados)) 'CNPJ_FUNDO_CLASSE' else
    if ('CNPJ_FUNDO' %in% names(dados)) 'CNPJ_FUNDO' else stop('Identificador ausente.')
  original <- dados[[identificador]]
  if (anyNA(original) || any(!nzchar(trimws(original)))) stop('CNPJ vazio.')
  # Normaliza apenas apresentação; não remove letras nem completa zeros.
  chave <- toupper(gsub('[./ -]', '', original))
  dados[, c('cnpj','dt_comptc','arquivo_origem','zip_origem','linha_origem','campo_identidade') :=
    list(chave, data, basename(arquivo), zip_origem, seq_len(.N), identificador)]
  desconhecidos <- character()
  if (!is.null(dicionario)) {
    mapa <- dicionario[dicionario$tabela == tabela, , drop = FALSE]
    desconhecidos <- setdiff(names(dados), c(mapa$campo, 'cnpj','dt_comptc',
      'arquivo_origem','zip_origem','linha_origem','campo_identidade'))
    for (i in seq_len(nrow(mapa))) {
      nome <- mapa$campo[i]
      if (!nome %in% names(dados)) next
      tipo <- mapa$tipo[i]
      if (tipo %in% c('numeric','float','int')) {
        raw <- dados[[nome]]
        presente <- !is.na(raw)
        if (any(!grepl('^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$', raw[presente])))
          stop('Decimal incompatível com contrato: ', nome)
        valor <- as.numeric(raw)
        if (any(!is.finite(valor[presente]))) stop('Valor fora da representação numérica.')
        # Guarda representação recebida para não perder precisão financeira.
        dados[, (paste0(nome, '__original')) := raw]
        dados[, (nome) := valor]
      } else if (tipo == 'date') dados[, (nome) := as.Date(get(nome))]
      # bigint fica textual, pois pode ultrapassar a precisão exata do double.
    }
  }
  dados <- dados[dt_comptc >= as.Date(config$inicio) & dt_comptc <= as.Date(config$fim)]
  list(dados = dados, diagnostico = list(tabela = tabela, encoding = encoding,
    separador = ';', decimal = '.', desconhecidos = desconhecidos,
    ausentes = if (!is.null(dicionario)) setdiff(mapa$campo, names(dados)) else character(),
    linhas = nrow(dados), qualidade = qualidade))
}

# P06-FUN-008 | P06-RF-012: diagnóstico por tabela/competência, sem descartar originais.
# Saída longa inclui ausências/novidades, cardinalidade, formato/DV e conversões.
relatar_qualidade_fidc <- function(dados, tabela, dicionario = NULL) {
  d <- data.table::as.data.table(dados)
  campos <- setdiff(names(d), c('cnpj','dt_comptc','arquivo_origem','zip_origem',
    'linha_origem','campo_identidade', grep('__original$', names(d), value=TRUE)))
  mapa <- if (is.null(dicionario)) data.frame(campo=character(),tipo=character()) else
    dicionario[dicionario$tabela == tabela, , drop=FALSE]
  competencias <- if ('DT_COMPTC' %in% names(d)) substr(as.character(d$DT_COMPTC),1,7) else
    rep('nao_identificada',nrow(d))
  competencias[is.na(competencias)] <- 'nao_identificada'
  grupos <- unique(competencias)
  if (!length(grupos)) grupos <- 'sem_registros'
  resultados <- list()
  for (mes in grupos) {
    x <- d[which(competencias == mes)]
    eventos <- list()
    # Eventos herdam P06-FUN-008 e não modificam as linhas examinadas.
    adicionar <- function(tipo, campo='', quantidade=0L, detalhe='') {
      eventos[[length(eventos)+1L]] <<- data.table::data.table(tabela=tabela,
        competencia=mes,tipo=tipo,campo=campo,quantidade=as.integer(quantidade),detalhe=detalhe)
    }
    adicionar('registros', quantidade=nrow(x))
    for (campo in setdiff(campos,mapa$campo)) adicionar('campo_novo',campo,nrow(x))
    for (campo in setdiff(mapa$campo,campos)) adicionar('campo_ausente',campo,nrow(x))
    if (!'DT_COMPTC' %in% names(x)) adicionar('data_invalida','DT_COMPTC',max(1L,nrow(x))) else {
      raw <- as.character(x$DT_COMPTC)
      data <- suppressWarnings(as.Date(raw,format='%Y-%m-%d'))
      invalido <- is.na(data) | is.na(raw) | (!is.na(data) & format(data,'%Y-%m-%d') != raw)
      adicionar('data_invalida','DT_COMPTC',sum(invalido))
    }
    identidade <- if ('CNPJ_FUNDO_CLASSE' %in% names(x)) 'CNPJ_FUNDO_CLASSE' else 'CNPJ_FUNDO'
    if (!identidade %in% names(x)) adicionar('identificador_vazio',identidade,max(1L,nrow(x))) else {
      ni <- toupper(gsub('[./ -]','',x[[identidade]]))
      vazio <- is.na(ni) | !nzchar(ni)
      formato <- !vazio & !grepl('^[A-Z0-9]{12}[0-9]{2}$',ni)
      adicionar('identificador_vazio',identidade,sum(vazio))
      adicionar('identificador_formato_invalido',identidade,sum(formato))
      numericos <- !vazio & grepl('^[0-9]{14}$',ni)
      adicionar('identificador_dv_invalido',identidade,
        sum(!vapply(ni[numericos],validar_dv_ni,logical(1))))
      adicionar('identificador_alfanumerico_nao_homologado',identidade,
        sum(!vazio & grepl('[A-Z]',ni)), 'Preservado sem confirmação cadastral')
      if ('DT_COMPTC' %in% names(x)) {
        chaves <- data.table::data.table(ni=ni,data=as.character(x$DT_COMPTC))
        adicionar('chaves_com_multiplas_linhas',quantidade=nrow(chaves[, .N, by=.(ni,data)][N>1]))
      }
    }
    adicionar('repeticoes_integrais',quantidade=sum(duplicated(x[, ..campos])))
    for (campo in intersect(mapa$campo[mapa$tipo %in% c('numeric','float','int','date')],names(x))) {
      original <- paste0(campo,'__original')
      raw <- as.character(if (original %in% names(x)) x[[original]] else x[[campo]])
      presente <- !is.na(raw)
      tipo <- mapa$tipo[match(campo,mapa$campo)]
      invalido <- if (tipo=='date') {
        v <- suppressWarnings(as.Date(raw,format='%Y-%m-%d'))
        presente & (is.na(v) | (!is.na(v) & format(v,'%Y-%m-%d')!=raw))
      } else presente & (!grepl('^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$',raw) |
        !is.finite(suppressWarnings(as.numeric(raw))))
      adicionar('conversao_invalida',campo,sum(invalido))
    }
    adicionar('unidades_e_escala',detalhe='Não confirmadas, valores originais preservados')
    resultados[[length(resultados)+1L]] <- data.table::rbindlist(eventos)
  }
  data.table::rbindlist(resultados)
}

# P06-FUN-002 | Auditoria sem descarte: multiplicidade e repetição integral.
auditar_chaves_fidc <- function(dados, chave = c('cnpj','dt_comptc')) {
  dados <- data.table::as.data.table(dados)
  if (!all(chave %in% names(dados))) stop('Chave ausente.')
  multiplicidades <- dados[, .(linhas = .N), by = chave][linhas > 1L]
  campos <- setdiff(names(dados), c('arquivo_origem','zip_origem','linha_origem'))
  list(multiplicidades = multiplicidades,
    repeticoes_integrais = sum(duplicated(dados[, ..campos])),
    linhas = nrow(dados), politica = 'preservar_todas_as_linhas')
}

# P06-FUN-003 | P06-RF-004/011: pivot explícito de detalhes, depois full join 1:1.
# A posição rNNNN é técnica, não é chave ou correspondência entre detalhes.
consolidar_tabelas_fidc <- function(tabelas, config) {
  if (!length(tabelas)) stop('Nenhuma tabela válida.')
  chave <- c('cnpj','dt_comptc')
  # União calculada uma vez. Atribuição por coluna evita copiar o flat em cada join.
  flat <- unique(data.table::rbindlist(lapply(tabelas,function(d)
    unique(data.table::as.data.table(d)[, ..chave]))))
  data.table::setorderv(flat,chave)
  if (!nrow(flat)) stop('Nenhuma linha atual válida.')
  auditoria <- list()
  for (id in sort(names(tabelas))) {
    d <- data.table::copy(data.table::as.data.table(tabelas[[id]]))
    auditoria[[id]] <- auditar_chaves_fidc(d)
    if (!nrow(d)) next
    if (anyNA(d[, ..chave])) stop('Chave incompleta.')
    data.table::setorderv(d, c(chave,'zip_origem','arquivo_origem','linha_origem'))
    d[, .registro := sprintf('r%04d', seq_len(.N)), by = chave]
    valores <- setdiff(names(d), c(chave, '.registro'))
    tamanho <- length(valores) * max(d[, .N, by = chave]$N)
    if (tamanho + ncol(flat) > config$max_colunas_flat)
      stop('Limite de colunas do flat excedido; revisar escopo.')
    largo <- data.table::dcast(d, cnpj + dt_comptc ~ .registro, value.var = valores)
    renomear <- setdiff(names(largo), chave)
    data.table::setnames(largo, renomear, paste0(id, '__', renomear))
    if (anyDuplicated(largo[, ..chave])) stop('Pivot não gerou chave única.')
    indices <- largo[flat,on=chave,which=TRUE]
    for (campo in setdiff(names(largo),chave))
      data.table::set(flat,j=campo,value=largo[[campo]][indices])
  }
  data.table::setorderv(flat, chave)
  data.table::setkeyv(flat,chave)
  # Órfãos não são excluídos por uma âncora I: full outer join preserva a união.
  list(flat = flat, auditoria = auditoria)
}

# P06-FUN-007 | CPF/CNPJ numéricos: somente dígitos verificadores.
validar_dv_ni <- function(digitos) {
  if (length(digitos) != 1 || is.na(digitos) || !grepl('^([0-9]{11}|[0-9]{14})$', digitos)) return(FALSE)
  d <- as.integer(strsplit(digitos, '')[[1]])
  if (length(unique(d)) == 1) return(FALSE)
  n <- length(d)
  pesos1 <- if (n == 11) 10:2 else c(5:2, 9:2)
  pesos2 <- if (n == 11) 11:2 else c(6:2, 9:2)
  resto1 <- sum(d[seq_len(n-2)] * pesos1) %% 11
  dv1 <- if (resto1 < 2) 0 else 11-resto1
  resto2 <- sum(c(d[seq_len(n-2)], dv1) * pesos2) %% 11
  dv2 <- if (resto2 < 2) 0 else 11-resto2
  identical(as.numeric(tail(d, 2)), c(dv1,dv2))
}

# P06-FUN-006 | Original imutável; candidatos não confirmam identidade cadastral.
avaliar_identificador_cedente <- function(original, completar_zeros = FALSE) {
  normalizado <- if (is.na(original)) NA_character_ else gsub('[./ -]', '', original)
  formato <- if (is.na(normalizado) || !nzchar(normalizado)) 'vazio' else
    if (!grepl('^[0-9]+$', normalizado)) 'nao_numerico' else
    if (nchar(normalizado) == 11) 'CPF' else if (nchar(normalizado) == 14) 'CNPJ' else 'nao_identificado'
  cpf <- cnpj <- NA_character_
  if (!is.na(normalizado) && grepl('^[0-9]+$', normalizado) && completar_zeros) {
    if (nchar(normalizado) <= 11) cpf <- paste0(strrep('0',11-nchar(normalizado)), normalizado)
    if (nchar(normalizado) <= 14) cnpj <- paste0(strrep('0',14-nchar(normalizado)), normalizado)
  }
  valido <- validar_dv_ni(normalizado)
  vcpf <- validar_dv_ni(cpf)
  vcnpj <- validar_dv_ni(cnpj)
  status <- if (vcpf && vcnpj) 'ambiguo' else
    if (valido) 'dv_valido_sem_confirmacao_cadastral' else
    if (vcpf || vcnpj) 'hipotese_zeros' else 'nao_validado'
  data.frame(ni_original = original, ni_normalizado = normalizado, formato = formato,
    dv_valido = valido, candidato_cpf = cpf, candidato_cnpj = cnpj,
    status_identificacao = status, stringsAsFactors = FALSE)
}

# P06-FUN-005 | Longo por grupo/índice/linha, percentual bruto preservado.
extrair_cedentes_fidc <- function(dados, config) {
  campos <- grep('^TAB_I2[AB]12_CPF_CNPJ_CEDENTE_[0-9]+$', names(dados), value = TRUE)
  saida <- list()
  for (campo in campos) {
    indice <- sub('.*_', '', campo)
    grupo <- sub('_CPF_CNPJ_CEDENTE_.*', '', campo)
    percentual <- paste0(grupo, '_PR_CEDENTE_', indice)
    presentes <- which(!is.na(dados[[campo]]) & nzchar(trimws(dados[[campo]])))
    if (!length(presentes)) next
    d <- data.table::copy(dados[presentes, c('cnpj','dt_comptc','arquivo_origem',
      'zip_origem','linha_origem'), with = FALSE])
    valores <- dados[[campo]][presentes]
    identificados <- data.table::rbindlist(lapply(valores, avaliar_identificador_cedente,
      completar_zeros = config$completar_zeros))
    bruto <- paste0(percentual, '__original')
    p <- if (bruto %in% names(dados)) dados[[bruto]][presentes] else
      if (percentual %in% names(dados)) as.character(dados[[percentual]][presentes]) else rep(NA_character_, length(presentes))
    d[, c('grupo','indice','percentual_original','escala_percentual') :=
      list(grupo, as.integer(indice), p, config$escala_percentual)]
    saida[[length(saida)+1L]] <- cbind(d, identificados)
  }
  if (!length(saida)) return(data.table::data.table(cnpj = character(), dt_comptc = as.Date(character()),
    ni_original = character(), percentual_original = character()))
  resultado <- data.table::rbindlist(saida, use.names = TRUE, fill = TRUE)
  data.table::setorderv(resultado, intersect(c('cnpj','dt_comptc','grupo','indice','linha_origem'), names(resultado)))
  resultado
}

# P06-FUN-004 | Checkpoints por membro, assinaturas locais, geração por seleção.
# interromper_apos facilita demonstração real de retomada em processo novo.
retomar_consolidacao_fidc <- function(downloads, config, raiz = '.', dicionario = NULL,
    interromper_apos = Inf) {
  politica <- resolver_politica_execucao(config$usar_checkpoints, config$atualizar_downloads,
    config$forcar_reprocessamento)
  inicio_execucao <- proc.time()[['elapsed']]
  gc(reset=TRUE)
  estado_execucao <- validar_destino(raiz,paste0(config$saidas,'/execucao.rds'))
  atual <- validar_destino(raiz,paste0(config$saidas,'/atual.rds'))
  terminar <- registrar_tentativa(config,raiz,'P06')
  finalizado <- FALSE
  motivo_falha <- 'Execução interrompida ou gravação malsucedida'
  on.exit({
    if (!finalizado) {
      falha <- list(estado='falhou',incompleto=TRUE,geracao=NULL,
        motivo=motivo_falha)
      try(terminar('falhou',falha$motivo),silent=TRUE)
    }
  },add=TRUE)
  withCallingHandlers({
  vinculo <- validar_downloads_plano(downloads,config,raiz)
  filtro <- preparar_indice_filtros_fidc(downloads,config,raiz)
  message('Pré-consolidação: ',expressao_filtros_fidc(if(is.null(config$filtros)) list() else config$filtros))
  logica <- assinatura_transformacao()
  checkpoint <- validar_destino(raiz, config$checkpoints)
  dir.create(checkpoint, recursive = TRUE, showWarnings = FALSE)
  tabelas <- list(); faltas <- character(); diagnosticos <- list(); usados <- 0L; processados <- 0L
  for (registro in downloads) {
    if (registro$estado != 'concluido') { faltas <- c(faltas, registro$unidade); next }
    membros <- extrair_zip_fidc(registro, config, raiz)
    ids <- sub('^inf_mensal_fidc_tab_(.+)_[0-9]{4}([0-9]{2})?\\.csv$', '\\1', membros$Name)
    for (id in config$tabelas) {
      posicoes <- which(ids == id)
      if (!length(posicoes)) {
        # A tabela X ainda nÃ£o consta nos pacotes histÃ³ricos de 2020â€“2022.
        # Essa ausÃªncia por vintage nÃ£o torna incompleta a seleÃ§Ã£o mensal.
        if (identical(id,'X') && as.integer(registro$unidade) <= 2022L) next
        faltas <- c(faltas, paste(registro$unidade,id,sep='/')); next
      }
      for (i in posicoes) {
        caminho <- file.path(checkpoint, paste0(registro$unidade, '_', id, '_', i, '.rds'))
        manifesto <- paste0(caminho, '.manifesto.rds')
        mapa <- if (is.null(dicionario)) NULL else dicionario[dicionario$tabela == id, ]
        assinatura <- calcular_hash_assinatura(list(hash = membros$hash[i],
          inicio = config$inicio, fim = config$fim, versao = config$versao_transformacao,
          logica=logica, mapa = mapa, filtro=if(is.null(filtro)) NULL else filtro$assinatura))
        anterior <- ler_rds_recuperavel(manifesto, function(x)
          is.list(x) && is.character(x$estado) && length(x$estado)==1L)
        recuperar_rollback(caminho, function(arq) {
          x <- readRDS(arq)
          is.list(x) && is.data.frame(x$dados)
        })
        reutilizar <- politica$reutilizar_checkpoint && !is.null(anterior) &&
          anterior$estado == 'concluido' && identical(assinatura, anterior$assinatura) &&
          file.exists(caminho) && identical(anterior$hash, calcular_hash_assinatura(caminho, TRUE))
        if (reutilizar) {
          unidade <- ler_rds_recuperavel(caminho,function(x)
            is.list(x) && is.data.frame(x$dados) && is.list(x$diagnostico))
          reutilizar <- !is.null(unidade)
        }
        if (reutilizar) {
          usados <- usados+1L
        } else {
          gravar_validado_atomico(list(estado = 'em_processamento', assinatura = assinatura), manifesto)
          unidade <- tryCatch(ler_padronizar_fidc(membros$caminho[i], id, config, dicionario, basename(registro$arquivo)),
            fidc_erro_leitura = function(e) {
              erro_qualidade <- validar_destino(raiz,paste0(config$saidas,'/qualidade_falha.csv'))
              gravar_validado_atomico(e$qualidade,erro_qualidade,'csv')
              stop(e)
            })
          if(!is.null(filtro)) unidade$dados <- aplicar_indice_filtros_fidc(unidade$dados,filtro$chaves)
          meta <- gravar_validado_atomico(unidade, caminho)
          gravar_validado_atomico(list(estado = 'concluido', assinatura = assinatura,
            hash = meta$hash, linhas = nrow(unidade$dados), entrada = membros$hash[i]), manifesto)
          processados <- processados+1L
          message('P06 processado: ', registro$unidade, '/', id)
        }
        tabelas[[id]][[length(tabelas[[id]])+1L]] <- unidade$dados
        diagnosticos[[paste(registro$unidade,id,sep='/')]] <- unidade$diagnostico
        if (usados+processados >= interromper_apos) stop('Interrupção solicitada após checkpoint válido.')
      }
    }
  }
  incompleto <- length(faltas) > 0L
  if (!length(tabelas) || (incompleto && !config$permitir_parcial)) {
    falha <- list(estado = if (!length(tabelas)) 'sem_unidades_validas' else 'selecao_incompleta',
      incompleto = TRUE, faltas = faltas, geracao = NULL, reutilizados = usados, processados = processados)
    terminar(falha$estado,'Seleção incompleta',plano=vinculo$assinatura)
    finalizado <- TRUE
    return(falha)
  }
  tabelas <- lapply(tabelas,data.table::rbindlist,use.names=TRUE,fill=TRUE)
  tabelas <- tabelas[sort(names(tabelas))]
  for (id in names(tabelas)) data.table::setorderv(tabelas[[id]],
    c('cnpj','dt_comptc','zip_origem','arquivo_origem','linha_origem'))
  qualidade <- data.table::rbindlist(lapply(names(tabelas), function(id)
    relatar_qualidade_fidc(tabelas[[id]],id,dicionario)))
  flat <- if (isTRUE(config$gerar_flat)) consolidar_tabelas_fidc(tabelas, config) else
    list(flat=NULL,auditoria=lapply(tabelas,auditar_chaves_fidc))
  cedentes <- if ('I' %in% names(tabelas)) extrair_cedentes_fidc(tabelas[['I']], config) else NULL
  assinatura_saida <- calcular_hash_assinatura(list(config = config[c('inicio','fim','tabelas',
    'versao_transformacao','completar_zeros','escala_percentual','gerar_flat','exportar_parquet','filtros')],
    plano=vinculo$assinatura, logica=assinatura_transformacao('saida'), mapa=calcular_hash_assinatura(dicionario),
    conteudo = lapply(tabelas, calcular_hash_assinatura)))
  pasta <- validar_destino(raiz, paste0(config$saidas, '/geracoes/', assinatura_saida))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  arquivos <- list()
  for (id in names(tabelas)) {
    d <- tabelas[[id]]
    data.table::setorderv(d, c('cnpj','dt_comptc','zip_origem','arquivo_origem','linha_origem'))
    arquivos[[paste0(id,'_rds')]] <- gravar_validado_atomico(as.data.frame(d), file.path(pasta,paste0('inf_mensal_fidc_tab_',id,'.rds')))
    arquivos[[paste0(id,'_csv')]] <- gravar_validado_atomico(d, file.path(pasta,paste0('inf_mensal_fidc_tab_',id,'.csv')), 'csv')
  }
  if (isTRUE(config$gerar_flat)) {
    arquivos$flat_rds <- gravar_validado_atomico(as.data.frame(flat$flat), file.path(pasta,'inf_mensal_fidc_flat.rds'))
    arquivos$flat_csv <- gravar_validado_atomico(flat$flat, file.path(pasta,'inf_mensal_fidc_flat.csv'), 'csv')
  }
  if (!is.null(cedentes)) {
    arquivos$cedentes_rds <- gravar_validado_atomico(as.data.frame(cedentes), file.path(pasta,'inf_mensal_fidc_cedentes.rds'))
    arquivos$cedentes_csv <- gravar_validado_atomico(cedentes, file.path(pasta,'inf_mensal_fidc_cedentes.csv'), 'csv')
  }
  arquivos$qualidade_csv <- gravar_validado_atomico(qualidade,file.path(pasta,'qualidade.csv'),'csv')
  arquivos$qualidade_rds <- gravar_validado_atomico(as.data.frame(qualidade),file.path(pasta,'qualidade.rds'))
  if (isTRUE(config$exportar_parquet)) {
    exportaveis <- c(tabelas, if (!is.null(flat$flat)) list(flat=flat$flat),
      if (!is.null(cedentes)) list(cedentes=cedentes))
    for (id in names(exportaveis)) arquivos[[paste0(id,'_parquet')]] <-
      exportar_parquet_fidc(exportaveis[[id]],file.path(pasta,paste0(id,'.parquet')))
  }
  vazio_filtrado <- !is.null(filtro) && sum(vapply(tabelas,nrow,integer(1)))==0L
  resultado <- list(estado = if(vazio_filtrado) 'sem_registros_elegiveis' else if (incompleto) 'parcial' else 'concluido', incompleto = incompleto,
    faltas = faltas, geracao = pasta, assinatura = assinatura_saida,
    arquivos = arquivos, config = config, filtros=filtro, codigo = assinatura_codigo(raiz),
    assinatura_plano=vinculo$assinatura, unidades=vinculo$unidades,
    logica=logica, mapa=calcular_hash_assinatura(dicionario),
    logica_saida=assinatura_transformacao('saida'),
    contratos=list(dicionario=list(caminho='referencias/cvm/dicionario_campos_declarados.csv',
      hash=if(file.exists(file.path(raiz,'referencias/cvm/dicionario_campos_declarados.csv')))
        calcular_hash_assinatura(file.path(raiz,'referencias/cvm/dicionario_campos_declarados.csv'),TRUE) else NA_character_)),
    modo = if (isTRUE(config$gerar_flat)) 'completo' else 'temporal',
    linhas_flat = if (is.null(flat$flat)) 0L else nrow(flat$flat),
    colunas_flat = if (is.null(flat$flat)) 0L else ncol(flat$flat),
    linhas_cedentes = if (is.null(cedentes)) 0L else nrow(cedentes),
    linhas_tabelas = vapply(tabelas, nrow, integer(1)), auditoria = flat$auditoria,
    diagnosticos = diagnosticos, reutilizados = usados, processados = processados)
  gravar_validado_atomico(resultado, file.path(pasta,'manifesto_saida.rds'))
  # Ponteiro publicado só depois da geração inteira validada; saídas antigas não são atuais.
  if (identical(resultado$estado,'concluido'))
    gravar_validado_atomico(resultado, validar_destino(raiz,paste0(config$saidas,'/atual.rds')))
  terminar(resultado$estado,assinatura=assinatura_saida,plano=vinculo$assinatura)
  memoria <- gc()
  metricas <- list(assinatura=assinatura_saida,codigo=resultado$codigo,modo=resultado$modo,
    segundos=proc.time()[['elapsed']]-inicio_execucao,
    reutilizados=usados,processados=processados,
    bytes_saidas=sum(file.info(vapply(arquivos,function(x)x$caminho,character(1)))$size),
    memoria_max_gc_mb=sum(memoria[,6]),
    metodo_memoria='Soma dos máximos Ncells/Vcells do gc desde reset; não é pico RSS do processo',
    ambiente=registrar_ambiente())
  destino_metricas <- if(startsWith(config$saidas,'logs/evidencias/')) config$saidas else 'logs'
  gravar_validado_atomico(metricas,validar_destino(raiz,paste0(destino_metricas,'/metricas_',resultado$modo,'.rds')))
  finalizado <- TRUE
  resultado
  },error=function(e) { motivo_falha <<- conditionMessage(e) })
}

# P06-FUN-010 | P06-RF-013: extensão opcional; verifica round-trip antes de publicar.
exportar_parquet_fidc <- function(dados,caminho) {
  if (!requireNamespace('arrow',quietly=TRUE)) stop('Parquet solicitado: instale arrow separadamente.')
  temporario <- tempfile('.parquet-',dirname(caminho))
  on.exit(unlink(temporario),add=TRUE)
  original <- as.data.frame(dados)
  arrow::write_parquet(original,temporario)
  observado <- as.data.frame(arrow::read_parquet(temporario))
  if (!isTRUE(all.equal(original,observado,check.attributes=FALSE))) stop('Parquet divergente.')
  recuperar_rollback(caminho,function(arq) { arrow::read_parquet(arq); TRUE })
  backup <- paste0(caminho,'.rollback')
  if (file.exists(caminho) && !file.rename(caminho,backup)) stop('Parquet bloqueado.')
  if (!file.rename(temporario,caminho)) {
    if (file.exists(backup)) file.rename(backup,caminho)
    stop('Publicação Parquet falhou.')
  }
  if (file.exists(backup)) unlink(backup)
  list(caminho=caminho,hash=calcular_hash_assinatura(caminho,TRUE))
}
