# P04-MOD-001 | Configuração, inventário e seleção; source sem efeitos.
# Requisitos P04-RF-001 a 005, P04-RNF-001. Dependências P02, httr2.

# P04-FUN-001 | Configuração validada, caminhos relativos, piloto confirmado.
validar_configuracao <- function(config = list(), raiz = '.') {
  defaults <- list(dataset = 'FIDC', inicio = '2026-07-01', fim = '2026-08-31',
    tabelas = c('I','II','III','IV','V','VI','VII','VIII','IX','X',
      'X_1','X_1_1','X_2','X_3','X_4','X_5','X_6','X_7'),
    dados = 'dados', saidas = 'saidas', checkpoints = 'checkpoints',
    usar_checkpoints = TRUE, atualizar_downloads = FALSE, forcar_reprocessamento = FALSE,
    tentativas = 3L, timeout = 90, max_bytes_zip = 1024^3,
    max_colunas_flat = 20000L, versao_transformacao = 'fidc-v2',
    gerar_flat = TRUE, exportar_parquet = FALSE,
    completar_zeros = FALSE, escala_percentual = NA_character_, permitir_parcial = FALSE)
  if (!is.list(config) || any(!names(config) %in% names(defaults))) stop('Parâmetro desconhecido.')
  config <- utils::modifyList(defaults, config)
  if (!identical(config$dataset, 'FIDC')) stop('Dataset não suportado.')
  for (nome in c('inicio','fim')) {
    v <- config[[nome]]
    if (length(v) != 1L || is.na(v) || !grepl('^[0-9]{4}-[0-9]{2}-[0-9]{2}$', v) ||
        is.na(as.Date(v)) || format(as.Date(v), '%Y-%m-%d') != v) stop('Data inválida.')
  }
  if (as.Date(config$inicio) > as.Date(config$fim)) stop('Intervalo invertido.')
  if (!length(config$tabelas) || anyDuplicated(config$tabelas) ||
      any(!config$tabelas %in% defaults$tabelas)) stop('Tabela não suportada.')
  for (nome in c('dados','saidas','checkpoints')) validar_destino(raiz, config[[nome]])
  resolver_politica_execucao(config$usar_checkpoints, config$atualizar_downloads,
    config$forcar_reprocessamento)
  for (nome in c('completar_zeros','permitir_parcial','gerar_flat','exportar_parquet'))
    if (!is.logical(config[[nome]]) || length(config[[nome]]) != 1L || is.na(config[[nome]]))
      stop('Parâmetro booleano inválido.')
  for (nome in c('tentativas','timeout','max_bytes_zip','max_colunas_flat'))
    if (!is.numeric(config[[nome]]) || length(config[[nome]]) != 1 ||
        !is.finite(config[[nome]]) || config[[nome]] <= 0) stop('Limite inválido.')
  if (!is.character(config$escala_percentual) || length(config$escala_percentual) != 1 ||
      (!is.na(config$escala_percentual) && !config$escala_percentual %in% c('0-1','0-100')))
    stop('Escala percentual inválida.')
  if (!is.character(config$versao_transformacao) || length(config$versao_transformacao) != 1 ||
      is.na(config$versao_transformacao) || !nzchar(config$versao_transformacao)) stop('Versão inválida.')
  if (config$tentativas != as.integer(config$tentativas)) stop('Tentativas deve ser inteiro.')
  config
}

# P04-FUN-002 | Inventário apenas de nomes efetivamente listados, sem ZIP fictício.
inventariar_recursos_fidc <- function(config, paginas = NULL) {
  urls <- c(DADOS = 'https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/',
    HIST = 'https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/HIST/')
  if (is.null(paginas)) {
    paginas <- list()
    for (nome in names(urls)) paginas[[nome]] <- httr2::resp_body_string(
      httr2::req_perform(httr2::req_timeout(httr2::request(urls[[nome]]), config$timeout)))
  }
  inventario <- list()
  for (nome in names(urls)) {
    if (is.null(paginas[[nome]])) stop('Página oficial ausente.')
    arquivos <- unique(regmatches(paginas[[nome]],
      gregexpr('inf_mensal_fidc_[0-9]{4}([0-9]{2})?\\.zip', paginas[[nome]]))[[1]])
    arquivos <- arquivos[nzchar(arquivos)]
    for (arquivo in arquivos) {
      ref <- sub('.*_([0-9]+)\\.zip$', '\\1', arquivo)
      mensal <- nchar(ref) == 6L
      inicio <- as.Date(paste0(substr(ref, 1, 4), '-', if (mensal) substr(ref, 5, 6) else '01', '-01'))
      if (is.na(inicio)) stop('Referência oficial inválida.')
      fim <- if (mensal) seq(inicio, by = 'month', length.out = 2)[2] - 1 else as.Date(paste0(ref,'-12-31'))
      inventario[[length(inventario)+1L]] <- data.frame(unidade = ref, arquivo = arquivo,
        url = paste0(urls[[nome]], arquivo), inicio = inicio, fim = fim, tipo = if (mensal) 'mensal' else 'anual')
    }
  }
  if (!length(inventario)) stop('Inventário oficial vazio.')
  do.call(rbind, inventario)
}

# P04-FUN-003 | Seleção com cobertura comprovada, sem sobreposição mensal/anual.
selecionar_unidades_fidc <- function(config, inventario) {
  meses <- seq(as.Date(format(as.Date(config$inicio), '%Y-%m-01')),
    as.Date(format(as.Date(config$fim), '%Y-%m-01')), by = 'month')
  escolhidos <- integer()
  for (mes in as.character(meses)) {
    candidatos <- which(inventario$inicio <= as.Date(mes) & inventario$fim >= as.Date(mes))
    if (!length(candidatos)) stop('Competência indisponível: ', mes)
    anuais <- candidatos[inventario$tipo[candidatos] == 'anual']
    escolhido <- if (length(anuais)) anuais[1] else candidatos[1]
    escolhidos <- unique(c(escolhidos, escolhido))
  }
  inventario[escolhidos[order(inventario$inicio[escolhidos])], , drop = FALSE]
}
