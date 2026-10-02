# Módulo: P03-MOD-001 | P03 | P03-RF-001, P03-RNF-002.
# Entrada executável: preserva opções do processo e testa .env fictício.
bibliotecas_anteriores <- .libPaths()
variavel_anterior <- Sys.getenv('C4_ENV_TESTE', unset = NA_character_)
env_teste <- tempfile(fileext = '.env')
tryCatch({
  if (dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'), .libPaths()))
  source('scripts/p03_verificar_ambiente.R', encoding = 'UTF-8')
  diagnostico <- verificar_ambiente()
  cat(diagnostico$r, '\nLocale: ', diagnostico$locale, '\n', sep = '')
  print(diagnostico$pacotes, row.names = FALSE)
  cat('Pendências: ', paste(diagnostico$pendencias, collapse = '; '), '\n', sep = '')
  stopifnot(diagnostico$utf8, all(diagnostico$pacotes$carregado))
  writeLines('C4_ENV_TESTE=valor_simulado', env_teste)
  dotenv::load_dot_env(env_teste)
  stopifnot(identical(Sys.getenv('C4_ENV_TESTE'), 'valor_simulado'))
  cat('Leitura de .env simulado: OK (valores omitidos).\n')
}, finally = {
  .libPaths(bibliotecas_anteriores)
  if (is.na(variavel_anterior)) Sys.unsetenv('C4_ENV_TESTE')
  else Sys.setenv(C4_ENV_TESTE = variavel_anterior)
  unlink(env_teste)
})
