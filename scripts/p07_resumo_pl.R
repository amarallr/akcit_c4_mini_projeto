# P07-MOD-003 | P07-RF-007: estatísticas descritivas; nenhuma alteração dos datasets.
# P07-FUN-005 | Uma observação de PL por CNPJ/data DT_COMPTC; quantis R tipo 7.
resumir_pl_mensal <- function(dados) {
  campos <- c('cnpj','dt_comptc','TAB_IV_A_VL_PL')
  if (!is.data.frame(dados) || !all(campos %in% names(dados))) stop('Tabela IV incompatível.')
  if (anyNA(dados$cnpj) || any(!nzchar(trimws(dados$cnpj))) || anyNA(dados$dt_comptc) ||
      anyDuplicated(dados[c('cnpj','dt_comptc')])) stop('Chave IV inválida ou duplicada; PL não pode ser contado duas vezes.')
  if (!is.numeric(dados$TAB_IV_A_VL_PL) ||
      any(!is.finite(dados$TAB_IV_A_VL_PL[!is.na(dados$TAB_IV_A_VL_PL)]))) stop('PL incompatível.')
  datas <- as.character(as.Date(dados$dt_comptc))
  if (!length(datas)) stop('Tabela IV sem registros.')
  partes <- lapply(sort(unique(datas)),function(data) {
    raw <- dados$TAB_IV_A_VL_PL[datas==data]; pl <- raw[!is.na(raw)]
    q <- if(length(pl)) stats::quantile(pl,probs=c(0,.25,.5,.75,1),type=7,names=FALSE) else rep(NA_real_,5)
    media <- if(length(pl)) mean(pl) else NA_real_
    cv <- if(length(pl)>=2L && !is.na(media) && media!=0) stats::sd(pl)/media*100 else NA_real_
    data.frame(data_competencia=data,competencia=substr(data,1,7),registros_com_pl=length(pl),registros_sem_pl=sum(is.na(raw)),
      pl_total_calculado=if(length(pl)) sum(pl) else NA_real_,
      pl_max_valor_fonte=q[5],pl_percentil_75_valor_fonte=q[4],pl_mediana_valor_fonte=q[3],
      pl_percentil_25_valor_fonte=q[2],pl_min_valor_fonte=q[1],pl_coeficiente_variacao_percentual=cv,
      cv_definicao=if(length(pl)<2L) 'amostra_insuficiente' else if(media==0) 'media_zero' else 'amostral_sd_sobre_media_vezes_100',
      quantis_metodo='R_tipo_7',stringsAsFactors=FALSE)
  })
  do.call(rbind,partes)
}

# P07-FUN-006 | Acrescenta colunas, preservando a soma decimal publicada e datasets.
atualizar_resumo_pl <- function(raiz='.',config=list()) {
  p <- carregar_pipeline(raiz); config <- p$validar_configuracao(config,raiz)
  atual <- readRDS(file.path(raiz,config$saidas,'atual.rds'))
  tentativa <- readRDS(file.path(raiz,config$saidas,'execucao.rds'))
  if (!identical(atual$estado,'concluido') || !identical(tentativa$estado,'concluido') ||
      !identical(tentativa$etapa,'P06') || !identical(tentativa$assinatura,atual$assinatura) ||
      !identical(atual$config,config)) stop('Tentativa e geração atuais incompatíveis; execute P06.')
  caminho <- file.path(atual$geracao,'inf_mensal_fidc_tab_IV.rds')
  meta <- atual$arquivos$IV_rds
  if (is.null(meta) || !identical(meta$hash,calcular_hash_assinatura(caminho,TRUE))) stop('Tabela IV alterada.')
  estatisticas <- resumir_pl_mensal(readRDS(caminho))
  destino <- file.path(raiz,'P07_RESUMO_COMPETENCIAS.csv')
  resumo <- read.csv(destino,stringsAsFactors=FALSE,colClasses=c(pl_total_valor_fonte='character'))
  if ('data_competencia' %in% names(resumo)) {
    pos <- match(resumo$data_competencia,estatisticas$data_competencia)
    mesmas <- setequal(resumo$data_competencia,estatisticas$data_competencia)
  } else {
    # Migração do relatório mensal antigo só quando há uma data exata por mês.
    if(anyDuplicated(estatisticas$competencia)) stop('Resumo mensal antigo abrange várias datas de competência; migração exige revisão, sem agregar as datas.')
    pos <- match(resumo$competencia,estatisticas$competencia)
    mesmas <- setequal(resumo$competencia,estatisticas$competencia)
  }
  if (anyNA(pos) || !mesmas ||
      any(abs(as.numeric(resumo$pl_total_valor_fonte)-estatisticas$pl_total_calculado[pos])>.005))
    stop('Seleção/soma do resumo anterior incompatível com IV; revisar antes de substituir.')
  novas <- setdiff(names(estatisticas),c('competencia','pl_total_calculado'))
  for(nome in novas) resumo[[nome]] <- estatisticas[[nome]][pos]
  # O formato original desse artefato de documentação é CSV separado por vírgula.
  temporario <- tempfile('.resumo-pl-',dirname(destino))
  on.exit(unlink(temporario),add=TRUE)
  utils::write.csv(resumo,temporario,row.names=FALSE,na='',fileEncoding='UTF-8')
  observado <- read.csv(temporario,stringsAsFactors=FALSE,colClasses=c(pl_total_valor_fonte='character'))
  if (!identical(observado$pl_total_valor_fonte,resumo$pl_total_valor_fonte) || nrow(observado)!=nrow(resumo)) stop('Resumo divergente.')
  backup <- paste0(destino,'.rollback')
  if(file.exists(backup)) stop('Rollback do resumo pendente.')
  if(!file.rename(destino,backup)) stop('Resumo bloqueado.')
  if(!file.rename(temporario,destino)) {file.rename(backup,destino);stop('Publicação do resumo falhou.')}
  unlink(backup)
  resumo
}

if(sys.nframe()==0L) {
  .libPaths(c(normalizePath('.R-library'),.libPaths()))
  source('scripts/p02_utilitarios.R')
  args <- commandArgs(trailingOnly=TRUE)
  config <- if(length(args)) readRDS(args[1]) else list()
  if('config'%in%names(config)) config <- config$config
  print(atualizar_resumo_pl(config=config))
}
