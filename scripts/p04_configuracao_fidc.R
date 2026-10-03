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

# P04-FUN-004 | Plano canônico, cobertura e ausência de sobreposição por competência.
assinar_plano_fidc <- function(plano, config) {
  campos <- c('unidade','arquivo','url')
  if (!is.data.frame(plano) || !nrow(plano) || !all(campos %in% names(plano)))
    stop('Plano inválido: execute P04 e P05 para o plano atual.')
  p <- as.data.frame(lapply(plano[campos], as.character), stringsAsFactors=FALSE)
  if (anyNA(p) || any(!nzchar(as.matrix(p))) || anyDuplicated(p$unidade) ||
      any(!grepl('^[0-9]{4}([0-9]{2})?$',p$unidade))) stop('Plano duplicado ou inválido: execute P04/P05.')
  meses <- format(seq(as.Date(paste0(substr(config$inicio,1,7),'-01')),
    as.Date(paste0(substr(config$fim,1,7),'-01')),by='month'),'%Y%m')
  coberturas <- lapply(p$unidade,function(u) if(nchar(u)==4L) paste0(u,sprintf('%02d',1:12)) else u)
  recebidos <- unlist(coberturas,use.names=FALSE)
  if (anyDuplicated(recebidos) || any(!meses %in% recebidos) ||
      any(!vapply(coberturas,function(x)any(x %in% meses),logical(1))) ||
      any(!substr(recebidos,5,6) %in% sprintf('%02d',1:12)))
    stop('Plano incompleto ou com sobreposição: execute P04 e P05 para o plano atual.')
  p <- p[order(p$unidade,p$arquivo,p$url),,drop=FALSE]; rownames(p) <- NULL
  list(plano=p, assinatura=calcular_hash_assinatura(list(plano=p,
    inicio=config$inicio,fim=config$fim,tabelas=sort(config$tabelas))))
}

# P04-FUN-005 | Também usado pelas chamadas diretas P06, medições e evidências.
validar_downloads_plano <- function(downloads, config, raiz='.', plano=NULL) {
  if (is.null(plano)) {
    preparado <- ler_rds_recuperavel(file.path(raiz,config$dados,'configuracao.rds'))
    if (is.null(preparado) || !identical(config[c('inicio','fim','tabelas')],
        preparado$config[c('inicio','fim','tabelas')]))
      stop('Plano ausente ou desatualizado: execute P04 e P05 para o plano atual.')
    plano <- preparado$plano
  }
  vinculo <- assinar_plano_fidc(plano,config)
  falhar <- function() stop('Downloads ausentes, extras, duplicados ou incompatíveis: execute P05 para o plano atual; ZIPs íntegros podem ser reutilizados.')
  if (!is.list(downloads) || !length(downloads)) falhar()
  ids <- vapply(downloads,function(x) if(is.character(x$unidade)&&length(x$unidade)==1L) x$unidade else '',character(1))
  if (anyDuplicated(ids) || !setequal(ids,vinculo$plano$unidade)) falhar()
  for (r in downloads) {
    p <- vinculo$plano[match(r$unidade,vinculo$plano$unidade),]
    if (!identical(basename(r$arquivo),p$arquivo) || !identical(r$url,p$url) ||
        (!is.null(r$assinatura_plano) && !identical(r$assinatura_plano,vinculo$assinatura))) falhar()
    # Migração conservadora: identidade exata e ZIP íntegro, nunca só nome da lista.
    if (is.null(r$assinatura_plano) && (!identical(r$estado,'concluido') ||
        !file.exists(r$arquivo) || !identical(calcular_hash_assinatura(r$arquivo,TRUE),r$hash) ||
        inherits(try(validar_zip_fidc(r$arquivo,config$max_bytes_zip),silent=TRUE),'try-error'))) falhar()
  }
  vinculo$unidades <- sort(unname(ids))
  vinculo
}
