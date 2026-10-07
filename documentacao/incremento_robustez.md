# Incremento de robustez — 02/10/2026

Referência: `ddd8b1e5a342c8692e17b137eced3dd0cf35d0bd`. A árvore local estava limpa e no próprio commit de referência. A implementação e os testes foram conduzidos com Codex; a revisão humana da entrega permanece distinguida das verificações automáticas.

## Achados e correções

| Achado | Classificação | Correção e evidência |
|---|---|---|
| P06 concluía com uma das duas unidades ausente | Reproduzido com código do commit de referência, fixture isolada | Plano canônico, assinatura e igualdade das unidades em chamada direta e CLI; P04-TST-005 |
| Alterar função de leitura não invalidava checkpoint | Reproduzido na referência | Assinatura dos corpos/argumentos relevantes, mapa por tabela e versão legível; P06-TST-013 |
| Modo temporal aceitava chave vazia | Reproduzido na referência | Identidade, datas, esquemas e contagens CSV/RDS nos dois modos; P07-TST-007 |
| Produtor usava checkpoints/saídas normais, podia interromper após reutilização | Confirmado por revisão do fluxo original; inferência de risco sobre dados do usuário | Área nova por demonstração, ZIPs copiados e checkpoint inicialmente ausente; P07-TST-008 executa processos reais |
| Retomada exigia reutilização mesmo com política que a desabilita | Confirmado por revisão do validador original | Execução da política solicitada separada da demonstração com checkpoints habilitados; 16 combinações de políticas/modos |
| P04/P05 encerravam deixando marcador ativo | Confirmado por revisão dos retornos originais | `etapa_concluida`, tentativas por ID, início/fim/configuração/plano e motivo; P02-TST-013/P01-TST-002 |
| Prompts continham implementação futura, quatro diagramas e resultados antigos | Confirmado por revisão textual | Regras comuns em P02, contratos específicos preservados, versões substituídas em `prompts/historico/2026-10-02-antes-robustez` |

Mensal/anual é uma escolha intencional: um ZIP anual pode cobrir a seleção inteira e é filtrado por `DT_COMPTC`; a sobreposição de unidades é rejeitada. Multiplicidades temporais legítimas permanecem preservadas. Uma tabela presente sem linhas não significa download ausente. Uma seleção inteira sem registros mantém os arquivos temporais, mas fica com aceite pendente; uma seleção incompleta nunca recebe aceite integral.

## Comportamento final

P04 assina período, tabelas e unidades canônicas, sem depender da ordem dos registros. P05 vincula os resultados ao plano. P06 consulta o plano persistido, inclusive quando chamado por medições ou pelo produtor de evidências. Download ausente, extra, duplicado ou incompatível interrompe orientando executar P05. Registros antigos só migram quando identidade, URL, nome e integridade do ZIP permitem provar a correspondência; a reconstrução por P05 pode reutilizar ZIPs válidos.

Checkpoints registram a lógica de leitura efetiva, conteúdo, período, mapa afetado e versão. Mudanças de documentação/testes não invalidam intermediários; alterações relevantes de leitura invalidam todos os afetados, e de mapa invalidam a tabela correspondente. A geração inclui lógica das saídas, mapa e plano, separadamente do hash completo de scripts/testes/lockfile/dicionário usado pelo aceite. O manifesto registra os contratos em disco e o hash do mapa efetivamente fornecido. Contrato ou código antigo impede evidência atual.

`saidas/atual.rds` conserva a última geração publicada; `saidas/execucao.rds` identifica a tentativa recente e `saidas/tentativas/<id>.rds` conserva cada registro. P04/P05 concluídos significam etapa concluída, sem análise pronta. Falha ou tentativa sem fim bloqueia o anúncio de sucesso atual. Uma morte abrupta do processo pode deixar `em_processamento` sem fim; isso significa tentativa não finalizada, sem presumir que o processo segue ativo. Arquivos separados não constituem transação conjunta no Windows/OneDrive.

P07 cria `logs/evidencias/<id>` e copia os ZIPs íntegros. Executa a configuração solicitada em área isolada e depois demonstra interrupção/retomada/repetição em três processos adicionais. A demonstração habilita checkpoints, desabilita atualização/força e usa caminhos próprios; alterações são registradas explicitamente. Período, tabelas, mapa, conteúdo e regras permanecem compatíveis. A prova registra checkpoint novo e seus hashes, entradas, PIDs, configurações e igualdade das saídas. Nenhum download da CVM é iniciado. O teste injeta executor e identifica sua prova como fixture; a execução operacional usa a suíte completa real. A variável de contexto do runner impede recursão inadvertida.

P07 verifica arquivos obrigatórios, hashes, esquema/contagem CSV/RDS, datas e identidade também sem flat. A união das chaves temporais deve ser não vazia; no modo completo coincide com a chave única do flat. Duplicidades temporais não são descartadas ou agregadas. O aceite temporal continua próprio.

## Verificação e preservação

Os resultados atualizados estão em `logs/testes_resumo.json`, `logs/reproducao_referencia_robustez.json`, `logs/preservacao_robustez.json` e `logs/evidencias_aceite.rds`. Esses arquivos locais não integram o Git. O relatório de fechamento registra os resultados efetivamente observados, sem reutilizar a aprovação histórica.

A comparação já executada confirmou igualdade SHA-256 dos **42 arquivos** do piloto anterior e do novo: 40 datasets e dois relatórios de qualidade. Há **382.452 linhas temporais**, **8.783 chaves no flat** e **14.749 colunas**. A igualdade byte a byte preserva identificadores, acentos, referências de origem, linhas e representações financeiras, inclusive `__original`. Assinatura da geração, proveniência e registros de tentativas são metadados novos e não entram nessa igualdade.

Dependências conferidas com `renv.lock`. Versões realmente utilizadas constam dos registros de ambiente. P03 continua exclusivamente documental; não houve instalação de R, execução de roteiro ou VM. Linux/CI são verificações distintas e só serão declaradas quando observadas.

## Executar no RStudio

Abra o projeto na raiz. No console:

```r
source('scripts/p02_dependencias.R')
gerenciar_dependencias('verificar')
source('scripts/p01_pipeline_fidc.R')
config <- list(inicio='2026-07-01', fim='2026-08-31')
executar_pipeline_etapa('P04', config)
executar_pipeline_etapa('P05', config)
resultado <- executar_pipeline_etapa('P06', config)
```

P04 consulta listagens e P05 pode consultar a CVM; a evidência usa somente ZIPs locais. Para o piloto já preparado, P06 pode ser repetido sem repetir P04/P05. Mudar período ou tabelas exige P04/P05 atuais. Para modo temporal, adicione `gerar_flat=FALSE` à mesma configuração em todas as chamadas.

No terminal PowerShell do RStudio, na raiz:

```powershell
Rscript --vanilla scripts/p02_testar.R todas
Rscript --vanilla scripts/p07_evidencias.R
Rscript --vanilla scripts/p01_pipeline_fidc.R P07
```

Configuração diferente do padrão deve ser salva em RDS e passada aos dois últimos comandos: `Rscript --vanilla scripts/p07_evidencias.R dados/minha_config.rds` e `Rscript --vanilla scripts/p01_pipeline_fidc.R P07 dados/minha_config.rds`.

Para análise, confira os dois ponteiros antes de abrir datasets:

```r
atual <- readRDS('saidas/atual.rds')
tentativa <- readRDS('saidas/execucao.rds')
stopifnot(atual$estado == 'concluido', tentativa$estado == 'concluido',
          tentativa$etapa == 'P06', tentativa$assinatura == atual$assinatura,
          tentativa$assinatura_plano == atual$assinatura_plano)
iv <- readRDS(file.path(atual$geracao, 'inf_mensal_fidc_tab_IV.rds'))
```

## Fechamento

Validação local concluída: **47 casos e 402 verificações**, zero falhas/erros/avisos/skips. Produtor operacional aprovado com dados reais locais em quatro processos R: checkpoint novo 1, retomada reutilizando 1; repetição e execução solicitada têm hashes iguais. **412 arquivos normais** permaneceram com hashes idênticos. Comparação do piloto preservou os **42 arquivos** byte a byte. R 4.5.1 e dependências conferidas com renv.lock. A biblioteca testthat informa compilação em R 4.5.3 ao carregar, com versões fixadas e sem avisos nos casos. Publicação autorizada pelo usuário e confirmada no GitHub: os três commits do incremento chegaram ao main, com HEAD local/remoto ba7564354a2d819adcff54abe9efa4b1bb449889. CI do incremento aprovada em Windows e Linux (47 casos/401 verificações em cada ambiente, zero falhas/erros/avisos/skips; suíte local: 47/402, com uma verificação adicional do Parquet opcional instalado): https://github.com/amarallr/akcit_c4_mini_projeto/actions/runs/37091112129. Aceite completo do piloto confirmado após conferir sincronização e evidências locais. Detalhes em evidencias/p07/sincronizacao_github.json. Dados, checkpoints, gerações e bibliotecas permanecem locais e ignorados pelo Git. O commit seguinte registra somente este fechamento documental; o resultado de CI acima refere-se exatamente ao commit informado. P03 não foi reativado.

## Estatísticas de PL solicitadas no incremento

Pedido adicional incorporado em P07-RF-007, módulo p07_resumo_pl.R e P07-TST-009. A soma decimal já publicada foi preservada. Cada grupo usa a data completa DT_COMPTC, sem juntar datas distintas do mesmo mês; data_competencia explicita a chave no CSV. Quartis são tipo 7 de R e CV é sd amostral/média × 100; média zero ou menos de duas observações deixa CV indefinido. Não há PL ausente no piloto. Uma chave IV duplicada interrompe o resumo, sem soma duplicada ou descarte silencioso. Dados originais e datasets não são alterados.

| Estatística, unidade da fonte | 31/07/2026 | 31/08/2026 |
|---|---:|---:|
| PL máximo | 61.976.224.290,87 | 58.815.322.507,62 |
| Percentil 75 | 152.129.288,97 | 150.506.075,95 |
| Mediana | 47.984.553,68 | 48.245.175,16 |
| Percentil 25 | 13.119.894,7175 | 13.461.836,74 |
| PL mínimo | -25.842.125,55 | -70.774.978,96 |
| CV amostral | 565,439243868264% | 536,375056550321% |

Reprodução: no terminal do RStudio, Rscript --vanilla scripts/p07_resumo_pl.R. Saída em resultados/estatisticas/estatisticas_por_competencia.csv.

A reprodução dos três problemas foi retrospectiva em cópia do código do commit de referência; não se afirma um ciclo TDD estrito. O caso adicional de saída parcial foi confirmado na revisão final e ganhou regressão de preservação do ponteiro concluído. P07 também rejeita hash apontando para arquivo fora da geração indicada.
