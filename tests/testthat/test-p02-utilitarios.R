source('helper-p02-pipeline.R')
testthat::test_that('P02-TST-011: lockfile rejeita versão divergente sem instalar ou alterar biblioteca', {
  e <- new.env(parent=globalenv())
  sys.source('../../scripts/p02_dependencias.R',envir=e)
  raiz <- tempfile();dir.create(raiz)
  lock <- list(R=list(Version=as.character(getRversion())),Packages=list(
    digest=list(Package='digest',Version=as.character(utils::packageVersion('digest')),Source='Repository',Repository='CRAN')))
  jsonlite::write_json(lock,file.path(raiz,'renv.lock'),auto_unbox=TRUE)
  anteriores <- .libPaths()
  testthat::expect_silent(e$gerenciar_dependencias('verificar',raiz))
  testthat::expect_identical(.libPaths(),anteriores)
  lock$Packages$digest$Version <- '0.0.0'
  jsonlite::write_json(lock,file.path(raiz,'renv.lock'),auto_unbox=TRUE)
  testthat::expect_error(e$gerenciar_dependencias('verificar',raiz),'diverge')
  testthat::expect_identical(.libPaths(),anteriores)
})
testthat::test_that('P02-TST-001/002: falha não destrói versão válida; hash reage ao conteúdo', {
  pasta <- tempfile();dir.create(pasta)
  caminho <- file.path(pasta,'a.rds')
  pipeline$gravar_validado_atomico(list(a=1),caminho)
  hash <- pipeline$calcular_hash_assinatura(caminho,TRUE)
  testthat::expect_error(pipeline$gravar_validado_atomico(list(a=2),caminho,validador=function(x)FALSE),'rejeitada')
  testthat::expect_identical(readRDS(caminho),list(a=1))
  testthat::expect_identical(hash,pipeline$calcular_hash_assinatura(caminho,TRUE))
  testthat::expect_false(identical(pipeline$calcular_hash_assinatura(list(a=1)),pipeline$calcular_hash_assinatura(list(a=2))))
  testthat::expect_identical(pipeline$calcular_hash_assinatura(list(a=1,b=list(z=3,y=2))),
    pipeline$calcular_hash_assinatura(list(b=list(y=2,z=3),a=1)))
  testthat::expect_error(pipeline$validar_destino(pasta,'../fora'),'inválido')
})

testthat::test_that('P02-TST-012: rollback restaura versão válida e preserva publicação interrompida', {
  pasta <- tempfile();dir.create(pasta);caminho <- file.path(pasta,'a.rds')
  saveRDS(list(v=1),paste0(caminho,'.rollback'))
  saveRDS(list(v=2),caminho)
  testthat::expect_true(pipeline$recuperar_rollback(caminho))
  testthat::expect_identical(readRDS(caminho),list(v=1))
  testthat::expect_length(list.files(pasta,pattern='interrompido'),1)
  writeLines('inválido',paste0(caminho,'.rollback'))
  testthat::expect_error(pipeline$recuperar_rollback(caminho),'inválido')
  testthat::expect_identical(readRDS(caminho),list(v=1))
})

testthat::test_that('P02-TST-012: falha de rename e RDS corrompido não perdem versão anterior', {
  pasta <- tempfile();dir.create(pasta);caminho <- file.path(pasta,'a.rds')
  saveRDS(list(v=1),caminho)
  n <- 0L
  renomear <- function(a,b) { n <<- n+1L; if(n==2L) FALSE else file.rename(a,b) }
  testthat::expect_error(pipeline$gravar_validado_atomico(list(v=2),caminho,renomear=renomear),'Publicação')
  testthat::expect_identical(readRDS(caminho),list(v=1))
  writeLines('corrompido',caminho)
  testthat::expect_warning(testthat::expect_null(pipeline$ler_rds_recuperavel(caminho)),'RDS inválido')
  testthat::expect_length(list.files(pasta,pattern='corrompido'),1)
})

testthat::test_that('P02-TST-011: assinatura de código detecta alteração sem depender de commit', {
  pasta <- tempfile();dir.create(pasta);dir.create(file.path(pasta,'scripts'))
  arq <- file.path(pasta,'scripts','p01.R');writeLines('a <- 1',arq)
  antes <- pipeline$assinatura_codigo(pasta)
  writeLines('a <- 2',arq)
  testthat::expect_false(identical(antes,pipeline$assinatura_codigo(pasta)))
  testthat::expect_identical(pipeline$assinatura_codigo(pasta),pipeline$assinatura_codigo(pasta))
  testthat::expect_true(nzchar(pipeline$registrar_ambiente()$r))
})
testthat::test_that('P02-TST-003: oito combinações sem forçar download por checkpoints', {
  casos <- expand.grid(c= c(FALSE,TRUE),a=c(FALSE,TRUE),f=c(FALSE,TRUE))
  for (i in seq_len(nrow(casos))) {
    p <- pipeline$resolver_politica_execucao(casos$c[i],casos$a[i],casos$f[i])
    testthat::expect_identical(p$baixar,casos$a[i]||casos$f[i])
    testthat::expect_identical(p$reutilizar_checkpoint,casos$c[i]&&!casos$f[i])
  }
})
testthat::test_that('P02-TST-004: duplicidade e referências inválidas são diagnosticadas', {
  c <- data.frame(id=c('R','F','M','T'),categoria=c('RF','FUN','MOD','TST'),estado='planejado')
  m <- data.frame(requisito_id='R',modulo_id='M',teste_id='T',funcoes_ids='F')
  testthat::expect_true(pipeline$validar_rastreabilidade(c,m)$valido)
  testthat::expect_false(pipeline$validar_rastreabilidade(rbind(c,c[1,]),m)$valido)
  m$teste_id <- 'ausente'
  testthat::expect_false(pipeline$validar_rastreabilidade(c,m)$valido)
  m$funcoes_ids <- ''
  testthat::expect_true('Função sem vínculo de requisito/teste' %in% pipeline$validar_rastreabilidade(c,m)$problemas)
  c$comentario <- ''
  testthat::expect_true('Função sem comentário' %in% pipeline$validar_rastreabilidade(c,m)$problemas)
})
