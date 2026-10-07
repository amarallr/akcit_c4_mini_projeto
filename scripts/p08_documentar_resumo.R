documentar_resumo_dados_fidc <- function() {
r <- read.csv('resultados/estatisticas/estatisticas_por_competencia.csv')
t <- read.csv('resultados/estatisticas/top25_administradores.csv',colClasses=c(cnpj_admin='character'))
t <- t[order(-t$pl_soma_periodo,t$cnpj_admin,na.last=TRUE),]
fmt <- function(x) formatC(x,format='f',digits=2,big.mark='.',decimal.mark=',')
data_legivel <- function(x) format(as.Date(x),'%d/%m/%Y')
data_geracao <- format(Sys.Date(),'%d/%m/%Y')
ultima_data <- max(as.Date(r$data_competencia))
ultimo_ano_completo <- as.integer(format(ultima_data,'%Y')) - as.integer(format(ultima_data,'%m') != '12')
anos_exibidos <- seq.int(ultimo_ano_completo - 4L,ultimo_ano_completo)
ano_competencia <- as.integer(format(as.Date(r$data_competencia),'%Y'))
mes_competencia <- as.integer(format(as.Date(r$data_competencia),'%m'))
linhas_temporais <- sum(atual$linhas_tabelas)
linhas_cedentes <- atual$linhas_cedentes
campos_declarados <- nrow(read.csv('referencias/cvm/dicionario_campos_declarados.csv',stringsAsFactors=FALSE,fileEncoding='UTF-8'))
cnpj_legivel <- function(x) ifelse(grepl('^[0-9]{14}$',x),sub('^(.{2})(.{3})(.{3})(.{4})(.{2})$','\\1.\\2.\\3/\\4-\\5',x),x)
linhas <- c('# Estatísticas dos FIDC','',
 'Esta página apresenta os resultados de um **mini projeto didático da Especialização em Engenharia de Software: Automação e Inovação com Inteligência Artificial Generativa, da Universidade Federal de Goiás (UFG)**. O projeto utiliza dados públicos dos informes mensais de Fundos de Investimento em Direitos Creditórios (FIDC) da Comissão de Valores Mobiliários (CVM) para exercitar o ciclo de desenvolvimento de software: configuração das fontes, obtenção dos dados, consolidação, testes e documentação.',
 '', 'A implementação foi desenvolvida em R, com RStudio, apoio de IA generativa por meio do Codex e controle de versões com Git e GitHub, sob decisões e revisão humanas. O pipeline reúne tabelas históricas por competência, uma base consolidada e dados de cedentes. As estatísticas e o ranking abaixo demonstram uma aplicação analítica dos dados produzidos pela seleção.',
 '', 'Consulte o [repositório do projeto](https://github.com/amarallr/akcit_c4_mini_projeto) para conhecer os prompts de desenvolvimento, a arquitetura, os testes e as instruções de reprodução. Os resultados representam a série selecionada e não constituem uma avaliação de todo o histórico de FIDC.',
 '',
 paste0('A série analisada abrange **',data_legivel(min(as.Date(r$data_competencia))),' a ',data_legivel(max(as.Date(r$data_competencia))),'**. Os valores de patrimônio líquido (PL) abaixo estão em **milhões da unidade da fonte**, arredondados a duas casas decimais. Os valores completos estão no [CSV por competência](estatisticas_por_competencia.csv) e no [CSV dos top 25](top25_administradores.csv).'),
 '', '## Metadados do conjunto de dados',
 '', '| Propriedade | Descrição |', '|:---|:---|',
 '| Fonte | Informes mensais de FIDC da CVM, arquivos históricos anuais e arquivos mensais publicados para 2025–2026. |',
 paste0('| Captura desta geração | ',data_geracao,'; a CVM pode atualizar arquivos históricos posteriormente. |'),
 paste0('| Cobertura desta geração | ',nrow(r),' datas de competência, de ',format(min(as.Date(r$data_competencia)),'%m/%Y'),' a ',format(max(as.Date(r$data_competencia)),'%m/%Y'),'; a competência é `DT_COMPTC`. |'),
 paste0('| Volume consolidado | ',format(linhas_temporais,big.mark='.',decimal.mark=','),' linhas nas 18 tabelas temporais e ',format(linhas_cedentes,big.mark='.',decimal.mark=','),' registros derivados de cedentes. |'),
 '| Organização | 18 tabelas temporais (I–X e subdivisões X_1, X_1_1 e X_2–X_7), consolidadas separadamente; modo temporal, sem tabela flat. |',
 paste0('| Esquema declarado | ',campos_declarados,' descrições de campos no dicionário da CVM. Consulte o [dicionário de campos](../../referencias/cvm/dicionario_campos_declarados.csv) e o [esquema observado do piloto](../../referencias/cvm/esquema_observado_piloto.csv). |'),
 '| Chaves analíticas | CNPJ normalizado, tipo `Fundo`/`Classe` e data de competência. I e IV são associadas por essas três dimensões. |',
 '| Campos usados nas estatísticas | IV: `TAB_IV_A_VL_PL`; I: `CNPJ_ADMIN` e `ADMIN`; IV: `TP_FUNDO_CLASSE`. |',
 '| Linhagem | As tabelas mantêm CNPJ e valores originais, nome do CSV e ZIP de origem, linha de origem e campo de identidade usado. |',
 '| Limites conhecidos | A tabela X não está presente nos pacotes históricos de 2020–2022. A CVM pode revisar arquivos; unidade monetária e escala percentual não foram confirmadas. |',
 '', 'Esta descrição se refere à geração consolidada deste relatório. O dicionário declara o leiaute; o esquema observado do piloto é uma evidência de julho/agosto de 2026, não uma afirmação de esquema idêntico em todas as competências.',
 '', '## PL por data de competência','',
 paste0('As tabelas exibem somente as competências do quarto trimestre nos cinco anos completos mais recentes (',min(anos_exibidos),'–',max(anos_exibidos),'). As séries completas continuam disponíveis nos CSVs para download. Estatísticas por DT_COMPTC sobre o PL original, com quantis tipo 7 de R. Fundos/classes e administradores contam CNPJs distintos por data. A associação entre as tabelas I e IV usa CNPJ, tipo (fundo/classe) e data exata.'),
 '', '| Data de competência | Fundos/classes (CNPJs distintos) | Administradores distintos |', '|:---|---:|---:|')
indices_exibidos <- which(ano_competencia %in% anos_exibidos & mes_competencia %in% 10:12)
for(i in indices_exibidos) linhas <- c(linhas,paste0('| ',data_legivel(r$data_competencia[i]),' | ',r$fundos_cnpj[i],' | ',r$quantidade_administradores[i],' |'))
linhas <- c(linhas,'','**Distribuição do PL — valores em milhões**','',
 '| Data de competência | Fundos/classes | PL mínimo | Percentil 25 | Mediana | PL médio | Percentil 75 | PL máximo |',
 '|:---|---:|---:|---:|---:|---:|---:|---:|')
for(i in indices_exibidos) linhas <- c(linhas,paste0('| ',data_legivel(r$data_competencia[i]),' | ',r$fundos_cnpj[i],' | ',paste(fmt(unlist(r[i,c('pl_min_valor_fonte','pl_percentil_25_valor_fonte','pl_mediana_valor_fonte','pl_media_valor_fonte','pl_percentil_75_valor_fonte','pl_max_valor_fonte')])/1e6),collapse=' | '),' |'))
trimestres <- intersect(paste0('pl_',anos_exibidos,'_T4'),names(t))
rotulos <- vapply(trimestres,function(campo) {
  ano <- sub('^pl_([0-9]{4})_T([1-4])$','\\1',campo)
  paste0('PL em dezembro/',ano)
},character(1))
linhas <- c(linhas,'','## Top 25 administradores por PL','',
 '**Ordenação:** PL acumulado do período, do maior para o menor. Valores de PL em milhões; participação em percentual. A quantidade de fundos/classes conta CNPJs distintos por administrador no período, sem repetir um fundo presente em mais de um mês. Um fundo que muda de administrador pode aparecer na contagem de ambos.','',
 'PL winsorizado antes da soma usada para ordenar o ranking: valores inferiores ao P2,5 são substituídos pelo P2,5 e superiores ao P97,5 pelo P97,5, calculados separadamente em cada data sobre todos os PLs disponíveis. Os dados originais permanecem preservados. A ordenação e o PL acumulado consideram todo o período; as colunas trimestrais mostram, sem winsorização, a soma do PL observado no último mês de cada trimestre (na tabela visível, dezembro dos cinco anos completos mais recentes). A associação usa o administrador vigente nessa competência; sem observação de PL do administrador na data, o valor fica ausente. Percentual usa a soma winsorizada dos administradores identificados, incluindo os fora do top 25. PL ausente é excluído e grupos inteiramente ausentes ficam sem valor. Registros sem administrador identificado permanecem nas estatísticas por competência, mas não entram no ranking nem em seu denominador.',
 paste0('Repetições com a mesma chave, PL e administrador foram contadas uma vez (IV: ',iv_dedup$removidas,'; I: ',i_dedup$removidas,'). Registros repetidos com valores conflitantes interrompem a geração para revisão.'),
 '', 'Cada coluna trimestral é uma posição: soma o PL dos registros da competência do último mês do trimestre, sem somar os meses anteriores. O ranking e a participação continuam calculados pela soma mensal winsorizada de todo o período. Unidade monetária e escala da fonte continuam não confirmadas.',
 '',paste0('| Posição | Administrador | CNPJ do administrador | Fundos/classes no período | ',paste(c(rotulos,'PL acumulado no período','Participação no PL total (%)'),collapse=' | '),' |'),
 paste0('| ',paste(c('---:',':---',':---','---:',rep('---:',length(trimestres)+2)),collapse=' | '),' |'))
for(i in seq_len(nrow(t))) linhas <- c(linhas,paste0('| ',paste(c(i,t$administrador[i],cnpj_legivel(t$cnpj_admin[i]),t$quantidade_fundos[i],fmt(unlist(t[i,c(trimestres,'pl_soma_periodo')])/1e6),fmt(t$percentual_pl_total[i])),collapse=' | '),' |'))
if(nrow(t)>=5L && all(is.finite(t$percentual_pl_total))) {
  top2 <- sum(t$percentual_pl_total[1:2]); top5 <- sum(t$percentual_pl_total[1:5]); top25 <- sum(t$percentual_pl_total)
  linhas <- c(linhas,'','## Breve análise dos top 25','',
    paste0('Os líderes, **',t$administrador[1],'** e **',t$administrador[2],'**, representam ',fmt(t$percentual_pl_total[1]),'% e ',fmt(t$percentual_pl_total[2]),'% do PL winsorizado, respectivamente. Juntos, concentram **',fmt(top2),'%**; os cinco primeiros somam **',fmt(top5),'%**.'),
    '',paste0('Os ',nrow(t),' administradores apresentados reúnem **',fmt(top25),'%** do total, enquanto os demais respondem por ',fmt(100-top25),'%. A concentração nos líderes indica uma distribuição desigual do PL administrado neste recorte.'),
    '', 'As participações descrevem o PL dos fundos/classes associados a cada administrador após winsorização, sem consolidar CNPJs de um mesmo grupo econômico. Não medem patrimônio próprio, rentabilidade ou qualidade do serviço. As posições de dezembro não permitem concluir uma tendência trimestral; a winsorização usada no ranking reduz a influência das maiores posições mensais individuais.')
}
writeLines(enc2utf8(linhas),'resultados/estatisticas/relatorio_estatisticas.md',useBytes=TRUE)
invisible('resultados/estatisticas/relatorio_estatisticas.md')
}
