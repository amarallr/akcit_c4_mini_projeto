source('helper-p02-pipeline.R')

testthat::test_that('P07-TST-007: hash deve corresponder ao arquivo obrigatório da geração', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  outra <- file.path(raiz,basename(r$arquivos$IV_csv$caminho))
  file.copy(r$arquivos$IV_csv$caminho,outra)
  r$arquivos$IV_csv$caminho <- outra
  e <- fixture_evidencias(r,f$config,raiz)
  a <- pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)
  testthat::expect_false(a$aceite_local)
  testthat::expect_true('Hash não corresponde ao arquivo da geração'%in%a$pendencias)
})

testthat::test_that('P07-TST-009: quantis, CV amostral e chaves sem soma duplicada', {
  e <- new.env(parent=globalenv());sys.source('../../scripts/p07_resumo_pl.R',envir=e)
  d <- data.frame(cnpj=c('a','b','c','d','e'),dt_comptc=as.Date('2026-07-31'),TAB_IV_A_VL_PL=c(1,2,3,4,NA))
  r <- e$resumir_pl_mensal(d)
  testthat::expect_equal(r$pl_total_calculado,10)
  testthat::expect_equal(r$pl_media_valor_fonte,2.5)
  testthat::expect_equal(unname(unlist(r[c('pl_min_valor_fonte','pl_percentil_25_valor_fonte','pl_mediana_valor_fonte','pl_percentil_75_valor_fonte','pl_max_valor_fonte')])),c(1,1.75,2.5,3.25,4))
  testthat::expect_equal(r$pl_coeficiente_variacao_percentual,sd(1:4)/mean(1:4)*100)
  testthat::expect_equal(r$registros_sem_pl,1)
  testthat::expect_identical(r$data_competencia,'2026-07-31')
  por_data <- d;por_data$dt_comptc <- as.Date(c('2026-07-30','2026-07-30','2026-07-31','2026-07-31','2026-07-31'))
  separado <- e$resumir_pl_mensal(por_data)
  testthat::expect_equal(nrow(separado),2)
  testthat::expect_equal(separado$pl_total_calculado,c(3,7))
  testthat::expect_equal(separado$pl_mediana_valor_fonte,c(1.5,3.5))
  testthat::expect_error(e$resumir_pl_mensal(rbind(d,d[1,])),'duplicada')
  d$TAB_IV_A_VL_PL <- c(-1,1,NA,NA,NA)
  testthat::expect_true(is.na(e$resumir_pl_mensal(d)$pl_coeficiente_variacao_percentual))
  d$TAB_IV_A_VL_PL <- NA_real_
  testthat::expect_identical(e$resumir_pl_mensal(d)$cv_definicao,'amostra_insuficiente')
})

testthat::test_that('PL por administrador: limite por data, PL no último mês do trimestre e denominador completo', {
  e <- new.env(parent=globalenv());sys.source('../../scripts/p07_resumo_pl.R',envir=e)
  iv <- data.frame(cnpj=rep(c('a','b'),2),dt_comptc=as.Date(rep(c('2026-03-31','2026-04-30'),each=2)),TAB_IV_A_VL_PL=c(0,100,10,30))
  cadastro <- iv[c('cnpj','dt_comptc')];cadastro$CNPJ_ADMIN <- c('01','02','01','02');cadastro$ADMIN <- c('A','B','A','B')
  d <- e$associar_administradores_pl(iv,cadastro[4:1,])
  r <- e$resumir_pl_administradores(d)
  testthat::expect_equal(r$cnpj_admin,c('02','01'))
  testthat::expect_equal(r$pl_2026_T1,c(100,0))
  testthat::expect_true(all(is.na(r$pl_2026_T2)))
  testthat::expect_equal(r$quantidade_fundos,c(1L,1L))
  testthat::expect_equal(r$percentual_pl_total,c(127,13)/140*100)
  testthat::expect_error(e$associar_administradores_pl(iv,rbind(cadastro,cadastro[1,])),'duplicada')
  testthat::expect_error(e$associar_administradores_pl(iv,cadastro[-1,]),'sem cadastro')
  muitos <- data.frame(cnpj=as.character(1:30),dt_comptc=as.Date('2026-07-31'),TAB_IV_A_VL_PL=1:30,cnpj_admin=as.character(1:30),administrador=as.character(1:30))
  top <- e$resumir_pl_administradores(muitos)
  testthat::expect_equal(nrow(top),25)
  testthat::expect_lt(sum(top$percentual_pl_total),100)
  muitos$TAB_IV_A_VL_PL <- NA_real_
  testthat::expect_true(all(is.na(e$resumir_pl_administradores(muitos)$percentual_pl_total)))
})

testthat::test_that('P07-TST-007: tabela vazia é preservada; seleção toda vazia não aprova', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607');f$config$gerar_flat <- FALSE
  original <- pipeline$ler_padronizar_fidc; todas <- FALSE
  on.exit({pipeline$ler_padronizar_fidc <- original},add=TRUE)
  pipeline$ler_padronizar_fidc <- function(arquivo,tabela,...) {
    x <- original(arquivo,tabela,...)
    if(todas || tabela=='VIII') x$dados <- x$dados[0,]
    x
  }
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(r$linhas_tabelas[['VIII']],0)
  e <- fixture_evidencias(r,f$config,raiz)
  testthat::expect_true(pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)$aceite_local)
  todas <- TRUE;f$config$forcar_reprocessamento <- TRUE
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  e <- fixture_evidencias(r,f$config,raiz)
  a <- pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)
  testthat::expect_false(a$aceite_local)
  testthat::expect_true('Seleção sem registros: aceite pendente'%in%a$pendencias)
})

testthat::test_that('P07-TST-008: produtor isolado em processos reais e executor injetado não recursa', {
  repo <- normalizePath('../..',winslash='/'); anterior <- getwd()
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  dir.create(file.path(raiz,'scripts'))
  file.copy(list.files(file.path(repo,'scripts'),full.names=TRUE),file.path(raiz,'scripts'))
  f$config$usar_checkpoints <- FALSE;f$config$forcar_reprocessamento <- TRUE
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  alvos <- c(file.path(raiz,'saidas/atual.rds'),file.path(raiz,'saidas/execucao.rds'),
    list.files(file.path(raiz,'checkpoints'),full.names=TRUE),vapply(r$arquivos,function(x)x$caminho,character(1)))
  antes <- vapply(alvos,pipeline$calcular_hash_assinatura,character(1),arquivo=TRUE)
  executor <- function() {
    fixture_evidencias(r,f$config,raiz)
    resumo <- file.path(raiz,'logs/testes_resumo.json')
    x <- jsonlite::read_json(resumo,simplifyVector=TRUE); x$origem <- 'fixture'
    jsonlite::write_json(x,resumo,auto_unbox=TRUE); 0L
  }
  setwd(raiz);on.exit(setwd(anterior),add=TRUE)
  testthat::expect_error(pipeline$produzir_evidencias_aceite(f$config,raiz), 'recursiva')
  evidencia <- pipeline$produzir_evidencias_aceite(f$config,raiz,executor_testes=executor)
  testthat::expect_identical(evidencia$origem,'fixture')
  testthat::expect_true(pipeline$validar_evidencias_aceite(evidencia,r,f$config,raiz))
  testthat::expect_identical(antes,vapply(alvos,pipeline$calcular_hash_assinatura,character(1),arquivo=TRUE))
  prova <- readRDS(file.path(raiz,evidencia$artefatos$retomada$caminho))
  testthat::expect_equal(prova$processados_interrupcao,1)
  testthat::expect_equal(prova$reutilizados,1)
  testthat::expect_false(prova$config_usuario$usar_checkpoints)
  testthat::expect_true(prova$config_demonstracao$usar_checkpoints)
  testthat::expect_length(unique(c(prova$pid_usuario,prova$pid_interrupcao,prova$pid_retomada,prova$pid_repeticao)),4)
})

testthat::test_that('P07-TST-007: temporal rejeita chave vazia, data fora do período e esquema divergente', {
  for (defeito in c('cnpj','data','esquema')) {
    raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607');f$config$gerar_flat <- FALSE
    r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
    d <- readRDS(r$arquivos$IV_rds$caminho)
    if(defeito=='cnpj') d$cnpj[1] <- ' . / - ' else if(defeito=='data') d$dt_comptc[1] <- as.Date('2026-08-31') else d$novo <- 'x'
    r$arquivos$IV_csv <- pipeline$gravar_validado_atomico(d,r$arquivos$IV_csv$caminho,'csv')
    e <- fixture_evidencias(r,f$config,raiz)
    a <- pipeline$executar_aceite(r,f$config,evidencias=e,raiz=raiz)
    testthat::expect_false(a$aceite_local)
    testthat::expect_true(any(grepl('Identidade|Esquema|Chaves',a$pendencias)))
  }
})

testthat::test_that('P07-TST-008: 16 políticas preservam dados e demonstram retomada separadamente', {
  casos <- expand.grid(c=c(FALSE,TRUE),a=c(FALSE,TRUE),f=c(FALSE,TRUE),flat=c(FALSE,TRUE))
  for(i in seq_len(nrow(casos))) {
    raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
    f$config$usar_checkpoints <- casos$c[i];f$config$atualizar_downloads <- casos$a[i]
    f$config$forcar_reprocessamento <- casos$f[i];f$config$gerar_flat <- casos$flat[i]
    r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
    testthat::expect_identical(r$estado,'concluido')
    testthat::expect_equal(r$processados,4)
    outra <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
    testthat::expect_equal(outra$reutilizados,if(casos$c[i]&&!casos$f[i]) 4 else 0)
    e <- fixture_evidencias(outra,f$config,raiz)
    testthat::expect_true(pipeline$executar_aceite(outra,f$config,evidencias=e,raiz=raiz)$aceite_local)
  }
})
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
