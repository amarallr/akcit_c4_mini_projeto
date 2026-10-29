# Lastro CO-STAR: prompts/02_utilitarios_dependencias_testes.txt
# Módulo: P02-MOD-002 | P02 — Runner | P02-RF-004.
# Entradas: etapa, subetapa ou todas; P05/P06 selecionam suas duas subetapas.
# Efeitos: testes locais em arquivos temporários, sem rede ou instalações.
# P02-TST-005: seleção e suíte das etapas implementadas, sem presumir futuras.
argumentos <- commandArgs(trailingOnly = TRUE)
etapa <- if (length(argumentos)) argumentos[1] else 'todas'
opcoes <- c('P01','P02','P03','P04','P05','P05_01','P05_02',
            'P06','P06_01','P06_02','P07','todas')
if (length(argumentos) > 1 || !etapa %in% opcoes)
  stop('Use P01 a P07, P05_01/P05_02, P06_01/P06_02 ou todas.')
if (!file.exists('C4-Mini-projeto.Rproj')) stop('Execute da raiz do projeto.')
bibliotecas_anteriores <- .libPaths()
Sys.setenv(FIDC_TESTES_ATIVOS='1')
dir.create('logs',recursive=TRUE,showWarnings=FALSE)
source('src/utils/p02_utilitarios.R',encoding='UTF-8')
codigo_teste <- NULL
concluiu <- FALSE
tryCatch({
  if (dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'), .libPaths()))
  if (!requireNamespace('testthat', quietly = TRUE)) stop('testthat ausente.')
  codigo_teste <- assinatura_codigo('.')
  jsonlite::write_json(list(estado='em_processamento',codigo=codigo_teste),
    'logs/testes_resumo.json',auto_unbox=TRUE,pretty=TRUE)
  cat('Suíte local por etapas e subetapas; sem aquisição real de dados.\n')
  suites <- c(P01 = 'tests/testthat/test-p01-orquestracao.R',
    P02 = 'tests/testthat/test-p02-utilitarios.R',
    P03 = 'tests/testthat/test-p03-ambiente.R',
    P04 = 'tests/testthat/test-p04-configuracao.R',
    P05_01 = 'tests/testthat/test-p05_01-download-fidc.R',
    P05_02 = 'tests/testthat/test-p05_02-download-fii.R',
    P06_01 = 'tests/testthat/test-p06_01-consolidacao-fidc.R',
    P06_02 = 'tests/testthat/test-p06_02-consolidacao-fii.R',
    P07 = 'tests/testthat/test-p07-aceite.R')
  selecionadas <- if (etapa == 'todas') suites else if (etapa %in% c('P05','P06'))
    suites[startsWith(names(suites), paste0(etapa, '_'))] else suites[names(suites) == etapa]
  resultados <- lapply(selecionadas, function(arquivo)
    testthat::test_file(arquivo, reporter = 'summary', stop_on_failure = TRUE))
  dir.create('logs', recursive=TRUE, showWarnings = FALSE)
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
