> Evidência histórica do primeiro incremento P04. Os limites e próximos passos abaixo descrevem aquele momento. Estado atual: P04–P07 implementados, piloto executado; consulte P07_ACEITE_ENTREGA.md, P04_ESQUEMA_OBSERVADO_PILOTO.csv e RETOMADA.md.

# P04 — Leitura do dicionário oficial e período piloto

Em 01/10/2026, o usuário confirmou o piloto **01/07/2026 a 31/08/2026** e autorizou somente a leitura do dicionário. Foram lidos os 18 textos do [ZIP oficial de metadados](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/meta_inf_mensal_fidc_txt.zip). Nenhum informe mensal foi baixado, nenhuma configuração ou função P04 foi implementada e P05 não foi iniciada.

## Evidência e método de leitura

Fonte: [diretório META da CVM](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/). ZIP recebido: 15.942 bytes; SHA-256 `217AF01B4451BAF92D0F39ABBE936C4FD97E6C007356284E1A435F5516264BBD`. A cópia original permanece em `locais/P04_dicionario_oficial/`, ignorada pelo Git. O hash identifica a cópia consultada, sem afirmar autenticidade criptográfica da publicação.

Os textos foram lidos diretamente dos membros do ZIP, sem executar seu conteúdo. Todos falharam na decodificação UTF-8 estrita. A leitura com Windows-1252 recuperou os acentos; não há bytes 0x80–0x9F, de modo que ISO-8859-1 produz os mesmos caracteres para estes textos. Isso descreve o dicionário consultado, **não confirma o encoding dos futuros CSVs**.

Foram identificadas 455 ocorrências de `Campo:` e suas propriedades declaradas. Campo repetido em tabelas diferentes é contado em cada tabela, não como nome global único. O [inventário de propriedades declaradas](P04_CAMPOS_DECLARADOS_DICIONARIO.csv) registra tabela, nome, tipo, tamanho, precisão, escala e arquivo de origem. É saída documental desta leitura, não configuração de processamento ou contrato validado contra os informes.

## Conteúdo observado no dicionário

| Tabela/metadado | Campos declarados |
|---|---:|
| I | 109 |
| II | 37 |
| III | 13 |
| IV | 6 |
| V | 37 |
| VI | 37 |
| VII | 29 |
| VIII | 6 |
| IX | 76 |
| X | 23 |
| X_1 | 5 |
| X_1_1 | 36 |
| X_2 | 6 |
| X_3 | 5 |
| X_4 | 7 |
| X_5 | 11 |
| X_6 | 6 |
| X_7 | 6 |
| **Total** | **455** |

Tipos declarados: 279 `numeric`, 83 `varchar`, 72 `float`, 18 `date`, dois `int` e um `bigint`. Trata-se de metadados de tipos, não de tipos R implementados. A presença desses textos não comprova a presença dos mesmos membros nos ZIPs de julho/agosto.

## Achados técnicos relevantes

1. **Identidade e competência:** `CNPJ_FUNDO_CLASSE` aparece em I–X e algumas subdivisões; X_1, X_2, X_3, X_4 e X_6 usam `CNPJ_FUNDO`. Ambos são `varchar(18)`. Não tratá-los como sinônimos automaticamente. `DT_COMPTC` é `date`, com domínio declarado `AAAA-MM-DD`, nos 18 textos. Isso não demonstra unicidade de linhas.
2. **Classe:** I contém `CLASSE` (`varchar(255)`), `CLASSE_UNICA` (`varchar(1)`) e `CNPJ_CLASSE` (`varchar(50)`). Os dois últimos estão sem descrição/domínio. `TP_FUNDO_CLASSE` consta em várias tabelas. Essas diferenças devem ser preservadas até confirmar o significado no layout real.
3. **Cedentes:** I descreve dois grupos, `TAB_I2A12_*` e `TAB_I2B12_*`, com nove identificadores e nove participações em cada grupo. Os 18 identificadores de cedentes são `varchar(255)`, embora o domínio diga numérico: preservar como texto. As 18 participações são `numeric(17,2)`; a descrição indica percentual, mas não permite confirmar se os CSVs representam 0–1 ou 0–100.
4. **Tabela VIII:** contém `CNPJ_FUNDO_CLASSE`, `DENOM_SOCIAL`, `DT_COMPTC`, `TP_FUNDO_CLASSE`, `VALOR` (`numeric(20,2)`) e `SEQUENCIAL` (`bigint`, precisão 19). Os dois últimos não têm descrição/domínio. Não assumir finalidade de `VALOR`, chave primária, granularidade ou significado de `SEQUENCIAL`.
5. **Tabela IX:** seus 72 campos numéricos são `float`, precisão declarada 53. Não converter essa precisão em quantidade de casas decimais. As propriedades não resolvem a representação textual dos CSVs.
6. **Tabela X:** o metadado X tem 23 campos, incluindo grupos relacionados a risco de crédito e débitos tributários. As oito subdivisões têm estruturas distintas, algumas com `TAB_X_CLASSE_SERIE`. Leitura do dicionário não decide inclusão nem autoriza achatá-las em um único join.

Além de I/`CLASSE_UNICA`, I/`CNPJ_CLASSE`, VIII/`VALOR` e VIII/`SEQUENCIAL`, há descrições/domínios vazios em X_6/`TAB_X_PR_DESEMP_REAL`, X_6/`TAB_X_PR_DESEMP_ESPERADO`, X_7/`TAB_X_PR_GARANTIA_DIRCRED` e X_7/`TAB_X_VL_GARANTIA_DIRCRED`: oito campos ao todo. Não completar essas lacunas por suposição.

## Limites e próximo incremento

Ainda faltam: membros reais de julho/agosto; correspondência entre dicionário e CSV; separador, encoding e decimais dos CSVs; nulos; unidades monetárias; escala percentual; chaves, cardinalidades e obrigatoriedade das tabelas. `numeric(p,s)` declara precisão/escala, não unidade monetária ou separador decimal. Os totais e tamanhos de campos não dimensionam linhas, memória ou tempo do piloto.

P04-RF-002: período confirmado, configuração não implementada. P04-RF-003/RF-005: inventário e tipos documentados parcialmente, sem validação nos informes. P04-TST-004 mantém evidência de consulta manual parcial; não aprova a função ainda inexistente. P04-TST-001/002/003 não executados. P03 permanece documental; P04 parcial; P05–P07 não iniciados.

IA realizou leitura e organização das evidências; a confirmação do período veio do usuário. Próximo passo sugerido, mediante autorização: definir o escopo de tabelas e os contratos provisórios, mantendo lacunas explícitas. A bola fica com o usuário após a publicação deste incremento.
