# Estatísticas dos FIDC

Esta página apresenta os resultados de um **mini projeto didático da Especialização em Engenharia de Software: Automação e Inovação com Inteligência Artificial Generativa, da Universidade Federal de Goiás (UFG)**. O projeto utiliza dados públicos dos informes mensais de Fundos de Investimento em Direitos Creditórios (FIDC) da Comissão de Valores Mobiliários (CVM) para exercitar o ciclo de desenvolvimento de software: configuração das fontes, obtenção dos dados, consolidação, testes e documentação.

A implementação foi desenvolvida em R, com RStudio, apoio de IA generativa por meio do Codex e controle de versões com Git e GitHub, sob decisões e revisão humanas. O pipeline reúne tabelas históricas por competência, uma base consolidada e dados de cedentes. As estatísticas e o ranking abaixo demonstram uma aplicação analítica dos dados produzidos pela seleção.

Consulte o [repositório do projeto](https://github.com/amarallr/akcit_c4_mini_projeto) para conhecer os prompts de desenvolvimento, a arquitetura, os testes e as instruções de reprodução. Os resultados representam a série selecionada e não constituem uma avaliação de todo o histórico de FIDC.

A série analisada abrange **31/01/2020 a 30/09/2026**. Os valores de patrimônio líquido (PL) abaixo estão em **milhões da unidade da fonte**, arredondados a duas casas decimais. Os valores completos estão no [CSV por competência](estatisticas_por_competencia.csv) e no [CSV dos top 25](top25_administradores.csv).

## Metadados do conjunto de dados

| Propriedade | Descrição |
|:---|:---|
| Fonte | Informes mensais de FIDC da CVM, arquivos históricos anuais e arquivos mensais publicados para 2025–2026. |
| Captura desta geração | 06/10/2026; a CVM pode atualizar arquivos históricos posteriormente. |
| Cobertura desta geração | 81 datas de competência, de 01/2020 a 09/2026; a competência é `DT_COMPTC`. |
| Volume consolidado | 8.420.840 linhas nas 18 tabelas temporais e 431.215 registros derivados de cedentes. |
| Organização | 18 tabelas temporais (I–X e subdivisões X_1, X_1_1 e X_2–X_7), consolidadas separadamente; modo temporal, sem tabela flat. |
| Esquema declarado | 455 descrições de campos no dicionário da CVM. Consulte o [dicionário de campos](../../referencias/cvm/dicionario_campos_declarados.csv) e o [esquema observado do piloto](../../referencias/cvm/esquema_observado_piloto.csv). |
| Chaves analíticas | CNPJ normalizado, tipo `Fundo`/`Classe` e data de competência. I e IV são associadas por essas três dimensões. |
| Campos usados nas estatísticas | IV: `TAB_IV_A_VL_PL`; I: `CNPJ_ADMIN` e `ADMIN`; IV: `TP_FUNDO_CLASSE`. |
| Linhagem | As tabelas mantêm CNPJ e valores originais, nome do CSV e ZIP de origem, linha de origem e campo de identidade usado. |
| Limites conhecidos | A tabela X não está presente nos pacotes históricos de 2020–2022. A CVM pode revisar arquivos; unidade monetária e escala percentual não foram confirmadas. |

Esta descrição se refere à geração consolidada deste relatório. O dicionário declara o leiaute; o esquema observado do piloto é uma evidência de julho/agosto de 2026, não uma afirmação de esquema idêntico em todas as competências.

## PL por data de competência

As tabelas exibem somente as competências do quarto trimestre nos cinco anos completos mais recentes (2021–2025). As séries completas continuam disponíveis nos CSVs para download. Estatísticas por DT_COMPTC sobre o PL original, com quantis tipo 7 de R. Fundos/classes e administradores contam CNPJs distintos por data. A associação entre as tabelas I e IV usa CNPJ, tipo (fundo/classe) e data exata.

| Data de competência | Fundos/classes (CNPJs distintos) | Administradores distintos |
|:---|---:|---:|
| 31/10/2021 | 1478 | 47 |
| 30/11/2021 | 1494 | 46 |
| 31/12/2021 | 1547 | 47 |
| 31/10/2022 | 1824 | 43 |
| 30/11/2022 | 1854 | 44 |
| 31/12/2022 | 1912 | 44 |
| 31/10/2023 | 2270 | 45 |
| 30/11/2023 | 2272 | 45 |
| 31/12/2023 | 2404 | 44 |
| 31/10/2024 | 3009 | 50 |
| 30/11/2024 | 3063 | 49 |
| 31/12/2024 | 3143 | 49 |
| 31/10/2025 | 3836 | 51 |
| 30/11/2025 | 3891 | 51 |
| 31/12/2025 | 4018 | 50 |

**Distribuição do PL — valores em milhões**

| Data de competência | Fundos/classes | PL mínimo | Percentil 25 | Mediana | PL médio | Percentil 75 | PL máximo |
|:---|---:|---:|---:|---:|---:|---:|---:|
| 31/10/2021 | 1478 | -27,75 | 10,98 | 38,53 | 209,24 | 116,82 | 79.533,41 |
| 30/11/2021 | 1494 | -27,79 | 10,96 | 38,82 | 221,29 | 118,30 | 101.630,13 |
| 31/12/2021 | 1547 | -27,70 | 10,18 | 38,27 | 199,71 | 117,39 | 66.772,12 |
| 31/10/2022 | 1824 | -31,23 | 10,75 | 39,70 | 192,17 | 124,85 | 48.908,01 |
| 30/11/2022 | 1854 | -31,10 | 11,06 | 39,30 | 199,51 | 127,64 | 61.320,72 |
| 31/12/2022 | 1912 | -31,05 | 11,49 | 40,48 | 198,17 | 129,64 | 47.936,80 |
| 31/10/2023 | 2270 | -30,31 | 8,99 | 38,19 | 191,25 | 119,80 | 41.601,44 |
| 30/11/2023 | 2272 | -30,18 | 9,69 | 38,67 | 197,40 | 124,24 | 45.241,54 |
| 31/12/2023 | 2404 | -30,15 | 10,44 | 41,21 | 202,23 | 132,55 | 37.740,75 |
| 31/10/2024 | 3009 | -30,66 | 12,74 | 45,46 | 225,09 | 141,75 | 90.714,29 |
| 30/11/2024 | 3063 | -36,06 | 13,10 | 46,39 | 226,97 | 146,04 | 96.152,10 |
| 31/12/2024 | 3143 | -35,82 | 13,94 | 48,08 | 232,39 | 148,26 | 91.809,97 |
| 31/10/2025 | 3836 | -32,87 | 13,99 | 49,19 | 233,13 | 161,17 | 66.637,65 |
| 30/11/2025 | 3891 | -40,80 | 13,99 | 49,66 | 233,11 | 162,20 | 61.657,44 |
| 31/12/2025 | 4018 | -32,60 | 13,45 | 48,68 | 228,70 | 159,04 | 61.562,44 |

## Top 25 administradores por PL

**Ordenação:** PL acumulado do período, do maior para o menor. Valores de PL em milhões; participação em percentual. A quantidade de fundos/classes conta CNPJs distintos por administrador no período, sem repetir um fundo presente em mais de um mês. Um fundo que muda de administrador pode aparecer na contagem de ambos.

PL winsorizado antes da soma usada para ordenar o ranking: valores inferiores ao P2,5 são substituídos pelo P2,5 e superiores ao P97,5 pelo P97,5, calculados separadamente em cada data sobre todos os PLs disponíveis. Os dados originais permanecem preservados. A ordenação e o PL acumulado consideram todo o período; as colunas trimestrais mostram, sem winsorização, a soma do PL observado no último mês de cada trimestre (na tabela visível, dezembro dos cinco anos completos mais recentes). A associação usa o administrador vigente nessa competência; sem observação de PL do administrador na data, o valor fica ausente. Percentual usa a soma winsorizada dos administradores identificados, incluindo os fora do top 25. PL ausente é excluído e grupos inteiramente ausentes ficam sem valor. Registros sem administrador identificado permanecem nas estatísticas por competência, mas não entram no ranking nem em seu denominador.
Repetições com a mesma chave, PL e administrador foram contadas uma vez (IV: 1; I: 1). Registros repetidos com valores conflitantes interrompem a geração para revisão.

Cada coluna trimestral é uma posição: soma o PL dos registros da competência do último mês do trimestre, sem somar os meses anteriores. O ranking e a participação continuam calculados pela soma mensal winsorizada de todo o período. Unidade monetária e escala da fonte continuam não confirmadas.

| Posição | Administrador | CNPJ do administrador | Fundos/classes no período | PL em dezembro/2021 | PL em dezembro/2022 | PL em dezembro/2023 | PL em dezembro/2024 | PL em dezembro/2025 | PL acumulado no período | Participação no PL total (%) |
| ---: | :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. | 62.285.390/0001-40 | 1190 | 37.237,73 | 50.555,15 | 67.150,77 | 91.610,80 | 135.847,93 | 5.001.543,87 | 18,22 |
| 2 | BTG PACTUAL SERVIÇOS FINANCEIROS S/A DTVM | 59.281.253/0001-23 | 608 | 17.506,87 | 23.710,38 | 52.721,65 | 75.108,44 | 115.505,61 | 3.073.413,06 | 11,20 |
| 3 | OLIVEIRA TRUST DTVM S.A. | 36.113.876/0001-91 | 278 | 59.104,69 | 74.482,51 | 85.702,59 | 94.728,46 | 86.131,34 | 2.999.673,21 | 10,93 |
| 4 | BANCO DAYCOVAL S.A. | 62.232.889/0001-90 | 506 | 4.603,70 | 12.909,71 | 20.513,62 | 39.792,19 | 55.015,63 | 1.525.067,12 | 5,56 |
| 5 | APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. | 13.486.793/0001-42 | 350 | 25.757,49 | 32.442,76 | 28.131,57 | 18.285,44 | 22.956,03 | 1.454.642,33 | 5,30 |
| 6 | CBSF DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL | 34.829.992/0001-86 | 349 | 4.324,15 | 9.522,01 | 28.865,94 | 74.456,98 | 82.602,16 | 1.389.212,39 | 5,06 |
| 7 | BANCO GENIAL S.A. | 45.246.410/0001-55 | 117 | 13.327,02 | 21.337,00 | 24.858,73 | 37.308,10 | 38.367,48 | 1.257.975,96 | 4,58 |
| 8 | BEM - DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. | 00.066.670/0001-00 | 68 | 12.613,06 | 15.763,51 | 18.066,63 | 25.943,60 | 46.709,53 | 1.202.519,28 | 4,38 |
| 9 | FINAXIS CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. | 03.317.692/0001-94 | 129 | 6.616,39 | 8.964,23 | 10.530,38 | 14.364,93 | 16.361,12 | 738.359,91 | 2,69 |
| 10 | HEMERA DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA | 39.669.186/0001-01 | 169 |  NA | 5.484,55 | 8.952,39 | 13.590,78 | 21.505,88 | 703.518,65 | 2,56 |
| 11 | APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. | 36.864.992/0001-42 | 76 | 3.076,51 | 9.170,21 | 12.147,49 | 12.590,63 | 12.693,12 | 637.959,18 | 2,32 |
| 12 | VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. | 22.610.500/0001-88 | 281 | 4.629,25 | 5.824,63 | 6.823,56 | 10.589,03 | 15.272,01 | 585.357,36 | 2,13 |
| 13 | INTRAG DTVM LTDA. | 62.418.140/0001-31 | 65 | 1.600,62 | 1.389,47 | 3.293,72 | 10.671,60 | 29.652,20 | 568.653,51 | 2,07 |
| 14 | BANVOX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA | 02.671.743/0001-19 | 174 | 7.433,72 | 8.087,88 | 7.284,60 | 13.267,19 | 7.412,38 | 554.807,35 | 2,02 |
| 15 | TRUSTEE DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. | 67.030.395/0001-46 | 150 | 3.345,20 | 4.365,33 | 7.334,94 | 9.895,54 | 14.104,29 | 498.845,08 | 1,82 |
| 16 | ID CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A. | 16.695.922/0001-09 | 356 | 74,09 | 1.169,97 | 3.524,81 | 8.467,28 | 15.507,39 | 393.809,78 | 1,43 |
| 17 | BNY MELLON SERVICOS FINANCEIROS DTVM S.A. | 02.201.501/0001-61 | 62 | 2.168,60 | 3.292,48 | 4.111,63 | 8.625,74 | 11.975,54 | 362.129,89 | 1,32 |
| 18 | SEFER INVESTIMENTOS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. | 00.329.598/0001-67 | 77 | 3.350,27 | 8.341,62 | 12.389,14 | 12.413,54 | 10.274,97 | 359.434,67 | 1,31 |
| 19 | S3 CACEIS BRASIL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A | 62.318.407/0001-19 | 27 | 5.201,79 | 5.434,99 | 6.455,07 | 7.869,97 | 9.179,29 | 359.347,60 | 1,31 |
| 20 | XP INVESTIMENTOS CCTVM S.A. | 02.332.886/0001-04 | 59 |  NA | 1.119,76 | 3.332,88 | 8.929,08 | 16.676,47 | 288.871,94 | 1,05 |
| 21 | PLANNER CORRETORA DE VALORES S.A. | 00.806.535/0001-54 | 275 | 357,00 | 1.077,80 | 2.499,81 | 4.421,54 | 8.378,13 | 271.405,81 | 0,99 |
| 22 | LIMINE TRUST DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. | 24.361.690/0001-72 | 232 | 495,04 | 899,40 | 1.261,91 | 4.586,31 | 11.890,85 | 270.632,89 | 0,99 |
| 23 | FIDD DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. | 37.678.915/0001-60 | 123 | 532,28 | 1.950,97 | 3.315,66 | 7.216,01 | 9.453,37 | 263.583,37 | 0,96 |
| 24 | MASTER S/A CORRETORA DE CAMBIO, TITULOS E VALORES MOBILIARIOS | 33.886.862/0001-12 | 140 | 1.804,86 | 2.786,33 | 4.952,79 | 4.892,32 | 2.174,81 | 230.308,76 | 0,84 |
| 25 | RJI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. | 42.066.258/0001-30 | 25 | 4.067,89 | 4.338,16 | 4.824,34 | 5.215,49 | 5.355,35 | 223.049,67 | 0,81 |

## Breve análise dos top 25

Os líderes, **QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.** e **BTG PACTUAL SERVIÇOS FINANCEIROS S/A DTVM**, representam 18,22% e 11,20% do PL winsorizado, respectivamente. Juntos, concentram **29,42%**; os cinco primeiros somam **51,21%**.

Os 25 administradores apresentados reúnem **91,87%** do total, enquanto os demais respondem por 8,13%. A concentração nos líderes indica uma distribuição desigual do PL administrado neste recorte.

As participações descrevem o PL dos fundos/classes associados a cada administrador após winsorização, sem consolidar CNPJs de um mesmo grupo econômico. Não medem patrimônio próprio, rentabilidade ou qualidade do serviço. As posições de dezembro não permitem concluir uma tendência trimestral; a winsorização usada no ranking reduz a influência das maiores posições mensais individuais.
