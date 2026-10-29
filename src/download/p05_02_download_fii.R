# Lastro CO-STAR: prompts/05_02_download_fii.txt
# P05_02: aquisição independente de FII; source() não acessa rede nem cria arquivos.

carregar_download_fii <- function(raiz = '.') {
  ambiente <- new.env(parent = globalenv())
  for (arquivo in c('src/utils/p02_utilitarios.R', 'src/download/p05_01_download_fidc.R',
                    'src/download/p05_02_download_fii.R'))
    sys.source(file.path(raiz, arquivo), envir = ambiente)
  ambiente
}

# P05_02-RF-001/010: destinos fixos impedem mistura com FIDC ou áreas restritas.
validar_configuracao_fii <- function(config, raiz = '.') {
  padrao <- list(inicio = NULL, fim = NULL, atualizar_downloads = FALSE,
    tentativas = 3L, timeout = 90, max_bytes_zip = 128 * 1024^2)
  if (!is.list(config) || is.null(names(config)) || anyDuplicated(names(config)) ||
      any(!nzchar(names(config))) || any(!names(config) %in% names(padrao)))
    stop('Configuração FII inválida ou parâmetro desconhecido.')
  config <- utils::modifyList(padrao, config)
  for (nome in c('inicio', 'fim')) {
    x <- config[[nome]]
    if (!is.character(x) || length(x) != 1L || is.na(x) ||
        !grepl('^[0-9]{4}-[0-9]{2}-[0-9]{2}$', x) ||
        is.na(as.Date(x)) || format(as.Date(x), '%Y-%m-%d') != x)
      stop('Data FII inválida.')
  }
  if (as.Date(config$inicio) > as.Date(config$fim)) stop('Intervalo FII invertido.')
  if (!is.logical(config$atualizar_downloads) || length(config$atualizar_downloads) != 1L ||
      is.na(config$atualizar_downloads)) stop('Política de atualização FII inválida.')
  for (nome in c('tentativas', 'timeout', 'max_bytes_zip')) {
    x <- config[[nome]]
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0)
      stop('Limite FII inválido.')
  }
  if (config$tentativas != as.integer(config$tentativas)) stop('Tentativas deve ser inteiro.')
  config$dataset <- 'FII'
  config$dados <- 'data/data_fii/data_fii_raw'
  config$usar_checkpoints <- TRUE
  config$forcar_reprocessamento <- FALSE
  for (pasta in c(config$dados, 'config', 'logs/fii')) {
    destino <- validar_destino(raiz, pasta)
    ancestral <- destino
    while (!file.exists(ancestral)) ancestral <- dirname(ancestral)
    real <- normalizePath(ancestral, winslash = '/', mustWork = TRUE)
    if (grepl('/(restricted|tax_secrecy)(/|$)', real, ignore.case = TRUE))
      stop('Área restrita não pode ser usada pelo P05_02.')
  }
  config
}

# P05_02-RF-001/002: descoberta de nomes; URLs sempre reconstruídas no domínio oficial.
inventariar_recursos_fii <- function(pagina) {
  if (!is.character(pagina) || !length(pagina) || anyNA(pagina)) stop('Índice FII inválido.')
  texto <- paste(pagina, collapse = '\n')
  arquivos <- sort(unique(regmatches(texto,
    gregexpr('inf_mensal_fii_[0-9]{4}[.]zip', texto))[[1]]))
  if (!length(arquivos)) stop('Índice FII sem recursos anuais.')
  data.frame(unidade = sub('^inf_mensal_fii_([0-9]{4})[.]zip$', '\\1', arquivos),
    arquivo = arquivos,
    url = paste0('https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/DADOS/', arquivos),
    stringsAsFactors = FALSE)
}

selecionar_unidades_fii <- function(config, inventario) {
  anos <- as.character(seq(as.integer(substr(config$inicio, 1, 4)),
                          as.integer(substr(config$fim, 1, 4))))
  esperados <- paste0('inf_mensal_fii_', inventario$unidade, '.zip')
  if (!nrow(inventario) || anyDuplicated(inventario$unidade) ||
      any(!grepl('^[0-9]{4}$', inventario$unidade)) ||
      !identical(as.character(inventario$arquivo), esperados) ||
      any(inventario$url != paste0('https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/DADOS/', esperados)))
    stop('Inventário FII inconsistente.')
  cobertura <- data.frame(ano = anos, disponivel = anos %in% inventario$unidade)
  plano <- inventario[match(anos[anos %in% inventario$unidade], inventario$unidade), , drop = FALSE]
  rownames(plano) <- NULL
  list(plano = plano, cobertura = cobertura, faltantes = anos[!cobertura$disponivel])
}

# P05_02-RF-004/006: reutiliza somente primitivas de aquisição do P05_01, sem ETL FIDC.
baixar_recurso_fii <- function(unidade, config, raiz, transporte = transportar_http,
                               esperar = Sys.sleep) {
  if (length(unidade$unidade) != 1L || !grepl('^([0-9]{4}|dicionario)$', unidade$unidade))
    stop('Unidade FII inválida.')
  nome <- if (unidade$unidade == 'dicionario') 'meta_inf_mensal_fii.zip' else
    paste0('inf_mensal_fii_', unidade$unidade, '.zip')
  url <- paste0('https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/',
    if (unidade$unidade == 'dicionario') 'META/' else 'DADOS/', nome)
  if (!identical(as.character(unidade$arquivo), nome) ||
      !identical(as.character(unidade$url), url)) stop('Origem FII fora do catálogo oficial.')
  limitado <- function(url, destino, timeout) {
    status <- transporte(url, destino, timeout)
    if (status == 200L && (is.na(file.info(destino)$size) ||
        file.info(destino)$size > config$max_bytes_zip)) stop('ZIP FII excede limite de bytes.')
    status
  }
  registro <- baixar_unidade_fidc(unidade, config, raiz, limitado, esperar)
  if (!identical(registro$estado, 'concluido')) stop('Aquisição FII falhou: ', registro$motivo)
  if (file.info(registro$arquivo)$size > config$max_bytes_zip) stop('ZIP FII excede limite de bytes.')
  registro$membros <- extrair_zip_fidc(registro, config, raiz)
  # Cada hash mantém também seu ZIP: versões anteriores continuam reconstruíveis.
  versao <- file.path(raiz, config$dados, 'versoes', registro$unidade, registro$hash)
  dir.create(versao, recursive = TRUE, showWarnings = FALSE)
  copia <- file.path(versao, nome)
  if (!file.exists(copia) || calcular_hash_assinatura(copia, TRUE) != registro$hash) {
    temporario <- tempfile('.zip-', versao)
    on.exit(unlink(temporario), add = TRUE)
    if (!file.copy(registro$arquivo, temporario) ||
        calcular_hash_assinatura(temporario, TRUE) != registro$hash)
      stop('Falha ao copiar versão FII.')
    if (file.exists(copia) && !file.rename(copia, tempfile('.corrompido-', versao)))
      stop('Versão FII corrompida está bloqueada.')
    if (!file.rename(temporario, copia)) stop('Falha ao preservar versão FII.')
  }
  registro$arquivo_versao <- copia
  registro
}

# P05_02-RF-009/012: checkpoints por recurso e estado explícito da tentativa corrente.
executar_download_fii <- function(config, raiz = '.', pagina = NULL,
    transporte = transportar_http, esperar = Sys.sleep, interromper_apos = Inf) {
  config <- validar_configuracao_fii(config, raiz)
  if (!is.numeric(interromper_apos) || length(interromper_apos) != 1L ||
      is.na(interromper_apos) || interromper_apos < 1 ||
      (is.finite(interromper_apos) && interromper_apos != floor(interromper_apos)))
    stop('Limite de interrupção FII inválido.')
  area <- file.path(raiz, 'logs/fii')
  dir.create(file.path(area, 'execucoes'), recursive = TRUE, showWarnings = FALSE)
  id <- basename(tempfile('p05_02-'))
  tentativa <- list(id = id, dataset = 'FII', estado = 'em_processamento',
    config = config, inicio = format(Sys.time(), '%FT%T%z'), fim = NULL,
    origem_indice = 'https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/DADOS/',
    recursos = list(), motivo = NULL)
  persistir <- function() {
    gravar_validado_atomico(tentativa, file.path(area, 'execucoes', paste0(id, '.rds')))
    gravar_validado_atomico(tentativa, file.path(area, 'execucao.rds'))
  }
  persistir()
  terminou <- FALSE
  on.exit(if (!terminou) {
    tentativa$estado <- 'falhou'; tentativa$fim <- format(Sys.time(), '%FT%T%z')
    try(persistir(), silent = TRUE)
  }, add = TRUE)
  withCallingHandlers({
    if (is.null(pagina)) {
      indice <- tempfile('indice-', area)
      on.exit(unlink(indice), add = TRUE)
      status <- transporte(tentativa$origem_indice, indice, config$timeout)
      if (status != 200L) stop('Índice FII indisponível: HTTP ', status)
      if (file.info(indice)$size > 5 * 1024^2) stop('Índice FII excede limite.')
      pagina <- readLines(indice, warn = FALSE, encoding = 'UTF-8')
    }
    inventario <- inventariar_recursos_fii(pagina)
    selecao <- selecionar_unidades_fii(config, inventario)
    tentativa$cobertura <- selecao$cobertura
    tentativa$hash_indice <- calcular_hash_assinatura(pagina)
    gravar_validado_atomico(list(config = config, inventario = inventario,
      selecao = selecao, origem = tentativa$origem_indice, hash_indice = tentativa$hash_indice),
      file.path(raiz, 'config/fii_configuracao.rds'))
    persistir()
    if (length(selecao$faltantes)) stop('Anos FII indisponíveis: ', paste(selecao$faltantes, collapse = ', '))
    dicionario <- data.frame(unidade = 'dicionario', arquivo = 'meta_inf_mensal_fii.zip',
      url = 'https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/META/meta_inf_mensal_fii.zip')
    meta <- baixar_recurso_fii(dicionario, config, raiz, transporte, esperar)
    tentativa$dicionario <- meta
    gravar_validado_atomico(meta, file.path(raiz, config$dados, 'dicionario.rds'))
    caminho <- file.path(raiz, config$dados, 'downloads.rds')
    registros <- ler_rds_recuperavel(caminho)
    if (is.null(registros)) registros <- list()
    for (i in seq_len(nrow(selecao$plano))) {
      unidade <- selecao$plano[i, , drop = FALSE]
      message('P05_02 FII: ', unidade$unidade)
      reg <- baixar_recurso_fii(unidade, config, raiz, transporte, esperar)
      registros[[unidade$unidade]] <- reg
      registros <- registros[order(names(registros))]
      gravar_validado_atomico(registros, caminho)
      tentativa$recursos[[unidade$unidade]] <- reg
      persistir()
      if (i >= interromper_apos) stop('Interrupção FII solicitada após recurso validado.')
    }
    membros <- do.call(rbind, lapply(tentativa$recursos, function(r)
      data.frame(ano = r$unidade, membro = r$membros$Name,
        bytes = r$membros$Length, hash = r$membros$hash, stringsAsFactors = FALSE)))
    tentativa$inventario_membros <- membros
    tentativa$estado <- 'concluido'
    tentativa$fim <- format(Sys.time(), '%FT%T%z')
    gravar_validado_atomico(membros, file.path(area, 'inventario_membros.csv'), 'csv')
    persistir(); terminou <- TRUE
    tentativa
  }, error = function(e) { tentativa$motivo <<- conditionMessage(e) })
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L || length(args) > 4L ||
      any(!grepl('^(--atualizar|--limite=[1-9][0-9]*)$', args[-c(1, 2)])))
    stop('Uso: p05_02_download_fii.R AAAA-MM-DD AAAA-MM-DD [--atualizar] [--limite=N]')
  if (dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'), .libPaths()))
  p <- carregar_download_fii('.')
  limite <- grep('^--limite=', args, value = TRUE)
  r <- p$executar_download_fii(list(inicio = args[1], fim = args[2],
    atualizar_downloads = '--atualizar' %in% args),
    interromper_apos = if (length(limite)) as.integer(sub('--limite=', '', limite)) else Inf)
  cat('P05_02:', r$estado, '| anos:', length(r$recursos),
      '| membros:', nrow(r$inventario_membros), '\n')
}
