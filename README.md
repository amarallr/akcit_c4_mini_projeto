# Mini projeto didático CVM em R com IA generativa

Este protótipo da Especialização em Engenharia de Software com IA Generativa obtém informes mensais de FIDCs da CVM e produz datasets consolidados no tempo por tabela, uma tabela final única (flat) e uma base de cedentes. O desenvolvimento usa R, RStudio, Codex, Git e GitHub, com decisões e revisão humanas.

Há dois caminhos de uso: **reproduzir o desenvolvimento** a partir dos [sete prompts P01–P07](prompts/LEIA_ME.md), gerando os artefatos com IA no próprio ambiente, ou **executar a implementação existente**, abrindo este projeto no RStudio e seguindo os comandos abaixo. As evidências do autor não aprovam automaticamente outra reprodução.

O piloto julho/agosto de 2026 está validado. Esta revisão acrescenta dependências fixadas, testes em CI, recuperação de arquivos interrompidos, relatório de qualidade, medições e evidências automáticas de aceite. O flat continua habilitado por padrão; o modo temporal permite trabalhar com tabelas e cedentes sem montar suas 14.749 colunas. P03 permanece exclusivamente documental, sem VM ou teste de instalação.

O documento [Fases do Ciclo de Desenvolvimento de Software SWEBOK](<Fases do Ciclo de Desenvolvimento de Software SWEBOK.md>) relaciona as atividades e evidências do projeto a dez etapas didáticas do ciclo de software. O [DFD](ARQUITETURA.md) explica o caminho dos dados e sua relação com os prompts.

## Executar a implementação existente

Instale R e RStudio pelos meios permitidos no seu computador e abra `C4-Mini-projeto.Rproj`. O ambiente registrado usa **R 4.5.1**; `renv.lock` fixa as versões das dependências diretas e transitivas. No console do RStudio, restaure os pacotes antes de executar o pipeline:

```r
source('scripts/p02_dependencias.R')
gerenciar_dependencias('restaurar')
gerenciar_dependencias('verificar')
source('scripts/p01_pipeline_fidc.R')
executar_pipeline_etapa('P04')
executar_pipeline_etapa('P05')
executar_pipeline_etapa('P06')
```

A restauração usa `renv` com biblioteca local `.R-library`, sem instalar R ou mudar sua configuração global. Pacotes já disponíveis nas versões fixadas podem ser reutilizados. Não há instalação automática ao abrir o projeto ou carregar o pipeline. A restauração pode acessar CRAN; P04/P05 consultam a CVM pública, sem login. Linux pode precisar das bibliotecas de desenvolvimento de curl/OpenSSL; no Windows, pacotes com código compilado podem exigir Rtools quando não houver binário compatível. [Snapshot e portabilidade sem isolamento](https://pkgs.rstudio.com/renv/reference/snapshot.html), [restauração renv](https://pkgs.rstudio.com/renv/reference/restore.html).

Cada chamada executa somente a etapa indicada. P04 grava a seleção; P05 baixa, valida e extrai; P06 consolida. Depois, no terminal do RStudio, na raiz do projeto:

```powershell
Rscript --vanilla scripts/p07_evidencias.R
Rscript --vanilla scripts/p01_pipeline_fidc.R P07
```

O primeiro comando executa a suíte completa e demonstra interrupção, retomada e repetição em processos R novos, usando os downloads locais. Pode levar alguns minutos. O segundo verifica os datasets e as evidências produzidas. A CLI informa o aceite local e mantém a sincronização remota como conferência separada. No console, também é possível chamar `carregar_pipeline('.')$produzir_evidencias_aceite()` depois de carregar os utilitários P02.

Para executar apenas os testes: `Rscript --vanilla scripts/p02_testar.R todas`. A suíte usa fixtures e Git temporário, sem credenciais ou downloads da CVM. O [workflow Windows/Linux](.github/workflows/testes.yml) restaura dependências, executa essa suíte e guarda os resultados como artefatos da CI. Seus resultados são separados das evidências do piloto real; consulte a [página de execuções](https://github.com/amarallr/akcit_c4_mini_projeto/actions).

## Reproduzir o desenvolvimento pelos prompts

Nesse caminho, o ponto de partida são somente os sete prompts e as instruções do leitor. Código, projeto e registros são produzidos progressivamente com IA e revisão humana. A implementação deste repositório é uma referência opcional.

| Prompt | Responsabilidade |
|---|---|
| P01 — Coordenação | Organiza dependências, etapas explícitas e continuidade. |
| P02 — Biblioteca comum | Define caminhos, hashes, escrita validada, políticas, dependências e testes compartilhados. |
| P03 — Ambiente | Entrega o [roteiro documental](prompts/AMBIENTE_DO_ZERO.md); não instala, cria VM ou testa a execução do roteiro. |
| P04 — Configuração | Define período, tabelas, inventário, mapa de campos e plano de obtenção. |
| P05 — Obtenção | Baixa e valida ZIPs, preserva originais, extrai CSVs e mantém manifestos. |
| P06 — Consolidação | Produz temporais, flat opcional, cedentes, checkpoints e relatório de qualidade. |
| P07 — Aceite | Confere entregas e evidências vinculadas à seleção, à geração e ao conteúdo do código. |

[CO-STAR](prompts/CO_STAR.md) explica a estrutura dos prompts. Catálogo, matriz e registros ficam em `prompts`. P03-RF-006/P03-TST-004 continuam cancelados; diagnósticos e testes históricos de P03 não comprovam a execução do roteiro atual.

## Saídas e resumo do piloto

O modo completo entrega **18 datasets temporais + flat + cedentes**, cada um em CSV e RDS: **40 arquivos de dados**, além de `qualidade.csv`, `qualidade.rds` e manifestos. O modo temporal entrega os 18 temporais e cedentes, em **38 arquivos de dados**, com os mesmos relatórios; seu aceite é específico desse modo e não substitui o aceite do piloto completo.

| Competência | Registros nas 18 tabelas | Registros no flat | Fundos/classes por CNPJ | PL total — unidade da fonte |
|---|---:|---:|---:|---:|
| Julho/2026 | 189.577 | 4.386 | 4.386 | 1.015.421.915.561,51 |
| Agosto/2026 | 192.875 | 4.397 | 4.397 | 989.154.738.500,71 |

No período são 382.452 linhas temporais, 8.783 pares CNPJ/competência no flat e 4.493 CNPJs distintos. “Fundos” é a contagem operacional dos CNPJs informados como fundo/classe, sem presumir equivalência cadastral. O PL soma `TAB_IV_A_VL_PL` uma vez por chave da tabela IV. Unidade monetária e escala percentual permanecem **não confirmadas**; os valores originais são preservados. Veja [resumo mensal](P07_RESUMO_COMPETENCIAS.csv), [contagens por tabela](P07_RESUMO_TABELAS.csv) e [relatório de aceite](P07_ACEITE_ENTREGA.md).

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
config <- list(inicio='2026-07-01', fim='2026-08-31', gerar_flat=FALSE)
saveRDS(config, 'dados/config_temporal.rds')
executar_pipeline_etapa('P04', config)
executar_pipeline_etapa('P05', config)
executar_pipeline_etapa('P06', config)
```

No terminal: `Rscript --vanilla scripts/p07_evidencias.R dados/config_temporal.rds` e `Rscript --vanilla scripts/p01_pipeline_fidc.R P07 dados/config_temporal.rds`. O padrão inclui 18 leiautes I–X e subdivisões de X, checkpoints TRUE, atualização FALSE e força FALSE. Datas inclusivas filtram `DT_COMPTC`; mudar período/tabelas exige nova seleção P04/P05.

Checkpoints FALSE refaz a transformação; atualizar TRUE obtém novamente os ZIPs e reaproveita intermediários se o conteúdo for igual; forçar TRUE refaz ambos. Manifestos sempre persistem. A versão padrão da transformação é `fidc-v2`. Novas mudanças de lógica devem alterar essa versão; saídas são reconstruídas da seleção, sem append.

Rollback válido é restaurado conservadoramente, preservando o destino interrompido em outro arquivo. RDS corrompido é preservado para diagnóstico e exige reconstrução. Falhas mantêm as gerações anteriores em disco, mas o estado da execução impede apresentá-las como sucesso atual. Um rollback inválido ou arquivo bloqueado interrompe a operação para revisão. Windows/OneDrive não oferecem transação conjunta entre arquivos.

`qualidade.csv` registra, por tabela/competência, campos novos/ausentes, multiplicidades, repetições integrais, formato/DV dos identificadores e problemas de conversão. Conversões inválidas geram `saidas/qualidade_falha.csv` antes da interrupção. DV não confirma cadastro ou titularidade; identificadores alfanuméricos ficam preservados sem homologação cadastral.

Para medir com entradas locais: `Rscript --vanilla scripts/p06_medir.R`. O comando compara temporal e completo, termina no modo completo e grava `logs/comparacao_desempenho.csv`. [DESEMPENHO](DESEMPENHO.md) descreve método, medidas e limites. `exportar_parquet=TRUE` acrescenta Parquet somente se `arrow` estiver instalado; CSV/RDS continuam obrigatórios. Arrow não integra o lockfile obrigatório e sua versão deve ser registrada na avaliação opcional. [Documentação oficial do formato](https://arrow.apache.org/docs/r/reference/write_parquet.html).

## Exemplo de análise e limites

Consulte o estado concluído e analise uma tabela temporal, evitando carregar o flat inteiro:

```r
.libPaths(c(normalizePath('.R-library'), .libPaths()))
atual <- readRDS('saidas/atual.rds')
stopifnot(atual$estado == 'concluido')
execucao <- readRDS('saidas/execucao.rds')
stopifnot(execucao$estado == 'concluido', execucao$assinatura == atual$assinatura)
iv <- data.table::fread(file.path(atual$geracao, 'inf_mensal_fidc_tab_IV.csv'),
                       sep=';', colClasses=c(cnpj='character'))
iv[, .(registros=.N, fundos_classes=data.table::uniqueN(cnpj),
       pl_total_na_unidade_da_fonte=sum(TAB_IV_A_VL_PL, na.rm=TRUE)), by=dt_comptc]
```

Esse exemplo usa aritmética numérica de R para exploração; o resumo publicado conserva a representação decimal original. Não somar posições de competências distintas como fluxo financeiro. O piloto não homologa todo o histórico CVM ou mudanças de fundo/classe/subclasse. O flat é largo e esparso, com CSV de aproximadamente 245 MB; prefira temporais/RDS para análise e avalie memória antes de ampliar o período.

Fontes oficiais: [catálogo CVM](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal), [DADOS](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/), [HIST](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/HIST/) e [dicionário](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/meta_inf_mensal_fidc_txt.zip). O esquema observado está em [P04_ESQUEMA_OBSERVADO_PILOTO.csv](P04_ESQUEMA_OBSERVADO_PILOTO.csv). Unidade/escala não é confirmada por valores plausíveis ou fontes secundárias.

Erros comuns são pacote ausente, execução fora da raiz, ZIP inválido, configuração divergente e arquivo bloqueado no OneDrive. Consulte estado, diagnóstico e manifestos; não apague uma versão válida para resolver a falha. [CONTRIBUICAO](CONTRIBUICAO.md) orienta alterações e informa que o repositório ainda não declara licença de distribuição. [RETOMADA](RETOMADA.md) registra a situação, e [PUBLICACAO](PUBLICACAO.md) explica o fechamento do versão de referência.
