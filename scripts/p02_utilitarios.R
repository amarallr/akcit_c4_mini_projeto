# P02-MOD-001 | Contratos comuns P02-RF-002/003/006, P02-RNF-002/004.
# source() define funções, sem instalação, rede ou execução de etapas.

# P02-FUN-006 | Entrada raiz/caminho; saída caminho contido; sem gravação.
validar_destino <- function(raiz, caminho) {
  if (length(caminho) != 1L || is.na(caminho) || !nzchar(caminho) ||
      grepl('(^[A-Za-z]:|^[/\\\\]|(^|[/\\\\])\\.\\.([/\\\\]|$))', caminho))
    stop('Caminho relativo inválido.')
  raiz <- normalizePath(raiz, winslash = '/', mustWork = TRUE)
  destino <- file.path(raiz, caminho)
  ancestral <- destino
  while (!file.exists(ancestral)) ancestral <- dirname(ancestral)
  real <- normalizePath(ancestral, winslash = '/', mustWork = TRUE)
  if (!identical(tolower(real), tolower(raiz)) &&
      !startsWith(tolower(real), paste0(tolower(raiz), '/')))
    stop('Destino fora da raiz.')
  destino
}

# P02-FUN-002 | Arquivo ou parâmetros; SHA-256 e assinatura determinística.
calcular_hash_assinatura <- function(x, arquivo = FALSE) {
  if (arquivo) return(digest::digest(file = x, algo = 'sha256'))
  if (is.list(x) && !is.data.frame(x)) {
    if (!is.null(names(x))) x <- x[order(names(x))]
    x <- vapply(x, calcular_hash_assinatura, character(1))
  }
  digest::digest(x, algo = 'sha256', serializeVersion = 2)
}

# P02-FUN-001 | Escrita validada em temporário vizinho; preserva anterior.
# Windows/OneDrive: rollback na substituição, sem promessa de atomicidade entre arquivos.
gravar_validado_atomico <- function(objeto, caminho, formato = 'rds', validador = NULL,
    renomear = file.rename) {
  dir.create(dirname(caminho), recursive = TRUE, showWarnings = FALSE)
  recuperar_rollback(caminho, function(arq) {
    observado <- if (formato == 'rds') readRDS(arq) else
      data.table::fread(arq, sep = ';', colClasses = 'character', showProgress = FALSE)
    is.null(validador) || isTRUE(validador(observado))
  })
  temporario <- tempfile('.publicar-', tmpdir = dirname(caminho))
  on.exit(unlink(temporario), add = TRUE)
  if (formato == 'rds') {
    saveRDS(objeto, temporario, version = 2)
    observado <- readRDS(temporario)
    # Ponteiros internos data.table não são conteúdo persistente; comparar serialização.
    if (!identical(calcular_hash_assinatura(objeto), calcular_hash_assinatura(observado)))
      stop('RDS não preservou conteúdo.')
  } else if (formato == 'csv') {
    data.table::fwrite(objeto, temporario, sep = ';', dec = '.', quote = TRUE,
      na = '', bom = FALSE)
    # Validação de estrutura não precisa materializar todas as colunas do flat.
    cabecalho <- data.table::fread(temporario,sep=';',nrows=0,encoding='UTF-8',showProgress=FALSE)
    observado <- data.table::fread(temporario, sep = ';', colClasses = 'character',
      select=if(is.null(validador)) 1L else NULL,
      na.strings = '', encoding = 'UTF-8', showProgress = FALSE)
    if (nrow(observado) != nrow(objeto) || !identical(names(cabecalho), names(objeto)))
      stop('CSV divergente após escrita.')
  } else stop('Formato não suportado.')
  if (!is.null(validador) && !isTRUE(validador(observado))) stop('Validação rejeitada.')
  anterior <- paste0(caminho, '.rollback')
  if (file.exists(anterior)) stop('Rollback pendente, preservar e revisar: ', anterior)
  existia <- file.exists(caminho)
  if (existia && !renomear(caminho, anterior)) stop('Destino bloqueado.')
  if (!renomear(temporario, caminho)) {
    if (existia) file.rename(anterior, caminho)
    stop('Publicação falhou; versão anterior preservada.')
  }
  if (existia) unlink(anterior)
  list(caminho = caminho, hash = calcular_hash_assinatura(caminho, TRUE))
}

# P02-FUN-007 | P02-RF-008: recuperação conservadora; preserva destino interrompido.
# Validador recebe caminho. Sem backup válido, interrompe sem apagar arquivos.
recuperar_rollback <- function(caminho, validador = function(arq) { readRDS(arq); TRUE }) {
  backup <- paste0(caminho, '.rollback')
  if (!file.exists(backup)) return(invisible(FALSE))
  valido <- tryCatch(isTRUE(validador(backup)), error = function(e) FALSE)
  if (!valido) stop('Rollback inválido, preservar e revisar: ', backup)
  if (file.exists(caminho)) {
    preservado <- tempfile(paste0(basename(caminho), '.interrompido-'), dirname(caminho))
    if (!file.rename(caminho, preservado)) stop('Destino bloqueado na recuperação.')
  }
  if (!file.rename(backup, caminho)) stop('Não foi possível restaurar rollback.')
  invisible(TRUE)
}

# P02-FUN-008 | P02-RF-008: RDS corrompido nunca é considerado prova de sucesso.
ler_rds_recuperavel <- function(caminho, validador = function(x) is.list(x)) {
  recuperar_rollback(caminho, function(arq) isTRUE(validador(readRDS(arq))))
  if (!file.exists(caminho)) return(NULL)
  observado <- tryCatch(readRDS(caminho), error = function(e) NULL)
  if (is.null(observado) || !isTRUE(validador(observado))) {
    preservado <- tempfile(paste0(basename(caminho), '.corrompido-'), dirname(caminho))
    if (!file.rename(caminho, preservado)) stop('RDS corrompido bloqueado: ', caminho)
    warning('RDS inválido preservado, requer reconstrução: ', basename(caminho), call. = FALSE)
    return(NULL)
  }
  observado
}

# P02-FUN-009 | P07-RF-004: hash de conteúdo, estável após commit/reescrita Git.
assinatura_codigo <- function(raiz = '.') {
  raiz <- normalizePath(raiz,winslash='/',mustWork=TRUE)
  arquivos <- c(list.files(file.path(raiz,'scripts'), '\\.(R|ps1)$', full.names = TRUE),
    list.files(file.path(raiz,'tests'), '\\.R$', recursive = TRUE, full.names = TRUE),
    file.path(raiz, c('renv.lock','P04_CAMPOS_DECLARADOS_DICIONARIO.csv')))
  arquivos <- sort(arquivos[file.exists(arquivos)])
  calcular_hash_assinatura(setNames(lapply(arquivos, calcular_hash_assinatura, arquivo = TRUE),
    substring(arquivos, nchar(raiz)+2L)))
}

# P02-FUN-012 | Assina apenas funções que influenciam leitura e transformação.
assinatura_transformacao <- function(escopo='leitura') {
  nomes <- c('ler_padronizar_fidc','relatar_qualidade_fidc','validar_dv_ni')
  if(escopo=='saida') nomes <- c(nomes,'consolidar_tabelas_fidc','auditar_chaves_fidc',
    'extrair_cedentes_fidc','avaliar_identificador_cedente')
  calcular_hash_assinatura(setNames(lapply(nomes,function(n) {
    f <- get(n,envir=environment(assinatura_transformacao))
    list(argumentos=formals(f),corpo=deparse(body(f),width.cutoff=500L))
  }),nomes))
}

# P02-FUN-013 | Tentativa por etapa; estado inacabado denuncia processo abrupto.
registrar_tentativa <- function(config,raiz,etapa) {
  id <- basename(tempfile(paste0(etapa,'-',Sys.getpid(),'-')))
  registro <- list(id=id,etapa=etapa,pid=Sys.getpid(),inicio=format(Sys.time(),'%FT%T%z'),
    fim=NULL,estado='em_processamento',config=config,assinatura_plano=NULL,motivo=NULL)
  caminhos <- c(validar_destino(raiz,paste0(config$saidas,'/tentativas/',id,'.rds')),
    validar_destino(raiz,paste0(config$saidas,'/execucao.rds')))
  persistir <- function() for(caminho in caminhos) gravar_validado_atomico(registro,caminho)
  persistir()
  function(estado,motivo=NULL,assinatura=NULL,plano=NULL) {
    registro$estado <<- estado; registro$motivo <<- motivo
    registro$assinatura <<- assinatura; registro$assinatura_plano <<- plano
    registro$fim <<- format(Sys.time(),'%FT%T%z'); persistir()
  }
}

# P02-FUN-010 | P02-RF-007: versões observadas, sem caminhos pessoais.
registrar_ambiente <- function() {
  pacotes <- c('data.table','httr2','digest','testthat','dotenv','renv','jsonlite')
  list(r = as.character(getRversion()), plataforma = R.version$platform,
    pacotes = as.list(setNames(vapply(pacotes, function(p) if (requireNamespace(p, quietly=TRUE))
      as.character(utils::packageVersion(p)) else NA_character_, character(1)), pacotes)))
}

# P02-FUN-003 | Política pura: checkpoints nunca forçam download sozinhos.
resolver_politica_execucao <- function(usar_checkpoints = TRUE,
    atualizar_downloads = FALSE, forcar_reprocessamento = FALSE) {
  valores <- list(usar_checkpoints, atualizar_downloads, forcar_reprocessamento)
  if (any(!vapply(valores, function(v) is.logical(v) && length(v) == 1L && !is.na(v), logical(1))))
    stop('Políticas devem ser booleanas.')
  list(baixar = atualizar_downloads || forcar_reprocessamento,
    reutilizar_checkpoint = usar_checkpoints && !forcar_reprocessamento)
}

# P02-FUN-004 | IDs, referências e cobertura; não promove estado automaticamente.
validar_rastreabilidade <- function(catalogo, matriz) {
  problemas <- character()
  if (anyDuplicated(catalogo$id)) problemas <- c(problemas, 'ID duplicado')
  refs <- unique(c(matriz$requisito_id, matriz$modulo_id, matriz$teste_id,
    unlist(strsplit(matriz$funcoes_ids, '[; ,]+'))))
  refs <- refs[!is.na(refs) & nzchar(refs)]
  if (any(!refs %in% catalogo$id)) problemas <- c(problemas, 'Referência ausente')
  funcoes <- catalogo$id[catalogo$categoria == 'FUN' & !catalogo$estado %in% c('historico', 'cancelado')]
  if (any(!funcoes %in% unlist(strsplit(matriz$funcoes_ids, '[; ,]+'))))
    problemas <- c(problemas, 'Função sem vínculo de requisito/teste')
  requisitos <- catalogo$id[catalogo$categoria %in% c('RF','RNF') &
    !catalogo$estado %in% c('historico','cancelado')]
  if (any(!requisitos %in% matriz$requisito_id)) problemas <- c(problemas, 'Requisito sem teste')
  if ('comentario' %in% names(catalogo) && any(!nzchar(catalogo$comentario[catalogo$id %in% funcoes])))
    problemas <- c(problemas, 'Função sem comentário')
  list(valido = !length(problemas), problemas = problemas)
}

# P02-FUN-005 | Módulos em ambiente isolado; restaura .libPaths no chamador.
carregar_pipeline <- function(raiz = '.') {
  ambiente <- new.env(parent = globalenv())
  for (arquivo in c('p02_utilitarios.R', 'p04_configuracao_fidc.R',
    'p05_download_fidc.R', 'p06_consolidacao_fidc.R', 'p07_aceite.R', 'p07_evidencias.R'))
    sys.source(file.path(raiz, 'scripts', arquivo), envir = ambiente)
  ambiente
}
