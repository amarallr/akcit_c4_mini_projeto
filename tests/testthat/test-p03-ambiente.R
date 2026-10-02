# P03-TST-001/002/003 | P03 | testes locais sem rede e credenciais.
testthat::test_that('P03-TST-001: diagnóstico distingue ausência, carga e locale', {
  ambiente <- new.env(parent = globalenv())
  bibliotecas <- .libPaths()
  diretorio <- getwd()
  sys.source('../../scripts/p03_verificar_ambiente.R', envir = ambiente)
  testthat::expect_identical(.libPaths(), bibliotecas)
  testthat::expect_identical(getwd(), diretorio)
  observacoes <- list(r = 'R simulado', locale = 'simulado', utf8 = FALSE,
    instalados = 'instalado', carregados = c(instalado = FALSE, ausente = FALSE),
    executaveis = c(Rscript = 'simulado', git = ''), rstudio_console = NA)
  resultado <- ambiente$verificar_ambiente('.', c('instalado', 'ausente'), observacoes)
  testthat::expect_true('Locale UTF-8 não confirmado.' %in% resultado$pendencias)
  testthat::expect_true('Console RStudio requer evidência manual.' %in% resultado$pendencias)
  testthat::expect_true('Pacote ausente: ausente' %in% resultado$pendencias)
  testthat::expect_true('Falha no carregamento: instalado' %in% resultado$pendencias)
  testthat::expect_true('Executável ausente: git' %in% resultado$pendencias)
  observacoes$utf8 <- TRUE
  observacoes$rstudio_console <- TRUE
  observacoes$carregados['instalado'] <- TRUE
  observacoes$executaveis['git'] <- 'simulado'
  testthat::expect_length(ambiente$verificar_ambiente('.', 'instalado', observacoes)$pendencias, 0)
})

testthat::test_that('P03-TST-002: preparação preserva bytes e ambiente', {
  ambiente <- new.env(parent = globalenv())
  sys.source('../../scripts/p03_preparar_projeto.R', envir = ambiente)
  raiz <- tempfile('projeto-')
  dir.create(raiz)
  arquivo <- file.path(raiz, 'arquivo_preservado.R')
  writeBin(as.raw(c(0, 1, 255, 13, 10)), arquivo)
  original <- readBin(arquivo, 'raw', n = 100)
  bibliotecas <- .libPaths()
  locale <- Sys.getlocale()
  diretorio <- getwd()
  resultado <- ambiente$preparar_projeto(raiz,
    list('arquivo_preservado.R' = 'não substituir', 'scripts/p03_exemplo.R' = '# simulado'))
  testthat::expect_identical(readBin(arquivo, 'raw', n = 100), original)
  testthat::expect_identical(resultado$preservados, 'arquivo_preservado.R')
  testthat::expect_identical(resultado$criados, 'scripts/p03_exemplo.R')
  testthat::expect_length(ambiente$preparar_projeto(raiz,
    list('scripts/p03_exemplo.R' = 'outro'))$criados, 0)
  testthat::expect_identical(.libPaths(), bibliotecas)
  testthat::expect_identical(Sys.getlocale(), locale)
  testthat::expect_identical(getwd(), diretorio)
  testthat::expect_error(ambiente$preparar_projeto(raiz,
    list('nao_criar.R' = 'x', '../fora.R' = 'x')), 'Caminho')
  testthat::expect_false(file.exists(file.path(raiz, 'nao_criar.R')))
  unlink(raiz, recursive = TRUE)
})

testthat::test_that('P03-TST-003: remoto divergente e sessão válida sem efeitos', {
  ambiente <- new.env(parent = globalenv())
  sys.source('../../scripts/p03_verificar_ambiente.R', envir = ambiente)
  resultado <- ambiente$verificar_repositorio('https://github.com/outro/projeto.git',
    TRUE, 'amarallr/akcit_c4_mini_projeto', 'private',
    repositorio_esperado = 'amarallr/akcit_c4_mini_projeto')
  testthat::expect_identical(resultado$pendencias, 'Remoto divergente.')
  testthat::expect_true(resultado$reutilizar_sessao)
  testthat::expect_false(resultado$alterar_visibilidade)
  testthat::expect_identical(resultado$visibilidade, 'private')
  resultado <- ambiente$verificar_repositorio(
    'https://github.com/amarallr/akcit_c4_mini_projeto.git', TRUE,
    'amarallr/akcit_c4_mini_projeto', 'public',
    repositorio_esperado = 'amarallr/akcit_c4_mini_projeto')
  testthat::expect_length(resultado$pendencias, 0)
  testthat::expect_true(resultado$reutilizar_sessao)
  testthat::expect_true(length(ambiente$verificar_repositorio('ausente')$pendencias) > 0)
  for (remoto in c('https://github.com/aluna/fidc.git',
      'https://github.com/aluna/fidc', 'git@github.com:aluna/fidc.git',
      'ssh://git@github.com/aluna/fidc.git')) {
    proprio <- ambiente$verificar_repositorio(remoto, TRUE, 'aluna/fidc',
      'private', repositorio_esperado = 'aluna/fidc')
    testthat::expect_length(proprio$pendencias, 0)
    testthat::expect_identical(proprio$repositorio_esperado, 'aluna/fidc')
    testthat::expect_false(proprio$alterar_visibilidade)
  }
  outro <- ambiente$verificar_repositorio('https://github.com/aluna/fidc.git',
    TRUE, 'outra/fidc', 'public', repositorio_esperado = 'aluna/fidc')
  testthat::expect_identical(outro$pendencias, 'Repositório remoto não confirmado.')
  ausente <- ambiente$verificar_repositorio('https://github.com/aluna/fidc.git',
    TRUE, 'aluna/fidc', 'public')
  testthat::expect_true('Repositório esperado não informado.' %in% ausente$pendencias)
  desconhecido <- ambiente$verificar_repositorio(NA_character_, NA,
    repositorio_esperado = 'aluna/fidc')
  testthat::expect_true(all(c('Remoto divergente.', 'Autenticação não confirmada.',
    'Repositório remoto não confirmado.', 'Visibilidade atual não confirmada.') %in%
    desconhecido$pendencias))
  testthat::expect_error(ambiente$verificar_repositorio('x',
    repositorio_esperado = 'https://github.com/aluna/fidc'), 'conta/projeto')
  testthat::expect_error(ambiente$verificar_repositorio(c('x', 'y')), 'texto único')
  testthat::expect_error(ambiente$verificar_repositorio('x', autenticado = 'sim'), 'TRUE')
  testthat::expect_length(ambiente$verificar_repositorio(
    'https://github.com/Aluna/FIDC.git', TRUE, 'ALUNA/FIDC', 'private',
    repositorio_esperado = 'aluna/fidc')$pendencias, 0)
})
