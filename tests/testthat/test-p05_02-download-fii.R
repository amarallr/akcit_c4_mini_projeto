source('helper-p02-pipeline.R')
fii <- new.env(parent = globalenv())
for (arquivo in c('../../src/utils/p02_utilitarios.R',
                  '../../src/download/p05_01_download_fidc.R', '../../src/download/p05_02_download_fii.R'))
  sys.source(arquivo, envir = fii)

fixture_fii <- function(anos = c('2025', '2026')) {
  raiz <- tempfile('p05_02-'); dir.create(raiz)
  zip <- fixture_zip(file.path(raiz, 'fonte.zip'),
    list('inf_mensal_fii_geral_2026.csv' = 'CNPJ_FUNDO;DT_COMPTC\nfundo_ficticio;2026-07-01'))
  meta <- fixture_zip(file.path(raiz, 'meta.zip'), list('meta_fii.txt' = 'Dicionario ficticio'))
  chamadas <- character()
  transporte <- function(url, destino, timeout) {
    chamadas <<- c(chamadas, url)
    file.copy(if (grepl('/META/', url)) meta else zip, destino, overwrite = TRUE)
    200L
  }
  list(raiz = raiz, zip = zip, meta = meta, transporte = transporte,
    chamadas = function() chamadas,
    pagina = paste0('<a href="inf_mensal_fii_', anos, '.zip">ZIP</a>', collapse = '\n'),
    config = list(inicio = '2026-07-01', fim = '2026-08-31', tentativas = 1L))
}

testthat::test_that('P05_02-TST-001/002: plano anual, lacunas e configuração antes de efeitos', {
  f <- fixture_fii()
  config <- fii$validar_configuracao_fii(f$config, f$raiz)
  inventario <- fii$inventariar_recursos_fii(paste(f$pagina, f$pagina))
  testthat::expect_identical(inventario$unidade, c('2025', '2026'))
  plano <- fii$selecionar_unidades_fii(config, inventario)
  testthat::expect_identical(plano$plano$unidade, '2026')
  config$inicio <- '2024-01-01'
  testthat::expect_identical(fii$selecionar_unidades_fii(config, inventario)$faltantes, '2024')
  testthat::expect_error(fii$inventariar_recursos_fii('<html>vazio</html>'), 'sem recursos')
  for (alteracao in list(list(inicio = '2026-13-01'), list(fim = '2025-01-01'),
    list(dados = '../fora'), list(dados = 'restricted'), list(atualizar_downloads = NA),
    list(tentativas = 1.5), list(timeout = 0))) {
    testthat::expect_error(fii$executar_download_fii(utils::modifyList(f$config, alteracao),
      f$raiz, f$pagina, f$transporte))
  }
  testthat::expect_length(f$chamadas(), 0)
  testthat::expect_false(dir.exists(file.path(f$raiz, 'data')))
  testthat::expect_false(dir.exists(file.path(f$raiz, 'logs')))
  adulterado <- inventario; adulterado$url[1] <- 'https://outro.invalid/a.zip'
  testthat::expect_error(fii$selecionar_unidades_fii(config, adulterado), 'inconsistente')
})

testthat::test_that('P05_02-TST-005/007/008: dicionário, hashes, reuso e isolamento FIDC', {
  f <- fixture_fii()
  dir.create(file.path(f$raiz, 'data/data_fidc/data_fidc_raw'), recursive = TRUE)
  protegido <- file.path(f$raiz, 'data/data_fidc/data_fidc_raw/downloads.rds')
  saveRDS(list(dataset = 'FIDC', sentinela = TRUE), protegido)
  antes <- fii$calcular_hash_assinatura(protegido, TRUE)
  r <- fii$executar_download_fii(f$config, f$raiz, f$pagina, f$transporte)
  testthat::expect_identical(r$estado, 'concluido')
  testthat::expect_length(f$chamadas(), 2)
  testthat::expect_equal(nrow(r$inventario_membros), 1)
  testthat::expect_true(file.exists(r$dicionario$arquivo_versao))
  testthat::expect_identical(r$dicionario$hash,
    fii$calcular_hash_assinatura(r$dicionario$arquivo_versao, TRUE))
  falhar <- function(...) stop('rede não autorizada')
  reuso <- fii$executar_download_fii(f$config, f$raiz, f$pagina, falhar)
  testthat::expect_true(reuso$dicionario$reutilizado)
  testthat::expect_true(reuso$recursos[['2026']]$reutilizado)
  versao <- reuso$recursos[['2026']]$arquivo_versao
  writeLines('versão arquivada corrompida', versao)
  recuperado <- fii$executar_download_fii(f$config, f$raiz, f$pagina, falhar)
  testthat::expect_identical(fii$calcular_hash_assinatura(versao, TRUE),
    recuperado$recursos[['2026']]$hash)
  testthat::expect_identical(fii$calcular_hash_assinatura(protegido, TRUE), antes)
  testthat::expect_false(dir.exists(file.path(f$raiz, 'outputs')))
  ampliado <- f$config; ampliado$inicio <- '2025-01-01'
  fii$executar_download_fii(ampliado, f$raiz, f$pagina, f$transporte)
  fii$executar_download_fii(f$config, f$raiz, f$pagina, falhar)
  testthat::expect_identical(names(readRDS(file.path(f$raiz, 'data/data_fii/data_fii_raw/downloads.rds'))),
    c('2025', '2026'))
})

testthat::test_that('P05_02-TST-004/006: interrupção persiste falha e retoma sem nova aquisição', {
  f <- fixture_fii()
  testthat::expect_error(fii$executar_download_fii(f$config, f$raiz, f$pagina,
    f$transporte, interromper_apos = 1), 'Interrupção FII')
  tentativa <- readRDS(file.path(f$raiz, 'logs/fii/execucao.rds'))
  testthat::expect_identical(tentativa$estado, 'falhou')
  testthat::expect_match(tentativa$motivo, 'Interrupção FII')
  testthat::expect_true(file.exists(file.path(f$raiz, 'data/data_fii/data_fii_raw/downloads.rds')))
  r <- fii$executar_download_fii(f$config, f$raiz, f$pagina,
    function(...) stop('sem rede'))
  testthat::expect_identical(r$estado, 'concluido')
  testthat::expect_true(r$recursos[['2026']]$reutilizado)
  membro <- r$recursos[['2026']]$membros$caminho[1]
  writeLines('extração corrompida', membro)
  r <- fii$executar_download_fii(f$config, f$raiz, f$pagina, function(...) stop('sem rede'))
  testthat::expect_identical(fii$calcular_hash_assinatura(membro, TRUE),
    r$recursos[['2026']]$membros$hash[1])
  manifesto <- file.path(f$raiz, 'data/data_fii/data_fii_raw/originais/2026.manifesto.rds')
  writeLines('manifesto corrompido', manifesto)
  testthat::expect_warning(r <- fii$executar_download_fii(f$config, f$raiz,
    f$pagina, f$transporte), 'RDS inválido')
  testthat::expect_identical(r$estado, 'concluido')
})

testthat::test_that('P05_02-TST-004/005: atualização preserva versão anterior e falha não destrói ZIP', {
  f <- fixture_fii()
  r <- fii$executar_download_fii(f$config, f$raiz, f$pagina, f$transporte)
  anterior <- r$recursos[['2026']]
  fixture_zip(f$zip, list('inf_mensal_fii_geral_2026.csv' = 'campo\nversao_nova'))
  config <- f$config; config$atualizar_downloads <- TRUE
  novo <- fii$executar_download_fii(config, f$raiz, f$pagina, f$transporte)
  testthat::expect_false(identical(novo$recursos[['2026']]$hash, anterior$hash))
  testthat::expect_identical(fii$calcular_hash_assinatura(anterior$arquivo_versao, TRUE), anterior$hash)
  hash <- fii$calcular_hash_assinatura(novo$recursos[['2026']]$arquivo, TRUE)
  testthat::expect_error(fii$executar_download_fii(config, f$raiz, f$pagina,
    function(...) 404L), 'Aquisição FII falhou')
  testthat::expect_identical(fii$calcular_hash_assinatura(novo$recursos[['2026']]$arquivo, TRUE), hash)
  testthat::expect_identical(readRDS(file.path(f$raiz, 'logs/fii/execucao.rds'))$estado, 'falhou')
})

testthat::test_that('P05_02-TST-003/004: rejeita ZIP inseguro, truncado, limites e repete erro transitório', {
  f <- fixture_fii()
  config <- fii$validar_configuracao_fii(f$config, f$raiz)
  unidade <- fii$inventariar_recursos_fii(f$pagina)[2, ]
  perigoso <- fixture_zip(file.path(f$raiz, 'perigoso.zip'), list('../escape.csv' = 'x'))
  transporte <- function(url, destino, timeout) { file.copy(perigoso, destino); 200L }
  testthat::expect_error(fii$baixar_recurso_fii(unidade, config, f$raiz,
    transporte, function(...) NULL), 'Aquisição FII falhou')
  testthat::expect_false(file.exists(file.path(f$raiz, 'escape.csv')))
  testthat::expect_false(file.exists(file.path(f$raiz, 'data/data_fii/data_fii_raw/originais', unidade$arquivo)))
  config$max_bytes_zip <- 1
  testthat::expect_error(fii$baixar_recurso_fii(unidade, config, f$raiz,
    f$transporte, function(...) NULL), 'limite de bytes')
  config$max_bytes_zip <- 1024^2; config$tentativas <- 2L
  n <- 0L
  transitorio <- function(url, destino, timeout) {
    n <<- n + 1L
    if (n == 1L) return(503L)
    f$transporte(url, destino, timeout)
  }
  r <- fii$baixar_recurso_fii(unidade, config, f$raiz, transitorio, function(...) NULL)
  testthat::expect_identical(r$estado, 'concluido')
  testthat::expect_identical(n, 2L)
  writeBin(as.raw(1:10), r$arquivo)
  r <- fii$baixar_recurso_fii(unidade, config, f$raiz, f$transporte)
  testthat::expect_identical(r$estado, 'concluido')
})

testthat::test_that('P05_02-TST-001/009: lacuna não vira sucesso e carregamento não tem efeitos', {
  f <- fixture_fii('2025')
  testthat::expect_error(fii$executar_download_fii(f$config, f$raiz, f$pagina,
    f$transporte), 'Anos FII indisponíveis')
  testthat::expect_length(f$chamadas(), 0)
  testthat::expect_identical(readRDS(file.path(f$raiz, 'logs/fii/execucao.rds'))$estado, 'falhou')
  ambiente <- new.env(parent = baseenv())
  diretorio <- getwd(); bibliotecas <- .libPaths()
  sys.source('../../src/download/p05_02_download_fii.R', envir = ambiente)
  testthat::expect_identical(getwd(), diretorio)
  testthat::expect_identical(.libPaths(), bibliotecas)
  testthat::expect_true(is.function(ambiente$executar_download_fii))
})

testthat::test_that('P05_02: consulta do índice usa transporte e não confunde HTTP com catálogo vazio', {
  f <- fixture_fii()
  transporte <- function(url, destino, timeout) {
    if (grepl('/DADOS/$', url)) { writeLines(f$pagina, destino); return(200L) }
    f$transporte(url, destino, timeout)
  }
  r <- fii$executar_download_fii(f$config, f$raiz, transporte = transporte)
  testthat::expect_identical(r$estado, 'concluido')
  testthat::expect_error(fii$executar_download_fii(f$config, f$raiz,
    transporte = function(...) 503L), 'Índice FII indisponível')
  testthat::expect_identical(readRDS(file.path(f$raiz, 'logs/fii/execucao.rds'))$estado, 'falhou')
})
