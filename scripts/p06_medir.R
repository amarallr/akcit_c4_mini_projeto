# P06-MOD-002 | P06-RF-013: comparar modos com entradas locais, sem download.
# P06-FUN-009 | Tempo de parede, bytes publicados e máximos do heap observado por gc.
medir_pipeline <- function(config=list(),raiz='.') {
  p <- carregar_pipeline(raiz)
  config <- p$validar_configuracao(config,raiz)
  downloads <- p$ler_rds_recuperavel(file.path(raiz,config$dados,'downloads.rds'))
  if (is.null(downloads)) stop('Downloads locais válidos necessários.')
  mapa <- read.csv(file.path(raiz,'referencias/cvm/dicionario_campos_declarados.csv'),stringsAsFactors=FALSE)
  medicoes <- list()
  for (modo in c('temporal','completo')) {
    config$gerar_flat <- modo=='completo'
    p$retomar_consolidacao_fidc(downloads,config,raiz,mapa)
    metrica <- readRDS(file.path(raiz,'logs',paste0('metricas_',modo,'.rds')))
    medicoes[[modo]] <- data.frame(modo=modo,segundos=metrica$segundos,
      reutilizados=metrica$reutilizados,processados=metrica$processados,
      bytes_saidas=metrica$bytes_saidas,memoria_max_gc_mb=metrica$memoria_max_gc_mb,
      metodo_memoria=metrica$metodo_memoria,codigo=metrica$codigo,assinatura=metrica$assinatura)
  }
  comparacao <- do.call(rbind,medicoes)
  p$gravar_validado_atomico(comparacao,file.path(raiz,'logs/comparacao_desempenho.csv'),'csv')
  comparacao
}
if (sys.nframe()==0L) {
  .libPaths(c(normalizePath('.R-library'),.libPaths()))
  source('scripts/p02_utilitarios.R')
  args <- commandArgs(trailingOnly=TRUE)
  config <- if(length(args)) readRDS(args[1]) else list()
  if ('config' %in% names(config)) config <- config$config
  print(medir_pipeline(config))
}
