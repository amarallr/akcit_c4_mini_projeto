# P07-MOD-001 | Avaliação de evidências, sem fabricar aprovação.

# P07-FUN-002 | Pendências impedem aceite; sincronização distinta do resultado local.
gerar_relatorio_aceite <- function(resultado, testes_aprovados = FALSE,
    retomada_demonstrada = FALSE, sincronizado = FALSE, pendencias = character()) {
  faltas <- pendencias
  if (!identical(resultado$estado, 'concluido') || isTRUE(resultado$incompleto))
    faltas <- c(faltas, 'Piloto incompleto')
  if (!isTRUE(testes_aprovados)) faltas <- c(faltas, 'Testes não aprovados')
  if (!isTRUE(retomada_demonstrada)) faltas <- c(faltas, 'Retomada em processo novo não demonstrada')
  local <- !length(faltas)
  list(aceite_local = local, aceite_completo = local && isTRUE(sincronizado),
    pendencias = unique(c(faltas, if (!sincronizado) 'Sincronização não confirmada')))
}

# P07-FUN-001 | Verifica artefatos observados e resultado atual, sem chamar Git.
executar_aceite <- function(resultado, config, testes_aprovados = FALSE,
    retomada_demonstrada = FALSE, sincronizado = FALSE, evidencias = NULL, raiz = '.') {
  pendencias <- character()
  execucao <- ler_rds_recuperavel(file.path(raiz,config$saidas,'execucao.rds'))
  if (is.null(execucao) || !identical(execucao$estado,'concluido') ||
      !identical(execucao$assinatura,resultado$assinatura))
    pendencias <- c(pendencias,'Execução atual não concluída')
  if (is.null(resultado$geracao)) pendencias <- 'Geração atual ausente' else {
    esperados <- c(paste0('inf_mensal_fidc_tab_',rep(config$tabelas,each=2),rep(c('.csv','.rds'),length(config$tabelas))),
      if (isTRUE(config$gerar_flat)) c('inf_mensal_fidc_flat.csv','inf_mensal_fidc_flat.rds'),
      'qualidade.csv','qualidade.rds',
      if ('I'%in%config$tabelas) c('inf_mensal_fidc_cedentes.csv','inf_mensal_fidc_cedentes.rds'))
    if (any(!file.exists(file.path(resultado$geracao, esperados)))) pendencias <- 'Saída obrigatória ausente'
    if (!length(resultado$arquivos)) pendencias <- c(pendencias,'Hashes de saída ausentes')
    registrados <- vapply(resultado$arquivos,function(x)basename(x$caminho),character(1))
    if (any(!esperados%in%registrados)) pendencias <- c(pendencias,'Hash obrigatório ausente')
    for (meta in resultado$arquivos) {
      if (!file.exists(meta$caminho) || !identical(meta$hash,calcular_hash_assinatura(meta$caminho,TRUE)))
        pendencias <- c(pendencias,'Saída alterada após validação')
    }
    if (!length(pendencias) && isTRUE(config$gerar_flat)) {
      # Ler somente a chave do CSV reduz memória do aceite de um flat muito largo.
      flat <- data.table::fread(file.path(resultado$geracao,'inf_mensal_fidc_flat.csv'),sep=';',
        select=c('cnpj','dt_comptc'),colClasses='character',showProgress=FALSE)
      if (!nrow(flat) || anyDuplicated(flat)) pendencias <- 'Chave flat inválida'
      chaves <- data.table::rbindlist(lapply(config$tabelas,function(id)
        data.table::fread(file.path(resultado$geracao,paste0('inf_mensal_fidc_tab_',id,'.csv')),
          sep=';',select=c('cnpj','dt_comptc'),colClasses='character',showProgress=FALSE)))
      if (!data.table::fsetequal(flat,unique(chaves))) pendencias <- c(pendencias,'Cobertura de chaves divergente')
    }
  }
  provas_validas <- tryCatch(isTRUE(validar_evidencias_aceite(evidencias,resultado,config,raiz)),
    error=function(e)FALSE)
  if (!provas_validas) pendencias <- c(pendencias,'Evidências automáticas ausentes, inválidas ou de outro código')
  relatorio <- gerar_relatorio_aceite(resultado, provas_validas, provas_validas, sincronizado, pendencias)
  relatorio$modo <- if(isTRUE(config$gerar_flat)) 'completo' else 'temporal'
  relatorio$aceite_piloto_completo <- relatorio$aceite_completo && isTRUE(config$gerar_flat)
  relatorio
}
