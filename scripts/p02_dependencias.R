# P02-MOD-003 | P02-RF-007: renv explícito, biblioteca local, sem alterar .Rprofile.
# P02-FUN-011 | Ações restaurar/fixar/verificar; somente restaurar acessa rede.
gerenciar_dependencias <- function(acao='verificar',raiz='.',biblioteca='.R-library') {
  raiz <- normalizePath(raiz,winslash='/',mustWork=TRUE)
  anterior <- .libPaths(); on.exit(.libPaths(anterior),add=TRUE)
  lib <- file.path(raiz,biblioteca)
  dir.create(lib,recursive=TRUE,showWarnings=FALSE)
  .libPaths(c(normalizePath(lib),.libPaths()))
  if (!acao %in% c('restaurar','fixar','verificar')) stop('Ação de dependências inválida.')
  lock <- file.path(raiz,'renv.lock')
  options_antigas <- options(repos=c(CRAN='https://cloud.r-project.org'),renv.config.cache.enabled=FALSE)
  on.exit(options(options_antigas),add=TRUE)
  if (!requireNamespace('renv',quietly=TRUE)) {
    if (acao!='restaurar') stop('Instale renv na biblioteca local antes de fixar/verificar.')
    install.packages('https://cran.r-project.org/src/contrib/Archive/renv/renv_1.2.3.tar.gz',
      lib=lib,repos=NULL,type='source')
  }
  if (acao=='fixar') renv::snapshot(project=raiz,library=.libPaths(),lockfile=lock,
    packages=c('renv','data.table','httr2','digest','testthat','dotenv','jsonlite','curl','readr'),
    prompt=FALSE)
  if (acao=='restaurar') renv::restore(project=raiz,library=lib,lockfile=lock,prompt=FALSE)
  registrado <- renv::lockfile_read(lock)
  versoes <- vapply(registrado$Packages,function(x)x$Version,character(1))
  instalados <- vapply(names(versoes),function(p) if (requireNamespace(p,quietly=TRUE))
    as.character(utils::packageVersion(p)) else NA_character_,character(1))
  if (anyNA(instalados) || any(package_version(instalados)!=package_version(versoes)))
    stop('Biblioteca diverge de renv.lock, execute restaurar em sessão nova.')
  if (!identical(as.character(getRversion()),registrado$R$Version))
    warning('R difere da versão registrada; valide a compatibilidade nesta máquina.')
  invisible(list(r=as.character(getRversion()),pacotes=versoes))
}
if (sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE)
  gerenciar_dependencias(if(length(args)) args[1] else 'verificar')
  cat('Dependências conferidas com renv.lock.\n')
}
