# Mini projeto didático CVM em R com IA generativa

Este protótipo foi desenvolvido como projeto da **Especialização em Engenharia de Software: Automação e Inovação com Inteligência Artificial Generativa**, da Universidade Federal de Goiás (UFG). Ele obtém informes mensais de FIDCs da CVM e produz datasets consolidados no tempo por tabela, uma tabela final única (flat) e uma base de cedentes. O desenvolvimento usa R, RStudio, Codex, Git e GitHub, com decisões e revisão humanas.

**[Acesse a página de análises e metadados no GitHub Pages](https://amarallr.github.io/akcit_c4_mini_projeto/)**: descrição do conjunto CVM/FIDC, estatísticas do PL por competência, ranking dos top 25 administradores, análise da concentração e downloads dos CSVs.

O conteúdo também está disponível no [resumo das estatísticas em Markdown](resultados/estatisticas/relatorio_estatisticas.md). A publicação acompanha alterações no resumo e nos CSVs pela [rotina de publicação](.github/workflows/pages.yml). Para gerar a página localmente, execute `powershell -File scripts/publicar_resumo.ps1`.

Há dois caminhos de uso: **reproduzir o desenvolvimento** a partir dos [oito prompts P01–P08](prompts/LEIA_ME.md), gerando os artefatos com IA no próprio ambiente, ou **executar a implementação existente**, abrindo este projeto no RStudio e seguindo os comandos abaixo. As evidências do autor não aprovam automaticamente outra reprodução.

O piloto julho/agosto de 2026 tem referência histórica validada. O incremento atual amplia a seleção analítica para janeiro de 2020–setembro de 2026 e acrescenta P08 para estatísticas e ranking. O [incremento de robustez](documentacao/incremento_robustez.md) documenta validações anteriores e seus limites. O flat continua habilitado por padrão; seleções extensas podem usar o modo temporal para evitar suas 14.749 colunas. P03 permanece exclusivamente documental, sem VM ou teste de instalação.

O documento [Fases do Ciclo de Desenvolvimento de Software SWEBOK](<documentacao/ciclo_desenvolvimento_swebok.md>) relaciona as atividades e evidências do projeto a dez etapas didáticas do ciclo de software. O [DFD](documentacao/arquitetura.md) explica o caminho dos dados e sua relação com os prompts.

## Executar a implementação existente

Instale R e RStudio pelos meios permitidos no seu computador e abra `C4-Mini-projeto.Rproj`. O ambiente registrado usa **R 4.5.1**; `renv.lock` fixa as versões das dependências diretas e transitivas. No console do RStudio, restaure os pacotes antes de executar o pipeline:

```r
source('scripts/p02_dependencias.R')
gerenciar_dependencias('restaurar')
gerenciar_dependencias('verificar')
source('scripts/p01_pipeline_fidc.R')
config <- list(inicio='2020-01-01', fim='2026-09-30',
  dados='dados/atualizacao_2020', saidas='saidas/atualizacao_2020',
  checkpoints='checkpoints/atualizacao_2020', gerar_flat=FALSE,
  atualizar_downloads=TRUE)
executar_pipeline_etapa('P04', config)
executar_pipeline_etapa('P05', config)
executar_pipeline_etapa('P06', config)
system2('Rscript', c('--vanilla','scripts/p08_resumo_dados.R',
                    'dados/atualizacao_2020/configuracao.rds'))
```

A restauração usa `renv` com biblioteca local `.R-library`, sem instalar R ou mudar sua configuração global. Pacotes já disponíveis nas versões fixadas podem ser reutilizados. Não há instalação automática ao abrir o projeto ou carregar o pipeline. A restauração pode acessar CRAN; P04/P05 consultam a CVM pública, sem login. Linux pode precisar das bibliotecas de desenvolvimento de curl/OpenSSL; no Windows, pacotes com código compilado podem exigir Rtools quando não houver binário compatível. [Snapshot e portabilidade sem isolamento](https://pkgs.rstudio.com/renv/reference/snapshot.html), [restauração renv](https://pkgs.rstudio.com/renv/reference/restore.html).

Cada chamada executa somente a etapa indicada. P04 grava a seleção; P05 baixa, valida e extrai; P06 consolida; P08 calcula as estatísticas da geração concluída e atualiza os CSVs e o resumo público. Para o histórico desde 2020, use o comando P08 com a configuração correspondente, após concluir P06.

```powershell
Rscript --vanilla scripts/p07_evidencias.R
Rscript --vanilla scripts/p01_pipeline_fidc.R P07
```

O primeiro comando executa a suíte completa e demonstra interrupção, retomada e repetição em processos R novos, em uma área isolada nova, copiando ZIPs locais validados. Pode levar alguns minutos. O segundo verifica os datasets e as evidências produzidas. A CLI informa o aceite local e mantém a sincronização remota como conferência separada. No console, também é possível chamar `carregar_pipeline('.')$produzir_evidencias_aceite()` depois de carregar os utilitários P02.

Para executar apenas os testes: `Rscript --vanilla scripts/p02_testar.R todas`. A suíte usa fixtures e Git temporário, sem credenciais ou downloads da CVM. O [workflow Windows/Linux](.github/workflows/testes.yml) restaura dependências, executa essa suíte e guarda os resultados como artefatos da CI. Seus resultados são separados das evidências do piloto real; consulte a [página de execuções](https://github.com/amarallr/akcit_c4_mini_projeto/actions).

## Reproduzir o desenvolvimento pelos prompts

Nesse caminho, o ponto de partida são somente os oito prompts e as instruções do leitor. Código, projeto e registros são produzidos progressivamente com IA e revisão humana. A implementação deste repositório é uma referência opcional.

| Prompt | Responsabilidade |
|---|---|
| P01 — Coordenação | Organiza dependências, etapas explícitas e continuidade. |
| P02 — Biblioteca comum | Define caminhos, hashes, escrita validada, políticas, dependências e testes compartilhados. |
| P03 — Ambiente | Entrega o [roteiro documental](prompts/AMBIENTE_DO_ZERO.md); não instala, cria VM ou testa a execução do roteiro. |
| P04 — Configuração | Define período, tabelas, inventário, mapa de campos e plano de obtenção. |
| P05 — Obtenção | Baixa e valida ZIPs, preserva originais, extrai CSVs e mantém manifestos. |
| P06 — Consolidação | Produz temporais, flat opcional, cedentes, checkpoints e relatório de qualidade. |
| P07 — Aceite | Confere entregas e evidências vinculadas à seleção, à geração e ao conteúdo do código. |
| P08 — Estatísticas consolidadas | Calcula estatísticas por competência e top 25 de administradores após P06, documentando método e limites. |

[CO-STAR](prompts/CO_STAR.md) explica a estrutura dos prompts. Catálogo, matriz e registros ficam em `prompts`. P03-RF-006/P03-TST-004 continuam cancelados; diagnósticos e testes históricos de P03 não comprovam a execução do roteiro atual.

## Dados, metadados e estatísticas consolidadas

O conjunto reúne informes mensais públicos de Fundos de Investimento em Direitos Creditórios (FIDC) publicados pela Comissão de Valores Mobiliários. A seleção consolidada desta atualização cobre **81 datas de competência, de 31/01/2020 a 30/09/2026**, com referência de obtenção em 06/10/2026. Ela contém **8.420.840 linhas nas 18 tabelas temporais** e **431.215 registros derivados de cedentes**. O modo temporal preserva cada tabela separadamente e não gera o flat de 14.749 colunas.

| Metadado | Significado neste conjunto |
|---|---|
| Fonte e acesso | Arquivos CSV dos [informes mensais FIDC no catálogo CVM](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal), obtidos das áreas oficiais [DADOS](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/) e [HIST](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/HIST/). O histórico usa pacotes anuais; os dados mais recentes são publicados mensalmente. |
| Período | De 2020-01-01 a 2026-09-30; as estatísticas são agrupadas pela data completa `DT_COMPTC`, não pela data de download. |
| Organização | 18 leiautes: I, II, III, IV, V, VI, VII, VIII, IX, X, X_1, X_1_1 e X_2 a X_7. Cada tabela mantém sua própria granularidade; a tabela VIII também alimenta a extração de cedentes. |
| Dicionário | O [dicionário declarado da CVM](referencias/cvm/dicionario_campos_declarados.csv) contém 455 descrições de campos distribuídas pelos 18 leiautes. O [esquema observado do piloto](referencias/cvm/esquema_observado_piloto.csv) documenta uma comparação específica de julho/agosto de 2026, não garante que todas as colunas existam em todos os anos. |
| Chave de análise | CNPJ normalizado, tipo de registro (`Fundo` ou `Classe`) e `DT_COMPTC`. As tabelas I e IV são associadas por essas três dimensões para evitar misturar registros de fundo e classe que compartilham CNPJ/data. |
| Campos estatísticos | A tabela IV fornece `TAB_IV_A_VL_PL`; a tabela I fornece `CNPJ_ADMIN` e `ADMIN`. O PL continua preservado nos valores e campos originais, junto com arquivo/ZIP/linha de origem e identidade usada na padronização. |
| Formatos | As tabelas consolidadas têm CSV e RDS em diretórios locais ignorados pelo Git. Os CSVs públicos do resumo usam UTF-8, vírgula como separador e ponto decimal; os identificadores devem ser lidos como texto. |
| Limites | A tabela X não consta dos pacotes oficiais de 2020–2022. Os arquivos históricos podem ser revistos pela CVM. A unidade monetária e a escala percentual da fonte não foram confirmadas. O conjunto não representa, por si, avaliação de risco, rentabilidade ou qualidade dos fundos/administradores. |

O P08 gera o [relatório legível](resultados/estatisticas/relatorio_estatisticas.md), o [CSV completo por competência](resultados/estatisticas/estatisticas_por_competencia.csv) e o [ranking dos 25 administradores](resultados/estatisticas/top25_administradores.csv), depois de uma consolidação P06 concluída. Para facilitar a leitura no Pages, as tabelas visíveis mostram apenas outubro–dezembro dos cinco anos completos mais recentes; os CSVs para download mantêm a série integral. Em telas estreitas, as tabelas se reorganizam em cartões, sem barra de rolagem horizontal. Os valores trimestrais representam a soma do PL informado no último mês do trimestre (dezembro nas colunas mostradas), sem somar os meses anteriores. Para reproduzir o resumo desta seleção, execute `Rscript --vanilla scripts/p08_resumo_dados.R dados/atualizacao_2020/configuracao.rds`. As estatísticas descritivas usam `TAB_IV_A_VL_PL`; o ranking e o PL acumulado continuam baseados na soma mensal winsorizada no período. Registros sem administrador identificado ficam nas estatísticas por competência e fora do ranking e de seu denominador. Os valores não representam fluxo financeiro nem patrimônio próprio do administrador.

Os arquivos de referência, documentos e evidências estão organizados em `referencias/`, `documentacao/` e `evidencias/`; os artefatos públicos derivados ficam em `resultados/estatisticas/`. A página Pages explica esses metadados e publica também os dicionários e CSVs. O relatório histórico de aceite continua em [documentacao/aceite_entrega.md](documentacao/aceite_entrega.md) e descreve o piloto anterior, separado desta atualização de 2020–2026.

| Local | Conteúdo |
|---|---|
| `dados/configuracao.rds` | Configuração, inventário e plano |
| `dados/originais`, `dados/extraidos` | ZIPs, CSVs e manifestos de obtenção |
| `checkpoints` | Intermediários e assinaturas por origem/leiaute |
| `saidas/geracoes/<assinatura>` | Datasets e relatório de qualidade da seleção |
| `saidas/atual.rds`, `saidas/execucao.rds` | Referência atual e estado da tentativa mais recente |
| `logs` | Testes, evidências de retomada e métricas |

Localize a geração com `readRDS('saidas/atual.rds')$geracao`, conferindo também o estado concluído em `saidas/execucao.rds`. Dados, saídas e logs ficam locais, fora do Git. CSV usa UTF-8, `;` e decimal `.`; identificadores devem ser importados como texto.

O flat usa CNPJ textual normalizado e competência, preserva a união das chaves e abre detalhes em posições independentes por leiaute. `VIII__VALOR_r0002`, por exemplo, não se relaciona à segunda linha de X_4. As origens permanecem em colunas próprias; não há descarte por completude, agregação financeira ou produto cartesiano.

## Configuração, recuperação e desempenho

Para trabalhar sem flat, use a mesma configuração em todas as etapas e na produção de evidências:

```r
config <- list(inicio='2020-01-01', fim='2026-09-30', gerar_flat=FALSE,
  dados='dados/atualizacao_2020', saidas='saidas/atualizacao_2020',
  checkpoints='checkpoints/atualizacao_2020', atualizar_downloads=TRUE)
executar_pipeline_etapa('P04', config)
executar_pipeline_etapa('P05', config)
executar_pipeline_etapa('P06', config)
system2('Rscript', c('--vanilla','scripts/p08_resumo_dados.R',
                    'dados/atualizacao_2020/configuracao.rds'))
```

No terminal: `Rscript --vanilla scripts/p07_evidencias.R dados/config_temporal.rds` e `Rscript --vanilla scripts/p01_pipeline_fidc.R P07 dados/config_temporal.rds`. O padrão inclui 18 leiautes I–X e subdivisões de X, checkpoints TRUE, atualização FALSE e força FALSE. Datas inclusivas filtram `DT_COMPTC`; mudar período/tabelas exige nova seleção P04/P05. P06 valida vínculo e completude do plano também nas chamadas diretas; entradas ausentes/extras/duplicadas ou incompatíveis orientam executar P05. Tabelas vazias presentes podem ser preservadas; seleção inteira sem registros fica pendente de aceite.

Checkpoints FALSE refaz a transformação; atualizar TRUE obtém novamente os ZIPs e reaproveita intermediários se o conteúdo for igual; forçar TRUE refaz ambos. Manifestos sempre persistem. A versão padrão da transformação é `fidc-v2`. O hash automático da lógica relevante também invalida checkpoints incompatíveis; a versão continua como informação legível; saídas são reconstruídas da seleção, sem append.

Rollback válido é restaurado conservadoramente, preservando o destino interrompido em outro arquivo. RDS corrompido é preservado para diagnóstico e exige reconstrução. Falhas preservam a última geração concluída em atual.rds; execucao.rds e tentativas/<id>.rds identificam a tentativa recente e impedem anúncio de sucesso atual. P04/P05 terminam como etapa_concluida, sem anunciar dados prontos. Estado em_processamento sem fim identifica tentativa não finalizada após encerramento abrupto. Um rollback inválido ou arquivo bloqueado interrompe a operação para revisão. Windows/OneDrive não oferecem transação conjunta entre arquivos.

`qualidade.csv` registra, por tabela/competência, campos novos/ausentes, multiplicidades, repetições integrais, formato/DV dos identificadores e problemas de conversão. Conversões inválidas geram `saidas/qualidade_falha.csv` antes da interrupção. DV não confirma cadastro ou titularidade; identificadores alfanuméricos ficam preservados sem homologação cadastral.

Para medir com entradas locais: `Rscript --vanilla scripts/p06_medir.R`. O comando compara temporal e completo, termina no modo completo e grava `logs/comparacao_desempenho.csv`. [DESEMPENHO](documentacao/desempenho.md) descreve método, medidas e limites. `exportar_parquet=TRUE` acrescenta Parquet somente se `arrow` estiver instalado; CSV/RDS continuam obrigatórios. Arrow não integra o lockfile obrigatório e sua versão deve ser registrada na avaliação opcional. [Documentação oficial do formato](https://arrow.apache.org/docs/r/reference/write_parquet.html).

## Exemplo de análise e limites

Consulte o estado concluído e analise uma tabela temporal, evitando carregar o flat inteiro:

```r
.libPaths(c(normalizePath('.R-library'), .libPaths()))
atual <- readRDS('saidas/atual.rds')
stopifnot(atual$estado == 'concluido')
execucao <- readRDS('saidas/execucao.rds')
stopifnot(execucao$estado == 'concluido', execucao$etapa == 'P06',
          execucao$assinatura == atual$assinatura,
          execucao$assinatura_plano == atual$assinatura_plano)
iv <- data.table::fread(file.path(atual$geracao, 'inf_mensal_fidc_tab_IV.csv'),
                       sep=';', colClasses=c(cnpj='character'))
iv[, .(registros=.N, fundos_classes=data.table::uniqueN(cnpj),
       pl_total_na_unidade_da_fonte=sum(TAB_IV_A_VL_PL, na.rm=TRUE)), by=dt_comptc]
```

Esse exemplo usa aritmética numérica de R para exploração; o resumo publicado conserva a representação decimal original. Não somar posições de competências distintas como fluxo financeiro. O piloto não homologa todo o histórico CVM ou mudanças de fundo/classe/subclasse. O flat é largo e esparso, com CSV de aproximadamente 245 MB; prefira temporais/RDS para análise e avalie memória antes de ampliar o período.

Fontes oficiais: [catálogo CVM](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal), [DADOS](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/), [HIST](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/HIST/) e [dicionário](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/meta_inf_mensal_fidc_txt.zip). O esquema observado está em [referencias/cvm/esquema_observado_piloto.csv](referencias/cvm/esquema_observado_piloto.csv). Unidade/escala não é confirmada por valores plausíveis ou fontes secundárias.

Erros comuns são pacote ausente, execução fora da raiz, ZIP inválido, configuração divergente e arquivo bloqueado no OneDrive. Consulte estado, diagnóstico e manifestos; não apague uma versão válida para resolver a falha. [CONTRIBUICAO](documentacao/como_contribuir.md) orienta alterações e informa que o repositório ainda não declara licença de distribuição. [RETOMADA](documentacao/retomada.md) registra a situação, e [PUBLICACAO](documentacao/publicacao.md) explica o fechamento do versão de referência.

O prompt [P08](prompts/08_prompt_estatisticas_consolidadas.txt) especifica as estatísticas e o ranking derivados de uma geração P06. O resumo discrimina cada data de competência e conta fundos e administradores por CNPJ. O ranking acumulado winsoriza PL em 2,5%/97,5%; as colunas trimestrais representam o PL observado no último mês de cada trimestre. O CSV guarda valores integrais; a página apresenta milhões da unidade fonte, que continua não confirmada. Para reproduzir após P06:

```powershell
Rscript --vanilla scripts/p08_resumo_dados.R dados/atualizacao_2020/configuracao.rds
```

Datasets permanecem intactos. O período da análise é o definido na configuração passada ao P08; trimestres de ponta podem estar incompletos. P08 não interpreta soma de posições mensais como fluxo financeiro ou PL de encerramento.
