# Módulo: P03-MOD-001 | P03 — Preparação | P03-RF-002, P03-RNF-001.
# Função: P03-FUN-002 — preparar_projeto | P03 | P03-RF-002, P03-RNF-001.
# Entradas: raiz e plano nomeado de arquivos/conteúdo UTF-8; saída: mudanças.
# Efeitos: cria somente arquivos ausentes contidos na raiz; nunca instala pacotes.
# Testes: P03-TST-002. Arquivos existentes e ambiente global são preservados.
preparar_projeto <- function(raiz = '.', plano = list()) {
  if (!dir.exists(raiz)) stop('Raiz inexistente; escolha um projeto existente.')
  raiz <- normalizePath(raiz, winslash = '/', mustWork = TRUE)
  nomes <- names(plano)
  if (length(plano) && (is.null(nomes) || any(!nzchar(nomes)) || anyDuplicated(nomes)))
    stop('Plano deve conter caminhos relativos únicos.')
  # P03-FUN-002 | P03-RF-002: validar todo o plano antes de qualquer escrita.
  for (nome in nomes) {
    partes <- strsplit(gsub('\\\\', '/', nome), '/', fixed = TRUE)[[1]]
    if (grepl('^[/\\\\]|:', nome) || any(partes %in% c('..', '.', '')))
      stop('Caminho fora do contrato: ', nome)
    destino <- file.path(raiz, nome)
    ancestral <- dirname(destino)
    while (!dir.exists(ancestral)) ancestral <- dirname(ancestral)
    ancestral <- normalizePath(ancestral, winslash = '/', mustWork = TRUE)
    if (!identical(tolower(ancestral), tolower(raiz)) &&
        !startsWith(tolower(ancestral), paste0(tolower(raiz), '/')))
      stop('Destino fora da raiz.')
  }
  criados <- preservados <- character()
  # P03-FUN-002 | P03-RNF-001: não substituir nem reinstalar trabalho válido.
  for (nome in nomes) {
    destino <- file.path(raiz, nome)
    if (file.exists(destino)) {
      preservados <- c(preservados, nome)
    } else {
      if (!dir.exists(dirname(destino)) &&
          !dir.create(dirname(destino), recursive = TRUE)) stop('Falha ao criar pasta.')
      writeLines(enc2utf8(plano[[nome]]), destino, useBytes = TRUE)
      if (!file.exists(destino)) stop('Arquivo não criado: ', nome)
      criados <- c(criados, nome)
    }
  }
  list(criados = criados, preservados = preservados)
}
