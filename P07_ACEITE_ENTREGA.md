# P07 — Aceite e entrega do piloto FIDC

O aceite do modo completo avalia a entrega de **datasets consolidados temporalmente por tabela do informe mensal e de uma única tabela final integrada (flat)**. Para julho/agosto de 2026, são 18 datasets temporais e um flat, cada um em CSV e RDS: **19 datasets principais, entregues em 38 arquivos**. A base de cedentes acrescenta um dataset em dois formatos, totalizando **20 datasets e 40 arquivos de dados**, além dos relatórios de qualidade e manifestos. O aceite do piloto completo exige esse conjunto. A opção `gerar_flat=FALSE` entrega 38 arquivos de dados e tem aceite temporal próprio, sem substituir o completo.

A execução do autor ocorreu em 01/10/2026, após autorização para implementar P04–P07, no âmbito da Especialização em Engenharia de Software com IA Generativa. A revisão incremental foi validada em 02/10/2026. P01 coordena o pipeline, P02 fornece a biblioteca comum e P03 permanece roteiro documental. As evidências locais demonstram o resultado deste piloto; a reprodução independente em ambiente limpo continua fora do escopo validado.

## Escopo, fontes e saídas verificadas

Período inclusivo: 2026-07-01 a 2026-08-31. Dois ZIPs mensais obtidos pelas funções P05, com 18 CSVs cada: I, II, III, IV, V, VI, VII, VIII, IX, X, X_1, X_1_1, X_2, X_3, X_4, X_5, X_6 e X_7. Fontes oficiais: [DADOS](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/), [HIST](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/HIST/) e [dicionário META](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/meta_inf_mensal_fidc_txt.zip). CVM pública sem credenciais.

| Original | SHA-256 observado |
|---|---|
| `inf_mensal_fidc_202607.zip` | `302e34cae13c70028ca9706423774f38e74075493a4d8be2eff4a76b308ebd43` |
| `inf_mensal_fidc_202608.zip` | `b5a790bc81e8adeaf1f5055850599808ce5de5ab872987985f552e291c753787` |

Arquivos originais, extração, dados, resultados, checkpoints e logs ficam locais e ignorados pelo Git. Hash identifica a versão recebida, sem garantir que a fonte nunca a revise. Membros e hashes individuais estão nos manifestos locais.

| Entrega observada | Resultado |
|---|---|
| CSVs temporais por leiaute | 18, concatenando julho/agosto, sem descarte de linhas |
| RDSs temporais tipados | 18 |
| Flat CSV/RDS | 8.783 linhas, 14.749 colunas |
| Cedentes CSV/RDS | 7.004 registros longos |
| Chave flat | CNPJ textual normalizado + competência, única |
| Cobertura da união de chaves | 8.783 pares; nenhuma chave de tabela temporal excluída |
| Tabela I | 4.386 linhas julho, 4.397 agosto |
| Tabela VIII | 41.248 linhas julho, 42.796 agosto, preservadas em temporal e pivot do flat |
| X_4 | 46.976 linhas julho, 47.939 agosto, preservadas |
| CSV flat | 244.781.526 bytes, aproximadamente 245 MB |

Contagens agregadas completas: [P07_EVIDENCIAS_PILOTO.csv](P07_EVIDENCIAS_PILOTO.csv). Não contém registros individuais. Manifesto da geração contém caminho/hash de cada CSV/RDS; `saidas/atual.rds` indica a geração atual. CSV usa UTF-8, ponto e vírgula e decimal ponto, RDS preserva tipos.

## Datasets exigidos para o aceite

A entrega temporal reúne os dois meses em cada arquivo `inf_mensal_fidc_tab_<tabela>.csv` e seu correspondente `.rds`, para **I, II, III, IV, V, VI, VII, VIII, IX, X, X_1, X_1_1, X_2, X_3, X_4, X_5, X_6 e X_7**. A presença das subdivisões de X explica por que são 18 tabelas, além do flat. Os arquivos `inf_mensal_fidc_flat.csv` e `.rds` integram a união das chaves de todas elas. Os arquivos `inf_mensal_fidc_cedentes.csv` e `.rds` são a entrega complementar.

Para aceitar os resultados, todas as tabelas selecionadas devem estar presentes nos dois formatos, conservar as linhas da seleção temporal e suas origens e constar no manifesto com hashes válidos. O flat deve ter uma linha por CNPJ/competência e cobrir exatamente a união das chaves temporais, preservando os detalhes em posições por leiaute. Testes, demonstração de retomada e documentação sustentam a entrega dos datasets.

## Resumo dos dados por competência

Resumo calculado em 02/10/2026 a partir da geração local validada, sem novo download ou reprocessamento do pipeline:

| Competência | Registros nas 18 tabelas temporais | Registros no flat | Fundos/classes — CNPJs distintos | Registros com PL | PL total — unidade original da fonte |
|---|---:|---:|---:|---:|---:|
| Julho/2026 | 189.577 | 4.386 | 4.386 | 4.386 | 1.015.421.915.561,51 |
| Agosto/2026 | 192.875 | 4.397 | 4.397 | 4.397 | 989.154.738.500,71 |

O conjunto temporal tem **382.452 linhas**; o flat tem **8.783 pares CNPJ/competência e 4.493 CNPJs distintos no período**. A quantidade de fundos corresponde operacionalmente aos CNPJs normalizados informados como fundo/classe. Não é uma contagem de cadastros de fundos independente da estrutura de classes. Linhas de detalhe podem repetir o CNPJ nas tabelas temporais.

O PL total soma `TAB_IV_A_VL_PL` da tabela IV, uma vez por CNPJ/competência, usando a representação decimal original. A tabela IV tem chave única e cobre exatamente as chaves do flat; não há valores de PL ausentes no piloto. A soma foi feita em centésimos inteiros dentro do limite de precisão exata, sem agregar colunas repetidas do flat. Unidade monetária e escala permanecem sem homologação; os números conservam a unidade da fonte. Como o PL representa uma posição mensal, os totais são apresentados separadamente por competência.

| Tabela temporal | Registros julho | Registros agosto | Registros no período |
|---|---:|---:|---:|
| I | 4.386 | 4.397 | 8.783 |
| II | 4.386 | 4.397 | 8.783 |
| III | 4.386 | 4.397 | 8.783 |
| IV | 4.386 | 4.397 | 8.783 |
| V | 4.386 | 4.397 | 8.783 |
| VI | 4.386 | 4.397 | 8.783 |
| VII | 4.386 | 4.397 | 8.783 |
| VIII | 41.248 | 42.796 | 84.044 |
| IX | 4.386 | 4.397 | 8.783 |
| X | 4.386 | 4.397 | 8.783 |
| X_1 | 11.790 | 12.021 | 23.811 |
| X_1_1 | 4.386 | 4.397 | 8.783 |
| X_2 | 12.375 | 12.534 | 24.909 |
| X_3 | 12.378 | 12.534 | 24.912 |
| X_4 | 46.976 | 47.939 | 94.915 |
| X_5 | 4.386 | 4.397 | 8.783 |
| X_6 | 12.178 | 12.287 | 24.465 |
| X_7 | 4.386 | 4.397 | 8.783 |
| **Total** | **189.577** | **192.875** | **382.452** |

Evidências agregadas: [resumo mensal](P07_RESUMO_COMPETENCIAS.csv) e [registros/CNPJs por tabela e competência](P07_RESUMO_TABELAS.csv). A base complementar de cedentes contém 7.004 registros no período e não integra a soma das 18 tabelas acima.

## Contrato de leitura e preservação dos campos

[P04_ESQUEMA_OBSERVADO_PILOTO.csv](P04_ESQUEMA_OBSERVADO_PILOTO.csv) compara dicionário com nomes/tipos realmente recebidos: 11 ocorrências de campos novos e cinco ausentes, por leiaute. X_1/X_2/X_3/X_4/X_6 recebem `CNPJ_FUNDO_CLASSE` e `TP_FUNDO_CLASSE` onde o metadado declara `CNPJ_FUNDO`; X_1 inclui `ID_SUBCLASSE`. Não foram fabricados aliases/semânticas. O leitor conserva atributos originais e registra `campo_identidade`, campos desconhecidos e ausentes.

Identificadores entram como texto, sem completar zeros automaticamente ou retirar letras. Valores numéricos declarados são validados com decimal ponto e guardam representação original em colunas próprias. `SEQUENCIAL` bigint permanece texto. Datas são ISO. Fallback Latin-1 é registrado quando o arquivo não passa UTF-8 estrito; não se afirma distinção CP1252/Latin-1 nos bytes compartilhados.

Cada linha mantém arquivo/ZIP/linha original. Multiplicidades por CNPJ/competência são auditadas: VIII 4.227 pares com múltiplas linhas; X_1 5.639; X_2 6.736; X_3 6.732; X_4 8.783; X_6 6.651. O flat abre todas as linhas em posições técnicas por leiaute e depois faz full outer join 1:1. Não agrega valores, escolhe completude, elimina conflitos nem multiplica patrimônio/ativos. Posição `rNNNN` não relaciona detalhes de leiautes diferentes.

Cedentes conservam NI e percentual originais, grupo/índice/origem, formato e DV. Escala percentual continua não confirmada, sem conversão. Completar zeros é hipótese configurável desativada; ambos os candidatos válidos são ambíguos. Não há confirmação cadastral, titularidade, exaustividade da lista ou obrigação de percentuais somarem 100.

## Comandos e demonstração de retomada

Execução explícita com `Rscript --vanilla scripts/p01_pipeline_fidc.R P04`, depois P05 e P06, cada etapa separadamente. P04 inventariou listagens reais e selecionou 202607/202608; P05 baixou, validou e extraiu; chamadas posteriores reutilizaram originais válidos sem novo GET.

Interrupção demonstrada: `Rscript --vanilla scripts/p01_pipeline_fidc.R P06 dados/configuracao.rds 1`. O processo terminou com a interrupção solicitada após persistir o primeiro checkpoint válido. Outro processo executou P06 sem o limite: um checkpoint reutilizado e 35 membros processados. O resultado não dependeu de objetos da sessão anterior.

Após ajustes de assinatura/ordenação, uma reconstrução leu os 36 membros e gerou os mesmos **20 CSVs byte a byte por SHA-256**: 18 temporais, flat e cedentes. Uma nova chamada reutilizou 36 checkpoints, processou zero membros e conservou novamente os 20 hashes. Essa repetição levou 58,17 segundos nesta máquina; a reconstrução medida levou 74,01 segundos. O tempo inclui montagem e validação das saídas; não é benchmark, SLA ou medição de memória máxima. O flat continua sendo reconstruído mesmo quando os intermediários são reutilizados.

Checksums históricos da comparação estão em `logs/equivalencia_piloto.rds`; relatório em `logs/repeticao_piloto.rds`. A geração histórica do primeiro piloto tem assinatura `139e42b638627b8061c52837d4d25ab7c478ac6b42411ef5d006fdccc85c5871`. A geração vigente deve ser consultada em `saidas/atual.rds` e confrontada com `saidas/execucao.rds`; nenhuma assinatura anterior aprova outra execução automaticamente.

## Testes e critérios de aceite

Comando: `Rscript --vanilla scripts/p02_testar.R todas`. No piloto original foram aprovados 22 casos/210 verificações. A suíte ampliada em 02/10/2026 aprovou **36 casos e 275 verificações**, sem falhas, erros, skips ou avisos de testes. O carregamento de testthat em R 4.5.1 avisou que ele foi compilado com R 4.5.3; as execuções aprovadas terminaram com código zero. Não se afirma teste de instalação do roteiro P03.

| Grupo | Verificação demonstrada |
|---|---|
| P01 | Dependências, etapa explícita, carregamento sem efeitos e continuidade |
| P02 | Preservação diante de validador falho, hash canonizado, oito políticas, IDs/referências/cobertura |
| P03 histórico | Regressão dos scripts anteriores, sem executar roteiro/instalar/criar VM |
| P04 | Datas/dataset/caminhos/tabelas e seleção mensal/anual simulada sem sobreposição |
| P05 | HTTP transitório/definitivo, HTML/corrupção, reaproveitamento e ZIP inseguro |
| P06 | Texto/zeros/acentos/decimal, filtros, multiplicidades, órfãos, pivot, ordem, idempotência, processo novo, ausência de saída atual e NI ambíguo |
| P07 | Aceite condicionado, adulteração de saída, `.env` fictício/exclusões, push falho e recuperação no Git bare temporário |

O teste Git inicialmente encontrou bloqueio do processo auxiliar pelo sandbox. A suíte foi executada com a permissão necessária; o teste usa repositório temporário, sem alterar o remoto real. Os unitários não usam rede CVM, esperas reais de retry ou credenciais. A integração real e a sincronização GitHub são verificadas separadamente.

`executar_aceite()` confere o estado da tentativa, os arquivos/hashes e, no modo completo, a unicidade e a cobertura da união das chaves do flat. O aceite operacional exige evidências automáticas; os parâmetros booleanos legados não aprovam uma geração. A CLI lê `logs/evidencias_aceite.rds`, produzido por `Rscript --vanilla scripts/p07_evidencias.R dados/config_incremento.rds` nesta revisão. Em outra reprodução, use sua própria configuração ou o padrão, sem copiar provas do autor.

A evidência vincula a **configuração completa**, incluindo modo de saída, à assinatura da geração e ao hash do conteúdo dos scripts, testes e lockfile. Também registra hashes de `logs/testes.rds`, `logs/testes_resumo.json` e da prova de retomada. O produtor executa a suíte, interrompe após um checkpoint, retoma e repete em processos novos, comparando todos os hashes das saídas. Ausência de artefato, adulteração, outro código/configuração ou tentativa incompleta impede aprovação. O hash de conteúdo permanece válido após a criação do commit de publicação, sem depender de um hash Git ainda inexistente na execução.

**Aceite local:** piloto completo, saídas/hashes/chave conferidos, testes aprovados, retomada demonstrada e exclusões Git verificadas. **Aceite completo:** requer adicionalmente publicação de código/documentação e igualdade HEAD local/remoto. A CLI não consulta Git, logo relata essa pendência; a publicação é comprovada no fechamento e em PUBLICACAO/RETOMADA, separadamente.

## Limitações e próximos incrementos possíveis

Piloto curto, sem homologação de todo o histórico, serviço contínuo ou reprodução independente em máquina limpa. O heap R foi medido com método e limites explícitos, sem afirmar pico RSS do processo. CI Windows/Linux foi configurada com fixtures; suas execuções são evidências separadas do piloto real. O flat continua esparso, largo e construído em memória; o modo temporal evita sua montagem. Limites de tamanho/colunas falham explicitamente. Leiautes históricos requerem mapas e testes próprios. Unidades/escala e equivalência fundo/classe/subclasse não foram inferidas.

## Melhorias verificadas em 02/10/2026

| Incremento | Evidência e alcance |
|---|---|
| Dependências | `renv.lock` registra R 4.5.1 e 48 pacotes diretos/transitivos; restauração e verificação executadas no ambiente atual, reutilizando versões disponíveis. [Ambiente observado](P02_AMBIENTE_VALIDADO.json). |
| CI | Workflow Windows/Linux executa fixtures e registra artefatos, sem CVM/credenciais. Resultado remoto deve ser consultado na [página Actions](https://github.com/amarallr/akcit_c4_mini_projeto/actions); configurar o workflow não equivale a observar sua execução. |
| Recuperação | Testes simulam rollback, manifesto corrompido, falha entre ZIP e manifesto final, falha de rename e falha de gravação do flat. Versões anteriores ficam preservadas; o marcador da tentativa impede sucesso anterior como atual. |
| Qualidade | [Relatório estruturado do piloto](P06_QUALIDADE_PILOTO.csv), por tabela/competência. Campos novos/ausentes, multiplicidades, repetições, formato/DV e conversões registrados sem descarte. Erros de leitura produzem relatório local antes de interromper. |
| Desempenho | Concatenação única por tabela, montagem do flat por coluna e validação com menos cópias. [Método e medidas](DESEMPENHO.md); 21 CSVs conservaram SHA-256. O flat RDS teve hash binário diferente, mas todas as colunas, tipos e valores foram idênticos e `all.equal()` retornou TRUE. |
| Parquet | Exportação e round-trip das tabelas IV/VIII reais com Arrow 25.0.1; menor que CSV e maior que RDS nos exemplos. Formato permanece opcional, sem dependência obrigatória. |
| Aceite | Produtor automatizado executa suíte e retomada/repetição em processos distintos, vinculando provas ao conteúdo de código/testes/lockfile, configuração e geração. |
| Documentação/licença | README separa reprodução pelos prompts e execução da implementação; arquitetura contém somente DFD. [Contribuição](CONTRIBUICAO.md) registra que não há licença de distribuição declarada; nenhuma licença foi atribuída sem escolha do autor. |

O dicionário oficial local descreve `TAB_IV_A_VL_PL` como patrimônio líquido e informa tipo numérico, sem explicitar unidade/escala no texto examinado. A página do [conjunto CVM](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal) e o dicionário são as referências desta revisão. Evidência insuficiente mantém unidade/escala como não confirmadas; valores plausíveis e fontes secundárias não foram usados para confirmá-las.

IA participou de requisitos, arquitetura, código, testes, investigação de falhas, documentação e revisão de publicação. As decisões humanas autorizaram período/escopo/chave/origem. O estudante pode agora revisar as saídas e o relatório para o aceite acadêmico ou escolher um novo incremento. Não há decisão pendente necessária para fechar a implementação autorizada.

## Fechamento da publicação

A entrega requer igualdade entre HEAD local/remoto e árvore limpa. O resultado remoto da CI é verificado separadamente em Actions. A CLI verifica o aceite local, sem consultar Git. Após publicação conferida, a bola fica com o usuário para revisão acadêmica ou escolha de novo incremento.
