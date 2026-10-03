source('helper-p02-pipeline.R')

testthat::test_that('P04-TST-005: ZIP anual filtra competências sem sobreposição mensal', {
  raiz <- tempfile();dir.create(raiz)
  config <- pipeline$validar_configuracao(list(tabelas='I'),raiz)
  plano <- data.frame(unidade='2026',arquivo='inf_mensal_fidc_2026.zip',url='simulado/2026')
  zip <- fixture_zip(file.path(raiz,'anual.zip'),list(inf_mensal_fidc_tab_I_2026.csv=
    'CNPJ_FUNDO_CLASSE;DT_COMPTC;VALOR\n00000000000191;2026-01-31;1\n00000000000191;2026-07-31;2\n00000000000191;2026-08-31;3\n'))
  d <- pipeline$retomar_downloads_fidc(plano,config,raiz,function(url,destino,timeout) {
    file.copy(zip,destino);200L
  })
  saveRDS(list(config=config,plano=plano),file.path(raiz,'dados/configuracao.rds'))
  r <- pipeline$retomar_consolidacao_fidc(d,config,raiz)
  testthat::expect_identical(r$estado,'concluido');testthat::expect_equal(r$linhas_flat,2)
  testthat::expect_identical(r$unidades,'2026')
})

testthat::test_that('P04-TST-005: vínculo canônico rejeita falta, excesso, repetição e seleção antiga', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz)
  a <- pipeline$assinar_plano_fidc(f$plano,f$config)
  testthat::expect_identical(a,pipeline$assinar_plano_fidc(f$plano[2:1,],f$config))
  for (d in list(f$downloads[1],c(f$downloads,f$downloads[1]),
      c(f$downloads,list(list(unidade='202609',arquivo='extra.zip',url='x')))))
    testthat::expect_error(pipeline$retomar_consolidacao_fidc(d,f$config,raiz,f$mapa),'P05')
  antigo <- lapply(f$downloads,function(x) { x$assinatura_plano <- NULL; x })
  testthat::expect_identical(pipeline$validar_downloads_plano(antigo,f$config,raiz)$assinatura,a$assinatura)
  antigo[[1]]$url <- 'outra'
  testthat::expect_error(pipeline$validar_downloads_plano(antigo,f$config,raiz),'P05')
  config <- f$config;config$fim <- '2026-09-30'
  plano <- rbind(f$plano,data.frame(unidade='202609',arquivo='inf_mensal_fidc_202609.zip',url='simulado/202609'))
  saveRDS(list(config=config,plano=plano),file.path(raiz,'dados/configuracao.rds'))
  testthat::expect_error(pipeline$retomar_consolidacao_fidc(f$downloads,config,raiz,f$mapa),'P05')
  anual <- data.frame(unidade='2026',arquivo='inf_mensal_fidc_2026.zip',url='simulado/2026')
  testthat::expect_length(pipeline$assinar_plano_fidc(anual,f$config)$assinatura,1)
  testthat::expect_error(pipeline$assinar_plano_fidc(rbind(anual,f$plano),f$config),'sobreposição')
})
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
