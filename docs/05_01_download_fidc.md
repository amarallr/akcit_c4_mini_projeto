# 05_01 — Download dos informes mensais FIDC

Esta subetapa pertence à família 05 (download), ao lado de
[05_02 — FII](05_02_download_fii.md).

| Artefato | Caminho |
|---|---|
| Prompt | `prompts/05_01_download_fidc.txt` |
| Código | `src/download/p05_01_download_fidc.R` |
| Testes | `tests/testthat/test-p05_01-download-fidc.R` |
| IDs | `P05_01-RF-*`, `P05_01-FUN-*`, `P05_01-TST-*` |

P04 prepara o plano e a configuração antes da aquisição. O exemplo abaixo
pressupõe um RDS de configuração local preparado pelo usuário:

```powershell
Rscript --vanilla src/orchestration/p01_pipeline_fidc.R P05_01 config/pipeline.rds
Rscript --vanilla src/utils/p02_testar.R P05_01
```

A aquisição valida ZIPs, limita tentativas e preserva estados de falha e
recuperação. Fontes e manifestos ficam em `data/data_fidc/data_fidc_raw/`; os membros são extraídos
por unidade e hash. Os dados são consumidos pela
[consolidação 06_01](06_01_consolidacao_fidc.md).

Na entrada FIDC, `P05` permanece como alias de `P05_01`. No runner de testes,
`P05` seleciona a família inteira: downloads FIDC e FII.
