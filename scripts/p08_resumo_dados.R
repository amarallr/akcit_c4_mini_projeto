# P08-MOD-001 | P08-FUN-001: geração verificável, painel estático e relatório real.
# CLI: Rscript --vanilla scripts/p08_resumo_dados.R [configuracao.rds]
gerar_resumo_dados_fidc <- function(arquivo_config='dados/atualizacao_2020/configuracao.rds') {
  bibliotecas <- .libPaths(); on.exit(.libPaths(bibliotecas),add=TRUE)
  if(dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'),.libPaths()))
  threads <- data.table::getDTthreads(); data.table::setDTthreads(2L)
  on.exit(data.table::setDTthreads(threads),add=TRUE)
  e <- new.env(parent=globalenv())
  for(f in c('p02_utilitarios.R','p04_configuracao_fidc.R','p06_consolidacao_fidc.R','p08_analise_fidc.R','p08_exportar_painel.R'))
    sys.source(file.path('scripts',f),envir=e)
  inicio <- proc.time()[['elapsed']]
  configuracao <- readRDS(arquivo_config)
  config <- if('config' %in% names(configuracao)) configuracao$config else configuracao
  atual <- readRDS(file.path(config$saidas,'atual.rds'))
  tentativa <- readRDS(file.path(config$saidas,'execucao.rds'))
  if(!identical(atual$estado,'concluido')||!identical(atual$config,config)||
    !identical(tentativa$estado,'concluido')||!identical(tentativa$etapa,'P06')||
    !identical(tentativa$assinatura,atual$assinatura)||!identical(tentativa$assinatura_plano,atual$assinatura_plano))
    stop('Geração/tentativa P06 incompatível ou não concluída.')
  plano <- e$assinar_plano_fidc(configuracao$plano,config)
  if(!identical(plano$assinatura,atual$assinatura_plano)) stop('Plano incompatível com a geração.')
  campos_i <- c('CNPJ_FUNDO','CNPJ_FUNDO_CLASSE','TP_FUNDO_CLASSE','cnpj','dt_comptc','campo_identidade',
    'CNPJ_ADMIN','ADMIN','DENOM_SOCIAL','COTST_INTERESSE','FUNDO_EXCLUSIVO','CONDOM','TAB_I_VL_ATIVO',e$mapa_carteira_fidc()$campo)
  campos_iv <- c('CNPJ_FUNDO','CNPJ_FUNDO_CLASSE','TP_FUNDO_CLASSE','cnpj','dt_comptc','campo_identidade',
    'DENOM_SOCIAL','TAB_IV_A_VL_PL','TAB_IV_A_VL_PL__original')
  entradas <- list(); tabelas <- list()
  for(id in c('I','IV','X_1','X_1_1')) {
    message('Validando/leitura seletiva: ',id)
    registro <- atual$arquivos[[paste0(id,'_csv')]]
    if(is.null(registro)||!file.exists(registro$caminho)||!identical(registro$hash,e$calcular_hash_assinatura(registro$caminho,TRUE))) stop('Hash de entrada divergente: ',id)
    cab <- names(data.table::fread(registro$caminho,sep=';',nrows=0,showProgress=FALSE))
    campos <- switch(id,I=campos_i,IV=campos_iv,
      X_1=c(campos_iv,'TAB_X_CLASSE_SERIE','TAB_X_NR_COTST'),
      X_1_1=c(campos_iv,grep('^TAB_X_NR_COTST_.*(?<!__original)$',cab,value=TRUE,perl=TRUE)))
    tabelas[[id]] <- data.table::fread(registro$caminho,sep=';',select=intersect(campos,cab),
      colClasses=list(character=intersect(c('cnpj','CNPJ_ADMIN','CNPJ_FUNDO','CNPJ_FUNDO_CLASSE','TAB_IV_A_VL_PL__original'),cab)),na.strings='',encoding='UTF-8',showProgress=FALSE)
    # P08-FUN-001: alguns CSVs consolidados antigos mantêm bytes Latin-1 sem marca.
    # Corrigir somente texto de exibição inválido em UTF-8; fontes/hashes ficam intactos.
    for(campo in names(tabelas[[id]])) if(is.character(tabelas[[id]][[campo]])) {
      v <- tabelas[[id]][[campo]]; invalido <- !is.na(v)&is.na(iconv(v,from='UTF-8',to='UTF-8',sub=NA))
      if(any(invalido)) {v[invalido] <- iconv(v[invalido],from='latin1',to='UTF-8');data.table::set(tabelas[[id]],j=campo,value=v)}
    }
    entradas[[id]] <- list(arquivo=basename(registro$caminho),sha256=registro$hash,linhas=nrow(tabelas[[id]]),campos=names(tabelas[[id]]))
  }
  if(any(tabelas$IV$dt_comptc<config$inicio|tabelas$IV$dt_comptc>config$fim)) stop('Competência fora da configuração.')
  message('Calculando análise compartilhada.')
  analise <- e$calcular_analise_fidc(tabelas$IV,tabelas$I)
  analise$cotistas <- e$preparar_cotistas_p08(tabelas$X_1,tabelas$X_1_1,analise$posicoes)
  if(!nrow(analise$posicoes)) stop('Sem registros elegíveis: não há análise publicável.')
  meta <- list(schema='p08-v2026-10-07',gerado_em=format(Sys.time(),'%FT%T%z'),assinatura=atual$assinatura,
    assinatura_plano=atual$assinatura_plano,periodo_solicitado=c(config$inicio,config$fim),
    periodo_observado=range(analise$posicoes$data),competencias=sort(unique(analise$posicoes$data)),
    universos=sort(unique(analise$posicoes$tipo)),unidade='unidade da fonte',
    unidade_evidencia='numeric/scale=2 declara precisão, não moeda. Unidade monetária não confirmada no dicionário consultado.',
    filtros=e$validar_filtros_fidc(if(is.null(config$filtros)) list() else config$filtros),
    expressao_filtros=e$expressao_filtros_fidc(if(is.null(config$filtros)) list() else config$filtros),
    pre_consolidacao=if(is.null(atual$filtros)) 'Sem pré-filtro ativo; geração completa preservada' else 'Índice mensal aplicado antes da consolidação',
    entradas=entradas,tabelas_disponiveis=names(atual$linhas_tabelas),linhas_tabelas=as.list(atual$linhas_tabelas),
    quantis='quantile(x, probs=0.975, type=7, na.rm=TRUE); P97,5 original antes da winsorização',
    dicionario_fonte='https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/meta_inf_mensal_fidc_txt.zip',
    dicionario_consulta='2026-10-07',separacao_universos='Fundo, Classe e Fundo legado separados; vínculo patrimonial não confirmado.',
    cotistas='TAB_X_1 informa quantidade por classe/série; TAB_X_1_1 detalha o perfil nas classes sênior e subordinada. Total direto somente para chave com uma linha em X_1. Não somar séries, categorias ou entidades como pessoas distintas. Ausência não é zero.',
    biblioteca=list(nome='Plotly.js',versao='3.1.0',licenca='MIT',documentacao='https://plotly.com/javascript/'))
  dir.create(file.path(config$saidas,'resumo_estatisticas'),recursive=TRUE,showWarnings=FALSE)
  saveRDS(list(assinatura=atual$assinatura,config=config,metadados=meta,analise=analise),file.path(config$saidas,'resumo_estatisticas/resumo_historico.rds'))
  e$exportar_painel_fidc(analise,meta,inicio)
  cat('P08 concluído: ',length(meta$competencias),' competências; ',nrow(analise$posicoes),' posições; universos separados.\n',sep='')
  invisible(list(analise=analise,metadados=meta))
}
if(sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE)
  gerar_resumo_dados_fidc(if(length(args)) args[1] else 'dados/atualizacao_2020/configuracao.rds')
}
