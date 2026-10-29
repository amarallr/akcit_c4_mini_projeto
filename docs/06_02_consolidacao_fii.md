# 06_02 — Consolidação temporal FII

Fontes adquiridas pela [subetapa 05_02](05_02_download_fii.md).

Execute a partir da raiz:

Rscript --vanilla src/consolidation/p06_02_consolidacao_fii.R 2026-07-01 2026-08-31

## Contrato da consolidação

- Uma tabela por leiaute oficial, nos formatos CSV e RDS, sem join entre tabelas.
- União dos campos históricos por nome; campo inexistente em uma fonte recebe
  valor ausente. Não há preenchimento com zero nem equivalência inferida entre nomes.
- Todos os campos oficiais são mantidos como texto. Separadores decimais, zeros
  e escalas permanecem como publicados. O CSV de saída usa UTF-8 e `;`.
- Campos técnicos `cnpj`, `data_referencia` e `versao` permitem análise temporal
  sem apagar as identidades e datas originais. CNPJ permanece textual; a data
  técnica é do tipo `Date` no RDS.
- A identidade técnica usa `CNPJ_Fundo_Classe` quando disponível e `CNPJ_Fundo`
  no histórico, sem inferir séries ou relações entre fundos diferentes.
- Todas as linhas e versões são preservadas. A combinação
  `cnpj + data_referencia + versao` é auditada, sem presumir unicidade.
- A origem `hash_zip + arquivo_origem + linha_origem` identifica cada linha
  dentro da tabela. Repetições de negócio não são eliminadas nem agregadas.
- O marcador da geração corrente é atualizado somente depois de validar e gravar
  todos os arquivos. As gerações anteriores permanecem disponíveis.

Cada geração contém seis arquivos de dados, `qualidade.csv`, `cobertura.csv`,
`esquemas.csv`, `fontes.csv` e `manifesto.rds`. O manifesto registra os hashes
dos arquivos, período, política, dicionário e geração. `atual.rds` aponta para
a geração publicada mais recentemente.

## Qualidade e limites

O relatório de cobertura distingue anos disponíveis no índice de meses com
linhas observadas. Um arquivo anual não comprova a existência de todas as
competências. Meses sem linhas são informados, sem inventar posições.

Os campos declarados no dicionário corrente são comparados com cada fonte
histórica. Diferenças de esquema e codificação são registradas; o dicionário
atual não é tratado como prova de que todo o histórico tem o mesmo leiaute.

Não se escolhe automaticamente a última versão, não se somam valores entre
fundos e não se calcula rentabilidade ou exposição. Uma visão financeira
numérica ou uma regra de reapresentações exigirá contrato adicional explícito.

## Testes

```powershell
Rscript --vanilla src/utils/p02_testar.R P05_02
Rscript --vanilla src/utils/p02_testar.R P06_02
Rscript --vanilla src/utils/p02_testar.R todas
```

As suítes usam ZIPs fictícios e transporte substituível, sem rede real. Verificam
reuso, atualização, interrupção, corrupção, falhas HTTP, isolamento FIDC,
mudanças de esquema, codificação, repetição de chaves e preservação do produto anterior.
