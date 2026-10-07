# Fixtures locais P02–P07: sem rede, credenciais ou relógio externo.
pipeline <- new.env(parent = globalenv())
for (nome in c('p02_utilitarios.R','p04_configuracao_fidc.R','p05_download_fidc.R',
  'p06_consolidacao_fidc.R','p07_aceite.R','p07_evidencias.R'))
  sys.source(file.path('../../scripts',nome), envir = pipeline)

# ZIP stored mínimo com CRC real; não exige zip/Rtools instalado.
fixture_zip <- function(destino, membros) {
  locais <- raw(); centrais <- raw(); offset <- 0L
  for (nome in names(membros)) {
    bytes <- charToRaw(enc2utf8(membros[[nome]])); n <- charToRaw(nome)
    crc_hex <- digest::digest(bytes,algo='crc32',serialize=FALSE)
    crc <- rev(as.raw(strtoi(substring(crc_hex,seq(1,8,2),seq(2,8,2)),16L)))
    local <- c(as.raw(c(80,75,3,4)),writeBin(as.integer(c(20,0,0,0,0)),raw(),size=2,endian='little'),
      crc,writeBin(as.integer(rep(length(bytes),2)),raw(),size=4,endian='little'),
      writeBin(as.integer(c(length(n),0)),raw(),size=2,endian='little'),n,bytes)
    central <- c(as.raw(c(80,75,1,2)),writeBin(as.integer(c(20,20,0,0,0,0)),raw(),size=2,endian='little'),
      crc,writeBin(as.integer(rep(length(bytes),2)),raw(),size=4,endian='little'),
      writeBin(as.integer(c(length(n),0,0,0,0)),raw(),size=2,endian='little'),
      writeBin(as.integer(c(0,offset)),raw(),size=4,endian='little'),n)
    locais <- c(locais,local); centrais <- c(centrais,central); offset <- length(locais)
  }
  fim <- c(as.raw(c(80,75,5,6)),writeBin(as.integer(c(0,0,length(membros),length(membros))),
    raw(),size=2,endian='little'),writeBin(as.integer(c(length(centrais),length(locais))),raw(),size=4,endian='little'),
    writeBin(0L,raw(),size=2,endian='little'))
  writeBin(c(locais,centrais,fim),destino)
  destino
}

fixture_piloto <- function(raiz, meses = c('202607','202608')) {
  dir.create(raiz,recursive=TRUE,showWarnings=FALSE)
  dir.create(file.path(raiz,'referencias/cvm'),recursive=TRUE,showWarnings=FALSE)
  file.copy('../../referencias/cvm/dicionario_campos_declarados.csv',file.path(raiz,'referencias/cvm/dicionario_campos_declarados.csv'))
  config <- pipeline$validar_configuracao(list(tabelas=c('I','IV','VIII','X_4')),raiz)
  config$inicio <- paste0(substr(min(meses),1,4),'-',substr(min(meses),5,6),'-01')
  config$fim <- as.character(seq(as.Date(paste0(substr(max(meses),1,4),'-',substr(max(meses),5,6),'-01')),by='month',length.out=2)[2]-1)
  plano <- data.frame(unidade=meses,arquivo=paste0('inf_mensal_fidc_',meses,'.zip'),url=paste0('simulado/',meses))
  dir.create(file.path(raiz,'dados'),showWarnings=FALSE)
  saveRDS(list(config=config,plano=plano),file.path(raiz,'dados/configuracao.rds'))
  origem <- tempfile();dir.create(origem)
  for (mes in meses) {
    data <- if (mes == '202607') '2026-07-31' else '2026-08-31'
    base <- paste0('CNPJ_FUNDO_CLASSE;DT_COMPTC;DENOM_SOCIAL;',
      'TP_FUNDO_CLASSE;')
    membros <- list()
    membros[[paste0('inf_mensal_fidc_tab_I_',mes,'.csv')]] <- paste0(base,'TAB_I_VL_ATIVO\n',
      '00.000.000/0001-91;',data,';Ação;Classe;100.50\n')
    membros[[paste0('inf_mensal_fidc_tab_IV_',mes,'.csv')]] <- paste0(base,'TAB_IV_A_VL_PL\n',
      '00.000.000/0001-91;',data,';Ação;Classe;90.25\n',
      '01.000.000/0001-91;',data,';Órfão;Classe;33.00\n')
    membros[[paste0('inf_mensal_fidc_tab_VIII_',mes,'.csv')]] <- paste0(base,'SEQUENCIAL;VALOR\n',
      '00.000.000/0001-91;',data,';Ação;Classe;1;10.00\n',
      '00.000.000/0001-91;',data,';Ação;Classe;2;20.00\n')
    membros[[paste0('inf_mensal_fidc_tab_X_4_',mes,'.csv')]] <- paste0(base,'TAB_X_CLASSE_SERIE;TAB_X_TP_OPER;TAB_X_VL_TOTAL\n',
      '00.000.000/0001-91;',data,';Ação;Classe;Sênior;Captação;5.00\n',
      '00.000.000/0001-91;',data,';Ação;Classe;Subordinada;Resgate;6.00\n')
    fixture_zip(file.path(origem,paste0(mes,'.zip')),membros)
  }
  transporte <- function(url,destino,timeout) {
    file.copy(file.path(origem,paste0(basename(url),'.zip')),destino,overwrite=TRUE);200L
  }
  downloads <- pipeline$retomar_downloads_fidc(plano,config,raiz,transporte,function(x)NULL)
  saveRDS(downloads,file.path(raiz,'dados/downloads.rds'))
  mapa <- read.csv('../../referencias/cvm/dicionario_campos_declarados.csv',stringsAsFactors=FALSE)
  list(config=config,downloads=downloads,plano=plano,mapa=mapa,transporte=transporte,origem=origem)
}

# Evidências SIMULADAS para testar validação; não são provas do piloto real.
fixture_evidencias <- function(r,config,raiz) {
  dir.create(file.path(raiz,'logs'),showWarnings=FALSE)
  teste <- 'logs/testes.rds'; resumo <- 'logs/testes_resumo.json'; ret <- 'logs/retomada.rds'
  saveRDS(list(origem='fixture'),file.path(raiz,teste))
  hashes <- vapply(r$arquivos,function(x)x$hash,character(1))
  hash_teste <- pipeline$calcular_hash_assinatura(file.path(raiz,teste),TRUE)
  jsonlite::write_json(list(estado='concluido',suite='todas',codigo=r$codigo,casos=1,
    verificacoes=1,falhas=0,erros=0,avisos=0,skips=0,hash_resultados=hash_teste),
    file.path(raiz,resumo),auto_unbox=TRUE)
  demo <- config; demo$usar_checkpoints <- TRUE; demo$atualizar_downloads <- FALSE; demo$forcar_reprocessamento <- FALSE
  cp <- list.files(file.path(raiz,config$checkpoints),pattern='manifesto.rds$',full.names=TRUE)[1]
  intermediario <- sub('.manifesto.rds$','',cp)
  saveRDS(list(origem='fixture',codigo=r$codigo,config=config,assinatura=r$assinatura,pid_interrupcao=1L,
    pid_retomada=2L,pid_repeticao=3L,reutilizados=1L,hashes_antes=hashes,hashes_depois=hashes,
    hashes_usuario=hashes,config_usuario=config,config_demonstracao=demo,
    assinatura_plano=r$assinatura_plano,processados_interrupcao=1L,
    checkpoints=list(list(caminho=substring(cp,nchar(raiz)+2L),hash=pipeline$calcular_hash_assinatura(cp,TRUE),
      intermediario=substring(intermediario,nchar(raiz)+2L),hash_intermediario=pipeline$calcular_hash_assinatura(intermediario,TRUE)))),file.path(raiz,ret))
  arqs <- c(testes=teste,resumo=resumo,retomada=ret)
  list(codigo=r$codigo,config=config,assinatura=r$assinatura,
    artefatos=lapply(arqs,function(a)list(caminho=a,hash=pipeline$calcular_hash_assinatura(file.path(raiz,a),TRUE))))
}
