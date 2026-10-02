# Módulo: P01-MOD-001 | Prompt responsável: P01.
# Dependências: contratos P02; funções P03 carregadas em ambiente isolado.
# Função: P01-FUN-001 — executar_etapa | P01-RF-001/002/003, P01-RNF-001.
# Entradas: etapa e configuração; saída: resumo e pendências observadas.
# Efeitos: P03 diagnostica e cria somente arquivos explicitamente planejados;
# registro opcional acrescenta continuidade e matriz operacional em logs/p01/.
# Não instala ferramentas, executa testes, chama Git ou avança para outra etapa.
# Testes: P01-TST-001/002. source() apenas define a função.
executar_etapa <- function(etapa = 'P03', configuracao = list()) {
  if (length(etapa) != 1L || is.na(etapa) || !etapa %in% paste0('P0', 3:7))
    stop('Informe uma única etapa entre P03 e P07.')
  if (!is.list(configuracao)) stop('Configuração deve ser uma lista.')
  raiz <- if (is.null(configuracao$raiz)) '.' else configuracao$raiz
  if (!dir.exists(raiz)) stop('Raiz do projeto inexistente.')
  raiz <- normalizePath(raiz, winslash = '/', mustWork = TRUE)
  registrar <- if (is.null(configuracao$registrar)) TRUE else configuracao$registrar
  if (!is.logical(registrar) || length(registrar) != 1L || is.na(registrar))
    stop('registrar deve ser TRUE ou FALSE.')
  for (nome in c('commit', 'decisoes')) {
    valor <- configuracao[[nome]]
    if (!is.null(valor) && (!is.character(valor) || length(valor) != 1L || is.na(valor)))
      stop(nome, ' deve ser um texto único, quando informado.')
  }
  arquivos <- c('C4-Mini-projeto.Rproj', 'prompts/01_prompt_main.txt',
    'prompts/02_prompt_lib.txt', 'prompts/03_prompt_ambiente_situacao.txt',
    'scripts/p03_verificar_ambiente.R', 'scripts/p03_preparar_projeto.R')
  ausentes <- arquivos[!file.exists(file.path(raiz, arquivos))]
  resultado <- list(etapa = etapa, estado = 'pendente', executada = FALSE,
    pendencias = character(), diagnostico = NULL, arquivos = NULL,
    testes = 'nao_executados_por_este_coordenador',
    decisoes = if (is.null(configuracao$decisoes)) 'Nenhuma decisão adicional informada.' else configuracao$decisoes,
    commit = if (is.null(configuracao$commit)) NA_character_ else configuracao$commit,
    sincronizacao_remota = 'nao_verificada', proxima_etapa = NA_character_,
    proximo_movimento = 'Resolver as pendências da etapa solicitada.',
    registro = NULL, matriz_execucoes = NULL)

  # P01-RF-001: execução explícita, sem avanço automático ou efeitos ao carregar.
  if (etapa != 'P03') {
    entrada <- file.path(raiz,'scripts/p01_pipeline_fidc.R')
    if (!file.exists(entrada)) {
      resultado$estado <- 'nao_implementada'
      resultado$pendencias <- paste(etapa,'não implementada; nenhum módulo executado.')
    } else {
      ambiente <- new.env(parent=globalenv())
      sys.source(entrada,envir=ambiente)
      resposta <- tryCatch(ambiente$executar_pipeline_etapa(etapa,
        if (is.null(configuracao$pipeline)) list() else configuracao$pipeline,raiz),
        error=function(e) list(estado='pendente',erro=conditionMessage(e)))
      resultado$diagnostico <- resposta
      resultado$estado <- if (!is.null(resposta$erro)) 'pendente' else 'executada'
      resultado$executada <- is.null(resposta$erro)
      resultado$pendencias <- if (!is.null(resposta$erro)) resposta$erro else
        if (etapa=='P07') resposta$pendencias else if (isTRUE(resposta$incompleto)) resposta$faltas else character()
    }
    resultado$proximo_movimento <- 'Revisar o resultado da etapa solicitada; próxima etapa exige instrução explícita.'
  } else if (length(ausentes)) {
    resultado$pendencias <- paste('Dependência ausente:', ausentes)
    resultado$proximo_movimento <- 'Gerar/verificar os artefatos ausentes a partir dos prompts antes de executar P03.'
  } else {
    ambiente <- new.env(parent = globalenv())
    sys.source(file.path(raiz, 'scripts/p03_verificar_ambiente.R'), envir = ambiente)
    sys.source(file.path(raiz, 'scripts/p03_preparar_projeto.R'), envir = ambiente)
    bibliotecas <- .libPaths()
    on.exit(.libPaths(bibliotecas), add = TRUE)
    biblioteca_local <- file.path(raiz, '.R-library')
    if (dir.exists(biblioteca_local)) .libPaths(c(biblioteca_local, bibliotecas))
    pacotes <- configuracao$pacotes
    if (is.null(pacotes)) pacotes <- c('testthat', 'curl', 'httr2', 'digest', 'readr', 'dotenv')
    resultado$diagnostico <- ambiente$verificar_ambiente(raiz, pacotes,
      observacoes = configuracao$observacoes)
    resultado$pendencias <- resultado$diagnostico$pendencias
    resultado$executada <- TRUE
    plano <- configuracao$plano
    if (is.null(plano)) plano <- list()
    # Não criar arquivos de preparação quando o diagnóstico ainda é pendente.
    if (!length(resultado$pendencias)) {
      resultado$arquivos <- ambiente$preparar_projeto(raiz, plano)
      resultado$estado <- 'verificada'
      resultado$proxima_etapa <- 'P04'
      resultado$proximo_movimento <- paste('Diagnóstico e plano P03 verificados; revisar testes e demais',
        'pendências de P03. P04 é somente prevista e não será executada.')
    }
  }

  if (registrar) {
    # P01-RF-002/P01-RNF-001: acrescentar evidência, sem reescrever documentos
    # nem promover requisitos/testes normativos pelo sucesso de um diagnóstico.
    registro <- file.path(raiz, 'prompts/registro_projeto.txt')
    pasta_logs <- file.path(raiz, 'logs/p01')
    # Reutilizar a contenção de caminhos de P03 antes de escrever em retomadas.
    verificar_destino <- function(destino) {
      ancestral <- if (file.exists(destino)) destino else dirname(destino)
      while (!file.exists(ancestral)) ancestral <- dirname(ancestral)
      ancestral <- normalizePath(ancestral, winslash = '/', mustWork = TRUE)
      if (!identical(tolower(ancestral), tolower(raiz)) &&
          !startsWith(tolower(ancestral), paste0(tolower(raiz), '/')))
        stop('Destino de continuidade fora da raiz.')
    }
    matriz <- file.path(pasta_logs, 'matriz_execucoes.csv')
    verificar_destino(registro)
    verificar_destino(matriz)
    linha <- data.frame(data_hora = format(Sys.time(), '%Y-%m-%dT%H:%M:%S%z'),
      requisito_id = 'P01-RF-001 P01-RF-002', modulo_id = 'P01-MOD-001',
      funcao_id = 'P01-FUN-001', etapa = etapa, estado = resultado$estado,
      executada = resultado$executada, pendencias = paste(resultado$pendencias, collapse = '; '),
      testes = resultado$testes, commit = resultado$commit,
      decisoes = resultado$decisoes,
      arquivos_criados = paste(resultado$arquivos$criados, collapse = '; '),
      arquivos_preservados = paste(resultado$arquivos$preservados, collapse = '; '),
      sincronizacao_remota = resultado$sincronizacao_remota,
      proximo_movimento = resultado$proximo_movimento)
    existe <- file.exists(matriz)
    if (existe) {
      anterior <- read.csv(matriz, stringsAsFactors = FALSE, fileEncoding = 'UTF-8')
      if (!identical(names(anterior), names(linha))) stop('Matriz operacional incompatível; preservada.')
    }
    dir.create(dirname(registro), recursive = TRUE, showWarnings = FALSE)
    dir.create(pasta_logs, recursive = TRUE, showWarnings = FALSE)
    write.table(linha, matriz, sep = ',', row.names = FALSE, col.names = !existe,
      append = existe, fileEncoding = 'UTF-8', na = '')
    texto <- c('', 'P01 — EXECUÇÃO LOCAL (não equivale a aceite completo)',
      paste('Etapa:', etapa, '| Estado:', resultado$estado),
      paste('Pendências:', paste(resultado$pendencias, collapse = '; ')),
      paste('Testes:', resultado$testes, '| Sincronização remota: nao_verificada'),
      paste('Commit informado:', resultado$commit),
      paste('Decisões informadas:', resultado$decisoes),
      paste('Arquivos criados:', paste(resultado$arquivos$criados, collapse = '; ')),
      paste('Arquivos preservados:', paste(resultado$arquivos$preservados, collapse = '; ')),
      paste('Próximo movimento:', resultado$proximo_movimento),
      'Matriz operacional: logs/p01/matriz_execucoes.csv; catálogo normativo preservado.')
    texto <- sub('[ \t]+$', '', texto)
    conexao <- file(registro, open = 'ab')
    tryCatch(writeBin(charToRaw(paste0(paste(enc2utf8(texto), collapse = '\n'), '\n')),
      conexao), finally = close(conexao))
    resultado$registro <- registro
    resultado$matriz_execucoes <- matriz
  }
  resultado
}

if (sys.nframe() == 0L) {
  argumentos <- commandArgs(trailingOnly = TRUE)
  if (length(argumentos) > 1L) stop('Uso: Rscript --vanilla scripts/p01_executar.R [P03]')
  resumo <- executar_etapa(if (length(argumentos)) argumentos[1] else 'P03')
  cat('Etapa:', resumo$etapa, '| Estado:', resumo$estado, '\n')
  if (length(resumo$pendencias)) cat(paste(resumo$pendencias, collapse = '\n'), '\n')
  cat('Próximo movimento:', resumo$proximo_movimento, '\n')
  quit(status = if (resumo$estado %in% c('verificada','executada') && !length(resumo$pendencias)) 0L else 1L)
}
