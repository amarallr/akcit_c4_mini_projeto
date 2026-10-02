source('helper-p02-pipeline.R')
testthat::test_that('P04-TST-003: modos explícitos preservam flat como padrão', {
  testthat::expect_true(pipeline$validar_configuracao()$gerar_flat)
  testthat::expect_false(pipeline$validar_configuracao()$exportar_parquet)
  testthat::expect_error(pipeline$validar_configuracao(list(gerar_flat='não')),'booleano')
  testthat::expect_false(pipeline$validar_configuracao(list(gerar_flat=FALSE))$gerar_flat)
})
testthat::test_that('P04-TST-001: contratos de configuração rejeitam entradas inválidas', {
  testthat::expect_identical(pipeline$validar_configuracao()$inicio,'2026-07-01')
  for (config in list(list(dataset='FII'),list(inicio='2026-02-30'),list(fim='2025-01-01'),
      list(tabelas='XXX'),list(dados='../fora'),list(timeout=NA_real_),list(usar_checkpoints=NA)))
    testthat::expect_error(pipeline$validar_configuracao(config))
})
testthat::test_that('P04-TST-002/003: seleção histórica não inventa meses e subdivisões são explícitas', {
  config <- pipeline$validar_configuracao(list(inicio='2024-07-01',fim='2024-08-31'))
  inventario <- pipeline$inventariar_recursos_fidc(config,list(DADOS='inf_mensal_fidc_202501.zip',HIST='inf_mensal_fidc_2024.zip'))
  plano <- pipeline$selecionar_unidades_fidc(config,inventario)
  testthat::expect_equal(nrow(plano),1)
  testthat::expect_identical(plano$unidade,'2024')
  config$inicio <- '2023-01-01'
  testthat::expect_error(pipeline$selecionar_unidades_fidc(config,inventario),'indisponível')
  mapa <- read.csv('../../P04_CAMPOS_DECLARADOS_DICIONARIO.csv')
  testthat::expect_true(all(c('I','VIII','X','X_1_1','X_7') %in% mapa$tabela))
  testthat::expect_equal(mapa$tipo[mapa$tabela=='VIII'&mapa$campo=='SEQUENCIAL'],'bigint')
})
