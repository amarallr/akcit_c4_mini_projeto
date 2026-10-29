# Lastro CO-STAR: prompts/06_02_consolidacao_fii.txt
# P06_02: temporais FII por tabela oficial; nenhuma agregação ou seleção de reapresentações.

carregar_consolidacao_fii <- function(raiz = '.') {
  ambiente <- new.env(parent = globalenv())
  for (arquivo in c('src/utils/p02_utilitarios.R', 'src/download/p05_01_download_fidc.R',
    'src/download/p05_02_download_fii.R', 'src/consolidation/p06_02_consolidacao_fii.R'))
    sys.source(file.path(raiz, arquivo), envir = ambiente)
  ambiente
}

ler_texto_fii <- function(arquivo) {
  bytes <- readBin(arquivo, 'raw', n = file.info(arquivo)$size)
  texto <- rawToChar(bytes)
  encoding <- if (!is.na(iconv(texto, 'UTF-8', 'UTF-8', sub = NA))) 'UTF-8' else 'Latin-1'
  list(encoding = encoding, texto = if (encoding == 'Latin-1')
    iconv(texto, 'latin1', 'UTF-8') else texto)
}

# P06_02-RF-001/002: leitura textual preserva zeros, escalas e métricas originais.
ler_tabela_fii <- function(arquivo, registro, hash_esperado) {
  if (!file.exists(arquivo) || !identical(calcular_hash_assinatura(arquivo, TRUE), hash_esperado))
    stop('Fonte FII ausente ou divergente do manifesto.')
  texto <- ler_texto_fii(arquivo)
  d <- data.table::fread(arquivo, sep = ';', encoding = texto$encoding,
    colClasses = 'character', na.strings = '', showProgress = FALSE)
  originais <- names(d)
  if (!all(c('Data_Referencia', 'Versao') %in% originais) ||
      !any(c('CNPJ_Fundo', 'CNPJ_Fundo_Classe') %in% originais)) stop('Leiaute FII sem identidade/data/versão.')
  normalizar <- function(x) toupper(gsub('[./[:space:]-]', '', x))
  cnpj <- rep(NA_character_, nrow(d)); campo <- rep(NA_character_, nrow(d))
  for (id in intersect(c('CNPJ_Fundo_Classe', 'CNPJ_Fundo'), originais)) {
    valor <- normalizar(d[[id]])
    conflito <- !is.na(cnpj) & !is.na(valor) & nzchar(valor) & cnpj != valor
    if (any(conflito)) stop('Identidades FII divergentes na mesma linha.')
    usar <- is.na(cnpj) & !is.na(valor) & nzchar(valor)
    cnpj[usar] <- valor[usar]; campo[usar] <- id
  }
  dt <- as.Date(d$Data_Referencia, format = '%Y-%m-%d')
  if (anyNA(dt) || any(format(dt, '%Y-%m-%d') != d$Data_Referencia))
    stop('Data de referência FII inválida; não descartar linhas silenciosamente.')
  extras <- data.table::data.table(cnpj = cnpj, data_referencia = dt,
    versao = d$Versao, campo_identidade = campo,
    arquivo_origem = rep(basename(arquivo), nrow(d)),
    zip_origem = rep(basename(registro$arquivo), nrow(d)),
    hash_zip = rep(registro$hash, nrow(d)), linha_origem = seq_len(nrow(d)),
    ano_arquivo = rep(registro$unidade, nrow(d)))
  if (any(names(extras) %in% originais)) stop('Colisão entre campo oficial e campo técnico FII.')
  list(dados = cbind(extras, d), campos = originais, encoding = texto$encoding)
}

# P06_02-RF-003/004: gerações isoladas, hashes de saída e marcador atualizado por último.
consolidar_fii <- function(config, raiz = '.') {
  config <- validar_configuracao_fii(config, raiz)
  for (pasta in c('outputs/fii/temporal', 'data/data_fii/data_fii_interim/revisao_fii'))
    validar_destino(raiz, pasta)
  registros <- ler_rds_recuperavel(file.path(raiz, 'data/data_fii/data_fii_raw/downloads.rds'))
  meta <- ler_rds_recuperavel(file.path(raiz, 'data/data_fii/data_fii_raw/dicionario.rds'))
  if (is.null(registros) || is.null(meta)) stop('Execute o P05_02 antes de consolidar FII.')
  anos <- as.character(seq(as.integer(substr(config$inicio, 1, 4)),
    as.integer(substr(config$fim, 1, 4))))
  if (any(!anos %in% names(registros))) stop('Anos FII não adquiridos; execute P05_02.')
  registros <- registros[anos]
  tabelas <- c('geral', 'ativo_passivo', 'complemento')
  if (!identical(meta$estado, 'concluido') ||
      !file.exists(meta$arquivo_versao) ||
      !identical(calcular_hash_assinatura(meta$arquivo_versao, TRUE), meta$hash))
    stop('Dicionário FII inválido.')
  declarados <- setNames(lapply(tabelas, function(tabela) {
    nome <- paste0('meta_inf_mensal_fii_', tabela, '.txt')
    i <- match(nome, meta$membros$Name)
    if (is.na(i)) stop('Dicionário FII sem tabela: ', tabela)
    arquivo <- meta$membros$caminho[i]
    if (!file.exists(arquivo) || calcular_hash_assinatura(arquivo, TRUE) != meta$membros$hash[i])
      stop('Membro do dicionário FII divergente.')
    linhas <- strsplit(ler_texto_fii(arquivo)$texto, '\n', fixed = TRUE)[[1]]
    campos <- trimws(sub('^Campo:[[:space:]]*', '', grep('^Campo:', linhas, value = TRUE)))
    if (!length(campos) || anyDuplicated(campos)) stop('Dicionário FII sem campos válidos.')
    campos
  }), tabelas)
  partes <- setNames(lapply(tabelas, function(x) list()), tabelas)
  esquemas <- list(); fontes <- list()
  inicio <- as.Date(paste0(substr(config$inicio, 1, 7), '-01'))
  fim <- as.Date(paste0(substr(config$fim, 1, 7), '-01'))
  for (r in registros) {
    if (!identical(r$estado, 'concluido') || r$dataset != 'FII' ||
        !file.exists(r$arquivo_versao) ||
        !identical(calcular_hash_assinatura(r$arquivo_versao, TRUE), r$hash))
      stop('Registro de aquisição FII inválido.')
    for (tabela in tabelas) {
      nome <- paste0('inf_mensal_fii_', tabela, '_', r$unidade, '.csv')
      i <- match(nome, r$membros$Name)
      if (is.na(i)) stop('Fonte FII sem tabela: ', tabela)
      lido <- ler_tabela_fii(r$membros$caminho[i], r, r$membros$hash[i])
      d <- lido$dados
      campos <- sort(unique(c(lido$campos, declarados[[tabela]])))
      esquemas[[length(esquemas) + 1L]] <- data.frame(tabela = tabela, ano = r$unidade,
        campo = campos, declarado = campos %in% declarados[[tabela]],
        observado = campos %in% lido$campos, encoding = lido$encoding)
      selecionar <- d$data_referencia >= inicio & d$data_referencia <= fim
      fontes[[length(fontes) + 1L]] <- data.frame(tabela = tabela, ano = r$unidade,
        linhas_fonte = nrow(d), linhas_periodo = sum(selecionar), hash_zip = r$hash)
      partes[[tabela]][[r$unidade]] <- d[selecionar]
    }
  }
  consolidado <- lapply(partes, function(x) {
    d <- data.table::rbindlist(x, use.names = TRUE, fill = TRUE)
    data.table::setcolorder(d, c('cnpj', 'data_referencia', 'versao', 'campo_identidade',
      'arquivo_origem', 'zip_origem', 'hash_zip', 'linha_origem', 'ano_arquivo',
      sort(setdiff(names(d), c('cnpj', 'data_referencia', 'versao', 'campo_identidade',
        'arquivo_origem', 'zip_origem', 'hash_zip', 'linha_origem', 'ano_arquivo')))))
    data.table::setorderv(d, c('data_referencia', 'cnpj', 'versao', 'ano_arquivo', 'linha_origem'))
    if (anyDuplicated(d[, c('hash_zip', 'arquivo_origem', 'linha_origem'), with = FALSE]))
      stop('Chave técnica FII duplicada.')
    as.data.frame(d)
  })
  qualidade <- do.call(rbind, lapply(names(consolidado), function(tabela) {
    d <- consolidado[[tabela]]
    data.frame(tabela = tabela, linhas = nrow(d), colunas = ncol(d),
      identidades_ausentes = sum(is.na(d$cnpj)),
      repeticoes_chave_negocio = sum(duplicated(d[c('cnpj', 'data_referencia', 'versao')])),
      dt_min = if (nrow(d)) as.character(min(d$data_referencia)) else NA_character_,
      dt_max = if (nrow(d)) as.character(max(d$data_referencia)) else NA_character_)
  }))
  meses <- seq(inicio, fim, by = 'month')
  cobertura <- do.call(rbind, lapply(names(consolidado), function(tabela) {
    d <- consolidado[[tabela]]
    referencias <- format(meses, '%Y-%m')
    contagens <- table(factor(format(d$data_referencia, '%Y-%m'), levels = referencias))
    data.frame(tabela = tabela, mes = referencias,
      linhas = as.integer(contagens), row.names = NULL)
  }))
  codigo <- calcular_hash_assinatura(lapply(c('ler_texto_fii', 'ler_tabela_fii', 'consolidar_fii'),
    function(n) deparse(body(get(n, envir = environment(consolidar_fii))), width.cutoff = 500L)))
  assinatura <- calcular_hash_assinatura(list(versao = 'fii-temporal-v1', codigo = codigo,
    inicio = config$inicio, fim = config$fim, fontes = lapply(registros, function(r) r$hash),
    dicionario = meta$hash))
  base <- file.path(raiz, 'outputs/fii/temporal')
  pasta <- file.path(base, 'geracoes', assinatura)
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  arquivos <- list()
  for (tabela in names(consolidado)) for (formato in c('rds', 'csv')) {
    nome <- paste0('inf_mensal_fii_', tabela, '.', formato)
    arquivos[[nome]] <- gravar_validado_atomico(consolidado[[tabela]], file.path(pasta, nome), formato)
  }
  for (nome in c('qualidade', 'cobertura', 'esquemas', 'fontes')) {
    dados <- switch(nome, qualidade = qualidade, cobertura = cobertura,
      esquemas = do.call(rbind, esquemas), fontes = do.call(rbind, fontes))
    arquivos[[paste0(nome, '.csv')]] <- gravar_validado_atomico(dados,
      file.path(pasta, paste0(nome, '.csv')), 'csv')
  }
  manifesto <- list(estado = 'concluido', dataset = 'FII', assinatura = assinatura,
    config = config, geracao = pasta, arquivos = arquivos, qualidade = qualidade,
    cobertura = cobertura, dicionario_hash = meta$hash,
    politica = 'Preservar todas as linhas e versões, sem agregação ou eliminação de repetições.')
  gravar_validado_atomico(manifesto, file.path(pasta, 'manifesto.rds'))
  gravar_validado_atomico(manifesto, file.path(base, 'atual.rds'))
  manifesto
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L) stop('Uso: p06_02_consolidacao_fii.R AAAA-MM-DD AAAA-MM-DD')
  if (dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'), .libPaths()))
  p <- carregar_consolidacao_fii('.')
  r <- p$consolidar_fii(list(inicio = args[1], fim = args[2]))
  cat('P06_02:', r$estado, '\n'); print(r$qualidade, row.names = FALSE)
}
