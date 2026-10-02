source('helper-p02-pipeline.R')
testthat::test_that('P07-TST-004: resultado, testes e retomada independem de push', {
  r <- list(estado='concluido',incompleto=FALSE)
  testthat::expect_false(pipeline$gerar_relatorio_aceite(r)$aceite_local)
  a <- pipeline$gerar_relatorio_aceite(r,TRUE,TRUE,FALSE)
  testthat::expect_true(a$aceite_local);testthat::expect_false(a$aceite_completo)
  testthat::expect_true(pipeline$gerar_relatorio_aceite(r,TRUE,TRUE,TRUE)$aceite_completo)
  r$incompleto <- TRUE
  testthat::expect_false(pipeline$gerar_relatorio_aceite(r,TRUE,TRUE,TRUE)$aceite_local)
})

testthat::test_that('P07-TST-001/004: saída alterada reprova aceite observado', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  e <- fixture_evidencias(r,f$config,raiz)
  testthat::expect_true(pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)$aceite_local)
  writeLines('alterado',file.path(r$geracao,'inf_mensal_fidc_flat.csv'))
  a <- pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)
  testthat::expect_false(a$aceite_local)
  testthat::expect_true('Saída alterada após validação'%in%a$pendencias)
})

testthat::test_that('P07-TST-006: booleanos, prova adulterada e outro código reprovam', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_false(pipeline$executar_aceite(r,f$config,TRUE,TRUE,TRUE,raiz=raiz)$aceite_local)
  e <- fixture_evidencias(r,f$config,raiz)
  testthat::expect_true(pipeline$validar_evidencias_aceite(e,r,f$config,raiz))
  outro <- f$config; outro$gerar_flat <- FALSE
  testthat::expect_false(pipeline$validar_evidencias_aceite(e,r,outro,raiz))
  e$codigo <- 'outro'
  testthat::expect_false(pipeline$validar_evidencias_aceite(e,r,f$config,raiz))
  e <- fixture_evidencias(r,f$config,raiz)
  writeLines('adulterado',file.path(raiz,'logs/testes.rds'))
  testthat::expect_false(pipeline$validar_evidencias_aceite(e,r,f$config,raiz))
})

testthat::test_that('P07-TST-006: modo temporal tem aceite próprio; marcador impede sucesso antigo', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  f$config$gerar_flat <- FALSE
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  e <- fixture_evidencias(r,f$config,raiz)
  aceite <- pipeline$executar_aceite(r,f$config,sincronizado=TRUE,evidencias=e,raiz=raiz)
  testthat::expect_true(aceite$aceite_local)
  testthat::expect_identical(aceite$modo,'temporal')
  testthat::expect_false(aceite$aceite_piloto_completo)
  saveRDS(list(estado='falhou'),file.path(raiz,'saidas/execucao.rds'))
  testthat::expect_false(pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)$aceite_local)
})
testthat::test_that('P07-TST-002: exclusões são observadas no Git sem exibir segredos', {
  repo <- normalizePath('../..',winslash='/')
  paths <- c('.env','dados/a.zip','saidas/a.csv','checkpoints/a.rds','tmp/a.txt')
  anteriores <- getwd();on.exit(setwd(anteriores));setwd(repo)
  for (p in paths) testthat::expect_equal(system2('git',c('check-ignore','--quiet',shQuote(p))),0)
  testthat::expect_false(system2('git',c('ls-files','--error-unmatch','.env'),
    stdout=FALSE,stderr=FALSE)==0)
  # P07-TST-002: arquivo fictício local, variável própria restaurada sem imprimir valor.
  env <- tempfile();writeLines('FIDC_TESTE_ENV=valor_ficticio',env)
  anterior_env <- Sys.getenv('FIDC_TESTE_ENV',unset=NA_character_)
  on.exit({ if (is.na(anterior_env)) Sys.unsetenv('FIDC_TESTE_ENV') else
    Sys.setenv(FIDC_TESTE_ENV=anterior_env);unlink(env) },add=TRUE)
  dotenv::load_dot_env(env)
  testthat::expect_true(identical(Sys.getenv('FIDC_TESTE_ENV'),'valor_ficticio'))
})
testthat::test_that('P07-TST-003: push falha sem perder commit, depois envia o mesmo commit', {
  raiz <- tempfile();dir.create(raiz);local <- file.path(raiz,'local');dir.create(local)
  remoto <- file.path(raiz,'remoto.git')
  anterior <- getwd();on.exit(setwd(anterior));setwd(local)
  system2('git',c('init','--quiet'))
  system2('git',c('config','user.name','Simulado'));system2('git',c('config','user.email','simulado@example.com'))
  writeLines('simulado','a.txt');system2('git',c('add','a.txt'))
  system2('git',c('commit','--quiet','-m','simulado'))
  head <- system2('git',c('rev-parse','HEAD'),stdout=TRUE)
  erro <- suppressWarnings(system2('git',c('push',shQuote(remoto),'HEAD:refs/heads/main'),stdout=TRUE,stderr=TRUE))
  testthat::expect_true(!is.null(attr(erro,'status')))
  testthat::expect_identical(system2('git',c('rev-parse','HEAD'),stdout=TRUE),head)
  system2('git',c('init','--bare','--quiet',shQuote(remoto)))
  ok <- system2('git',c('push',shQuote(remoto),'HEAD:refs/heads/main'),stdout=TRUE,stderr=TRUE)
  testthat::expect_true(is.null(attr(ok,'status')))
  testthat::expect_identical(strsplit(system2('git',c('ls-remote',shQuote(remoto),'refs/heads/main'),stdout=TRUE),'\t')[[1]][1],head)
})
