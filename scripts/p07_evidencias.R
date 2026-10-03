# P07-MOD-002 | P07-RF-004: testes reais e retomada em processos novos, sem GET CVM.
# P07-FUN-004 | Validação de evidências lidas do disco; booleanos manuais não bastam.
validar_evidencias_aceite <- function(evidencia,resultado,config,raiz='.') {
  codigo <- assinatura_codigo(raiz)
  if (!identical(resultado$logica,assinatura_transformacao()) ||
      !identical(resultado$logica_saida,assinatura_transformacao('saida'))) return(FALSE)
  mapa <- read.csv(file.path(raiz,'P04_CAMPOS_DECLARADOS_DICIONARIO.csv'),stringsAsFactors=FALSE,fileEncoding='UTF-8')
  if (!identical(resultado$mapa,calcular_hash_assinatura(mapa))) return(FALSE)
  for(meta in resultado$contratos) {
    arq <- validar_destino(raiz,meta$caminho)
    if (!file.exists(arq) || !identical(meta$hash,calcular_hash_assinatura(arq,TRUE))) return(FALSE)
  }
  if (!is.list(evidencia) || !identical(evidencia$codigo,codigo) ||
      !identical(resultado$codigo,codigo) || !identical(evidencia$config,config) ||
      !identical(resultado$config,config) || !identical(evidencia$assinatura,resultado$assinatura)) return(FALSE)
  artefatos <- evidencia$artefatos
  if (is.null(artefatos) || !all(c('testes','resumo','retomada') %in% names(artefatos))) return(FALSE)
  for (meta in artefatos) {
    caminho <- tryCatch(validar_destino(raiz,meta$caminho),error=function(e)NULL)
    if (is.null(caminho) || !file.exists(caminho) ||
        !identical(calcular_hash_assinatura(caminho,TRUE),meta$hash)) return(FALSE)
  }
  testes <- jsonlite::read_json(validar_destino(raiz,artefatos$resumo$caminho),simplifyVector=TRUE)
  retomada <- readRDS(validar_destino(raiz,artefatos$retomada$caminho))
  obrigatorios <- c('estado','suite','codigo','casos','verificacoes','falhas','erros','avisos','skips','hash_resultados')
  if (!all(obrigatorios %in% names(testes))) return(FALSE)
  if (!all(c('codigo','assinatura','config','pid_interrupcao','pid_retomada','pid_repeticao',
    'reutilizados','hashes_antes','hashes_depois') %in% names(retomada))) return(FALSE)
  if (!all(c('config_demonstracao','config_usuario','checkpoints','processados_interrupcao',
      'hashes_usuario','assinatura_plano') %in% names(retomada))) return(FALSE)
  invariantes <- setdiff(names(config),c('dados','saidas','checkpoints','usar_checkpoints','atualizar_downloads','forcar_reprocessamento'))
  if (!identical(retomada$config_demonstracao[invariantes],config[invariantes]) ||
      !identical(retomada$config_usuario[setdiff(names(config),c('dados','saidas','checkpoints'))],
        config[setdiff(names(config),c('dados','saidas','checkpoints'))]) ||
      !isTRUE(retomada$config_demonstracao$usar_checkpoints) ||
      !identical(retomada$config_demonstracao$forcar_reprocessamento,FALSE) ||
      !identical(retomada$config_demonstracao$atualizar_downloads,FALSE) ||
      !identical(retomada$assinatura_plano,resultado$assinatura_plano) ||
      !identical(retomada$hashes_usuario,retomada$hashes_depois) ||
      retomada$processados_interrupcao<1L || !length(retomada$checkpoints)) return(FALSE)
  for (cp in retomada$checkpoints) {
    for (campo in c('caminho','intermediario')) {
      arq <- validar_destino(raiz,cp[[campo]])
      hash <- cp[[if(campo=='caminho') 'hash' else 'hash_intermediario']]
      if (!file.exists(arq) || !identical(calcular_hash_assinatura(arq,TRUE),hash)) return(FALSE)
    }
  }
  isTRUE(testes$estado=='concluido') && identical(testes$suite,'todas') &&
    identical(testes$codigo,codigo) && testes$casos>0 && testes$verificacoes>0 &&
    all(c(testes$falhas,testes$erros,testes$avisos,testes$skips)==0) &&
    identical(testes$hash_resultados,artefatos$testes$hash) &&
    identical(retomada$codigo,codigo) && identical(retomada$assinatura,resultado$assinatura) &&
    identical(retomada$config,config) && retomada$pid_interrupcao!=retomada$pid_retomada &&
    !anyDuplicated(c(retomada$pid_interrupcao,retomada$pid_retomada,retomada$pid_repeticao)) && retomada$reutilizados>0 &&
    length(retomada$hashes_antes)>0 && identical(retomada$hashes_antes,retomada$hashes_depois) &&
    identical(retomada$hashes_depois,vapply(resultado$arquivos,function(x)x$hash,character(1)))
}

# P07-FUN-003 | Executa suíte, interrompe após checkpoint, retoma e repete em Rscript.
# Entrada config validada e downloads locais. Saída evidência ligada ao conteúdo do código.
produzir_evidencias_aceite <- function(config=list(),raiz='.',executor_testes=NULL) {
  raiz <- normalizePath(raiz,winslash='/',mustWork=TRUE)
  if (!identical(normalizePath(getwd(),winslash='/'),raiz)) stop('Execute as evidências da raiz do projeto.')
  config <- validar_configuracao(config,raiz)
  downloads <- ler_rds_recuperavel(file.path(raiz,config$dados,'downloads.rds'))
  vinculo <- validar_downloads_plano(downloads,config,raiz)
  atual <- ler_rds_recuperavel(file.path(raiz,config$saidas,'atual.rds'))
  estado <- ler_rds_recuperavel(file.path(raiz,config$saidas,'execucao.rds'))
  if (is.null(atual) || !identical(atual$config,config) || !identical(atual$estado,'concluido') ||
      !identical(estado$estado,'concluido') || !identical(estado$assinatura,atual$assinatura))
    stop('Execute P06 com a configuração solicitada antes de produzir evidências.')
  id <- basename(tempfile(paste0('demo-',Sys.getpid(),'-')))
  relativo <- paste0('logs/evidencias/',id)
  area <- validar_destino(raiz,relativo); dir.create(area,recursive=TRUE)
  codigo <- assinatura_codigo(raiz); rscript <- file.path(R.home('bin'),'Rscript')
  if (is.null(executor_testes)) {
    if (identical(Sys.getenv('FIDC_TESTES_ATIVOS'),'1')) stop('Produção recursiva impedida; injete executor_testes.')
    executor_testes <- function() system2(rscript,
      c('--vanilla',shQuote(file.path(raiz,'scripts/p02_testar.R')),'todas'),
      stdout=file.path(area,'testes.txt'),stderr=file.path(area,'testes.txt'))
  }
  if (!identical(as.integer(executor_testes()),0L)) stop('Suíte falhou; evidência não aprovada.')
  usuario <- config; usuario$dados <- paste0(relativo,'/dados')
  usuario$saidas <- paste0(relativo,'/usuario'); usuario$checkpoints <- paste0(relativo,'/checkpoints_usuario')
  dir.create(file.path(raiz,usuario$dados,'originais'),recursive=TRUE)
  locais <- lapply(downloads,function(r) {
    destino <- file.path(raiz,usuario$dados,'originais',basename(r$arquivo))
    if (!file.exists(r$arquivo) || !identical(calcular_hash_assinatura(r$arquivo,TRUE),r$hash)) stop('ZIP local incompatível: execute P05.')
    validar_zip_fidc(r$arquivo,config$max_bytes_zip)
    if (!file.copy(r$arquivo,destino)) stop('Cópia local falhou.')
    r$arquivo <- destino; r
  })
  saveRDS(list(config=usuario,plano=vinculo$plano),file.path(raiz,usuario$dados,'configuracao.rds'))
  demo <- usuario; demo$saidas <- paste0(relativo,'/demonstracao'); demo$checkpoints <- paste0(relativo,'/checkpoints_demo')
  demo$usar_checkpoints <- TRUE; demo$atualizar_downloads <- FALSE; demo$forcar_reprocessamento <- FALSE
  entrada <- file.path(area,'entrada.rds'); saveRDS(list(raiz=raiz,usuario=usuario,demo=demo,downloads=locais,bibliotecas=.libPaths()),entrada)
  script <- file.path(area,'processar.R')
  writeLines(c(
    "args <- commandArgs(trailingOnly=TRUE); x <- readRDS(args[1])",
    "setwd(x$raiz); .libPaths(x$bibliotecas)",
    "source('scripts/p02_utilitarios.R'); p <- carregar_pipeline('.')",
    "mapa <- read.csv('P04_CAMPOS_DECLARADOS_DICIONARIO.csv',stringsAsFactors=FALSE)",
    "saveRDS(Sys.getpid(),args[3]); config <- if(args[2]=='usuario') x$usuario else x$demo",
    "r <- p$retomar_consolidacao_fidc(x$downloads,config,'.',mapa,if(args[2]=='interromper') 1 else Inf)",
    "saveRDS(r,args[4])"),script,useBytes=TRUE)
  executar <- function(modo) {
    pid <- file.path(area,paste0(modo,'_pid.rds')); saida <- file.path(area,paste0(modo,'.rds'))
    status <- suppressWarnings(system2(rscript,c('--vanilla',shQuote(script),shQuote(entrada),modo,
      shQuote(pid),shQuote(saida)),stdout=file.path(area,paste0(modo,'.txt')),stderr=file.path(area,paste0(modo,'.txt'))))
    list(status=status,pid=if(file.exists(pid)) readRDS(pid) else NA_integer_,resultado=if(status==0L) readRDS(saida) else NULL)
  }
  solicitada <- executar('usuario'); interrompida <- executar('interromper')
  manifestos <- list.files(file.path(raiz,demo$checkpoints),pattern='manifesto.rds$',full.names=TRUE)
  novos <- lapply(manifestos,readRDS)
  if (interrompida$status==0 || !length(novos) ||
      !all(vapply(novos,function(x)identical(x$estado,'concluido'),logical(1))) ||
      !any(grepl('Interrupção solicitada',readLines(file.path(area,'interromper.txt'),warn=FALSE))))
    stop('Persistência/interrupção não demonstrada.')
  checkpoints <- lapply(manifestos,function(m) list(caminho=substring(m,nchar(raiz)+2L),
    hash=calcular_hash_assinatura(m,TRUE),intermediario=substring(sub('.manifesto.rds$','',m),nchar(raiz)+2L),
    hash_intermediario=calcular_hash_assinatura(sub('.manifesto.rds$','',m),TRUE)))
  retomada <- executar('retomar'); repeticao <- executar('repetir')
  if (solicitada$status!=0 || retomada$status!=0 || repeticao$status!=0) stop('Execução/retomada/repetição falhou.')
  obter_hashes <- function(x) vapply(x$arquivos,function(meta)meta$hash,character(1))
  prova <- list(id=id,origem='dados_locais',codigo=codigo,config=config,config_usuario=usuario,
    config_demonstracao=demo,parametros_modificados=names(config)[!vapply(names(config),function(n)identical(config[[n]],demo[[n]]),logical(1))],
    assinatura=atual$assinatura,assinatura_plano=vinculo$assinatura,
    entradas=vapply(locais,function(x)x$hash,character(1)),checkpoints=checkpoints,
    pid_usuario=solicitada$pid,pid_interrupcao=interrompida$pid,pid_retomada=retomada$pid,pid_repeticao=repeticao$pid,
    reutilizados=retomada$resultado$reutilizados,processados_interrupcao=length(novos),
    hashes_usuario=obter_hashes(solicitada$resultado),hashes_antes=obter_hashes(retomada$resultado),hashes_depois=obter_hashes(repeticao$resultado))
  caminho_prova <- file.path(area,'retomada.rds'); gravar_validado_atomico(prova,caminho_prova)
  relativos <- c(testes='logs/testes.rds',resumo='logs/testes_resumo.json',retomada=paste0(relativo,'/retomada.rds'))
  artefatos <- lapply(relativos,function(arq)list(caminho=arq,hash=calcular_hash_assinatura(file.path(raiz,arq),TRUE)))
  resumo <- jsonlite::read_json(file.path(raiz,'logs/testes_resumo.json'),simplifyVector=TRUE)
  evidencia <- list(estado='concluido',origem=if(identical(resumo$origem,'fixture')) 'fixture' else 'dados_locais',
    codigo=codigo,config=config,assinatura=atual$assinatura,artefatos=artefatos)
  if (!isTRUE(validar_evidencias_aceite(evidencia,atual,config,raiz))) stop('Evidência inconsistente.')
  gravar_validado_atomico(evidencia,validar_destino(raiz,'logs/evidencias_aceite.rds'))
  evidencia
}
if (sys.nframe()==0L) {
  .libPaths(c(normalizePath('.R-library'),.libPaths()))
  source('scripts/p02_utilitarios.R')
  p <- carregar_pipeline('.')
  args <- commandArgs(trailingOnly=TRUE)
  config <- if(length(args)) readRDS(args[1]) else list()
  if ('config' %in% names(config)) config <- config$config
  p$produzir_evidencias_aceite(config)
  cat('Evidências automáticas produzidas e conferidas.\n')
}
