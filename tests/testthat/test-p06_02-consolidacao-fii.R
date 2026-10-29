source('helper-p02-pipeline.R')
consolidacao_fii <- new.env(parent = globalenv())
for (arquivo in c('../../src/utils/p02_utilitarios.R', '../../src/download/p05_01_download_fidc.R',
    '../../src/download/p05_02_download_fii.R', '../../src/consolidation/p06_02_consolidacao_fii.R'))
  sys.source(arquivo, envir = consolidacao_fii)

fixture_consolidacao_fii <- function() {
  raiz <- tempfile('p06_02-'); dir.create(raiz)
  tabelas <- c('geral', 'ativo_passivo', 'complemento')
  meta <- fixture_zip(file.path(raiz, 'meta.zip'), setNames(rep(list(
    'Campo: CNPJ_Fundo_Classe\nCampo: Data_Referencia\nCampo: Versao\nCampo: Valor'), 3),
    paste0('meta_inf_mensal_fii_', tabelas, '.txt')))
  antigos <- setNames(rep(list(paste('CNPJ_Fundo;Data_Referencia;Versao;Valor',
    '00.000.000/0000-00;2025-12-01;1;000,10',
    '00.000.000/0000-00;2025-12-01;1;000,20', sep = '\n')), 3),
    paste0('inf_mensal_fii_', tabelas, '_2025.csv'))
  novos <- setNames(rep(list(paste('CNPJ_Fundo_Classe;Data_Referencia;Versao;Valor;Novo',
    '00.000.000/0000-00;2026-01-01;2;001,00;S', sep = '\n')), 3),
    paste0('inf_mensal_fii_', tabelas, '_2026.csv'))
  zip2025 <- fixture_zip(file.path(raiz, '2025.zip'), antigos)
  zip2026 <- fixture_zip(file.path(raiz, '2026.zip'), novos)
  transporte <- function(url, destino, timeout) {
    arq <- if (grepl('/META/', url)) meta else if (grepl('2025', url)) zip2025 else zip2026
    file.copy(arq, destino, overwrite = TRUE); 200L
  }
  config <- list(inicio = '2025-12-01', fim = '2026-02-28')
  pagina <- 'inf_mensal_fii_2025.zip inf_mensal_fii_2026.zip'
  consolidacao_fii$executar_download_fii(config, raiz, pagina, transporte)
  list(raiz = raiz, config = config)
}

testthat::test_that('P06_02: união de esquemas preserva repetições, textos e origem sem agregação', {
  f <- fixture_consolidacao_fii()
  r <- consolidacao_fii$consolidar_fii(f$config, f$raiz)
  testthat::expect_identical(r$estado, 'concluido')
  testthat::expect_identical(r$qualidade$linhas, rep(3L, 3))
  testthat::expect_identical(r$qualidade$repeticoes_chave_negocio, rep(1L, 3))
  d <- readRDS(file.path(r$geracao, 'inf_mensal_fii_geral.rds'))
  testthat::expect_identical(d$Valor, c('000,10', '000,20', '001,00'))
  testthat::expect_identical(d$cnpj, rep('00000000000000', 3))
  testthat::expect_true(all(c('CNPJ_Fundo', 'CNPJ_Fundo_Classe') %in% names(d)))
  testthat::expect_true(all(is.na(d$Novo[1:2])))
  testthat::expect_s3_class(d$data_referencia, 'Date')
  testthat::expect_identical(d$linha_origem, c(1L, 2L, 1L))
  testthat::expect_equal(sum(r$cobertura$linhas == 0L), 3)
  csv <- data.table::fread(file.path(r$geracao, 'inf_mensal_fii_geral.csv'),
    sep = ';', colClasses = 'character', showProgress = FALSE)
  testthat::expect_identical(csv$Valor, d$Valor)
  hashes <- vapply(r$arquivos, function(x) x$hash, character(1))
  repetido <- consolidacao_fii$consolidar_fii(f$config, f$raiz)
  testthat::expect_identical(repetido$assinatura, r$assinatura)
  testthat::expect_identical(vapply(repetido$arquivos, function(x) x$hash, character(1)), hashes)
})

testthat::test_that('P06_02: filtro por competência, lacunas e corrupção preservam o marcador anterior', {
  f <- fixture_consolidacao_fii()
  config <- list(inicio = '2026-01-15', fim = '2026-02-28')
  r <- consolidacao_fii$consolidar_fii(config, f$raiz)
  testthat::expect_identical(r$qualidade$linhas, rep(1L, 3))
  marcador <- file.path(f$raiz, 'outputs/fii/temporal/atual.rds')
  antes <- consolidacao_fii$calcular_hash_assinatura(marcador, TRUE)
  teste <- list(inicio = '2024-01-01', fim = '2026-02-28')
  testthat::expect_error(consolidacao_fii$consolidar_fii(teste, f$raiz), 'não adquiridos')
  regs <- readRDS(file.path(f$raiz, 'data/data_fii/data_fii_raw/downloads.rds'))
  writeLines('corrompido', regs[['2026']]$membros$caminho[1])
  testthat::expect_error(consolidacao_fii$consolidar_fii(config, f$raiz), 'divergente')
  testthat::expect_identical(consolidacao_fii$calcular_hash_assinatura(marcador, TRUE), antes)
})

testthat::test_that('P06_02: Latin-1, identidade conflitante e data inválida são tratados explicitamente', {
  raiz <- tempfile(); dir.create(raiz)
  arquivo <- file.path(raiz, 'inf_mensal_fii_geral_2026.csv')
  texto <- 'CNPJ_Fundo_Classe;Data_Referencia;Versao;Descricao\n00000000000000;2026-01-01;1;número fictício'
  writeBin(charToRaw(iconv(texto, 'UTF-8', 'latin1')), arquivo)
  r <- list(unidade = '2026', arquivo = 'inf_mensal_fii_2026.zip', hash = 'hash_ficticio')
  ler <- function() consolidacao_fii$ler_tabela_fii(arquivo, r,
    consolidacao_fii$calcular_hash_assinatura(arquivo, TRUE))
  d <- ler()
  testthat::expect_identical(d$encoding, 'Latin-1')
  testthat::expect_identical(d$dados$Descricao, 'número fictício')
  writeLines('CNPJ_Fundo;Data_Referencia;Versao\n00000000000000;2026-02-30;1', arquivo)
  testthat::expect_error(ler(), 'Data de referência FII inválida')
  writeLines('CNPJ_Fundo;CNPJ_Fundo_Classe;Data_Referencia;Versao\n00000000000000;11111111111111;2026-01-01;1', arquivo)
  testthat::expect_error(ler(), 'Identidades FII divergentes')
})
