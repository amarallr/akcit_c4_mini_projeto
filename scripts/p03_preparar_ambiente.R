# Módulo: P03-MOD-001 | P03 | P03-RF-002, P03-RNF-001.
# Entrada executável de instalação explícita; não é módulo de funções.
# Preservar instalações funcionais; só usar quando houver pacotes ausentes.
dir.create('.R-library', showWarnings = FALSE)
.libPaths(c(normalizePath('.R-library'), .libPaths()))
pacotes <- c('testthat', 'curl', 'httr2', 'digest', 'readr', 'dotenv')
ausentes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(ausentes)) {
  install.packages(ausentes, lib = '.R-library',
                   repos = 'https://cloud.r-project.org', type = 'binary')
}
restantes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(restantes)) stop('Pacotes indisponíveis: ', paste(restantes, collapse = ', '))
message('Dependências disponíveis: ', paste(pacotes, collapse = ', '))
