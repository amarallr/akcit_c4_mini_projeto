# Módulo: P03-MOD-001 | P03 — Ambiente | P03-RF-001, P03-RNF-002.
# Carregar este arquivo apenas define funções; o wrapper executa o diagnóstico.

# Função: P03-FUN-001 — verificar_ambiente | P03 | P03-RF-001, P03-RNF-002.
# Finalidade: distinguir recursos observados de pendências, sem credenciais.
# Entradas: raiz, pacotes escolhidos e observações opcionais para testes.
# Saída: diagnóstico; efeitos: leitura e carga de namespaces, sem instalações.
# Testes: P03-TST-001. Não altera .libPaths, locale ou diretório de trabalho.
verificar_ambiente <- function(raiz = '.', pacotes = c('testthat', 'curl',
    'httr2', 'digest', 'readr', 'dotenv'), observacoes = NULL) {
  if (!dir.exists(raiz)) stop('Raiz do projeto inexistente.')
  # P03-FUN-001 | P03-RF-001: instalação e carregamento são evidências distintas.
  if (is.null(observacoes)) {
    instalados <- rownames(installed.packages())
    carregados <- setNames(logical(length(pacotes)), pacotes)
    for (pacote in pacotes) carregados[pacote] <- requireNamespace(pacote, quietly = TRUE)
    observacoes <- list(r = R.version.string, locale = Sys.getlocale(),
      utf8 = isTRUE(l10n_info()[['UTF-8']]), instalados = instalados,
      carregados = carregados, executaveis = Sys.which(c('Rscript', 'git')),
      rstudio_console = NA)
  }
  estado_pacotes <- data.frame(pacote = pacotes,
    instalado = pacotes %in% observacoes$instalados,
    carregado = as.logical(observacoes$carregados[pacotes]))
  estado_pacotes$carregado[is.na(estado_pacotes$carregado)] <- FALSE
  pendencias <- character()
  if (!isTRUE(observacoes$utf8)) pendencias <- c(pendencias, 'Locale UTF-8 não confirmado.')
  if (!isTRUE(observacoes$rstudio_console))
    pendencias <- c(pendencias, 'Console RStudio requer evidência manual.')
  for (i in seq_len(nrow(estado_pacotes))) {
    if (!estado_pacotes$instalado[i])
      pendencias <- c(pendencias, paste('Pacote ausente:', pacotes[i]))
    else if (!estado_pacotes$carregado[i])
      pendencias <- c(pendencias, paste('Falha no carregamento:', pacotes[i]))
  }
  for (nome in c('Rscript', 'git')) {
    if (!nzchar(observacoes$executaveis[nome]))
      pendencias <- c(pendencias, paste('Executável ausente:', nome))
  }
  list(r = observacoes$r, locale = observacoes$locale,
    utf8 = isTRUE(observacoes$utf8), pacotes = estado_pacotes,
    pendencias = pendencias)
}

# Função: P03-FUN-003 — verificar_repositorio | P03 | P03-RF-003.
# Entradas: remoto, observações e repositorio_esperado = 'conta/projeto'.
# Saída: diagnóstico; ausência da referência esperada é pendência, não suposição.
# Efeitos: nenhum; não faz login, criação de repositório nem altera visibilidade.
# Testes: P03-TST-003. Observações remotas devem vir de consulta separada.
verificar_repositorio <- function(remoto, autenticado = NA,
    repositorio = NA_character_, visibilidade = NA_character_,
    repositorio_esperado = NA_character_) {
  for (nome in c('remoto', 'repositorio', 'visibilidade', 'repositorio_esperado')) {
    valor <- get(nome)
    if (!is.character(valor) || length(valor) != 1L)
      stop(nome, ' deve ser um texto único ou NA_character_.')
  }
  if (!is.logical(autenticado) || length(autenticado) != 1L)
    stop('autenticado deve ser TRUE, FALSE ou NA.')
  informado <- !is.na(repositorio_esperado) && nzchar(repositorio_esperado)
  if (informado && (!grepl('^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$',
      repositorio_esperado) || basename(repositorio_esperado) %in% c('.', '..')))
    stop('repositorio_esperado deve usar o formato conta/projeto, sem URL.')
  # P03-FUN-003 | P03-RF-003: admitir HTTPS/SSH do mesmo repositório.
  esperado <- if (informado) c(
    paste0('https://github.com/', repositorio_esperado, '.git'),
    paste0('https://github.com/', repositorio_esperado),
    paste0('git@github.com:', repositorio_esperado, '.git'),
    paste0('ssh://git@github.com/', repositorio_esperado, '.git')) else character()
  pendencias <- character()
  if (!informado) pendencias <- c(pendencias, 'Repositório esperado não informado.')
  else if (is.na(remoto) || !tolower(remoto) %in% tolower(esperado))
    pendencias <- c(pendencias, 'Remoto divergente.')
  if (!isTRUE(autenticado)) pendencias <- c(pendencias, 'Autenticação não confirmada.')
  if (is.na(repositorio) || !informado ||
      !identical(tolower(repositorio), tolower(repositorio_esperado)))
    pendencias <- c(pendencias, 'Repositório remoto não confirmado.')
  if (is.na(visibilidade) || !visibilidade %in% c('public', 'private', 'internal'))
    pendencias <- c(pendencias, 'Visibilidade atual não confirmada.')
  list(pendencias = pendencias, repositorio_esperado = repositorio_esperado,
    reutilizar_sessao = isTRUE(autenticado),
    visibilidade = visibilidade, alterar_visibilidade = FALSE)
}
