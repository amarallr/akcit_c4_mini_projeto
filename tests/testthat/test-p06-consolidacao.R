source('helper-p02-pipeline.R')

testthat::test_that('P02-TST-013/P06-TST-013: saída parcial preserva ponteiro concluído', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  anterior <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  original <- pipeline$extrair_zip_fidc
  on.exit({pipeline$extrair_zip_fidc <- original},add=TRUE)
  pipeline$extrair_zip_fidc <- function(...) {
    membros <- original(...);membros[!grepl('_tab_VIII_',membros$Name),]
  }
  f$config$permitir_parcial <- TRUE
  parcial <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_identical(parcial$estado,'parcial')
  testthat::expect_identical(readRDS(file.path(raiz,'saidas/atual.rds'))$assinatura,anterior$assinatura)
  testthat::expect_identical(readRDS(file.path(raiz,'saidas/execucao.rds'))$estado,'parcial')
  testthat::expect_false(pipeline$executar_aceite(anterior,anterior$config,raiz=raiz)$aceite_local)
})

testthat::test_that('P06-TST-013: lógica e mapa invalidam, documentação não invalida', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  original <- pipeline$ler_padronizar_fidc
  on.exit({pipeline$ler_padronizar_fidc <- original},add=TRUE)
  a <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  writeLines('Mudança documental',file.path(raiz,'README.md'))
  b <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(b$reutilizados,4)
  f$mapa$tipo[f$mapa$tabela=='IV' & f$mapa$campo=='TAB_IV_A_VL_PL'] <- 'text'
  c <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(c$processados,1)
  testthat::expect_equal(c$reutilizados,3)
  pipeline$ler_padronizar_fidc <- function(...) original(...)
  d <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(d$processados,4)
  testthat::expect_false(identical(c$assinatura,d$assinatura))
})
testthat::test_that('P06-TST-012: modo temporal evita pivot e conserva todas as linhas', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz)
  completo <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  f$config$gerar_flat <- FALSE;f$config$max_colunas_flat <- 1L
  temporal <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_identical(temporal$modo,'temporal')
  testthat::expect_equal(temporal$linhas_flat,0)
  testthat::expect_false(file.exists(file.path(temporal$geracao,'inf_mensal_fidc_flat.csv')))
  testthat::expect_identical(temporal$linhas_tabelas,completo$linhas_tabelas)
  testthat::expect_false(identical(temporal$assinatura,completo$assinatura))
  testthat::expect_identical(temporal$arquivos$VIII_csv$hash,completo$arquivos$VIII_csv$hash)
})

testthat::test_that('P06-TST-011: qualidade detecta problemas sem descartar dados', {
  d <- data.table::data.table(CNPJ_FUNDO_CLASSE=c('123','123'),DT_COMPTC='2026-07-31',NOVO='x',VALOR='erro')
  mapa <- data.frame(tabela='VIII',campo=c('VALOR','AUSENTE'),tipo=c('numeric','text'))
  q <- pipeline$relatar_qualidade_fidc(d,'VIII',mapa)
  testthat::expect_equal(q$quantidade[q$tipo=='conversao_invalida'],2)
  testthat::expect_equal(q$quantidade[q$tipo=='identificador_formato_invalido'],2)
  testthat::expect_equal(q$quantidade[q$tipo=='repeticoes_integrais'],1)
  testthat::expect_equal(q$quantidade[q$tipo=='chaves_com_multiplas_linhas'],1)
  testthat::expect_true('AUSENTE' %in% q$campo[q$tipo=='campo_ausente'])
  testthat::expect_identical(d$VALOR,rep('erro',2))
})

testthat::test_that('P02-TST-012: checkpoint corrompido e falha de saída não anunciam sucesso anterior', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  valido <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  manifestos <- list.files(file.path(raiz,'checkpoints'),pattern='manifesto.rds$',full.names=TRUE)
  writeLines('corrompido',manifestos[1])
  testthat::expect_warning(r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa),'RDS inválido')
  testthat::expect_equal(r$processados,1)
  testthat::expect_equal(r$reutilizados,3)
  testthat::expect_identical(r$arquivos$flat_csv$hash,valido$arquivos$flat_csv$hash)
  original <- pipeline$gravar_validado_atomico
  on.exit({pipeline$gravar_validado_atomico <- original},add=TRUE)
  pipeline$gravar_validado_atomico <- function(objeto,caminho,...) {
    if(grepl('inf_mensal_fidc_flat.csv$',caminho)) stop('Falha simulada de escrita')
    original(objeto,caminho,...)
  }
  testthat::expect_error(pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa),'Falha simulada')
  testthat::expect_identical(readRDS(file.path(raiz,'saidas/atual.rds'))$geracao,valido$geracao)
  testthat::expect_identical(readRDS(file.path(raiz,'saidas/execucao.rds'))$estado,'falhou')
  testthat::expect_true(file.exists(file.path(valido$geracao,'inf_mensal_fidc_flat.csv')))
})

testthat::test_that('P06-TST-011: conversão inválida publica diagnóstico antes de falhar', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  original <- pipeline$ler_padronizar_fidc
  on.exit({pipeline$ler_padronizar_fidc <- original},add=TRUE)
  pipeline$ler_padronizar_fidc <- function(arquivo,...) {
    linhas <- readLines(arquivo,encoding='UTF-8')
    writeLines(gsub('100.50','erro',linhas,fixed=TRUE),arquivo,useBytes=TRUE)
    original(arquivo,...)
  }
  testthat::expect_error(pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa),'Decimal')
  q <- data.table::fread(file.path(raiz,'saidas/qualidade_falha.csv'),sep=';')
  testthat::expect_true(any(q$tipo=='conversao_invalida' & q$quantidade>0))
  testthat::expect_false(file.exists(file.path(raiz,'saidas/atual.rds')))
})

testthat::test_that('P06-TST-012: Parquet é opcional e preserva identificador textual', {
  arq <- tempfile(fileext='.parquet')
  d <- data.table::data.table(cnpj='00000000000191',dt_comptc=as.Date('2026-07-31'),v='100.50')
  if (requireNamespace('arrow',quietly=TRUE)) {
    meta <- pipeline$exportar_parquet_fidc(d,arq)
    testthat::expect_identical(arrow::read_parquet(arq)$cnpj,d$cnpj)
    testthat::expect_identical(meta$hash,pipeline$calcular_hash_assinatura(arq,TRUE))
  } else testthat::expect_error(pipeline$exportar_parquet_fidc(d,arq),'Parquet solicitado')
})
testthat::test_that('P06-TST-001/002: texto, acentos, filtros e decimal inválido', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  m <- pipeline$extrair_zip_fidc(f$downloads[[1]],f$config,raiz)
  arquivo <- m$caminho[grepl('_tab_I_',m$Name)]
  r <- pipeline$ler_padronizar_fidc(arquivo,'I',f$config,f$mapa)
  testthat::expect_identical(r$dados$cnpj,'00000000000191')
  testthat::expect_identical(r$dados$DENOM_SOCIAL,'Ação')
  testthat::expect_equal(r$dados$TAB_I_VL_ATIVO,100.50)
  testthat::expect_identical(r$dados$TAB_I_VL_ATIVO__original,'100.50')
  f$config$inicio <- '2026-08-01'
  testthat::expect_equal(nrow(pipeline$ler_padronizar_fidc(arquivo,'I',f$config,f$mapa)$dados),0)
  linhas <- readLines(arquivo,encoding='UTF-8');writeLines(gsub('100.50','100,50',linhas,fixed=TRUE),arquivo,useBytes=TRUE)
  testthat::expect_error(pipeline$ler_padronizar_fidc(arquivo,'I',f$config,f$mapa),'Decimal')
})
testthat::test_that('P06-TST-003/004/006/010: flat preserva detalhes, órfãos e valores sem multiplicar', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz)
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  flat <- readRDS(file.path(r$geracao,'inf_mensal_fidc_flat.rds'))
  testthat::expect_equal(nrow(flat),4)
  testthat::expect_false(anyDuplicated(flat[c('cnpj','dt_comptc')])>0)
  testthat::expect_true(any(grepl('VIII__VALOR_r0002',names(flat),fixed=TRUE)))
  testthat::expect_equal(sum(flat$I__TAB_I_VL_ATIVO_r0001,na.rm=TRUE),201)
  testthat::expect_true(any(grepl('IV__arquivo_origem',names(flat))))
  novamente <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(novamente$reutilizados,8)
  testthat::expect_identical(novamente$assinatura,r$assinatura)
  reverso <- pipeline$retomar_consolidacao_fidc(rev(f$downloads),f$config,raiz,f$mapa)
  testthat::expect_identical(reverso$assinatura,r$assinatura)
  hash_csv <- pipeline$calcular_hash_assinatura(file.path(r$geracao,'inf_mensal_fidc_flat.csv'),TRUE)
  f$config$usar_checkpoints <- FALSE
  sem <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(sem$processados,8)
  testthat::expect_identical(hash_csv,pipeline$calcular_hash_assinatura(file.path(sem$geracao,'inf_mensal_fidc_flat.csv'),TRUE))
  f$config$usar_checkpoints <- TRUE
  f$config$inicio <- '2026-08-01'
  plano <- f$plano[f$plano$unidade=='202608',]
  saveRDS(list(config=f$config,plano=plano),file.path(raiz,'dados/configuracao.rds'))
  downloads <- pipeline$retomar_downloads_fidc(plano,f$config,raiz,f$transporte)
  agosto <- pipeline$retomar_consolidacao_fidc(downloads,f$config,raiz,f$mapa)
  testthat::expect_equal(agosto$linhas_flat,2)
  testthat::expect_true(agosto$processados>0)
  d <- data.table::data.table(cnpj='1',dt_comptc=as.Date('2026-07-31'),v=c(1,2),
    arquivo_origem='a',zip_origem='z',linha_origem=1:2)
  testthat::expect_equal(nrow(pipeline$auditar_chaves_fidc(d)$multiplicidades),1)
  testthat::expect_equal(pipeline$auditar_chaves_fidc(d)$linhas,2)
})
testthat::test_that('P06-TST-005: interrupção persiste; outro processo reutiliza checkpoints', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  testthat::expect_error(pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa,1),'Interrupção')
  repo <- normalizePath('../..',winslash='/')
  saveRDS(list(f=f,raiz=raiz),file.path(raiz,'entrada.rds'))
  script <- file.path(raiz,'retomar.R')
  writeLines(c(paste0('setwd(',encodeString(repo,quote='"'),')'),
    ".libPaths(c('.R-library',.libPaths())); source('scripts/p02_utilitarios.R'); p <- carregar_pipeline('.')",
    paste0('x <- readRDS(',encodeString(file.path(raiz,'entrada.rds'),quote='"'),')'),
    'r <- p$retomar_consolidacao_fidc(x$f$downloads,x$f$config,x$raiz,x$f$mapa)',
    paste0('saveRDS(r,',encodeString(file.path(raiz,'resultado.rds'),quote='"'),')')),script)
  output <- system2(file.path(R.home('bin'),'Rscript'),c('--vanilla',shQuote(script)),stdout=TRUE,stderr=TRUE)
  testthat::expect_true(is.null(attr(output,'status')))
  r <- readRDS(file.path(raiz,'resultado.rds'))
  testthat::expect_equal(r$reutilizados,1)
  testthat::expect_equal(r$processados,3)
})
testthat::test_that('P06-TST-007/008: cedentes preservam originais, índices e ambiguidades', {
  c <- pipeline$validar_configuracao()
  d <- data.table::data.table(cnpj='00000000000191',dt_comptc=as.Date('2026-07-31'),
    arquivo_origem='I.csv',zip_origem='z',linha_origem=1L,
    TAB_I2A12_CPF_CNPJ_CEDENTE_1='529.982.247-25',TAB_I2A12_PR_CEDENTE_1__original='10.00',
    TAB_I2A12_CPF_CNPJ_CEDENTE_2='ABC12')
  ced <- pipeline$extrair_cedentes_fidc(d,c)
  testthat::expect_equal(nrow(ced),2)
  testthat::expect_identical(ced$ni_original,c('529.982.247-25','ABC12'))
  testthat::expect_true(ced$dv_valido[1]);testthat::expect_false(ced$dv_valido[2])
  testthat::expect_true(is.na(ced$percentual_original[2]))
  testthat::expect_false(pipeline$validar_dv_ni('11111111111'))
  testthat::expect_true(pipeline$validar_dv_ni('00000000000191'))
  testthat::expect_identical(pipeline$avaliar_identificador_cedente('ABC12')$formato,'nao_numerico')
  testthat::expect_identical(pipeline$avaliar_identificador_cedente('11111111111')$status_identificacao,'nao_validado')
  testthat::expect_identical(pipeline$avaliar_identificador_cedente(NA_character_)$formato,'vazio')
  ambiguo <- pipeline$avaliar_identificador_cedente('191',TRUE)
  testthat::expect_identical(ambiguo$status_identificacao,'ambiguo')
  testthat::expect_identical(ambiguo$ni_original,'191')
  testthat::expect_true(pipeline$validar_dv_ni(ambiguo$candidato_cpf))
  testthat::expect_true(pipeline$validar_dv_ni(ambiguo$candidato_cnpj))
  testthat::expect_identical(pipeline$avaliar_identificador_cedente('00000000191',TRUE)$status_identificacao,'ambiguo')
})
testthat::test_that('P06-TST-009: ausência não usa geração antiga como atual', {
  raiz <- tempfile();dir.create(raiz);f <- fixture_piloto(raiz,'202607')
  anterior <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  f$downloads[[1]]$estado <- 'falhou'
  r <- pipeline$retomar_consolidacao_fidc(f$downloads,f$config,raiz,f$mapa)
  testthat::expect_identical(r$estado,'sem_unidades_validas')
  testthat::expect_null(r$geracao)
  testthat::expect_true(r$incompleto)
  testthat::expect_identical(readRDS(file.path(raiz,'saidas/atual.rds'))$geracao,anterior$geracao)
  testthat::expect_true(file.exists(file.path(anterior$geracao,'inf_mensal_fidc_flat.csv')))
})
