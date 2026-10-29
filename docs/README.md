# Documentação do projeto

Documentação dos pipelines públicos FIDC e FII. P05 reúne os downloads e P06
reúne as consolidações: `_01` identifica FIDC; `_02`, FII.
Dados, código e produtos privados não acompanham a publicação.

Leia nesta ordem:

1. [Visão geral](../README.md): objetivo, produtos e pontos de entrada.
2. [Estrutura e nomes](estrutura.md): mapa de pastas, responsabilidades e convenções.
3. [Fluxo das consolidações](fluxo_consolidacoes.md): entradas, processamento e saídas.
4. [Prompts e rastreabilidade](../prompts/README.md): CO-STAR e vínculo entre etapas, código e testes.

## Etapa 05 — Download

- [05_01 — FIDC](05_01_download_fidc.md).
- [05_02 — FII](05_02_download_fii.md).

## Etapa 06 — Consolidação

- [06_01 — FIDC](06_01_consolidacao_fidc.md).
- [06_02 — FII](06_02_consolidacao_fii.md).

Os dicionários usados pelo código ficam em [references/cvm/](references/cvm/).

Produtos vigentes: consolidações temporais e a consolidação única das movimentações.

Dados de origem e produtos permanecem locais e ignorados pelo Git. Nunca acessar `restricted/`.
