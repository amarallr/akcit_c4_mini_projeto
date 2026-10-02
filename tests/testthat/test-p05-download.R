source('helper-p02-pipeline.R')
testthat::test_that('P02-TST-012: falha entre ZIP e manifesto mantém rollback e estado falho', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  f$config$atualizar_downloads <- TRUE
  original <- pipeline$gravar_validado_atomico
  on.exit({pipeline$gravar_validado_atomico <- original},add=TRUE)
  pipeline$gravar_validado_atomico <- function(objeto,caminho,...) {
    if (identical(objeto$estado,'concluido')) stop('Falha no manifesto final')
    original(objeto,caminho,...)
  }
  testthat::expect_error(pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,
    f$transporte,function(x)NULL),'manifesto final')
  testthat::expect_true(file.exists(paste0(f$downloads[[1]]$arquivo,'.rollback')))
  testthat::expect_identical(readRDS(file.path(raiz,'dados/originais/202607.manifesto.rds'))$estado,'falhou')
  pipeline$gravar_validado_atomico <- original
  recuperado <- pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,f$transporte,function(x)NULL)
  testthat::expect_identical(recuperado$estado,'concluido')
  testthat::expect_identical(recuperado$hash,f$downloads[[1]]$hash)
})
testthat::test_that('P02-TST-012: ZIP em rollback e manifesto corrompido são recuperáveis', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  r <- f$downloads[[1]]
  file.rename(r$arquivo,paste0(r$arquivo,'.rollback'))
  testthat::expect_true(pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,
    function(...)stop('rede não autorizada'))$reutilizado)
  manifesto <- file.path(raiz,'dados/originais/202607.manifesto.rds')
  writeLines('corrompido',manifesto)
  testthat::expect_warning(novo <- pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,
    f$transporte,function(x)NULL),'RDS inválido')
  testthat::expect_identical(novo$estado,'concluido')
  testthat::expect_identical(novo$hash,r$hash)
  testthat::expect_true(any(grepl('corrompido',list.files(dirname(manifesto)))))
})
testthat::test_that('P05-TST-001/002: tentativas transitórias, definitivo e ZIP HTML', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  f$config$atualizar_downloads <- TRUE
  n <- 0L
  transporte <- function(url,destino,timeout) { n <<- n+1L;if(n==1) return(503L);f$transporte(url,destino,timeout) }
  r <- pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,transporte,function(x)NULL)
  testthat::expect_identical(r$estado,'concluido');testthat::expect_equal(n,2)
  n <- 0L
  definitivo <- function(url,destino,timeout) { n <<- n+1L;404L }
  r <- pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,definitivo,function(x)NULL)
  testthat::expect_equal(n,1);testthat::expect_identical(r$estado,'indisponivel')
  testthat::expect_true(r$anterior_valido);testthat::expect_false(r$atualizado)
  html <- file.path(raiz,'html.zip');writeLines('<html>erro</html>',html)
  testthat::expect_error(pipeline$validar_zip_fidc(html))
})
testthat::test_that('P05-TST-003/004/005/006: reutilização, corrupção e extração segura', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  fail <- function(...)stop('rede não deve ser usada')
  r <- pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,fail,function(x)NULL)
  testthat::expect_true(r$reutilizado)
  writeLines('corrompido',r$arquivo)
  r <- pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,f$transporte,function(x)NULL)
  testthat::expect_identical(r$estado,'concluido')
  m <- pipeline$extrair_zip_fidc(r,f$config,raiz)
  testthat::expect_equal(nrow(m),4)
  testthat::expect_true(all(file.exists(m$caminho)))
  perigoso <- fixture_zip(file.path(raiz,'perigoso.zip'),setNames(list('texto'),'../escape.txt'))
  testthat::expect_error(pipeline$validar_zip_fidc(perigoso),'inseguro')
  truncado <- file.path(raiz,'truncado.zip');writeBin(readBin(r$arquivo,'raw',n=20),truncado)
  testthat::expect_error(pipeline$validar_zip_fidc(truncado))
  f$config$usar_checkpoints <- FALSE
  testthat::expect_true(pipeline$baixar_unidade_fidc(f$plano,f$config,raiz,fail)$reutilizado)
})
