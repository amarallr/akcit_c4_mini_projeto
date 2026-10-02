# P07-MOD-002 | P07-RF-004: testes reais e retomada em processos novos, sem GET CVM.
# P07-FUN-004 | Validação de evidências lidas do disco; booleanos manuais não bastam.
validar_evidencias_aceite <- function(evidencia,resultado,config,raiz='.') {
  codigo <- assinatura_codigo(raiz)
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
  isTRUE(testes$estado=='concluido') && identical(testes$suite,'todas') &&
    identical(testes$codigo,codigo) && testes$casos>0 && testes$verificacoes>0 &&
    all(c(testes$falhas,testes$erros,testes$avisos,testes$skips)==0) &&
    identical(testes$hash_resultados,artefatos$testes$hash) &&
    identical(retomada$codigo,codigo) && identical(retomada$assinatura,resultado$assinatura) &&
    identical(retomada$config,config) && retomada$pid_interrupcao!=retomada$pid_retomada &&
    retomada$pid_retomada!=retomada$pid_repeticao && retomada$reutilizados>0 &&
    length(retomada$hashes_antes)>0 && identical(retomada$hashes_antes,retomada$hashes_depois) &&
    identical(retomada$hashes_depois,vapply(resultado$arquivos,function(x)x$hash,character(1)))
}

# P07-FUN-003 | Executa suíte, interrompe após checkpoint, retoma e repete em Rscript.
# Entrada config validada e downloads locais. Saída evidência ligada ao conteúdo do código.
produzir_evidencias_aceite <- function(config=list(),raiz='.') {
  raiz <- normalizePath(raiz,winslash='/',mustWork=TRUE)
  if (!identical(normalizePath(getwd(),winslash='/'),raiz)) stop('Execute as evidências da raiz do projeto.')
  config <- validar_configuracao(config,raiz)
  area <- validar_destino(raiz,'logs/evidencias')
  dir.create(area,recursive=TRUE,showWarnings=FALSE)
  entrada <- file.path(area,'entrada.rds')
  saveRDS(list(raiz=raiz,config=config),entrada)
  codigo <- assinatura_codigo(raiz)
  evidencia_destino <- validar_destino(raiz,'logs/evidencias_aceite.rds')
  gravar_validado_atomico(list(estado='em_processamento',codigo=codigo),evidencia_destino)
  rscript <- file.path(R.home('bin'),'Rscript')
  teste_status <- system2(rscript,c('--vanilla',shQuote(file.path(raiz,'scripts/p02_testar.R')),'todas'),
    stdout=file.path(area,'testes.txt'),stderr=file.path(area,'testes.txt'))
  if (teste_status!=0) stop('Suíte falhou; evidência não aprovada.')
  script <- file.path(area,'processar.R')
  # Gerador de processo herda P07-FUN-003: argumentos escapados, sem comandos de shell.
  writeLines(c(
    "args <- commandArgs(trailingOnly=TRUE); x <- readRDS(args[1])",
    "setwd(x$raiz); .libPaths(c(normalizePath('.R-library'),.libPaths()))",
    "source('scripts/p02_utilitarios.R'); p <- carregar_pipeline('.')",
    "downloads <- p$ler_rds_recuperavel(file.path(x$config$dados,'downloads.rds'))",
    "mapa <- read.csv('P04_CAMPOS_DECLARADOS_DICIONARIO.csv',stringsAsFactors=FALSE)",
    "pid <- Sys.getpid(); saveRDS(pid,args[3])",
    "r <- p$retomar_consolidacao_fidc(downloads,x$config,'.',mapa,if(args[2]=='interromper') 1 else Inf)",
    "saveRDS(r,args[4])"),script,useBytes=TRUE)
  executar <- function(modo) {
    pid <- file.path(area,paste0(modo,'_pid.rds'))
    saida <- file.path(area,paste0(modo,'.rds'))
    status <- suppressWarnings(system2(rscript,c('--vanilla',shQuote(script),shQuote(entrada),modo,
      shQuote(pid),shQuote(saida)),stdout=file.path(area,paste0(modo,'.txt')),
      stderr=file.path(area,paste0(modo,'.txt'))))
    list(status=status,pid=readRDS(pid),resultado=if(status==0L) readRDS(saida) else NULL)
  }
  interrompida <- executar('interromper')
  if (interrompida$status==0 || !any(grepl('Interrupção solicitada',
    readLines(file.path(area,'interromper.txt'),warn=FALSE)))) stop('Interrupção não demonstrada.')
  retomada <- executar('retomar')
  repeticao <- executar('repetir')
  if (retomada$status!=0 || repeticao$status!=0) stop('Retomada/repetição falhou.')
  resultado <- repeticao$resultado
  obter_hashes <- function(x) vapply(x$arquivos,function(meta)meta$hash,character(1))
  prova <- list(codigo=codigo,config=config,assinatura=resultado$assinatura,
    pid_interrupcao=interrompida$pid,pid_retomada=retomada$pid,pid_repeticao=repeticao$pid,
    reutilizados=retomada$resultado$reutilizados,
    hashes_antes=obter_hashes(retomada$resultado),hashes_depois=obter_hashes(resultado))
  caminho_prova <- file.path(area,'retomada.rds')
  gravar_validado_atomico(prova,caminho_prova)
  relativos <- c(testes='logs/testes.rds',resumo='logs/testes_resumo.json',retomada='logs/evidencias/retomada.rds')
  artefatos <- lapply(relativos,function(arq)list(caminho=arq,hash=calcular_hash_assinatura(file.path(raiz,arq),TRUE)))
  evidencia <- list(estado='concluido',codigo=codigo,config=config,
    assinatura=resultado$assinatura,artefatos=artefatos)
  if (!isTRUE(validar_evidencias_aceite(evidencia,resultado,config,raiz))) stop('Evidência inconsistente.')
  gravar_validado_atomico(evidencia,evidencia_destino)
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
