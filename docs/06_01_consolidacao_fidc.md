# 06_01 — Consolidação temporal FIDC

Esta subetapa pertence à família 06 (consolidação), ao lado de
[06_02 — FII](06_02_consolidacao_fii.md).

| Artefato | Caminho |
|---|---|
| Prompt | `prompts/06_01_consolidacao_fidc.txt` |
| Código | `src/consolidation/p06_01_consolidacao_fidc.R` |
| Medição | `src/consolidation/p06_01_medir_execucao.R` |
| Testes | `tests/testthat/test-p06_01-consolidacao-fidc.R` |
| IDs | `P06_01-RF-*`, `P06_01-FUN-*`, `P06_01-TST-*` |

Depois do [download 05_01](05_01_download_fidc.md), execute com a mesma
configuração local preparada pelo usuário:

```powershell
Rscript --vanilla src/orchestration/p01_pipeline_fidc.R P06_01 config/pipeline.rds
Rscript --vanilla src/utils/p02_testar.R P06_01
```

O produto temporal mantém uma tabela por leiaute em `outputs/fidc/temporal/`.
O processamento usa checkpoints e auditoria de chaves e multiplicidades,
sem gerar flat, detalhes ou cedentes. As consolidações privadas de movimentações
mantêm seus contratos e instruções locais, fora dos artefatos públicos.

Na entrada FIDC, `P06` permanece como alias de `P06_01`. No runner de testes,
`P06` seleciona a família inteira: consolidações FIDC e FII.
