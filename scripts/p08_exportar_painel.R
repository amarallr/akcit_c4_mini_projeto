# P08-MOD-003 | Exportação estreita e particionada; fórmulas em P08-MOD-002.
# P08-FUN-009 | P08-RF-009: JSON compacto mantém colunas/schema e precisão double.
gravar_json_p08 <- function(x,path) {
  jsonlite::write_json(x,path,auto_unbox=TRUE,na='null',null='null',digits=NA,pretty=FALSE)
}

# P08-FUN-010 | P08-RF-010: dicionário de negócio com cobertura e linhagem.
dicionario_analitico_fidc <- function(a,meta) {
  fonte <- data.table::fread('referencias/cvm/dicionario_textual_2026-10-07.csv',encoding='UTF-8',colClasses=c(consulta='character'))
  campos <- unique(c('CNPJ_FUNDO','CNPJ_FUNDO_CLASSE','TP_FUNDO_CLASSE','DT_COMPTC','DENOM_SOCIAL',
    'CNPJ_ADMIN','ADMIN','COTST_INTERESSE','FUNDO_EXCLUSIVO','CONDOM','TAB_X_NR_COTST','TAB_X_CLASSE_SERIE',
    'TAB_IV_A_VL_PL','TAB_I_VL_ATIVO',a$mapa$campo))
  mapa <- fonte[campo %in% campos]
  mapa[,`:=`(origem='original',unidade=ifelse(tipo %in% c('numeric','float'),'unidade da fonte','texto/data'),
    granularidade=ifelse(tabela=='X_1','CNPJ/tipo/data/classe-série','CNPJ/tipo/data'),
    nulos='Indisponível; nunca zero',transformacao='Identificadores textuais; nomes/valores originais preservados',
    paginas='Dados e metodologia; pré-filtros; painel; relatório')]
  mapa[,disponibilidade:=vapply(seq_len(.N),function(j) {
    ent <- meta$entradas[[tabela[j]]]
    if(is.null(ent)) 'Não utilizada nesta análise; filtro X_1 disponível no P06' else
      if(campo[j] %in% ent$campos) 'Presente na geração; cobertura por posição' else 'Ausente na geração selecionada'
  },character(1))]
  mapa[,cobertura:=vapply(campo,function(c) if(c %in% names(a$posicoes)) mean(!is.na(a$posicoes[[c]])) else NA_real_,numeric(1))]
  derivados <- data.table::data.table(tabela='P08',campo=c('p97_5','pl_wins','participacao','percentual','diferenca'),
    descricao=c('Percentil 97,5 (P97,5) do PL original no grupo indicado, interpolação tipo 7',
      'PL winsorizado nos limites globais do universo/tipo/competência',
      'Valor do administrador / soma do valor de todos os administradores identificados',
      'Soma de componentes / soma das bases presentes e positivas nas mesmas posições',
      'Ativo total menos soma dos quatro componentes de nível Ativo'),
    tipo='numeric',origem='derivado',unidade=c('unidade da fonte','unidade da fonte','razão 0–1','razão 0–1','unidade da fonte'),
    granularidade='Grupo/tipo/data indicado',nulos='Indisponível; denominador não positivo/zero tratado explicitamente',
    transformacao=c('quantile(x, .975, type=7, na.rm=TRUE)','pmin(pmax(pl,p2_5_global),p97_5_global)',
      'valor / denominador anterior ao top25','sum(valor[comparáveis]) / sum(base[comparáveis])','ativo - soma(componentes completos)'),
    paginas='Painel; relatório; CSV',disponibilidade='Calculado',fonte=meta$dicionario_fonte,consulta=meta$dicionario_consulta)
  data.table::rbindlist(list(mapa,derivados),fill=TRUE)
}

# P08-FUN-011 | P08-RF-009/011: dados mensais sob demanda, downloads completos e manifesto.
exportar_painel_fidc <- function(a,meta,inicio) {
  force(inicio)
  pasta <- 'resultados/estatisticas'; dir.create(file.path(pasta,'dados'),recursive=TRUE,showWarnings=FALSE)
  csv <- function(d,nome) data.table::fwrite(d,file.path(pasta,nome),na='',quote='auto',bom=FALSE)
  s <- data.table::copy(a$estatisticas)
  s[,`:=`(competencia=substr(data,1,7),data_competencia=data,fundos_cnpj=cnpjs,
    registros_flat=NA_integer_,registros_com_pl=n_valido,registros_sem_pl=n_ausente,
    pl_total_valor_fonte=total,pl_max_valor_fonte=maximo,pl_percentil_75_valor_fonte=p75,
    pl_mediana_valor_fonte=mediana,pl_percentil_25_valor_fonte=p25,pl_min_valor_fonte=minimo,
    pl_media_valor_fonte=media,quantidade_administradores=administradores,
    quantis_metodo='R type=7',pl_coeficiente_variacao_percentual=ifelse(media!=0,desvio_padrao/media*100,NA_real_),
    cv_definicao='Desvio padrão amostral / média; indisponível para n<2 ou média zero')]
  csv(s,'estatisticas_por_competencia.csv')
  csv(a$ranking,'ranking_por_competencia.csv'); csv(a$historico,'ranking_historico_completo.csv')
  legado <- data.table::copy(a$historico[posicao<=25])
  legado[,`:=`(ranking=posicao,pl_acumulado_valor_fonte=valor,percentual_pl_acumulado=participacao*100,
    fundos_cnpj=cnpjs,quantidade_fundos=fundos_classes,pl_soma_periodo=valor,percentual_pl_total=participacao*100,
    criterio_ranking='Soma de posições mensais winsorizadas; universo tipo separado')]
  trimestrais <- posicoes_trimestrais_fidc(a$ranking,meta$competencias)
  trimestres <- unique(paste0(substr(meta$competencias,1,4),'_T',ceiling(as.integer(substr(meta$competencias,6,7))/3)))
  for(t in trimestres) {
    v <- trimestrais[trimestre==t]
    legado[, (paste0('pl_',t)) := v$pl_original[match(paste(tipo,cnpj_admin),paste(v$tipo,v$cnpj_admin))]]
  }
  csv(trimestrais,'posicoes_trimestrais.csv')
  csv(legado,'top25_administradores.csv'); csv(a$estatisticas_admin,'estatisticas_por_administrador.csv')
  csv(a$concentracao,'concentracao.csv'); csv(a$carteira$reconciliacao,'reconciliacao_carteira.csv')
  csv(a$agregados_carteira,'carteira_por_administrador.csv'); csv(a$mapa,'mapa_carteira.csv')
  dic <- dicionario_analitico_fidc(a,meta); csv(dic,'dicionario_analitico.csv')
  colunas <- c('cnpj','tipo','data','DENOM_SOCIAL','cnpj_admin','nome_admin','pl','pl_wins',
    'TAB_IV_A_VL_PL__original','COTST_INTERESSE','FUNDO_EXCLUSIVO','CONDOM','TAB_I_VL_ATIVO',a$mapa$campo)
  colunas <- intersect(colunas,names(a$posicoes))
  csv(a$posicoes[,..colunas],'posicoes_fundos_classes.csv')
  # Vetores por coluna evitam serializar centenas de milhares de pequenas listas R.
  compactar <- function(d) list(colunas=names(d),valores=unname(lapply(d,I)),formato='colunas')
  for(data_alvo in meta$competencias) {
    d <- a$posicoes[data==data_alvo,..colunas]
    gravar_json_p08(list(posicoes=compactar(d),ranking=a$ranking[data==data_alvo],
      estatisticas_admin=a$estatisticas_admin[data==data_alvo],
      estatisticas_admin_wins=a$estatisticas_admin_wins[data==data_alvo],
      reconciliacao=compactar(a$carteira$reconciliacao[data==data_alvo])),
      file.path(pasta,'dados',paste0(data_alvo,'.json')))
    # Longo particionado mantém todas as categorias sem arquivo único excessivo.
    csv(a$carteira$longo[data==data_alvo,.(cnpj,tipo,data,cnpj_admin,campo,valor,base,percentual)],
      paste0('dados/carteira_',data_alvo,'.csv'))
  }
  historico <- a$posicoes[,c('cnpj','tipo','data','cnpj_admin','nome_admin','pl','pl_wins','TAB_I_VL_ATIVO',
    intersect(a$mapa$campo,names(a$posicoes))),with=FALSE]
  # 100 partições estreitas de histórico; identidade permanece composta no navegador.
  historico[,bucket:=substr(cnpj,13,14)]
  for(b in unique(historico$bucket)) gravar_json_p08(compactar(historico[bucket==b,! 'bucket']),file.path(pasta,'dados',paste0('historico_',b,'.json')))
  universo_carteira <- a$carteira$longo[,{
    ok <- !is.na(valor)&!is.na(base)&base>0
    list(valor=if(any(ok))sum(valor[ok]) else NA_real_,base=if(any(ok))sum(base[ok]) else NA_real_,
      percentual=if(any(ok))sum(valor[ok])/sum(base[ok]) else NA_real_,cobertos=sum(ok),elegiveis=.N)
  },by=.(tipo,data,categoria,nivel)]
  for(u in meta$universos) gravar_json_p08(list(universo=universo_carteira[tipo==u],
    administradores=a$agregados_carteira[tipo==u]),file.path(pasta,'dados',paste0('carteira_serie_',gsub(' ','_',u),'.json')))
  vinculos <- a$posicoes[!is.na(cnpj_admin),.(competencias=list(match(sort(unique(data)),meta$competencias)-1L)),by=.(tipo,cnpj_admin,cnpj)]
  gravar_json_p08(vinculos,file.path(pasta,'dados/vinculos_admin.json'))
  gravar_json_p08(list(estatisticas=a$estatisticas,estatisticas_wins=a$estatisticas_wins,
    historico=a$historico,series_admin=a$estatisticas_admin,
    ranking_mensal_wins=ranking_posicoes_fidc(a$posicoes,'pl_wins'),
    concentracao=a$concentracao,mapa=a$mapa,dicionario=dic),file.path(pasta,'visao_geral.json'))
  sys.source('scripts/p08_relatorio_analise.R',envir=environment())
  documentar_analise_fidc(a,meta,dic)
  arquivos <- list.files(pasta,recursive=TRUE,full.names=TRUE)
  arquivos <- arquivos[!grepl('manifesto_publico.json$',arquivos)]
  meta$segundos_geracao <- proc.time()[['elapsed']]-inicio
  meta$codigo_analitico <- assinatura_codigo('.')
  meta$bytes_publicados <- sum(file.info(arquivos)$size)
  meta$arquivos <- lapply(arquivos,function(f) list(arquivo=substring(gsub('\\\\','/',f),nchar(pasta)+2),
    bytes=unname(file.info(f)$size),sha256=calcular_hash_assinatura(f,TRUE)))
  gravar_json_p08(meta,file.path(pasta,'manifesto_publico.json'))
  cat('Volume derivado: ',round(meta$bytes_publicados/1024^2,2),' MiB; geração ',round(meta$segundos_geracao,1),' s.\n',sep='')
}
