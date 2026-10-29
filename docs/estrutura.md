# Estrutura e convenções de nomes

As pastas principais representam responsabilidades e mantêm nomes sem numeração.
A sequência de execução pertence ao pipeline; a ordem de leitura pertence ao
[índice da documentação](README.md).

## Mapa de pastas

| Pasta | Responsabilidade |
|---|---|
| `src/orchestration/` | P01: entradas e coordenação explícita das etapas |
| `src/configuration/` | P04: configuração, inventário e seleção de fontes |
| `src/download/` | P05_01: aquisição FIDC; P05_02: aquisição FII |
| `src/consolidation/` | P06_01: temporal FIDC e medição; P06_02: temporal FII |
| `src/validation/` | P03: verificação e preparação do ambiente |
| `src/acceptance/` | P07: aceite e evidências |
| `src/utils/` | P02: utilitários, dependências e execução dos testes |
| `src/analysis/` | Área reservada para módulos de análise |
| `src/ingestion/` | Área reservada para módulos de ingestão |
| `src/transformation/` | Área reservada para módulos de transformação |
| `src/visualization/` | Área reservada para módulos de visualização |
| `tests/testthat/` | Testes automatizados e dados fictícios de teste |
| `docs/` | Documentação corrente |
| `docs/references/cvm/` | Dicionários e referências usados pelo código |
| `config/fidc_configuracao.rds` | Configuração FIDC |
| `config/fidc_config_incremento.rds` | Estado de incremento FIDC |
| `config/fii_configuracao.rds` | Configuração FII |
| `data/data_fidc/data_fidc_raw/` | Fontes FIDC, extrações e manifestos |
| `data/data_fidc/data_fidc_interim/checkpoints/` | Estado reutilizável FIDC |
| `data/data_fidc/data_fidc_processed/` | Área de dados processados FIDC |
| `data/data_fii/data_fii_raw/` | Fontes, dicionário e versões FII |
| `data/data_fii/data_fii_interim/` | Intermediários e validações FII |
| `data/data_fii/data_fii_processed/` | Área de dados processados FII |
| `data/interim/temporarios/revisao_movimentacoes/` | Reconstrução local antes da publicação |
| `outputs/fidc/temporal/` | Produto temporal FIDC corrente |
| `outputs/fidc/movements/` | Produtos FIDC de movimentações e metadados correntes |
| `outputs/fii/temporal/` | Produtos temporais FII separados por tabela oficial |
| `logs/` | Registros de execução e resultados de testes |
| `logs/fii/` | Aquisições, cobertura e validações FII |
| `logs/fidc/evidencias/` | Evidências locais do aceite FIDC |
| `reports/` | Relatórios locais de trabalho |
| `prompts/` | Prompts CO-STAR, requisitos e vínculo com o código |
| `tmp/` | Arquivos auxiliares temporários e instruções locais de `doit` |

As áreas indicadas como reservadas podem permanecer vazias. Não é necessário
criar arquivos para preencher a estrutura. As análises exploratórias
confidenciais devem ficar em `locais/`, criada somente quando necessária.

## Convenções de nomes

- Manter as pastas principais existentes, como `src/`, `data/`, `outputs/`,
  `docs/` e `tests/`, sem prefixos `01_`, `02_` ou semelhantes.
- Nas áreas de dados, configuração, logs e saídas, indicar o domínio no nome
  quando os artefatos forem específicos: `data_fidc`, `data_fii`, `fidc_`, `fii_`,
  ou pastas `fidc/` e `fii/`. Artefatos comuns permanecem sem esse prefixo.
- Organizar o código por responsabilidade. Usar nomes descritivos, em minúsculas,
  sem espaços nem acentos, com palavras separadas por `_`.
- Usar etapas `p01` a `p07`, com subetapas nas famílias de download e consolidação:
  `p05_01` e `p06_01` para FIDC; `p05_02` e `p06_02` para FII. A mesma hierarquia
  vincula prompts, módulos, documentos, requisitos e testes.
- Consultar o [índice dos prompts](../prompts/README.md). Cada módulo público
  aponta para seu prompt no cabeçalho.
- Para módulos vinculados a uma etapa, seguir o padrão existente
  `pNN_descricao.R` ou `pNN_SS_descricao.R` quando houver subetapa, com extensão
  adequada à linguagem (`.R` ou `.ps1`).
- Nos testes, usar `test-pNN-descricao.R` ou `test-pNN_SS-descricao.R` e os auxiliares
  `helper-*.R`, reconhecidos pelo runner de testes.
- Usar nomes temáticos nos documentos, como `estrutura.md` e
  `fluxo_consolidacoes.md`, para orientações gerais. Documentos de uma subetapa
  usam o mesmo prefixo dos prompts, como `05_01_download_fidc.md`.
- Manter os nomes e as extensões dos arquivos oficiais de origem. As unidades
  temporais e os hashes de extração identificam a origem e sua versão.
- Preservar os nomes dos produtos finais: eles fazem parte dos caminhos usados
  pelos geradores e consumidores. Novos arquivos devem indicar conteúdo e, quando
  aplicável, período ou versão, sem identificadores pessoais nos nomes.
- Evitar nomes ambíguos como `novo`, `final2` ou `copia`. Versões de código ficam
  no Git; temporários e reconstruções ficam nas áreas locais apropriadas.

## Limites entre código, fontes e produtos

O código fica em `src/`; as fontes e os intermediários ficam em `data/`; os
produtos finais ficam em `outputs/`. Arquivos de trabalho não devem ser
misturados aos produtos finais.

Dados, configurações, produtos e código privado permanecem locais e ignorados
pelo Git. Anotações e resultados confidenciais não devem ser copiados para a
documentação versionada. `restricted/` fica totalmente fora de buscas,
inventários, reorganizações e publicações.

A pasta `restricted/` da raiz é ultra confidencial e não se confunde com
`data/restricted/`, uma área reservada da estrutura de dados.
