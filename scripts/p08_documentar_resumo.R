# P08-FUN-002 | P08-RF-004/011: entrada compatível, usa os mesmos cálculos do painel.
documentar_resumo_dados_fidc <- function(arquivo_config='dados/atualizacao_2020/configuracao.rds') {
  c <- readRDS(arquivo_config); config <- if('config' %in% names(c)) c$config else c
  x <- readRDS(file.path(config$saidas,'resumo_estatisticas/resumo_historico.rds'))
  if(is.null(x$analise)||!identical(x$metadados$schema,'p08-v2026-10-07')) stop('Execute P08 para gerar os cálculos atuais antes de documentar.')
  e <- new.env(parent=globalenv())
  for(n in c('p08_exportar_painel.R','p08_relatorio_analise.R')) sys.source(file.path('scripts',n),envir=e)
  e$documentar_analise_fidc(x$analise,x$metadados,e$dicionario_analitico_fidc(x$analise,x$metadados))
  invisible(x$metadados)
}
if(sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE)
  if(dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'),.libPaths()))
  documentar_resumo_dados_fidc(if(length(args)) args[1] else 'dados/atualizacao_2020/configuracao.rds')
}
