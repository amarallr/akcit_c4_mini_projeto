# Módulo: P02-MOD-002 | P02 — Runner | P02-RF-004.
# Entradas: etapa opcional (P01, P03 ou todas); saída: resultados/exit code.
# Efeitos: testes locais em arquivos temporários, sem rede ou instalações.
# P02-TST-005: seleção e suíte das etapas implementadas, sem presumir futuras.
argumentos <- commandArgs(trailingOnly = TRUE)
etapa <- if (length(argumentos)) argumentos[1] else 'todas'
if (length(argumentos) > 1 || !etapa %in% c(paste0('P0', 1:7), 'todas'))
  stop('Use P01 a P07 ou todas.')
if (!file.exists('C4-Mini-projeto.Rproj')) stop('Execute da raiz do projeto.')
bibliotecas_anteriores <- .libPaths()
Sys.setenv(FIDC_TESTES_ATIVOS='1')
dir.create('logs',showWarnings=FALSE)
source('scripts/p02_utilitarios.R',encoding='UTF-8')
codigo_teste <- NULL
concluiu <- FALSE
tryCatch({
  if (dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'), .libPaths()))
  if (!requireNamespace('testthat', quietly = TRUE)) stop('testthat ausente.')
  codigo_teste <- assinatura_codigo('.')
  jsonlite::write_json(list(estado='em_processamento',codigo=codigo_teste),
    'logs/testes_resumo.json',auto_unbox=TRUE,pretty=TRUE)
  cat('Suíte local P01 a P07; P03 conserva apenas testes históricos, sem testar o roteiro de instalação.\n')
  suites <- c(P01 = 'tests/testthat/test-p01-orquestracao.R',
    P02 = 'tests/testthat/test-p02-utilitarios.R',
    P03 = 'tests/testthat/test-p03-ambiente.R',
    P04 = 'tests/testthat/test-p04-configuracao.R',
    P05 = 'tests/testthat/test-p05-download.R',
    P06 = 'tests/testthat/test-p06-consolidacao.R',
    P07 = 'tests/testthat/test-p07-aceite.R')
  selecionadas <- if (etapa == 'todas') suites else suites[etapa]
  resultados <- lapply(selecionadas, function(arquivo)
    testthat::test_file(arquivo, reporter = 'summary', stop_on_failure = TRUE))
  dir.create('logs', showWarnings = FALSE)
  saveRDS(resultados, 'logs/testes.rds')
  contagens <- do.call(rbind,lapply(resultados,as.data.frame))
  resumo <- list(estado='concluido',suite=etapa,codigo=codigo_teste,
    ambiente=registrar_ambiente(),origem=if(Sys.getenv('GITHUB_ACTIONS')=='true') 'CI' else 'local',
    casos=nrow(contagens),verificacoes=sum(contagens$nb),aprovadas=sum(contagens$passed),
    falhas=sum(contagens$failed),erros=sum(contagens$error),avisos=sum(contagens$warning),
    skips=sum(contagens$skipped),hash_resultados=calcular_hash_assinatura('logs/testes.rds',TRUE))
  jsonlite::write_json(resumo,'logs/testes_resumo.json',auto_unbox=TRUE,pretty=TRUE)
  concluiu <- TRUE
}, finally = {
  if (!concluiu && requireNamespace('jsonlite',quietly=TRUE))
    jsonlite::write_json(list(estado='falhou',codigo=codigo_teste),'logs/testes_resumo.json',auto_unbox=TRUE)
  .libPaths(bibliotecas_anteriores)
})
