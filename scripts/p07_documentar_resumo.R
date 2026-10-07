r <- read.csv('resultados/estatisticas/estatisticas_por_competencia.csv')
t <- read.csv('resultados/estatisticas/top25_administradores.csv',colClasses=c(cnpj_admin='character'))
t <- t[order(-t$pl_soma_periodo,t$cnpj_admin,na.last=TRUE),]
fmt <- function(x) formatC(x,format='f',digits=2,big.mark='.',decimal.mark=',')
data_legivel <- function(x) format(as.Date(x),'%d/%m/%Y')
cnpj_legivel <- function(x) ifelse(grepl('^[0-9]{14}$',x),sub('^(.{2})(.{3})(.{3})(.{4})(.{2})$','\\1.\\2.\\3/\\4-\\5',x),x)
linhas <- c('# Estatísticas dos FIDC','',
 'Esta página apresenta os resultados de um **mini projeto didático da Especialização em Engenharia de Software com IA Generativa**. O projeto utiliza dados públicos dos informes mensais de Fundos de Investimento em Direitos Creditórios (FIDC) da Comissão de Valores Mobiliários (CVM) para exercitar o ciclo de desenvolvimento de software: configuração das fontes, obtenção dos dados, consolidação, testes e documentação.',
 '', 'A implementação foi desenvolvida em R, com RStudio, apoio de IA generativa por meio do Codex e controle de versões com Git e GitHub, sob decisões e revisão humanas. O pipeline reúne tabelas históricas por competência, uma base consolidada e dados de cedentes. As estatísticas e o ranking abaixo demonstram uma aplicação analítica dos dados produzidos pela seleção.',
 '', 'Consulte o [repositório do projeto](https://github.com/amarallr/akcit_c4_mini_projeto) para conhecer os prompts de desenvolvimento, a arquitetura, os testes e as instruções de reprodução. Os resultados representam a série selecionada e não constituem uma avaliação de todo o histórico de FIDC.',
 '',
 paste0('A série analisada abrange **',data_legivel(min(as.Date(r$data_competencia))),' a ',data_legivel(max(as.Date(r$data_competencia))),'**. Os valores de patrimônio líquido (PL) abaixo estão em **milhões da unidade da fonte**, arredondados a duas casas decimais. Os valores completos estão no [CSV por competência](resultados/estatisticas/estatisticas_por_competencia.csv) e no [CSV dos top 25](resultados/estatisticas/top25_administradores.csv).'),
 '', '## PL por data de competência','',
 'Estatísticas por DT_COMPTC sobre o PL original, com quantis tipo 7 de R. Fundos/classes e administradores contam CNPJs distintos por data. Administradores da tabela I são associados à IV por CNPJ do fundo/classe e data exata.',
 '', '| Data de competência | Fundos/classes (CNPJs distintos) | Administradores distintos |', '|:---|---:|---:|')
for(i in seq_len(nrow(r))) linhas <- c(linhas,paste0('| ',data_legivel(r$data_competencia[i]),' | ',r$fundos_cnpj[i],' | ',r$quantidade_administradores[i],' |'))
linhas <- c(linhas,'','**Distribuição do PL — valores em milhões**','',
 '| Data de competência | Fundos/classes | PL mínimo | Percentil 25 | Mediana | PL médio | Percentil 75 | PL máximo |',
 '|:---|---:|---:|---:|---:|---:|---:|---:|')
for(i in seq_len(nrow(r))) linhas <- c(linhas,paste0('| ',data_legivel(r$data_competencia[i]),' | ',r$fundos_cnpj[i],' | ',paste(fmt(unlist(r[i,c('pl_min_valor_fonte','pl_percentil_25_valor_fonte','pl_mediana_valor_fonte','pl_media_valor_fonte','pl_percentil_75_valor_fonte','pl_max_valor_fonte')])/1e6),collapse=' | '),' |'))
trimestres <- grep('^pl_[0-9]{4}_T[1-4]$',names(t),value=TRUE)
rotulos <- vapply(trimestres,function(campo) {
  ano <- sub('^pl_([0-9]{4})_T([1-4])$','\\1',campo)
  trimestre <- as.integer(sub('.*_T','',campo))
  mes <- c('março','junho','setembro','dezembro')[trimestre]
  paste0('PL em ',mes,'/',ano)
},character(1))
linhas <- c(linhas,'','## Top 25 administradores por PL','',
 '**Ordenação:** PL acumulado do período, do maior para o menor. Valores de PL em milhões; participação em percentual. A quantidade de fundos/classes conta CNPJs distintos por administrador no período, sem repetir um fundo presente em mais de um mês. Um fundo que muda de administrador pode aparecer na contagem de ambos.','',
 'PL winsorizado antes da soma: valores inferiores ao P2,5 são substituídos pelo P2,5 e superiores ao P97,5 pelo P97,5, calculados separadamente em cada data sobre todos os PLs disponíveis. Os dados originais permanecem preservados. Ranking decrescente pela soma do período; percentual usa a soma winsorizada de todos os administradores, incluindo os fora do top 25. PL ausente é excluído e grupos inteiramente ausentes ficam sem valor.',
 '', 'Cada coluna trimestral é uma posição: soma o PL observado no último mês do trimestre, sem somar os meses anteriores. Essa posição usa os valores originais, sem winsorização; o ranking e a participação usam a soma mensal winsorizada do período completo. Sem observação do administrador naquela competência, o valor fica ausente. Unidade e escala da fonte continuam não confirmadas.',
 '',paste0('| Posição | Administrador | CNPJ do administrador | Fundos/classes no período | ',paste(c(rotulos,'PL acumulado no período','Participação no PL total (%)'),collapse=' | '),' |'),
 paste0('| ',paste(c('---:',':---',':---','---:',rep('---:',length(trimestres)+2)),collapse=' | '),' |'))
for(i in seq_len(nrow(t))) linhas <- c(linhas,paste0('| ',paste(c(i,t$administrador[i],cnpj_legivel(t$cnpj_admin[i]),t$quantidade_fundos[i],fmt(unlist(t[i,c(trimestres,'pl_soma_periodo')])/1e6),fmt(t$percentual_pl_total[i])),collapse=' | '),' |'))
if(nrow(t)>=5L && all(is.finite(t$percentual_pl_total))) {
  top2 <- sum(t$percentual_pl_total[1:2]); top5 <- sum(t$percentual_pl_total[1:5]); top25 <- sum(t$percentual_pl_total)
  linhas <- c(linhas,'','## Breve análise dos top 25','',
    paste0('Os líderes, **',t$administrador[1],'** e **',t$administrador[2],'**, representam ',fmt(t$percentual_pl_total[1]),'% e ',fmt(t$percentual_pl_total[2]),'% do PL winsorizado, respectivamente. Juntos, concentram **',fmt(top2),'%**; os cinco primeiros somam **',fmt(top5),'%**.'),
    '',paste0('Os ',nrow(t),' administradores apresentados reúnem **',fmt(top25),'%** do total, enquanto os demais respondem por ',fmt(100-top25),'%. A concentração nos líderes indica uma distribuição desigual do PL administrado neste recorte.'),
    '', 'As participações descrevem o PL dos fundos/classes associados a cada administrador após winsorização, sem consolidar CNPJs de um mesmo grupo econômico. Não medem patrimônio próprio, rentabilidade ou qualidade do serviço. Os valores de fim de trimestre são posições pontuais e não permitem concluir tendência trimestral; a winsorização reduz a influência das maiores posições mensais individuais.')
}
writeLines(enc2utf8(linhas),'resultados/estatisticas/relatorio_estatisticas.md',useBytes=TRUE)
