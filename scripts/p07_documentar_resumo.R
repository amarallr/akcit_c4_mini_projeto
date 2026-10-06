r <- read.csv('P07_RESUMO_COMPETENCIAS.csv')
t <- read.csv('P07_TOP25_ADMINISTRADORES.csv',colClasses=c(cnpj_admin='character'))
t <- t[order(-t$pl_soma_periodo,t$cnpj_admin,na.last=TRUE),]
fmt <- function(x) formatC(x,format='f',digits=2,big.mark='.',decimal.mark=',')
data_legivel <- function(x) format(as.Date(x),'%d/%m/%Y')
cnpj_legivel <- function(x) ifelse(grepl('^[0-9]{14}$',x),sub('^(.{2})(.{3})(.{3})(.{4})(.{2})$','\\1.\\2.\\3/\\4-\\5',x),x)
linhas <- c('# Estatísticas e administradores do piloto','',
 'O piloto abrange julho e agosto de 2026. Os valores de patrimônio líquido (PL) abaixo estão em **milhões da unidade da fonte**, arredondados a duas casas decimais. Os valores completos estão no [CSV por competência](P07_RESUMO_COMPETENCIAS.csv) e no [CSV dos top 25](P07_TOP25_ADMINISTRADORES.csv).',
 '', '## PL por data de competência','',
 'Estatísticas por DT_COMPTC sobre o PL original, com quantis tipo 7 de R. Administradores distintos pelo CNPJ da tabela I, associado à IV por CNPJ do fundo/classe e data exata.',
 '', '| Data de competência | Administradores distintos |', '|:---|---:|')
for(i in seq_len(nrow(r))) linhas <- c(linhas,paste0('| ',data_legivel(r$data_competencia[i]),' | ',r$quantidade_administradores[i],' |'))
linhas <- c(linhas,'','**Distribuição do PL — valores em milhões**','',
 '| Data de competência | PL mínimo | Percentil 25 | Mediana | PL médio | Percentil 75 | PL máximo |',
 '|:---|---:|---:|---:|---:|---:|---:|')
for(i in seq_len(nrow(r))) linhas <- c(linhas,paste0('| ',data_legivel(r$data_competencia[i]),' | ',paste(fmt(unlist(r[i,c('pl_min_valor_fonte','pl_percentil_25_valor_fonte','pl_mediana_valor_fonte','pl_media_valor_fonte','pl_percentil_75_valor_fonte','pl_max_valor_fonte')])/1e6),collapse=' | '),' |'))
trimestres <- grep('^pl_[0-9]{4}_T[1-4]$',names(t),value=TRUE)
rotulos <- sub('^pl_([0-9]{4})_T([1-4])$','PL — \\2º trim./\\1',trimestres)
linhas <- c(linhas,'','## Top 25 administradores por PL','',
 '**Ordenação:** PL acumulado do período, do maior para o menor. Valores de PL em milhões; participação em percentual.','',
 'PL winsorizado antes da soma: valores inferiores ao P2,5 são substituídos pelo P2,5 e superiores ao P97,5 pelo P97,5, calculados separadamente em cada data sobre todos os PLs disponíveis. Os dados originais permanecem preservados. Ranking decrescente pela soma do período; percentual usa a soma winsorizada de todos os administradores, incluindo os fora do top 25. PL ausente é excluído e grupos inteiramente ausentes ficam sem valor.',
 '', 'O piloto contém somente julho e agosto de 2026: 2026_T3 é parcial. A soma de posições mensais atende à agregação solicitada e não representa fluxo financeiro nem PL de encerramento trimestral. Unidade e escala da fonte continuam não confirmadas.',
 '',paste0('| Posição | Administrador | CNPJ do administrador | ',paste(c(rotulos,'PL acumulado no período','Participação no PL total (%)'),collapse=' | '),' |'),
 paste0('| ',paste(c('---:',':---',':---',rep('---:',length(trimestres)+2)),collapse=' | '),' |'))
for(i in seq_len(nrow(t))) linhas <- c(linhas,paste0('| ',paste(c(i,t$administrador[i],cnpj_legivel(t$cnpj_admin[i]),fmt(unlist(t[i,c(trimestres,'pl_soma_periodo')])/1e6),fmt(t$percentual_pl_total[i])),collapse=' | '),' |'))
if(nrow(t)>=5L && all(is.finite(t$percentual_pl_total))) {
  top2 <- sum(t$percentual_pl_total[1:2]); top5 <- sum(t$percentual_pl_total[1:5]); top25 <- sum(t$percentual_pl_total)
  linhas <- c(linhas,'','## Breve análise dos top 25','',
    paste0('Os líderes, **',t$administrador[1],'** e **',t$administrador[2],'**, representam ',fmt(t$percentual_pl_total[1]),'% e ',fmt(t$percentual_pl_total[2]),'% do PL winsorizado, respectivamente. Juntos, concentram **',fmt(top2),'%**; os cinco primeiros somam **',fmt(top5),'%**.'),
    '',paste0('Os ',nrow(t),' administradores apresentados reúnem **',fmt(top25),'%** do total, enquanto os demais respondem por ',fmt(100-top25),'%. A concentração nos líderes indica uma distribuição desigual do PL administrado neste recorte.'),
    '', 'As participações descrevem o PL dos fundos/classes associados a cada administrador após winsorização, sem consolidar CNPJs de um mesmo grupo econômico. Não medem patrimônio próprio, rentabilidade ou qualidade do serviço. Os dois meses do mesmo trimestre não permitem concluir uma tendência trimestral; a winsorização reduz a influência das maiores posições individuais.')
}
writeLines(enc2utf8(linhas),'RESUMO_DADOS.md',useBytes=TRUE)
