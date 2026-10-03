# P01-MOD-001 | Entrada P04-P07, coordenação explícita, sem efeitos em source().
# P01-FUN-002 | P01-RF-001/002, P02-RF-006, P07-RF-001.
# Entradas: etapa/configuração/raiz/limite; saída: resultado persistido.
# Efeitos: somente etapa solicitada, sem Git ou avanço automático.
executar_pipeline_etapa <- function(etapa, configuracao = list(), raiz = '.', interromper_apos = Inf) {
  if (length(etapa) != 1L || !etapa %in% paste0('P0',4:7)) stop('Informe P04, P05, P06 ou P07.')
  ambiente <- new.env(parent = globalenv())
  sys.source(file.path(raiz,'scripts/p02_utilitarios.R'),envir=ambiente)
  ambiente <- ambiente$carregar_pipeline(raiz)
  bibliotecas <- .libPaths()
  on.exit(.libPaths(bibliotecas),add=TRUE)
  if (dir.exists(file.path(raiz,'.R-library')))
    .libPaths(c(normalizePath(file.path(raiz,'.R-library')),bibliotecas))
  if ('config' %in% names(configuracao)) configuracao <- configuracao$config
  config <- ambiente$validar_configuracao(configuracao,raiz)
  if (etapa %in% c('P04','P05','P06')) {
    terminar <- ambiente$registrar_tentativa(config,raiz,etapa)
    finalizado <- FALSE
    motivo_falha <- 'Etapa interrompida ou não concluída'
    on.exit(if(!finalizado) terminar('falhou',motivo_falha),add=TRUE)
  }
  withCallingHandlers({
  caminho_config <- ambiente$validar_destino(raiz,paste0(config$dados,'/configuracao.rds'))
  if (etapa == 'P04') {
    inventario <- ambiente$inventariar_recursos_fidc(config)
    plano <- ambiente$selecionar_unidades_fidc(config,inventario)
    vinculo <- ambiente$assinar_plano_fidc(plano,config)
    resultado <- list(config=config,inventario=inventario,plano=plano,assinatura_plano=vinculo$assinatura)
    ambiente$gravar_validado_atomico(resultado,caminho_config)
    terminar('etapa_concluida',plano=vinculo$assinatura); finalizado <- TRUE
    return(resultado)
  }
  if (!file.exists(caminho_config)) stop('Execute P04 primeiro.')
  preparado <- ambiente$ler_rds_recuperavel(caminho_config)
  if (is.null(preparado)) stop('Configuração inválida: execute P04 novamente.')
  if (!identical(config[c('inicio','fim','tabelas')],preparado$config[c('inicio','fim','tabelas')]))
    stop('Configuração mudou: execute P04 novamente.')
  caminho_downloads <- ambiente$validar_destino(raiz,paste0(config$dados,'/downloads.rds'))
  if (etapa == 'P05') {
    resultado <- ambiente$retomar_downloads_fidc(preparado$plano,config,raiz)
    ambiente$gravar_validado_atomico(resultado,caminho_downloads)
    for (registro in resultado) if (registro$estado == 'concluido')
      ambiente$extrair_zip_fidc(registro,config,raiz)
    ok <- all(vapply(resultado,function(x)identical(x$estado,'concluido'),logical(1)))
    terminar(if(ok) 'etapa_concluida' else 'falhou',
      if(!ok) 'Downloads não concluídos',plano=ambiente$assinar_plano_fidc(preparado$plano,config)$assinatura)
    finalizado <- TRUE
    return(resultado)
  }
  if (etapa == 'P06') {
    if (!file.exists(caminho_downloads)) stop('Execute P05 primeiro.')
    dicionario <- read.csv(file.path(raiz,'P04_CAMPOS_DECLARADOS_DICIONARIO.csv'),
      stringsAsFactors=FALSE,fileEncoding='UTF-8')
    downloads <- ambiente$ler_rds_recuperavel(caminho_downloads)
    if (is.null(downloads)) stop('Registro de downloads inválido: execute P05 novamente.')
    resultado <- ambiente$retomar_consolidacao_fidc(downloads,config,raiz,dicionario,interromper_apos)
    terminar(resultado$estado,assinatura=resultado$assinatura,plano=resultado$assinatura_plano)
    finalizado <- TRUE
    return(resultado)
  }
  caminho_atual <- ambiente$validar_destino(raiz,paste0(config$saidas,'/atual.rds'))
  if (!file.exists(caminho_atual)) stop('Execute P06 primeiro.')
  resultado <- ambiente$ler_rds_recuperavel(caminho_atual)
  if (is.null(resultado)) stop('Geração atual inválida, execute P06 novamente.')
  caminho_evidencias <- file.path(raiz,'logs/evidencias_aceite.rds')
  evidencia <- ambiente$ler_rds_recuperavel(caminho_evidencias)
  ambiente$executar_aceite(resultado,config,evidencias=evidencia,raiz=raiz)
  },error=function(e) { if(etapa!='P07') motivo_falha <<- conditionMessage(e) })
}
# P01-FUN-002 | Interface terminal, impressão e código de saída.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly=TRUE)
  if (!length(args) || length(args)>3L) stop('Uso: p01_pipeline_fidc.R P04..P07 [config.rds] [limite]')
  entrada <- if (length(args)>=2L) readRDS(args[2]) else list()
  resultado <- executar_pipeline_etapa(args[1],entrada,
    interromper_apos=if (length(args)>=3L) as.numeric(args[3]) else Inf)
  if (args[1]=='P04') print(resultado$plano) else if (args[1]=='P05') {
    print(vapply(resultado,function(x)x$estado,character(1)))
    if (any(vapply(resultado,function(x)x$estado!='concluido',logical(1)))) quit(status=1)
  } else if (args[1]=='P06') {
    print(resultado[c('estado','geracao','linhas_flat','colunas_flat','linhas_cedentes','reutilizados','processados')])
    if (!identical(resultado$estado,'concluido')) quit(status=1)
  } else {
    print(resultado)
    if (!isTRUE(resultado$aceite_local)) quit(status=1)
  }
}
