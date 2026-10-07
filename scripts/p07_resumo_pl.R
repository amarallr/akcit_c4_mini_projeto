# P07-MOD-003 | P07-RF-007: estatísticas descritivas; nenhuma alteração dos datasets.
# P07-FUN-005 | Uma observação de PL por CNPJ/tipo/data; quantis R tipo 7.
resumir_pl_mensal <- function(dados) {
  campos <- c('cnpj','dt_comptc','TAB_IV_A_VL_PL')
  if (!is.data.frame(dados) || !all(campos %in% names(dados))) stop('Tabela IV incompatível.')
  chave <- c('cnpj','dt_comptc',if('TP_FUNDO_CLASSE' %in% names(dados)) 'TP_FUNDO_CLASSE')
  if (anyNA(dados$cnpj) || any(!nzchar(trimws(dados$cnpj))) || anyNA(dados$dt_comptc) ||
      anyDuplicated(dados[chave])) stop('Chave IV inválida ou duplicada; PL não pode ser contado duas vezes.')
  if (!is.numeric(dados$TAB_IV_A_VL_PL) ||
      any(!is.finite(dados$TAB_IV_A_VL_PL[!is.na(dados$TAB_IV_A_VL_PL)]))) stop('PL incompatível.')
  datas <- as.character(as.Date(dados$dt_comptc))
  if (!length(datas)) stop('Tabela IV sem registros.')
  partes <- lapply(sort(unique(datas)),function(data) {
    raw <- dados$TAB_IV_A_VL_PL[datas==data]; pl <- raw[!is.na(raw)]
    q <- if(length(pl)) stats::quantile(pl,probs=c(0,.25,.5,.75,1),type=7,names=FALSE) else rep(NA_real_,5)
    media <- if(length(pl)) mean(pl) else NA_real_
    cv <- if(length(pl)>=2L && !is.na(media) && media!=0) stats::sd(pl)/media*100 else NA_real_
    data.frame(data_competencia=data,competencia=substr(data,1,7),registros_com_pl=length(pl),registros_sem_pl=sum(is.na(raw)),
      pl_total_calculado=if(length(pl)) sum(pl) else NA_real_,pl_media_valor_fonte=media,
      pl_max_valor_fonte=q[5],pl_percentil_75_valor_fonte=q[4],pl_mediana_valor_fonte=q[3],
      pl_percentil_25_valor_fonte=q[2],pl_min_valor_fonte=q[1],pl_coeficiente_variacao_percentual=cv,
      cv_definicao=if(length(pl)<2L) 'amostra_insuficiente' else if(media==0) 'media_zero' else 'amostral_sd_sobre_media_vezes_100',
      quantis_metodo='R_tipo_7',stringsAsFactors=FALSE)
  })
  do.call(rbind,partes)
}

# Associação exata por CNPJ/tipo/data, sem multiplicar observações de PL.
associar_administradores_pl <- function(iv, cadastro) {
  resumir_pl_mensal(iv)
  campos <- c('cnpj','dt_comptc','CNPJ_ADMIN','ADMIN')
  tipo_iv <- 'TP_FUNDO_CLASSE' %in% names(iv)
  tipo_i <- 'TP_FUNDO_CLASSE' %in% names(cadastro)
  if(!identical(tipo_iv,tipo_i)) stop('Tipo fundo/classe ausente em apenas uma das tabelas.')
  if(tipo_iv) campos <- c(campos,'TP_FUNDO_CLASSE')
  if (!all(campos %in% names(cadastro)) || anyNA(cadastro[c('cnpj','dt_comptc')]) ||
      anyDuplicated(cadastro[c('cnpj','dt_comptc',if(tipo_i) 'TP_FUNDO_CLASSE')]))
    stop('Cadastro I incompatível ou chave duplicada.')
  chave <- function(d) {
    partes <- list(d$cnpj,as.character(as.Date(d$dt_comptc)))
    if(tipo_iv) partes <- c(partes,list(ifelse(is.na(d$TP_FUNDO_CLASSE),'<NA>',d$TP_FUNDO_CLASSE)))
    do.call(paste,c(partes,list(sep='|')))
  }
  pos <- match(chave(iv),chave(cadastro))
  if(anyNA(pos)) stop('PL sem cadastro I na mesma data.')
  iv$cnpj_admin <- gsub('[^A-Za-z0-9]','',trimws(cadastro$CNPJ_ADMIN[pos]))
  iv$administrador <- trimws(cadastro$ADMIN[pos])
  iv$cnpj_admin[is.na(iv$cnpj_admin) | !nzchar(iv$cnpj_admin)] <- NA_character_
  iv$administrador[is.na(iv$administrador) | !nzchar(iv$administrador)] <- NA_character_
  iv
}

resumir_pl_administradores <- function(dados) {
  resumir_pl_mensal(dados)
  if(!all(c('cnpj_admin','administrador') %in% names(dados))) stop('Administradores ausentes.')
  dados <- dados[!is.na(dados$cnpj_admin) & nzchar(dados$cnpj_admin),,drop=FALSE]
  if(!nrow(dados)) stop('Nenhum PL com administrador identificado para o ranking.')
  datas <- as.character(as.Date(dados$dt_comptc))
  pl <- dados$TAB_IV_A_VL_PL
  for(data in unique(datas)) {
    i <- which(datas==data & !is.na(pl))
    if(length(i)) {
      limites <- stats::quantile(pl[i],c(.025,.975),type=7,names=FALSE)
      pl[i] <- pmax(limites[1],pmin(limites[2],pl[i]))
    }
  }
  trimestre <- paste0(substr(datas,1,4),'_T',(as.integer(substr(datas,6,7))-1L)%/%3L+1L)
  ids <- sort(unique(dados$cnpj_admin))
  saida <- data.frame(cnpj_admin=ids,administrador=vapply(ids,function(id) {
    nomes <- dados$administrador[dados$cnpj_admin==id]
    nomes <- sort(unique(nomes[!is.na(nomes) & nzchar(nomes)]))
    if(length(nomes)) paste(nomes,collapse=' / ') else NA_character_
  },character(1)),stringsAsFactors=FALSE)
  meses <- as.integer(format(as.Date(dados$dt_comptc),'%m'))
  datas_date <- as.Date(dados$dt_comptc)
  for(t in sort(unique(trimestre))) {
    q <- as.integer(sub('.*_T','',t))
    mes_final <- q*3L
    candidatos <- which(trimestre==t & meses==mes_final)
    data_final <- if(length(candidatos)) max(datas_date[candidatos]) else as.Date(NA_character_)
    saida[[paste0('pl_',t)]] <- vapply(ids,function(id) {
      if(is.na(data_final)) return(NA_real_)
      pos <- which(datas_date==data_final & dados$cnpj_admin==id)
      valores <- dados$TAB_IV_A_VL_PL[pos]
      if(!length(valores)) NA_real_ else if(all(is.na(valores))) NA_real_ else sum(valores,na.rm=TRUE)
    },numeric(1))
  }
  saida$quantidade_fundos <- vapply(ids,function(id)
    length(unique(dados$cnpj[dados$cnpj_admin==id])),integer(1))
  saida$pl_soma_periodo <- vapply(ids,function(id) {
    valores <- pl[dados$cnpj_admin==id]
    if(all(is.na(valores))) NA_real_ else sum(valores,na.rm=TRUE)
  },numeric(1))
  total <- if(all(is.na(pl))) NA_real_ else sum(pl,na.rm=TRUE)
  saida$percentual_pl_total <- if(is.na(total) || total==0) NA_real_ else saida$pl_soma_periodo/total*100
  saida <- saida[order(-saida$pl_soma_periodo,saida$cnpj_admin,na.last=TRUE),]
  rownames(saida) <- NULL
  head(saida,25L)
}

# P07-FUN-006 | Acrescenta colunas, preservando a soma decimal publicada e datasets.
atualizar_resumo_pl <- function(raiz='.',config=list()) {
  p <- carregar_pipeline(raiz); config <- p$validar_configuracao(config,raiz)
  atual <- readRDS(file.path(raiz,config$saidas,'atual.rds'))
  tentativa <- readRDS(file.path(raiz,config$saidas,'execucao.rds'))
  if (!identical(atual$estado,'concluido') || !identical(tentativa$estado,'concluido') ||
      !identical(tentativa$etapa,'P06') || !identical(tentativa$assinatura,atual$assinatura) ||
      !identical(atual$config,config)) stop('Tentativa e geração atuais incompatíveis; execute P06.')
  caminho <- file.path(atual$geracao,'inf_mensal_fidc_tab_IV.rds')
  meta <- atual$arquivos$IV_rds
  if (is.null(meta) || !identical(meta$hash,calcular_hash_assinatura(caminho,TRUE))) stop('Tabela IV alterada.')
  caminho_i <- file.path(atual$geracao,'inf_mensal_fidc_tab_I.rds')
  if(is.null(atual$arquivos$I_rds) || !identical(atual$arquivos$I_rds$hash,calcular_hash_assinatura(caminho_i,TRUE))) stop('Tabela I alterada.')
  dados <- associar_administradores_pl(readRDS(caminho),readRDS(caminho_i))
  estatisticas <- resumir_pl_mensal(dados)
  estatisticas$quantidade_administradores <- vapply(estatisticas$data_competencia,function(data)
    length(unique(dados$cnpj_admin[as.character(dados$dt_comptc)==data & !is.na(dados$cnpj_admin)])),integer(1))
  ranking <- resumir_pl_administradores(dados)
  destino <- file.path(raiz,'resultados/estatisticas/estatisticas_por_competencia.csv')
  dir.create(dirname(destino),recursive=TRUE,showWarnings=FALSE)
  resumo <- read.csv(destino,stringsAsFactors=FALSE,colClasses=c(pl_total_valor_fonte='character'))
  if ('data_competencia' %in% names(resumo)) {
    pos <- match(resumo$data_competencia,estatisticas$data_competencia)
    mesmas <- setequal(resumo$data_competencia,estatisticas$data_competencia)
  } else {
    # Migração do relatório mensal antigo só quando há uma data exata por mês.
    if(anyDuplicated(estatisticas$competencia)) stop('Resumo mensal antigo abrange várias datas de competência; migração exige revisão, sem agregar as datas.')
    pos <- match(resumo$competencia,estatisticas$competencia)
    mesmas <- setequal(resumo$competencia,estatisticas$competencia)
  }
  if (anyNA(pos) || !mesmas ||
      any(abs(as.numeric(resumo$pl_total_valor_fonte)-estatisticas$pl_total_calculado[pos])>.005))
    stop('Seleção/soma do resumo anterior incompatível com IV; revisar antes de substituir.')
  novas <- setdiff(names(estatisticas),c('competencia','pl_total_calculado'))
  for(nome in novas) resumo[[nome]] <- estatisticas[[nome]][pos]
  # O formato original desse artefato de documentação é CSV separado por vírgula.
  temporario <- tempfile('.resumo-pl-',dirname(destino))
  on.exit(unlink(temporario),add=TRUE)
  utils::write.csv(resumo,temporario,row.names=FALSE,na='',fileEncoding='UTF-8')
  observado <- read.csv(temporario,stringsAsFactors=FALSE,colClasses=c(pl_total_valor_fonte='character'))
  if (!identical(observado$pl_total_valor_fonte,resumo$pl_total_valor_fonte) || nrow(observado)!=nrow(resumo)) stop('Resumo divergente.')
  backup <- paste0(destino,'.rollback')
  if(file.exists(backup)) stop('Rollback do resumo pendente.')
  if(!file.rename(destino,backup)) stop('Resumo bloqueado.')
  if(!file.rename(temporario,destino)) {file.rename(backup,destino);stop('Publicação do resumo falhou.')}
  unlink(backup)
  utils::write.csv(ranking,file.path(raiz,'resultados/estatisticas/top25_administradores.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
  pasta <- file.path(raiz,config$saidas,'resumos_piloto')
  dir.create(pasta,recursive=TRUE,showWarnings=FALSE)
  utils::write.csv(resumo,file.path(pasta,'resumo_competencias.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
  utils::write.csv(ranking,file.path(pasta,'top25_administradores.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
  saveRDS(list(assinatura=atual$assinatura,competencias=resumo,administradores=ranking,
    metodo='Winsorização por DT_COMPTC, quantis tipo 7: 2,5% e 97,5%; ranking pela soma no período; percentual sobre todo PL winsorizado.'),
    file.path(pasta,'resumo_piloto.rds'))
  if (normalizePath(raiz,winslash='/')==normalizePath(getwd(),winslash='/'))
    sys.source(file.path(raiz,'scripts/p07_documentar_resumo.R'),envir=new.env(parent=globalenv()))
  resumo
}

if(sys.nframe()==0L) {
  .libPaths(c(normalizePath('.R-library'),.libPaths()))
  source('scripts/p02_utilitarios.R')
  args <- commandArgs(trailingOnly=TRUE)
  config <- if(length(args)) readRDS(args[1]) else list()
  if('config'%in%names(config)) config <- config$config
  print(atualizar_resumo_pl(config=config))
}
