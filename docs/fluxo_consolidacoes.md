# Fluxo das consolidações

O fluxo produz consolidações temporais (uma tabela por leiaute) e uma tabela única de movimentações, com chave `cnpj`, `classe_serie` e `dt_comptc`.

Uma tabela adicional sem classe/série deriva das movimentações e mantém chave
`cnpj + dt_comptc`, com regras próprias de agregação e metadados.

Para a organização detalhada do código e as convenções de nomes, consulte
[Estrutura e nomes](estrutura.md).

| Área | Conteúdo |
|---|---|
| `src/` | Código por responsabilidade, etapa e subetapa |
| `data/data_fidc/data_fidc_raw/` | Fontes e metadados FIDC |
| `data/data_fii/data_fii_raw/` | Fontes e metadados FII |
| `data/data_fidc/data_fidc_interim/checkpoints/` | Checkpoints |
| `data/data_fidc/data_fidc_processed/` | Dados processados FIDC |
| `data/data_fii/data_fii_interim/` | Intermediários FII |
| `data/data_fii/data_fii_processed/` | Dados processados FII |
| `data/interim/temporarios/` | Área temporária da consolidação de movimentações |
| `outputs/fidc/temporal/` | Consolidações temporais |
| `outputs/fidc/movements/` | Tabela de movimentações e metadados |
| `outputs/fii/temporal/` | Consolidação temporal FII |
| `docs/` | Documentação corrente e referências CVM |
| `tests/`, `config/`, `logs/`, `reports/` | Testes, configuração, registros e relatórios |
| `prompts/` | Prompts CO-STAR e rastreabilidade |

A tabela de movimentações possui 62 colunas. Seus atributos de condomínio, exclusividade e interesse único e indissociável vêm da tabela I do Informe Mensal CVM.

Dados, produtos, registros e código privado são locais e ignorados pelo Git. `restricted/` permanece intocada e ignorada.

P04 seleciona as fontes; P05_01 baixa e extrai; P06_01 consolida; P07 avalia o aceite.
P01 coordena chamadas explícitas, P02 fornece os contratos comuns e P03 verifica
o ambiente. FII utiliza entradas independentes P05_02 e P06_02; consulte o
[download FII](05_02_download_fii.md) e a
[consolidação FII](06_02_consolidacao_fii.md). Os dois fluxos compartilham primitivas de integridade e
persistência, sem misturar fontes ou produtos.
