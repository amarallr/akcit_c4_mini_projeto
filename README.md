# Informes CVM: aquisição e consolidação de FIDC e FII

Projeto em R para adquirir, validar e consolidar os informes mensais de Fundos
de Investimento em Direitos Creditórios (FIDC) publicados pela CVM. O pipeline
separa configuração, download, processamento e aceite, preservando a origem dos
arquivos e permitindo retomada após interrupções.

A implementação mantém consolidações temporais FIDC por leiaute, aquisição e
consolidação temporal de Fundos de Investimento Imobiliário (FII) e produtos
locais privados de movimentações FIDC.

## Escopo implementado

O pipeline público FIDC usa as etapas P01–P07. FII possui entradas próprias:
[P05_02 para aquisição](prompts/05_02_download_fii.txt) e
[P06_02 para consolidação](prompts/06_02_consolidacao_fii.txt).
Os dois fluxos têm testes com dados fictícios, documentação de execução e prompts CO-STAR.

O código e os produtos de movimentações são privados e não acompanham o
repositório público. Sua descrição documenta o contexto do projeto; os comandos
de execução abaixo correspondem aos pipelines públicos de consolidação temporal.

## O que está implementado

- Inventário e seleção de fontes FIDC conforme período, leiautes e configuração.
- Download com tentativas limitadas, validação de ZIP, hashes e manifestos locais.
- Extrações separadas por unidade e versão, com recuperação de falhas.
- Consolidação temporal independente por leiaute, com CSV/RDS e Parquet opcional.
- Filtros configuráveis, auditoria de chaves, origem e qualidade dos dados.
- Checkpoints e assinaturas que vinculam o reuso às entradas e à transformação.
- Testes com dados fictícios e aceite baseado em evidências da execução.

Os prompts de manutenção usam CO-STAR e organizam requisitos, responsabilidades
e verificações conforme práticas selecionadas do SWEBOK. Consulte o
[índice e a rastreabilidade dos prompts](prompts/README.md).

## Produtos e limites

| Produto | Destino local | Contrato |
|---|---|---|
| Consolidação temporal | `outputs/fidc/temporal/` | Uma tabela independente por leiaute |
| Movimentações | `outputs/fidc/movements/` | 62 colunas; chave `cnpj + classe_serie + dt_comptc` |
| Movimentações sem classe/série | `outputs/fidc/movements/` | 61 colunas; chave `cnpj + dt_comptc` |
| Consolidação temporal FII | `outputs/fii/temporal/` | Tabelas geral, ativo/passivo e complemento separadas |

As movimentações são disponibilizadas localmente em RDS, CSV e XLSX, com
metadados. Incluem condomínio, exclusividade e interesse único e indissociável
dos cotistas, declarados na tabela I. A versão sem classe/série deriva da tabela
vigente e segue regras explícitas de agregação; métricas mensais repetidas entre
séries, como patrimônio líquido, não são somadas indiscriminadamente.

O escopo desta versão não inclui geração flat, de detalhes ou de cedentes.
Validação com fixtures
não comprova completude dos dados reais, titularidade de identificadores ou
equivalência entre leiautes diferentes.

## Organização do código

| Etapa | Responsabilidade | Pasta |
|---|---|---|
| P01 | Orquestração e entradas do pipeline | `src/orchestration/` |
| P02 | Contratos comuns, dependências e runner | `src/utils/` |
| P03 | Ambiente e preparação | `src/validation/` |
| P04 | Configuração e inventário FIDC | `src/configuration/` |
| P05_01 | Download e extração FIDC | `src/download/` |
| P05_02 | Aquisição FII e dicionário | `src/download/` |
| P06_01 | Consolidação temporal e medição | `src/consolidation/` |
| P06_02 | Consolidação temporal FII | `src/consolidation/` |
| P07 | Aceite e evidências | `src/acceptance/` |

As pastas representam responsabilidades e não recebem numeração. Os arquivos
usam P01 a P07, com subetapas em P05 (download) e P06 (consolidação), e indicam
o prompt de referência no cabeçalho. Em ambas as famílias, `_01` identifica
FIDC e `_02` identifica FII.
O [mapa completo](docs/estrutura.md) descreve dados, configurações, registros e
produtos; o [fluxo das consolidações](docs/fluxo_consolidacoes.md) explica suas
relações. A ordem de leitura está no [índice da documentação](docs/README.md).

Consulte o [histórico de alterações](CHANGELOG.md) para as versões publicadas.

## Ambiente e verificação

Execute os comandos a partir da raiz, preferencialmente abrindo
`C4-Mini-projeto.Rproj`. A versão de R e as dependências estão registradas em
`renv.lock`; a biblioteca local fica em `.R-library/`.

```powershell
Rscript --vanilla src/utils/p02_dependencias.R verificar
Rscript --vanilla src/validation/p03_diagnosticar_ambiente.R
Rscript --vanilla src/utils/p02_testar.R todas
```

Quando for necessário instalar ou restaurar as dependências, execute
`Rscript --vanilla src/utils/p02_dependencias.R restaurar`; essa ação acessa a
rede. A suíte completa usa fixtures locais. O workflow
[de testes](.github/workflows/testes.yml) executa essa suíte em Windows e Linux.

O runner aceita `P05` para testar os dois downloads e `P06` para testar as duas
consolidações. Use `P05_01`, `P05_02`, `P06_01` ou `P06_02` para uma única subetapa.

## Execução do pipeline FIDC

O ponto de entrada é `src/orchestration/p01_pipeline_fidc.R`. P04 prepara o plano;
P05_01 baixa e extrai; P06_01 consolida; P07 verifica o aceite. Cada chamada executa
somente a etapa solicitada.

Nessa entrada específica de FIDC, os identificadores antigos `P05` e `P06`
continuam aceitos como aliases de `P05_01` e `P06_01`.

O exemplo abaixo pressupõe um RDS de configuração preparado pelo usuário em
`config/pipeline.rds`; esse arquivo é ilustrativo, local e não acompanha o
repositório. Use a mesma configuração nas etapas seguintes.

```powershell
Rscript --vanilla src/orchestration/p01_pipeline_fidc.R P04 config/pipeline.rds
Rscript --vanilla src/orchestration/p01_pipeline_fidc.R P05_01 config/pipeline.rds
Rscript --vanilla src/orchestration/p01_pipeline_fidc.R P06_01 config/pipeline.rds
Rscript --vanilla src/orchestration/p01_pipeline_fidc.R P07 config/pipeline.rds
```

P04 persiste o plano em `config/fidc_configuracao.rds`. As fontes ficam em
`data/data_fidc/data_fidc_raw/`; as FII em `data/data_fii/data_fii_raw/`.
Os checkpoints ficam em `data/data_fidc/data_fidc_interim/checkpoints/` e as gerações temporais
em `outputs/fidc/temporal/`. P07 pode apontar evidências pendentes; ter os arquivos
de saída não basta para comprovar todos os critérios de aceite. As interfaces
de avaliação e produção de evidências ficam em `src/acceptance/`.

## Execução FII

O P05_02 consulta o [diretório oficial](https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/DADOS/)
e adquire os ZIPs anuais e o dicionário. O P06_02 lê apenas as fontes locais e gera
uma tabela temporal independente para cada uma das três tabelas oficiais.

```powershell
Rscript --vanilla src/download/p05_02_download_fii.R 2026-07-01 2026-08-31
Rscript --vanilla src/consolidation/p06_02_consolidacao_fii.R 2026-07-01 2026-08-31
```

Repetir P05_02 reutiliza ZIPs válidos; `--atualizar` solicita nova aquisição para
verificar reapresentações. Um ZIP anual pode trazer meses fora da seleção;
P06_02 seleciona as competências mensais do intervalo. Veja o
[guia de download FII](docs/05_02_download_fii.md) e o
[contrato de consolidação FII](docs/06_02_consolidacao_fii.md) para histórico
completo, retomada, regras e limitações.

## Confidencialidade

Fontes, configurações locais, produtos, evidências e código privado permanecem
ignorados pelo Git. Os testes públicos usam dados fictícios. Nenhuma seleção
pessoal, planilha ou resultado confidencial deve ser incluído no repositório.

A pasta `restricted/` da raiz é ultra confidencial: nunca abrir, percorrer,
alterar ou compartilhar seu conteúdo. Ela é distinta da área reservada
`data/restricted/`. Análises exploratórias ficam em `locais/`, criada quando
necessária; reconstruções ficam em `data/interim/temporarios/`.
`tmp/doit.txt` e as instruções locais também não são publicados.

## Validação

Os testes de todas as etapas usam fixtures, sem download real da CVM. A suíte inclui
interrupção, retomada, integridade, isolamento entre fluxos e mudanças de esquema.
A validação com fontes reais é uma execução separada e mantém suas evidências
em áreas locais ignoradas. O GitHub Actions executa a mesma seleção `todas`
para o código publicado, em Windows e Linux.
