# P07-MOD-001 | Avaliação de evidências, sem fabricar aprovação.

# P07-FUN-002 | Pendências impedem aceite; sincronização distinta do resultado local.
gerar_relatorio_aceite <- function(resultado, testes_aprovados = FALSE,
    retomada_demonstrada = FALSE, sincronizado = FALSE, pendencias = character()) {
  faltas <- pendencias
  if (!identical(resultado$estado, 'concluido') || isTRUE(resultado$incompleto))
    faltas <- c(faltas, 'Piloto incompleto')
  if (!isTRUE(testes_aprovados)) faltas <- c(faltas, 'Testes não aprovados')
  if (!isTRUE(retomada_demonstrada)) faltas <- c(faltas, 'Retomada em processo novo não demonstrada')
  local <- !length(faltas)
  list(aceite_local = local, aceite_completo = local && isTRUE(sincronizado),
    pendencias = unique(c(faltas, if (!sincronizado) 'Sincronização não confirmada')))
}

# P07-FUN-001 | Verifica artefatos observados e resultado atual, sem chamar Git.
executar_aceite <- function(resultado, config, testes_aprovados = FALSE,
    retomada_demonstrada = FALSE, sincronizado = FALSE, evidencias = NULL, raiz = '.') {
  pendencias <- character()
  vinculo <- tryCatch({
    downloads <- ler_rds_recuperavel(file.path(raiz,config$dados,'downloads.rds'))
    validar_downloads_plano(downloads,config,raiz)
  },error=function(e)NULL)
  if (is.null(vinculo) || !identical(vinculo$assinatura,resultado$assinatura_plano) ||
      !identical(vinculo$unidades,resultado$unidades))
    pendencias <- c(pendencias,'Plano, downloads e geração incompatíveis')
  if (!identical(resultado$config,config)) pendencias <- c(pendencias,'Configuração incompatível')
  execucao <- ler_rds_recuperavel(file.path(raiz,config$saidas,'execucao.rds'))
  if (is.null(execucao) || !identical(execucao$estado,'concluido') ||
      !identical(execucao$assinatura,resultado$assinatura))
    pendencias <- c(pendencias,'Execução atual não concluída')
  if (is.null(resultado$geracao)) pendencias <- 'Geração atual ausente' else {
    esperados <- c(paste0('inf_mensal_fidc_tab_',rep(config$tabelas,each=2),rep(c('.csv','.rds'),length(config$tabelas))),
      if (isTRUE(config$gerar_flat)) c('inf_mensal_fidc_flat.csv','inf_mensal_fidc_flat.rds'),
      'qualidade.csv','qualidade.rds',
      if ('I'%in%config$tabelas) c('inf_mensal_fidc_cedentes.csv','inf_mensal_fidc_cedentes.rds'))
    if (any(!file.exists(file.path(resultado$geracao, esperados)))) pendencias <- 'Saída obrigatória ausente'
    if (!length(resultado$arquivos)) pendencias <- c(pendencias,'Hashes de saída ausentes')
    registrados <- vapply(resultado$arquivos,function(x)basename(x$caminho),character(1))
    if (anyDuplicated(registrados)) pendencias <- c(pendencias,'Registro de saída duplicado')
    if (any(!esperados%in%registrados)) pendencias <- c(pendencias,'Hash obrigatório ausente')
    for (meta in resultado$arquivos) {
      if (!identical(normalizePath(dirname(meta$caminho),winslash='/',mustWork=FALSE),
          normalizePath(resultado$geracao,winslash='/',mustWork=FALSE)))
        pendencias <- c(pendencias,'Hash não corresponde ao arquivo da geração')
      if (!file.exists(meta$caminho) || !identical(meta$hash,calcular_hash_assinatura(meta$caminho,TRUE)))
        pendencias <- c(pendencias,'Saída alterada após validação')
    }
    if (!length(pendencias)) {
      chaves <- list()
      bases <- c(paste0('inf_mensal_fidc_tab_',config$tabelas),
        if(isTRUE(config$gerar_flat)) 'inf_mensal_fidc_flat',
        if('I'%in%config$tabelas) 'inf_mensal_fidc_cedentes','qualidade')
      for (base in bases) {
        rds <- readRDS(file.path(resultado$geracao,paste0(base,'.rds')))
        caminho <- file.path(resultado$geracao,paste0(base,'.csv'))
        cabecalho <- data.table::fread(caminho,sep=';',nrows=0,showProgress=FALSE)
        csv <- data.table::fread(caminho,sep=';',select=if(base=='qualidade') 1L else c('cnpj','dt_comptc'),
          colClasses='character',showProgress=FALSE)
        if (!identical(names(rds),names(cabecalho)) || nrow(rds)!=nrow(csv))
          pendencias <- c(pendencias,'Esquema ou contagem CSV/RDS divergente')
        if (base=='qualidade') next
        if (!all(c('cnpj','dt_comptc') %in% names(rds))) {
          pendencias <- c(pendencias,'Chave obrigatória ausente'); next
        }
        for (d in list(csv,rds)) {
          ni <- toupper(gsub('[./[:space:]-]','',as.character(d$cnpj)))
          raw <- as.character(d$dt_comptc)
          datas <- suppressWarnings(as.Date(raw,format='%Y-%m-%d'))
          if (anyNA(ni) || any(!nzchar(ni)) || anyNA(datas) ||
              any(format(datas,'%Y-%m-%d')!=raw) ||
              any(datas<as.Date(config$inicio) | datas>as.Date(config$fim)))
            pendencias <- c(pendencias,'Identidade ou competência inválida')
        }
        if (startsWith(base,'inf_mensal_fidc_tab_')) {
          id <- sub('inf_mensal_fidc_tab_','',base,fixed=TRUE)
          if (!identical(as.integer(resultado$linhas_tabelas[[id]]),as.integer(nrow(rds))))
            pendencias <- c(pendencias,'Contagem temporal incompatível')
          chaves[[base]] <- csv
        }
        if (!identical(as.character(rds$cnpj),csv$cnpj) ||
            !identical(as.character(rds$dt_comptc),csv$dt_comptc))
          pendencias <- c(pendencias,'Chaves CSV/RDS divergentes')
      }
      uniao <- unique(data.table::rbindlist(chaves))
      if (!nrow(uniao)) pendencias <- c(pendencias,'Seleção sem registros: aceite pendente')
    }
    if (!length(pendencias) && isTRUE(config$gerar_flat)) {
      # Ler somente a chave do CSV reduz memória do aceite de um flat muito largo.
      flat <- data.table::fread(file.path(resultado$geracao,'inf_mensal_fidc_flat.csv'),sep=';',
        select=c('cnpj','dt_comptc'),colClasses='character',showProgress=FALSE)
      if (!nrow(flat) || anyDuplicated(flat)) pendencias <- 'Chave flat inválida'
      if (!data.table::fsetequal(flat,uniao)) pendencias <- c(pendencias,'Cobertura de chaves divergente')
    }
  }
  provas_validas <- tryCatch(isTRUE(validar_evidencias_aceite(evidencias,resultado,config,raiz)),
    error=function(e)FALSE)
  if (!provas_validas) pendencias <- c(pendencias,'Evidências automáticas ausentes, inválidas ou de outro código')
  relatorio <- gerar_relatorio_aceite(resultado, provas_validas, provas_validas, sincronizado, pendencias)
  relatorio$modo <- if(isTRUE(config$gerar_flat)) 'completo' else 'temporal'
  relatorio$aceite_piloto_completo <- relatorio$aceite_completo && isTRUE(config$gerar_flat)
  relatorio
}
