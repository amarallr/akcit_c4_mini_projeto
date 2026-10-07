# Gera estatísticas e ranking para a configuração P06 selecionada.
# Uso: Rscript --vanilla scripts/p08_resumo_dados.R dados/atualizacao_2020/configuracao.rds
# P08 é análise posterior a P06 e opera somente sobre a geração configurada e conferida.
if(dir.exists('.R-library')) .libPaths(c(normalizePath('.R-library'),.libPaths()))
source('scripts/p02_utilitarios.R',encoding='UTF-8')
ambiente <- new.env(parent=globalenv())
sys.source('scripts/p07_resumo_pl.R',envir=ambiente)
gerar_resumo_dados_fidc <- function(arquivo_config='dados/atualizacao_2020/configuracao.rds') {
configuracao <- readRDS(arquivo_config)
config <- if('config' %in% names(configuracao)) configuracao$config else configuracao
atual <- readRDS(file.path(config$saidas,'atual.rds'))
if(!identical(atual$estado,'concluido') || !identical(atual$config,config))
  stop('A consolidação 2020+ não está concluída para esta configuração.')
iv_path <- file.path(atual$geracao,'inf_mensal_fidc_tab_IV.rds')
i_path <- file.path(atual$geracao,'inf_mensal_fidc_tab_I.rds')
if(!identical(atual$arquivos$IV_rds$hash,calcular_hash_assinatura(iv_path,TRUE)) ||
   !identical(atual$arquivos$I_rds$hash,calcular_hash_assinatura(i_path,TRUE)))
  stop('Hash de entrada histórica divergente.')
deduplicar_repeticoes_sem_conflito <- function(dados,chave,campos,rotulo) {
  if(!all(c(chave,campos) %in% names(dados))) stop(paste(rotulo,'sem os campos necessários.'))
  chave_texto <- do.call(paste,c(lapply(dados[chave],function(x) ifelse(is.na(x),'<NA>',as.character(x))),list(sep='|')))
  repetidas <- unique(chave_texto[duplicated(chave_texto)])
  remover <- logical(nrow(dados))
  for(k in repetidas) {
    pos <- which(chave_texto==k)
    conflitos <- vapply(campos,function(campo) length(unique(dados[[campo]][pos]))>1L,logical(1))
    if(any(conflitos)) stop(paste(rotulo,'tem valores conflitantes na chave:',k))
    remover[pos[-1L]] <- TRUE
  }
  list(dados=dados[!remover,,drop=FALSE],removidas=sum(remover))
}
iv_raw <- readRDS(iv_path); i_raw <- readRDS(i_path)
tipo <- 'TP_FUNDO_CLASSE' %in% names(iv_raw) && 'TP_FUNDO_CLASSE' %in% names(i_raw)
if(('TP_FUNDO_CLASSE' %in% names(iv_raw)) != ('TP_FUNDO_CLASSE' %in% names(i_raw)))
  stop('Tipo fundo/classe ausente em apenas uma das tabelas.')
chave <- c('cnpj',if(tipo) 'TP_FUNDO_CLASSE','dt_comptc')
iv_dedup <- deduplicar_repeticoes_sem_conflito(iv_raw,chave,'TAB_IV_A_VL_PL','Tabela IV')
i_dedup <- deduplicar_repeticoes_sem_conflito(i_raw,chave,c('CNPJ_ADMIN','ADMIN'),'Tabela I')
dados <- ambiente$associar_administradores_pl(iv_dedup$dados,i_dedup$dados)
estatisticas <- ambiente$resumir_pl_mensal(dados)
estatisticas$fundos_cnpj <- vapply(estatisticas$data_competencia,function(data)
  length(unique(dados$cnpj[as.character(dados$dt_comptc)==data])),integer(1))
estatisticas$quantidade_administradores <- vapply(estatisticas$data_competencia,function(data)
  length(unique(dados$cnpj_admin[as.character(dados$dt_comptc)==data & !is.na(dados$cnpj_admin)])),integer(1))
estatisticas$registros_flat <- NA_integer_
estatisticas$pl_total_valor_fonte <- vapply(estatisticas$pl_total_calculado,function(x)
  if(is.na(x)) NA_character_ else sprintf('%.2f',x),character(1))
ranking <- ambiente$resumir_pl_administradores(dados)
campos_publicados <- c('competencia','registros_flat','fundos_cnpj','registros_com_pl','registros_sem_pl',
 'pl_total_valor_fonte','pl_max_valor_fonte','pl_percentil_75_valor_fonte','pl_mediana_valor_fonte',
 'pl_percentil_25_valor_fonte','pl_min_valor_fonte','pl_media_valor_fonte',
 'pl_coeficiente_variacao_percentual','cv_definicao','quantis_metodo','data_competencia',
 'quantidade_administradores')
resumo <- estatisticas[campos_publicados]
pasta_publica <- 'resultados/estatisticas'
dir.create(pasta_publica,recursive=TRUE,showWarnings=FALSE)
arquivo_resumo <- file.path(pasta_publica,'estatisticas_por_competencia.csv')
arquivo_top25 <- file.path(pasta_publica,'top25_administradores.csv')
utils::write.csv(resumo,arquivo_resumo,row.names=FALSE,na='',fileEncoding='UTF-8')
utils::write.csv(ranking,arquivo_top25,row.names=FALSE,na='',fileEncoding='UTF-8')
pasta <- file.path(config$saidas,'resumo_estatisticas')
dir.create(pasta,recursive=TRUE,showWarnings=FALSE)
saveRDS(list(assinatura=atual$assinatura,config=config,competencias=resumo,administradores=ranking,
 deduplicacoes=list(tabela_IV=iv_dedup$removidas,tabela_I=i_dedup$removidas),
 metodo='Ranking e percentual pela soma mensal winsorizada em todo o período (quantis tipo 7: 2,5% e 97,5% por DT_COMPTC); colunas trimestrais são a soma do PL original no último mês de cada trimestre.'),
 file.path(pasta,'resumo_historico.rds'))
file.copy(c(arquivo_resumo,arquivo_top25),pasta,overwrite=TRUE)
cat('Estatísticas geradas para ',nrow(resumo),' datas de competência e ',nrow(ranking),' administradores no ranking.\n',sep='')
cat('Repetições sem conflito descartadas: IV=',iv_dedup$removidas,'; I=',i_dedup$removidas,'.\n',sep='')
sys.source('scripts/p08_documentar_resumo.R',envir=environment())
documentar_resumo_dados_fidc()
invisible(list(competencias=resumo,administradores=ranking,assinatura=atual$assinatura))
}

if(sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE)
  gerar_resumo_dados_fidc(if(length(args)) args[1] else 'dados/atualizacao_2020/configuracao.rds')
}
