# 05_02 — Download dos informes mensais FII

O P05_02 adquire ZIPs anuais e o dicionário do
[diretório CVM](https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/DADOS/).
O P06_02 consolida as fontes locais em três tabelas independentes: `geral`,
`ativo_passivo` e `complemento`. Consulte também o
[catálogo oficial](https://dados.cvm.gov.br/dataset/fii-doc-inf_mensal) e o
[diretório de metadados](https://dados.cvm.gov.br/dados/FII/DOC/INF_MENSAL/META/).

## Execução e retomada

Partindo da raiz do projeto, valide um intervalo pequeno:

```powershell
Rscript --vanilla src/download/p05_02_download_fii.R 2026-07-01 2026-08-31
Rscript --vanilla src/consolidation/p06_02_consolidacao_fii.R 2026-07-01 2026-08-31
```

Para demonstrar uma interrupção controlada, acrescente `--limite=1` ao P05_02.
A chamada retorna erro depois de persistir o primeiro recurso anual validado.
Reexecute sem esse parâmetro: o recurso e o dicionário devem ser reutilizados.
O índice oficial continua sendo consultado para selecionar as fontes disponíveis.

A ampliação usa o mesmo comando, com outro intervalo, por exemplo
`2016-01-01 2026-10-29`. O índice é descoberto durante a execução: a lista de
anos não está fixada no código. A seleção de ZIPs é anual; o recorte das linhas
ocorre no P06_02 pela competência mensal, incluindo o mês inicial e o final.

O parâmetro `--atualizar` do P05_02 solicita nova aquisição para verificar
reapresentações. A versão anterior é preservada por hash. Sem esse parâmetro,
o reuso valida o conteúdo local, mas não detecta mudanças remotas no ZIP.

## Áreas locais

| Área | Conteúdo |
|---|---|
| `config/fii_configuracao.rds` | Configuração, inventário e plano anual |
| `data/data_fii/data_fii_raw/originais/` | ZIP corrente por recurso e manifestos |
| `data/data_fii/data_fii_raw/versoes/` | ZIPs arquivados por recurso/hash |
| `data/data_fii/data_fii_raw/extraidos/` | Membros validados por recurso/hash |
| `data/data_fii/data_fii_raw/downloads.rds` | Registro cumulativo das aquisições anuais |
| `data/data_fii/data_fii_raw/dicionario.rds` | Origem, hash e membros do dicionário |
| `logs/fii/` | Tentativas, cobertura anual e inventário de membros |
| `outputs/fii/temporal/` | Marcador `atual.rds` e gerações dos produtos |

Todos esses artefatos permanecem locais e ignorados pelo Git. As áreas FIDC e
a pasta sigilosa `restricted/` não são insumos do fluxo FII.

Consulte o [contrato de consolidação FII](06_02_consolidacao_fii.md).

## Testes

Execute "Rscript --vanilla src/utils/p02_testar.R P05_02".
