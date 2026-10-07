# P08-MOD-004 | P08-FUN-012 | P08-RF-011: relatório de dados pelos cálculos do painel.
documentar_analise_fidc <- function(a,meta,dic) {
  fmt <- function(v) ifelse(is.na(v),'Indisponível',formatC(v,format='f',digits=2,big.mark='.',decimal.mark=','))
  pct <- function(v) paste0(fmt(v*100),'%')
  linhas <- c('# Relatório final de análise dos FIDCs',
    paste('Geração:',meta$gerado_em,'| Schema:',meta$schema),
    paste('Assinatura P06:',meta$assinatura),
    '## Resumo executivo',
    paste('Período observado:',paste(meta$periodo_observado,collapse=' a '),';',length(meta$competencias),'competências.'),
    paste('São',nrow(a$posicoes),'posições mensais,',data.table::uniqueN(a$posicoes$entidade),
      'identidades de fundos/classes e',data.table::uniqueN(a$posicoes$cnpj),'CNPJs distintos no período. Essas contagens incluem os universos separados, sem somar seus patrimônios.'),
    paste('Recorte de pré-consolidação:',meta$expressao_filtros,'.',meta$pre_consolidacao),
    'O relatório tem recorte fixo registrado; filtros exploratórios do painel não o alteram. Ano de 2026 incompleto: parcial até a última competência observada.',
    paste('Unidade:',meta$unidade,'.',meta$unidade_evidencia),
    '## Fonte, cobertura e principais colunas',
    paste('Informes mensais públicos da CVM. Período solicitado:',paste(meta$periodo_solicitado,collapse=' a '),'. Tabelas presentes:',paste(meta$tabelas_disponiveis,collapse=', '),'.'),
    'I e IV são utilizadas nesta análise e seus CSVs têm hashes verificados; as demais tabelas estão disponíveis, mas não foram incorporadas aos cálculos de PL/carteira. X não existe nos pacotes de 2020–2022. Não presumir que metadados presentes garantam dados em cada competência.',
    'CNPJ é identificador textual; DT_COMPTC é a competência do informe; TP_FUNDO_CLASSE separa Fundo e Classe. Nos leiautes antigos, CNPJ_FUNDO e tipo ausente recebem o rótulo Fundo legado. Não há relação patrimonial confirmada para somar fundos e classes. ADMIN/CNPJ_ADMIN identificam o administrador na data do informe, sem substituição pelo atual; não são identidade de gestor.',
    'TAB_IV_A_VL_PL é o patrimônio líquido informado (tabela IV). TAB_I_VL_ATIVO é ativo; TAB_I1_VL_DISP, TAB_I2_VL_CARTEIRA, TAB_I3_VL_POSICAO_DERIV e TAB_I4_VL_OUTRO_ATIVO são componentes do primeiro nível. Os campos I.2.a–I.2.j detalham a carteira; provisões são distintas e não adicionadas como ativos positivos.',
    'COTST_INTERESSE informa interesse único e indissociável (S/N); FUNDO_EXCLUSIVO informa exclusividade (S/N), critérios independentes. CONDOM tem domínio Aberto/Fechado. TAB_X_NR_COTST é número de cotistas por classe/série em X_1; múltiplas séries não comprovam quantidade de pessoas distintas da entidade e são desconhecidas no filtro de quantidade.',
    '[Dicionário analítico completo](dicionario_analitico.csv) | [Mapa de categorias e hierarquia](mapa_carteira.csv) | [Posições integrais](posicoes_fundos_classes.csv)',
    '## Metodologia e qualidade',
    'Chave CNPJ/tipo/data; I e IV passam por teste de cardinalidade antes do join 1:1. Repetições sem diferenças analíticas são resolvidas; divergências de PL/administrador interrompem geração. CNPJ de administrador é validado por formato e dígitos verificadores, sem confirmar cadastro/titularidade; identificador inválido ou ausente fica fora do ranking e dentro das estatísticas gerais.',
    'Quantis usam tipo 7 de R: h=1+(n−1)p, interpolação entre posições ordenadas. Percentil 97,5 (P97,5) = quantile(x, probs=0.975, type=7, na.rm=TRUE), calculado nos PL originais do grupo, antes da winsorização. n=0 indisponível; n=1 único valor. Desvio padrão amostral apenas n≥2. IQR=P75−P25. Boxplot: caixa P25–P75, mediana, bigodes nas observações dentro de 1,5×IQR e pontos extremos.',
    'Ranking por competência usa PL original na mesma data. Ranking histórico soma posições mensais winsorizadas em P2,5/P97,5 globais por universo/tipo/competência. Não é fluxo, PL atual, encerramento ou patrimônio próprio do administrador. Denominador de participação usa todos os administradores identificados antes de cortar top25; desempate pelo CNPJ crescente. Cobertura desigual pode influenciar o histórico.',
    'Nulo não é zero. Valores negativos permanecem identificados; razões com denominadores indisponíveis/zero não são publicadas como zero. HHI (escala 0–10.000) e top5/10/25 apenas quando todos os PL agregados identificados são não negativos e soma positiva, sem classificação regulatória automática.',
    '## Estatísticas e achados por universo')
  adicionar <- function(x) linhas <<- c(linhas,x)
  tabela <- function(d) {
    adicionar(paste0('| ',paste(names(d),collapse=' | '),' |'))
    adicionar(paste0('| ',paste(rep('---',ncol(d)),collapse=' | '),' |'))
    for(j in seq_len(nrow(d))) adicionar(paste0('| ',paste(gsub('[|\r\n]',' ',as.character(unlist(d[j]))),collapse=' | '),' |'))
    adicionar('')
  }
  for(universo in meta$universos) {
    s <- a$estatisticas[tipo==universo]; ultima <- max(s$data)
    atual <- s[data==ultima]; primeira <- s[1]; extremo <- s[which.max(total)]
    r <- a$ranking[tipo==universo & data==ultima]
    h <- a$historico[tipo==universo]
    adicionar(c(paste('## Universo:',universo),paste('Cobertura observada:',min(s$data),'a',ultima,';',nrow(s),'competências.'),
      paste('Na última competência',ultima,': PL total',fmt(atual$total),';',atual$n_valido,'valores válidos e',atual$n_ausente,
        'ausentes. Média',fmt(atual$media),'; mediana',fmt(atual$mediana),'; Percentil 97,5 (P97,5)',fmt(atual$p97_5),'.'),
      paste('Maior total observado:',fmt(extremo$total),'em',extremo$data,'. Primeiro total observado:',fmt(primeira$total),'em',primeira$data,'. A população varia entre datas; a diferença não é rentabilidade.'),
      paste('Posições sem administrador validado na última data:',atual$sem_admin,'; PL correspondente:',fmt(atual$pl_sem_admin),'.',
        'PL coberto por administradores:',pct(if(!is.na(atual$total)&&atual$total!=0) (atual$total-if(is.na(atual$pl_sem_admin))0 else atual$pl_sem_admin)/atual$total else NA_real_),'.'),
      paste('Distribuição original na última data:',atual$negativos,'PL negativos;',atual$zeros,'zeros;',atual$outliers,
        'potenciais outliers pelas cercas de 1,5×IQR;',atual$wins_alterados,'valores alterados na visão winsorizada. Extremo estatístico não comprova erro ou irregularidade.'),
      'Estatísticas descritivas por competência; a coluna P97,5 é do PL original. Todos os demais indicadores estão no CSV completo.'))
    tabela(data.table::data.table(Competência=s$data,`n válido`=s$n_valido,Mediana=fmt(s$mediana),
      `Percentil 97,5 (P97,5)`=fmt(s$p97_5)))
    cc <- a$concentracao[tipo==universo & data==ultima]
    if(nrow(cc)) adicionar(paste('Concentração na última competência: top5',pct(cc$top5),'; top10',pct(cc$top10),'; top25',pct(cc$top25),'; demais',pct(cc$demais),'; HHI',fmt(cc$hhi),'. [Concentração por competência](concentracao.csv).'))
    adicionar(paste('Top 25 por PL na competência',ultima,'— valores originais; participação sobre todos os administradores identificados.'))
    rr <- head(r,25)
    tabela(data.table::data.table(Posição=rr$posicao,Administrador=paste(rr$administrador,rr$cnpj_admin),
      PL=fmt(rr$valor),Participação=pct(rr$participacao),`Fundos/classes`=rr$fundos_classes))
    adicionar('Ranking histórico por soma de posições mensais winsorizadas — meses observados por administrador, valores não representam patrimônio atual.')
    hh <- head(h,25)
    tabela(data.table::data.table(Posição=hh$posicao,Administrador=paste(hh$administrador,hh$cnpj_admin),
      Soma=fmt(hh$valor),Participação=pct(hh$participacao),Meses=hh$meses))
    if(nrow(r)&&nrow(h)) adicionar(paste('Líder por competência:',r$administrador[1],'; líder histórico:',h$administrador[1],'. São medidas e populações temporais diferentes. [Rankings completos](ranking_por_competencia.csv).'))
    if(nrow(s)>=2) {
      anterior <- s$data[nrow(s)-1]; d0 <- a$posicoes[tipo==universo & data==anterior]
      d1 <- a$posicoes[tipo==universo & data==ultima]; comum <- intersect(d0$entidade,d1$entidade)
      adicionar(paste('Cobertura entre as duas últimas competências:',nrow(d0),'posições em',anterior,'e',nrow(d1),'em',ultima,
        '(',pct(if(nrow(d0))nrow(d1)/nrow(d0) else NA_real_),'da quantidade anterior).',
        'Essa alteração da população observada impede interpretar a diferença dos totais como mudança de tamanho do mercado. A origem da ausência não foi determinada; não se presume liquidação.'))
      v0 <- d0[entidade %in% comum & !is.na(pl),.(entidade,pl0=pl)]
      v1 <- d1[entidade %in% comum & !is.na(pl),.(entidade,pl1=pl)]
      pares <- merge(v0,v1,by='entidade')
      adicionar(paste('Comparação homogênea',anterior,'→',ultima,':',nrow(pares),'entidades com PL em ambas as datas; total inicial',fmt(sum(pares$pl0)),
        '; final',fmt(sum(pares$pl1)),'; diferença absoluta',fmt(sum(pares$pl1)-sum(pares$pl0)),'.',
        length(setdiff(d1$entidade,d0$entidade)),'entradas e',length(setdiff(d0$entidade,d1$entidade)),'saídas de registros na população observada. Entrada/saída não prova criação/liquidação; ausência de informe e mudança de leiaute também podem interferir.'))
    }
    rec <- a$carteira$reconciliacao[tipo==universo & data==ultima]
    adicionar(c('Composição do ativo na última competência: razão de somas nas mesmas posições comparáveis, base ativo total positivo.',
      paste('Reconciliação de quatro componentes do ativo:',sum(rec$reconciliado),'de',nrow(rec),'posições reconciliadas;',
        sum(is.na(rec$diferenca)),'sem dados completos;',sum(!is.na(rec$diferenca)&!rec$reconciliado),'com diferença acima da tolerância. Tolerância absoluta:',fmt(.05),
        'unidade da fonte, soma de cinco arredondamentos de centavos. Não foi criado residual para forçar 100%. Barras de 100% usam somente posições completas, não negativas e reconciliadas.'),
      '[Reconciliação por posição](reconciliacao_carteira.csv) | [Composição por administrador](carteira_por_administrador.csv)'))
    ca <- a$carteira$longo[tipo==universo & data==ultima & nivel=='Ativo',{
      ok <- !is.na(valor)&!is.na(base)&base>0
      list(Valor=if(any(ok))sum(valor[ok]) else NA_real_,Percentual=if(any(ok))sum(valor[ok])/sum(base[ok]) else NA_real_,Cobertos=sum(ok))
    },by=.(categoria)]
    tabela(data.table::data.table(Categoria=ca$categoria,Valor=fmt(ca$Valor),`% do ativo comparável`=pct(ca$Percentual),`Posições cobertas`=ca$Cobertos))
  }
  adicionar(c('## Evolução, distribuições e conclusões',
    'As séries do painel cobrem todas as competências disponíveis por universo. Datas ausentes permanecem lacunas, sem zero/interpolação. Histórico Q4 é apenas preset de apresentação; trimestres são posições do último mês, sem soma de meses. 2026 é identificado como incompleto.',
    'Média, mediana, dispersão e P97,5 descrevem a distribuição de PL entre posições na mesma competência. Boxplots por administrador usam fundos/classes, sem misturar meses como observações independentes. A visão winsorizada é transformação estatística claramente nomeada; as estatísticas descritivas originais permanecem acessíveis.',
    'Os resultados permitem comparar tamanho e concentração do PL informado e composição contábil com cobertura registrada. A separação de universos e o aumento/redução de registros impedem interpretar diferenças de total como crescimento de coorte fixa. A comparação homogênea final compara apenas entidades observadas com PL nas duas datas; seleção e sobrevivência continuam limitando a interpretação.',
    'Concentração e valores extremos não demonstram irregularidade, risco de crédito, eficiência, efeito tributário ou retorno de cota. Não há avaliação causal ou previsão. Investigações futuras: confirmar relação Fundo/Classe, total de cotistas distintos, unidades monetárias e mudanças de leiaute; comparar carteira em coorte estável e explicar divergências de reconciliação na fonte.',
    '## Apêndice: fórmulas, linhagem e reprodução',
    'Dados originais e consolidados não são editados. Números de CSV/JSON preservam precisão double (15–17 algarismos significativos); texto decimal original do PL também está no CSV de posições. Arredondamento a duas casas ocorre somente na apresentação. O resultado não garante aritmética decimal exata para todos os totais financeiros.',
    paste('Pré-filtros:',meta$expressao_filtros,'. A seleção é de posições mensais elegíveis; não é coorte fixa. No Pages filtros exploratórios somente selecionam dados já publicados. Configuração e processamento R ocorrem antes da publicação.'),
    'Reproduzir na raiz: Rscript --vanilla scripts/p08_resumo_dados.R dados/atualizacao_2020/configuracao.rds; depois powershell -File scripts/publicar_resumo.ps1. Para universo com pré-filtros, preparar P04 com config$filtros, reutilizar ZIPs íntegros e executar P06 antes do P08.',
    '[Manifesto com schema, assinatura, hashes, período e volume](manifesto_publico.json) | [Estatísticas completas](estatisticas_por_competencia.csv) | [Ranking histórico completo](ranking_historico_completo.csv)',
    paste('Biblioteca:',meta$biblioteca$nome,meta$biblioteca$versao,'(MIT), arquivos locais. Escolhida por linhas, barras, quartis explícitos, eventos de clique, redimensionamento e exportação. [Documentação oficial](https://plotly.com/javascript/).'),
    paste('Dicionário oficial consultado em',meta$dicionario_consulta,': [metadados CVM](',meta$dicionario_fonte,').',sep='')))
  for(id in names(meta$entradas)) adicionar(paste('Tabela',id,':',meta$entradas[[id]]$arquivo,'; SHA-256',meta$entradas[[id]]$sha256))
  writeLines(enc2utf8(linhas),'resultados/estatisticas/relatorio_analise_fidc.md',useBytes=TRUE)
  writeLines(enc2utf8(c('# Resumo de estatísticas FIDC',paste('Geração:',meta$gerado_em),
    paste('Período:',paste(meta$periodo_observado,collapse=' a ')),
    'O resumo foi ampliado para o [relatório final de análise](relatorio_analise_fidc.html), com Markdown [para download](relatorio_analise_fidc.md).',
    'O painel permite todo o período, separa universos Fundo/Classe/Fundo legado e apresenta P97,5 original, rankings por competência e histórico, carteira e drill down.',
    paste('Pré-consolidação:',meta$expressao_filtros),
    '[Estatísticas completas](estatisticas_por_competencia.csv) | [Top25 histórico](top25_administradores.csv)')),
    'resultados/estatisticas/relatorio_estatisticas.md',useBytes=TRUE)
}
