# P05-MOD-001 | Download, manifestos e extração segregada. P05-RF-001 a 006.
# Dependências P02, httr2/digest. Nenhuma rede em source().

# P05-FUN-005 | Transporte controlável; status HTTP devolvido, sem expor credenciais.
transportar_http <- function(url, destino, timeout = 90) {
  req <- httr2::req_timeout(httr2::request(url), timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  resp <- httr2::req_perform(req, path = destino)
  httr2::resp_status(resp)
}

# P05-FUN-004 | ZIP íntegro e caminhos seguros; extração temporária para verificar CRC.
validar_zip_fidc <- function(arquivo, limite = 1024^3) {
  if (!file.exists(arquivo) || file.info(arquivo)$size <= 0) stop('ZIP vazio/ausente.')
  antigo <- options(warn = 2)
  on.exit(options(antigo), add = TRUE)
  membros <- utils::unzip(arquivo, list = TRUE)
  if (!nrow(membros) || nrow(membros) > 256 || sum(membros$Length) > limite) stop('ZIP fora dos limites.')
  nomes <- membros$Name
  if (any(grepl('(^[/\\\\]|^[A-Za-z]:|(^|[/\\\\])\\.\\.([/\\\\]|$))', nomes)) ||
      anyDuplicated(tolower(nomes)) || any(grepl('[/\\\\]', nomes))) stop('Membro ZIP inseguro.')
  area <- tempfile('validar-zip-')
  dir.create(area)
  on.exit(unlink(area, recursive = TRUE), add = TRUE)
  utils::unzip(arquivo, exdir = area)
  if (any(!file.exists(file.path(area, nomes))) ||
      any(file.info(file.path(area, nomes))$size != membros$Length)) stop('ZIP incompleto.')
  membros$hash <- vapply(file.path(area, nomes), calcular_hash_assinatura, character(1), arquivo = TRUE)
  membros
}

# P05-FUN-001 | Transação por unidade, tentativas só em falhas transitórias.
baixar_unidade_fidc <- function(unidade, config, raiz = '.', transporte = transportar_http,
    esperar = Sys.sleep) {
  pasta <- validar_destino(raiz, paste0(config$dados, '/originais'))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  destino <- file.path(pasta, unidade$arquivo)
  manifesto <- file.path(pasta, paste0(unidade$unidade, '.manifesto.rds'))
  anterior <- ler_rds_recuperavel(manifesto, function(x)
    is.list(x) && is.character(x$estado) && length(x$estado) == 1L)
  backup <- paste0(destino, '.rollback')
  if (file.exists(backup)) {
    publicado <- !is.null(anterior) && identical(anterior$estado, 'concluido') &&
      file.exists(destino) && identical(calcular_hash_assinatura(destino, TRUE), anterior$hash)
    if (publicado) {
      preservado <- tempfile(paste0(basename(backup), '.preservado-'), pasta)
      if (!file.rename(backup, preservado)) stop('Backup ZIP bloqueado.')
    } else recuperar_rollback(destino, function(arq) {
      validar_zip_fidc(arq, config$max_bytes_zip)
      is.null(anterior$hash) || identical(calcular_hash_assinatura(arq, TRUE), anterior$hash)
    })
  }
  politica <- resolver_politica_execucao(config$usar_checkpoints, config$atualizar_downloads,
    config$forcar_reprocessamento)
  valido <- FALSE
  if (!is.null(anterior) && file.exists(destino) && !is.null(anterior$hash)) {
    valido <- identical(calcular_hash_assinatura(destino, TRUE), anterior$hash) &&
      !inherits(try(validar_zip_fidc(destino, config$max_bytes_zip), silent = TRUE), 'try-error')
  }
  if (valido && !politica$baixar && identical(anterior$estado, 'concluido')) {
    message('P05 reutilizado: ', unidade$unidade)
    anterior$reutilizado <- TRUE
    return(anterior)
  }
  registro <- list(unidade = unidade$unidade, dataset = config$dataset,
    referencia = unidade$unidade, arquivo = destino, url = unidade$url,
    estado = 'em_processamento', inicio = format(Sys.time(), '%FT%T%z'),
    tentativas = 0L, http = NA_integer_, hash = if (valido) anterior$hash else NULL,
    anterior_valido = valido, motivo = '', atualizado = FALSE)
  gravar_validado_atomico(registro, manifesto)
  confirmado <- FALSE
  on.exit({
    if (!confirmado) {
      registro$estado <- 'falhou'
      registro$motivo <- 'Interrupção ou falha na publicação, revisar e retomar.'
      try(gravar_validado_atomico(registro, manifesto), silent = TRUE)
    }
  }, add = TRUE)
  temporario <- tempfile('.download-', tmpdir = pasta)
  on.exit(unlink(temporario), add = TRUE)
  for (tentativa in seq_len(config$tentativas)) {
    registro$tentativas <- tentativa
    message('P05 download: ', unidade$unidade, ' tentativa ', tentativa)
    erro <- NULL
    status <- tryCatch(transporte(unidade$url, temporario, config$timeout),
      error = function(e) { erro <<- conditionMessage(e); NA_integer_ })
    registro$http <- status
    if (!is.na(status) && status == 200L) {
      membros <- tryCatch(validar_zip_fidc(temporario, config$max_bytes_zip),
        error = function(e) { erro <<- conditionMessage(e); NULL })
      if (!is.null(membros)) {
        backup <- paste0(destino, '.rollback')
        if (file.exists(backup)) stop('Rollback pendente de download.')
        if (file.exists(destino) && !file.rename(destino, backup)) stop('Original bloqueado.')
        if (!file.rename(temporario, destino)) {
          if (file.exists(backup)) file.rename(backup, destino)
          stop('Falha na publicação do ZIP.')
        }
        registro$hash <- calcular_hash_assinatura(destino, TRUE)
        registro$membros <- membros
        registro$bytes <- file.info(destino)$size
        registro$estado <- 'concluido'
        registro$atualizado <- TRUE
        registro$motivo <- ''
        break
      }
    }
    registro$motivo <- if (!is.null(erro)) erro else paste('HTTP', status)
    registro$estado <- if (!is.na(status) && status %in% c(404,410)) 'indisponivel' else 'falhou'
    gravar_validado_atomico(registro, manifesto)
    if (!is.na(status) && !status %in% c(408,429,500,502,503,504)) break
    if (tentativa < config$tentativas) esperar(min(2^(tentativa-1), 8))
  }
  registro$fim <- format(Sys.time(), '%FT%T%z')
  gravar_validado_atomico(registro, manifesto)
  confirmado <- TRUE
  if (registro$estado == 'concluido' && file.exists(backup)) {
    preservado <- tempfile(paste0(basename(backup), '.preservado-'), pasta)
    if (!file.rename(backup, preservado)) warning('ZIP anterior preservado em rollback.')
  }
  registro
}

# P05-FUN-002 | Seleção atual; falhas não substituem estado por sucesso anterior.
retomar_downloads_fidc <- function(plano, config, raiz = '.', transporte = transportar_http,
    esperar = Sys.sleep) {
  resultados <- vector('list', nrow(plano))
  for (i in seq_len(nrow(plano))) resultados[[i]] <- baixar_unidade_fidc(
    plano[i, , drop = FALSE], config, raiz, transporte, esperar)
  names(resultados) <- plano$unidade
  resultados
}

# P05-FUN-003 | Extração por unidade/hash, não mistura origens homônimas.
extrair_zip_fidc <- function(registro, config, raiz = '.') {
  if (registro$estado != 'concluido') stop('Download não concluído.')
  if (!identical(calcular_hash_assinatura(registro$arquivo, TRUE), registro$hash))
    stop('ZIP alterado após download.')
  membros <- validar_zip_fidc(registro$arquivo, config$max_bytes_zip)
  pasta <- validar_destino(raiz, paste0(config$dados, '/extraidos/', registro$unidade, '/', registro$hash))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  for (i in seq_len(nrow(membros))) {
    destino <- file.path(pasta, membros$Name[i])
    if (!file.exists(destino) || calcular_hash_assinatura(destino, TRUE) != membros$hash[i])
      utils::unzip(registro$arquivo, files = membros$Name[i], exdir = pasta)
    if (calcular_hash_assinatura(destino, TRUE) != membros$hash[i]) stop('Extração divergente.')
  }
  membros$caminho <- file.path(pasta, membros$Name)
  gravar_validado_atomico(list(estado = 'concluido', unidade = registro$unidade,
    hash_zip = registro$hash, membros = membros), file.path(pasta,'manifesto_extracao.rds'))
  membros
}
