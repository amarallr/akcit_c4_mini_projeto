# P08-MOD-002 | Cálculos compartilhados pelo painel e relatório; sem efeitos em source.
# P08-FUN-003 | P08-RF-005: tabela estreita, chaves mensais e cardinalidade auditável.
deduplicar_analise_fidc <- function(d,campos,rotulo) {
  k <- chaves_posicoes_fidc(d)
  x <- cbind(k,data.table::as.data.table(d)[,intersect(campos,names(d)),with=FALSE])
  valores <- setdiff(names(x),c('cnpj','tipo','data'))
  repetidas <- duplicated(x,by=c('cnpj','tipo','data')) | duplicated(x,by=c('cnpj','tipo','data'),fromLast=TRUE)
  if(any(repetidas)) {
    conflitos <- x[repetidas,lapply(.SD,function(v)length(unique(v))),by=.(cnpj,tipo,data),.SDcols=valores]
    if(any(as.matrix(conflitos[,..valores])>1L)) stop(rotulo,': valores conflitantes na chave analítica.')
  }
  unique(x,by=c('cnpj','tipo','data'))
}

# P08-FUN-004 | P08-RF-006: quantis tipo 7 nos originais, antes da winsorização.
estatisticas_pl_fidc <- function(x) {
  v <- x[!is.na(x)&is.finite(x)]; n <- length(v)
  q <- if(n) as.numeric(stats::quantile(v,c(.025,.25,.5,.75,.975),type=7,names=FALSE)) else rep(NA_real_,5)
  cercas <- q[c(2,4)]+c(-1.5,1.5)*(q[4]-q[2])
  internos <- v[v>=cercas[1]&v<=cercas[2]]
  list(n_valido=n,n_ausente=length(x)-n,cobertura=if(length(x)) n/length(x) else NA_real_,
    minimo=if(n) min(v) else NA_real_,p2_5=q[1],p25=q[2],mediana=q[3],p75=q[4],p97_5=q[5],
    media=if(n) mean(v) else NA_real_,maximo=if(n) max(v) else NA_real_,
    desvio_padrao=if(n>=2) stats::sd(v) else NA_real_,iqr=q[4]-q[2],
    total=if(n) sum(v) else NA_real_,negativos=sum(v<0),zeros=sum(v==0),
    bigode_inferior=if(length(internos)) min(internos) else NA_real_,
    bigode_superior=if(length(internos)) max(internos) else NA_real_,
    outliers=sum(v<cercas[1]|v>cercas[2]))
}

# P08-FUN-005 | P08-RF-007: denominador integral anterior ao corte top25.
ranking_posicoes_fidc <- function(d,valor='pl',grupos=c('tipo','data')) {
  r <- d[!is.na(cnpj_admin),.(valor=if(all(is.na(get(valor)))) NA_real_ else sum(get(valor),na.rm=TRUE),
    fundos_classes=data.table::uniqueN(paste(cnpj,tipo)),cnpjs=data.table::uniqueN(cnpj),
    meses=data.table::uniqueN(data),administrador=sort(unique(nome_admin[!is.na(nome_admin)]))[1]),
    by=c(grupos,'cnpj_admin')]
  data.table::setorderv(r,c(grupos,'valor','cnpj_admin'),c(rep(1L,length(grupos)),-1L,1L),na.last=TRUE)
  r[,`:=`(posicao=seq_len(.N),denominador=if(all(is.na(valor))) NA_real_ else sum(valor,na.rm=TRUE)),by=grupos]
  r[,participacao:=ifelse(!is.na(denominador)&denominador!=0,valor/denominador,NA_real_)]
  r
}

# P08-FUN-006 | P08-RF-008: mapa de níveis exclusivos, nunca soma pai com filha.
mapa_carteira_fidc <- function() {
  data.table::data.table(campo=c('TAB_I1_VL_DISP','TAB_I2_VL_CARTEIRA','TAB_I3_VL_POSICAO_DERIV','TAB_I4_VL_OUTRO_ATIVO',
    'TAB_I2A_VL_DIRCRED_RISCO','TAB_I2B_VL_DIRCRED_SEM_RISCO','TAB_I2C_VL_VLMOB','TAB_I2D_VL_TITPUB_FED',
    'TAB_I2E_VL_CDB','TAB_I2F_VL_OPER_COMPROM','TAB_I2G_VL_OUTRO_RF','TAB_I2H_VL_COTA_FIDC','TAB_I2I_VL_COTA_FIDC_NP','TAB_I2J_VL_CONTRATO_FUTURO'),
    rotulo=c('Disponibilidades','Carteira','Posição em derivativos','Outros ativos',
      'Direitos creditórios com riscos e benefícios','Direitos creditórios sem riscos e benefícios','Valores mobiliários',
      'Títulos públicos federais','CDB','Operações compromissadas','Outros títulos de renda fixa',
      'Cotas de FIDC','Cotas de FIDC não padronizado','Contratos futuros'),
    nivel=c(rep('Ativo',4),rep('Detalhe da carteira',10)),
    pai=c(rep('TAB_I_VL_ATIVO',4),rep('TAB_I2_VL_CARTEIRA',10)),tabela='I',
    unidade='unidade da fonte',sinal='Preservado',regra='Soma somente de posições com numerador e denominador presentes')
}

# P08-FUN-007 | P08-RF-008: razão de somas comparáveis; reconciliação com tolerância de centavos.
compor_carteira_fidc <- function(d,mapa=mapa_carteira_fidc()) {
  partes <- lapply(seq_len(nrow(mapa)),function(j) {
    campo <- mapa$campo[j]; pai <- mapa$pai[j]
    valor <- if(campo %in% names(d)) d[[campo]] else rep(NA_real_,nrow(d))
    base <- if(pai %in% names(d)) d[[pai]] else rep(NA_real_,nrow(d))
    data.table::data.table(d[,.(cnpj,tipo,data,cnpj_admin)],categoria=mapa$rotulo[j],campo=campo,nivel=mapa$nivel[j],
      valor=valor,base=base,percentual=ifelse(!is.na(base)&base>0,valor/base,NA_real_))
  })
  longo <- data.table::rbindlist(partes)
  topo <- mapa$campo[mapa$nivel=='Ativo']; componentes <- intersect(topo,names(d))
  matriz <- if(length(componentes)==length(topo)) as.matrix(d[,componentes,with=FALSE]) else NULL
  soma <- if(!is.null(matriz)) rowSums(matriz,na.rm=FALSE) else rep(NA_real_,nrow(d))
  ativo <- if('TAB_I_VL_ATIVO' %in% names(d)) d$TAB_I_VL_ATIVO else rep(NA_real_,nrow(d))
  dif <- ativo-soma; tol <- .01*(length(topo)+1)
  reconciliacao <- d[,.(cnpj,tipo,data,cnpj_admin)]
  reconciliacao[,`:=`(ativo=ativo,componentes=soma,diferenca=dif,tolerancia=tol,
    reconciliado=!is.na(dif)&abs(dif)<=tol,
    empilhavel=!is.na(dif)&abs(dif)<=tol & if(!is.null(matriz)) apply(matriz,1,function(v)all(v>=0)) else FALSE)]
  list(longo=longo,reconciliacao=reconciliacao)
}

# P08-FUN-008 | P08-RF-005/006/007/008: única fonte de cálculo do relatório e navegador.
calcular_analise_fidc <- function(iv,i) {
  message('P08: cardinalidade e associação I/IV')
  mapa <- mapa_carteira_fidc()
  a <- deduplicar_analise_fidc(iv,c('TAB_IV_A_VL_PL','TAB_IV_A_VL_PL__original','DENOM_SOCIAL'),'IV')
  b <- deduplicar_analise_fidc(i,c('CNPJ_ADMIN','ADMIN','COTST_INTERESSE','FUNDO_EXCLUSIVO','CONDOM',
    'TAB_I_VL_ATIVO',mapa$campo),'I')
  d <- merge(a,b,by=c('cnpj','tipo','data'),all.x=TRUE,sort=FALSE)
  if(nrow(d)!=nrow(a)) stop('Join multiplicador de PL.')
  d[,pl:=as.numeric(TAB_IV_A_VL_PL)]
  if(any(!is.finite(d$pl)&!is.na(d$pl))) stop('PL não finito.')
  d[,cnpj_admin:=toupper(gsub('[./ -]','',CNPJ_ADMIN))]
  valido <- vapply(d$cnpj_admin,validar_dv_ni,logical(1)) & !is.na(d$cnpj_admin) & nchar(d$cnpj_admin)==14L
  d[!valido,cnpj_admin:=NA_character_]
  d[,nome_admin:=as.character(ADMIN)]
  d[,entidade:=paste(cnpj,tipo,sep='|')]
  # Limiares globais do universo/tipo por competência; nunca recalculados por administrador.
  d[,pl_wins:=if(all(is.na(pl))) rep(NA_real_,.N) else pmin(pmax(pl,stats::quantile(pl,.025,type=7,na.rm=TRUE)),stats::quantile(pl,.975,type=7,na.rm=TRUE)),by=.(tipo,data)]
  d[,alterado:=!is.na(pl)&pl!=pl_wins]
  message('P08: estatísticas e rankings')
  s <- d[,c(estatisticas_pl_fidc(pl),list(fundos_classes=data.table::uniqueN(entidade),cnpjs=data.table::uniqueN(cnpj),
    administradores=data.table::uniqueN(cnpj_admin[!is.na(cnpj_admin)]),sem_admin=sum(is.na(cnpj_admin)),
    pl_sem_admin=if(all(is.na(pl[is.na(cnpj_admin)]))) NA_real_ else sum(pl[is.na(cnpj_admin)],na.rm=TRUE),
    wins_alterados=sum(alterado))),by=.(tipo,data)]
  sa <- d[!is.na(cnpj_admin),c(estatisticas_pl_fidc(pl),list(wins_alterados=sum(alterado))),by=.(tipo,data,cnpj_admin)]
  sw <- d[,estatisticas_pl_fidc(pl_wins),by=.(tipo,data)]
  saw <- d[!is.na(cnpj_admin),estatisticas_pl_fidc(pl_wins),by=.(tipo,data,cnpj_admin)]
  r <- ranking_posicoes_fidc(d)
  rh <- ranking_posicoes_fidc(d,'pl_wins','tipo')
  carteira <- compor_carteira_fidc(d,mapa)
  message('P08: agregação da carteira e concentração')
  agregado <- carteira$longo[,{
    ok <- !is.na(valor)&!is.na(base)&base>0
    list(valor=if(any(ok))sum(valor[ok]) else NA_real_,base=if(any(ok))sum(base[ok]) else NA_real_,
      percentual=if(any(ok))sum(valor[ok])/sum(base[ok]) else NA_real_,cobertos=sum(ok),elegiveis=.N,
      negativos=sum(valor<0,na.rm=TRUE))
  },by=.(tipo,data,cnpj_admin,categoria,nivel)]
  concentracao <- r[,{
    ok <- all(!is.na(valor)&valor>=0)&&sum(valor)>0
    list(top5=if(ok)sum(head(participacao,5)) else NA_real_,top10=if(ok)sum(head(participacao,10)) else NA_real_,
      top25=if(ok)sum(head(participacao,25)) else NA_real_,demais=if(ok)1-sum(head(participacao,25)) else NA_real_,
      hhi=if(ok)sum(participacao^2)*10000 else NA_real_)
  },by=.(tipo,data)]
  data.table::setorderv(s,c('tipo','data'))
  list(posicoes=d,estatisticas=s,estatisticas_admin=sa,estatisticas_wins=sw,estatisticas_admin_wins=saw,
    ranking=r,historico=rh,carteira=carteira,agregados_carteira=agregado,concentracao=concentracao,mapa=mapa)
}

# P08-FUN-016 | P08-RF-003: posições trimestrais só no último mês, nunca soma de meses.
posicoes_trimestrais_fidc <- function(ranking,competencias) {
  anos <- as.integer(substr(competencias,1,4)); meses <- as.integer(substr(competencias,6,7))
  trimestres <- unique(paste0(anos,'_T',ceiling(meses/3)))
  resultados <- list()
  for(t in trimestres) {
    ano <- as.integer(substr(t,1,4)); mes <- as.integer(substr(t,7,7))*3L
    fim_mes <- as.character(seq(as.Date(sprintf('%04d-%02d-01',ano,mes)),by='month',length.out=2)[2]-1)
    d <- ranking[data==fim_mes]
    if(nrow(d)) resultados[[length(resultados)+1L]] <- d[,.(tipo,cnpj_admin,trimestre=t,data=fim_mes,pl_original=valor,estado='Posição no último mês do trimestre')]
  }
  if(!length(resultados)) return(data.table::data.table(tipo=character(),cnpj_admin=character(),trimestre=character(),data=character(),pl_original=numeric(),estado=character()))
  data.table::rbindlist(resultados)
}
