# P08-TST-001/002/003 | fixtures isoladas, sem rede ou artefatos públicos.
for(n in c('p08_analise_fidc.R','p08_exportar_painel.R')) sys.source(file.path('../../scripts',n),envir=pipeline)

testthat::test_that('P08-TST-001: P97,5 interpolado e n=0/n=1 antecedem winsorização',{
  s <- pipeline$estatisticas_pl_fidc(c(0,10,20,30,NA))
  testthat::expect_equal(s$p97_5,29.25);testthat::expect_equal(s$p2_5,.75)
  testthat::expect_equal(s$n_valido,4);testthat::expect_equal(s$n_ausente,1)
  testthat::expect_equal(s$mediana,15);testthat::expect_equal(s$desvio_padrao,stats::sd(c(0,10,20,30)))
  testthat::expect_true(is.na(pipeline$estatisticas_pl_fidc(numeric())$p97_5))
  testthat::expect_equal(pipeline$estatisticas_pl_fidc(7)$p97_5,7)
  testthat::expect_true(is.na(pipeline$estatisticas_pl_fidc(7)$desvio_padrao))
})

testthat::test_that('P08-TST-001: chaves, admins históricos, universos e limites globais',{
  i <- data.frame(cnpj=sprintf('%014d',1:4),dt_comptc='2026-07-31',TP_FUNDO_CLASSE='Classe',
    CNPJ_ADMIN=c(rep('00.360.305/0001-04',2),rep('60.701.190/0001-04',2)),ADMIN=c('Caixa','Caixa','Itau','Itau'))
  iv <- i[,c('cnpj','dt_comptc','TP_FUNDO_CLASSE')];iv$TAB_IV_A_VL_PL <- c(0,10,20,30)
  a <- pipeline$calcular_analise_fidc(iv,i)
  testthat::expect_equal(a$estatisticas$p97_5,29.25)
  testthat::expect_equal(a$estatisticas_admin[cnpj_admin=='00360305000104']$p97_5,9.75)
  testthat::expect_equal(sort(a$posicoes$pl_wins),c(.75,10,20,29.25))
  testthat::expect_equal(a$ranking$denominador,rep(60,2))
  testthat::expect_equal(a$ranking$participacao,c(50/60,10/60))
  iv2 <- rbind(iv,iv[1,]);iv2$TP_FUNDO_CLASSE[5] <- 'Fundo'
  i2 <- rbind(i,i[1,]);i2$TP_FUNDO_CLASSE[5] <- 'Fundo'
  a2 <- pipeline$calcular_analise_fidc(iv2,i2)
  testthat::expect_equal(nrow(a2$estatisticas),2)
  testthat::expect_equal(a2$estatisticas[tipo=='Classe']$total,60)
  dup <- rbind(iv,iv[1,]);testthat::expect_equal(nrow(pipeline$deduplicar_analise_fidc(dup,'TAB_IV_A_VL_PL','IV')),4)
  dup$TAB_IV_A_VL_PL[5] <- 99;testthat::expect_error(pipeline$deduplicar_analise_fidc(dup,'TAB_IV_A_VL_PL','IV'),'conflitantes')
  i$CNPJ_ADMIN[1] <- NA;a3 <- pipeline$calcular_analise_fidc(iv,i)
  testthat::expect_equal(a3$estatisticas$sem_admin,1);testthat::expect_equal(a3$estatisticas$total,60)
  later <- i;later$dt_comptc <- '2026-08-31';later$CNPJ_ADMIN[2] <- '60.701.190/0001-04';later$ADMIN[2] <- 'Itau novo nome'
  ivlater <- iv;ivlater$dt_comptc <- later$dt_comptc
  hist <- pipeline$calcular_analise_fidc(rbind(iv,ivlater),rbind(i,later))
  testthat::expect_equal(hist$posicoes[cnpj==sprintf('%014d',2)&data=='2026-07-31']$cnpj_admin,'00360305000104')
  testthat::expect_equal(hist$posicoes[cnpj==sprintf('%014d',2)&data=='2026-08-31']$cnpj_admin,'60701190000104')
})

testthat::test_that('P08-TST-001: top25 usa denominador completo e desempate por CNPJ',{
 d <- data.table::data.table(tipo='Classe',data='2026-07-31',cnpj=sprintf('%014d',1:30),
  cnpj_admin=sprintf('%014d',1:30),nome_admin='Nome',pl=1)
 r <- pipeline$ranking_posicoes_fidc(d)
 testthat::expect_equal(nrow(r),30);testthat::expect_equal(r$participacao,rep(1/30,30))
 testthat::expect_equal(sum(r$participacao[1:25]),25/30)
 testthat::expect_identical(r$cnpj_admin,sort(d$cnpj_admin))
})

testthat::test_that('P08-TST-002: categorias exclusivas, nulos, zero, negativos e razão de somas',{
 d <- data.table::data.table(cnpj=c('a','b','c'),tipo='Classe',data='2026-07-31',cnpj_admin='x',
  TAB_I_VL_ATIVO=c(100,300,0),TAB_I1_VL_DISP=c(10,90,NA),TAB_I2_VL_CARTEIRA=c(90,210,-1),
  TAB_I3_VL_POSICAO_DERIV=0,TAB_I4_VL_OUTRO_ATIVO=0,TAB_I2A_VL_DIRCRED_RISCO=c(40,100,0))
 c <- pipeline$compor_carteira_fidc(d)
 testthat::expect_equal(c$reconciliacao$diferenca[1:2],c(0,0))
 testthat::expect_true(all(c$reconciliacao$reconciliado[1:2]))
 testthat::expect_true(is.na(c$reconciliacao$diferenca[3]))
 x <- c$longo[campo=='TAB_I1_VL_DISP'];ok <- !is.na(x$valor)&x$base>0
 testthat::expect_equal(sum(x$valor[ok])/sum(x$base[ok]),.25)
 testthat::expect_false(isTRUE(all.equal(mean(x$percentual,na.rm=TRUE),.25)))
 testthat::expect_true(is.na(c$longo[cnpj=='c'&campo=='TAB_I2_VL_CARTEIRA']$percentual))
 d$TAB_I4_VL_OUTRO_ATIVO[1] <- -5;c2 <- pipeline$compor_carteira_fidc(d)
 testthat::expect_false(c2$reconciliacao$empilhavel[1]);testthat::expect_equal(c2$reconciliacao$diferenca[1],5)
})

testthat::test_that('P08-TST-003: E/OU, desconhecidos, condomínio e cotistas inclusivos',{
 d <- data.frame(COTST_INTERESSE=c('S','N',NA,'S'),FUNDO_EXCLUSIVO=c('N','S',NA,'S'),CONDOM=c('ABERTO','FECHADO',NA,'FECHADO'),cotistas=c(0,2,NA,3))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(interesse='Sim',exclusivo='Sim'))$elegivel,c(FALSE,FALSE,FALSE,TRUE))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(interesse='Sim',exclusivo='Sim',operador='OU'))$elegivel,c(TRUE,TRUE,FALSE,TRUE))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(interesse='Não',incluir_desconhecidos=TRUE))$elegivel,c(FALSE,TRUE,TRUE,FALSE))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(exclusivo='Sim',operador='OU'))$elegivel,c(FALSE,TRUE,FALSE,TRUE))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(cotistas_min=0,cotistas_max=2))$elegivel,c(TRUE,TRUE,FALSE,FALSE))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(cotistas_igual=0))$elegivel,c(TRUE,FALSE,FALSE,FALSE))
 testthat::expect_equal(pipeline$avaliar_filtros_fidc(d,list(condominio=c('ABERTO','FECHADO')))$elegivel,c(TRUE,TRUE,FALSE,TRUE))
 testthat::expect_error(pipeline$avaliar_filtros_fidc(d[,setdiff(names(d),'COTST_INTERESSE')],list(interesse='Sim')),'indisponível')
 testthat::expect_error(pipeline$validar_filtros_fidc(list(cotistas_min=3,cotistas_max=2)),'invertido')
 testthat::expect_error(pipeline$validar_filtros_fidc(list(cotistas_igual=1.5)),'inteiro')
 testthat::expect_error(pipeline$validar_filtros_fidc(list(condominio='FECHADOO')),'domínio')
})

testthat::test_that('P08-TST-003: pré-filtro antes da materialização, mudança mensal e checkpoints',{
 raiz <- tempfile();dir.create(raiz)
 config <- pipeline$validar_configuracao(list(tabelas=c('I','IV'),gerar_flat=FALSE,
  filtros=list(interesse='Sim')),raiz)
 meses <- c('202607','202608');plano <- data.frame(unidade=meses,arquivo=paste0('inf_mensal_fidc_',meses,'.zip'),url=paste0('https://fixture/',meses))
 dir.create(file.path(raiz,'dados'));saveRDS(list(config=config,plano=plano),file.path(raiz,'dados/configuracao.rds'))
 origem <- tempfile();dir.create(origem)
 for(mes in meses){
  data <- if(mes=='202607')'2026-07-31' else '2026-08-31';indicador <- if(mes=='202607')'S' else 'N'
  cab <- 'CNPJ_FUNDO_CLASSE;TP_FUNDO_CLASSE;DT_COMPTC;'
  membros <- list();membros[[paste0('inf_mensal_fidc_tab_I_',mes,'.csv')]] <- paste0(cab,'COTST_INTERESSE;FUNDO_EXCLUSIVO;CONDOM\n00.000.000/0001-91;Classe;',data,';',indicador,';S;FECHADO\n')
  membros[[paste0('inf_mensal_fidc_tab_IV_',mes,'.csv')]] <- paste0(cab,'TAB_IV_A_VL_PL\n00.000.000/0001-91;Classe;',data,';100\n00.000.000/0001-91;Classe;',data,';100\n')
  fixture_zip(file.path(origem,paste0(mes,'.zip')),membros)
 }
 transporte <- function(url,destino,timeout){file.copy(file.path(origem,paste0(basename(url),'.zip')),destino);200L}
 downloads <- pipeline$retomar_downloads_fidc(plano,config,raiz,transporte,function(x)NULL)
 r <- pipeline$retomar_consolidacao_fidc(downloads,config,raiz)
 testthat::expect_equal(unname(r$linhas_tabelas),c(1L,2L))
 cp <- list.files(file.path(raiz,'checkpoints'),pattern='[.]rds$',full.names=TRUE)
 cp <- cp[!grepl('manifesto',cp)];testthat::expect_equal(sum(vapply(cp,function(p)nrow(readRDS(p)$dados),integer(1))),3L)
 testthat::expect_equal(r$filtros$contagens$depois,c(1,0))
 antigo <- r$arquivos$IV_rds$hash
 config$filtros$interesse <- 'Não'
 r2 <- pipeline$retomar_consolidacao_fidc(downloads,config,raiz)
 testthat::expect_equal(r2$reutilizados,0L);testthat::expect_false(identical(r$assinatura,r2$assinatura))
 testthat::expect_equal(pipeline$calcular_hash_assinatura(r$arquivos$IV_rds$caminho,TRUE),antigo)
 testthat::expect_equal(as.character(readRDS(r2$arquivos$IV_rds$caminho)$dt_comptc),rep('2026-08-31',2))
 config$filtros$condominio <- 'ABERTO'
 vazio <- pipeline$retomar_consolidacao_fidc(downloads,config,raiz)
 testthat::expect_identical(vazio$estado,'sem_registros_elegiveis')
 testthat::expect_identical(readRDS(file.path(raiz,'saidas/atual.rds'))$assinatura,r2$assinatura)
})

testthat::test_that('P08-TST-001: trimestre não soma meses nem substitui mês final ausente',{
 d <- data.table::data.table(tipo='Classe',data=c('2026-01-31','2026-02-28','2026-03-31'),cnpj_admin='a',valor=c(10,20,30))
 r <- pipeline$posicoes_trimestrais_fidc(d,d$data)
 testthat::expect_equal(r$pl_original,30)
 testthat::expect_equal(r$data,'2026-03-31')
 testthat::expect_equal(nrow(pipeline$posicoes_trimestrais_fidc(d[1:2],d$data[1:2])),0)
})

testthat::test_that('P08-TST-001: hash incompatível interrompe antes de gerar dados públicos',{
 source('../../scripts/p08_resumo_dados.R',local=TRUE)
 raiz <- tempfile();dir.create(raiz)
 cfg <- list(inicio='2026-07-01',fim='2026-07-31',tabelas=c('I','IV'),saidas=raiz)
 plano <- data.frame(unidade='202607',arquivo='inf_mensal_fidc_202607.zip',url='https://fixture/202607')
 sig <- pipeline$assinar_plano_fidc(plano,cfg)$assinatura
 caminho <- file.path(raiz,'i.csv');writeLines('alterado',caminho)
 atual <- list(estado='concluido',config=cfg,assinatura='fixture',assinatura_plano=sig,
  arquivos=list(I_csv=list(caminho=caminho,hash='hash-incompativel')))
 saveRDS(atual,file.path(raiz,'atual.rds'))
 saveRDS(list(estado='concluido',etapa='P06',assinatura='fixture',assinatura_plano=sig),file.path(raiz,'execucao.rds'))
 arquivo <- file.path(raiz,'config.rds');saveRDS(list(config=cfg,plano=plano),arquivo)
 projeto <- normalizePath('../..');antes <- getwd();setwd(projeto);on.exit(setwd(antes),add=TRUE)
 testthat::expect_error(gerar_resumo_dados_fidc(arquivo),'Hash de entrada divergente')
})
