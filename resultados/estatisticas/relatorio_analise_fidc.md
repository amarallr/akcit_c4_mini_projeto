# Relatório final de análise dos FIDCs
Geração: 2026-10-07T16:37:08-0300 | Schema: p08-v2026-10-07
Assinatura P06: 6e27d320806f0a0f180ff8f483bb4700106cda816336910dd747e011ac3efee0
## Resumo executivo
Período observado: 2020-01-31 a 2026-09-30 ; 81 competências.
São 186655 posições mensais, 10806 identidades de fundos/classes e 5798 CNPJs distintos no período. Essas contagens incluem os universos separados, sem somar seus patrimônios.
Recorte de pré-consolidação: Todas as posições | desconhecidos: excluídos nos critérios ativos . Sem pré-filtro ativo; geração completa preservada
O relatório tem recorte fixo registrado; filtros exploratórios do painel não o alteram. Ano de 2026 incompleto: parcial até a última competência observada.
Unidade: unidade da fonte . numeric/scale=2 declara precisão, não moeda. Unidade monetária não confirmada no dicionário consultado.
## Fonte, cobertura e principais colunas
Informes mensais públicos da CVM. Período solicitado: 2020-01-01 a 2026-09-30 . Tabelas presentes: I, II, III, IV, IX, V, VI, VII, VIII, X, X_1, X_1_1, X_2, X_3, X_4, X_5, X_6, X_7 .
I e IV são utilizadas nesta análise e seus CSVs têm hashes verificados; as demais tabelas estão disponíveis, mas não foram incorporadas aos cálculos de PL/carteira. X não existe nos pacotes de 2020–2022. Não presumir que metadados presentes garantam dados em cada competência.
CNPJ é identificador textual; DT_COMPTC é a competência do informe; TP_FUNDO_CLASSE separa Fundo e Classe. Nos leiautes antigos, CNPJ_FUNDO e tipo ausente recebem o rótulo Fundo legado. Não há relação patrimonial confirmada para somar fundos e classes. ADMIN/CNPJ_ADMIN identificam o administrador na data do informe, sem substituição pelo atual; não são identidade de gestor.
TAB_IV_A_VL_PL é o patrimônio líquido informado (tabela IV). TAB_I_VL_ATIVO é ativo; TAB_I1_VL_DISP, TAB_I2_VL_CARTEIRA, TAB_I3_VL_POSICAO_DERIV e TAB_I4_VL_OUTRO_ATIVO são componentes do primeiro nível. Os campos I.2.a–I.2.j detalham a carteira; provisões são distintas e não adicionadas como ativos positivos.
COTST_INTERESSE informa interesse único e indissociável (S/N); FUNDO_EXCLUSIVO informa exclusividade (S/N), critérios independentes. CONDOM tem domínio Aberto/Fechado. TAB_X_NR_COTST é número de cotistas por classe/série em X_1; múltiplas séries não comprovam quantidade de pessoas distintas da entidade e são desconhecidas no filtro de quantidade.
[Dicionário analítico completo](dicionario_analitico.csv) | [Mapa de categorias e hierarquia](mapa_carteira.csv) | [Posições integrais](posicoes_fundos_classes.csv)
## Metodologia e qualidade
Chave CNPJ/tipo/data; I e IV passam por teste de cardinalidade antes do join 1:1. Repetições sem diferenças analíticas são resolvidas; divergências de PL/administrador interrompem geração. CNPJ de administrador é validado por formato e dígitos verificadores, sem confirmar cadastro/titularidade; identificador inválido ou ausente fica fora do ranking e dentro das estatísticas gerais.
Quantis usam tipo 7 de R: h=1+(n−1)p, interpolação entre posições ordenadas. Percentil 97,5 (P97,5) = quantile(x, probs=0.975, type=7, na.rm=TRUE), calculado nos PL originais do grupo, antes da winsorização. n=0 indisponível; n=1 único valor. Desvio padrão amostral apenas n≥2. IQR=P75−P25. Boxplot: caixa P25–P75, mediana, bigodes nas observações dentro de 1,5×IQR e pontos extremos.
Ranking por competência usa PL original na mesma data. Ranking histórico soma posições mensais winsorizadas em P2,5/P97,5 globais por universo/tipo/competência. Não é fluxo, PL atual, encerramento ou patrimônio próprio do administrador. Denominador de participação usa todos os administradores identificados antes de cortar top25; desempate pelo CNPJ crescente. Cobertura desigual pode influenciar o histórico.
Nulo não é zero. Valores negativos permanecem identificados; razões com denominadores indisponíveis/zero não são publicadas como zero. HHI (escala 0–10.000) e top5/10/25 apenas quando todos os PL agregados identificados são não negativos e soma positiva, sem classificação regulatória automática.
## Estatísticas e achados por universo
## Universo: Classe
Cobertura observada: 2021-02-28 a 2026-09-30 ; 51 competências.
Na última competência 2026-09-30 : PL total 42.590.409.356,39 ; 422 valores válidos e 0 ausentes. Média 100.925.140,65 ; mediana 28.036.566,51 ; Percentil 97,5 (P97,5) 606.498.571,93 .
Maior total observado: 1.015.491.808.627,77 em 2026-07-31 . Primeiro total observado: 331.161.238,08 em 2021-02-28 . A população varia entre datas; a diferença não é rentabilidade.
Posições sem administrador validado na última data: 0 ; PL correspondente: Indisponível . PL coberto por administradores: 100,00% .
Distribuição original na última data: 2 PL negativos; 33 zeros; 48 potenciais outliers pelas cercas de 1,5×IQR; 13 valores alterados na visão winsorizada. Extremo estatístico não comprova erro ou irregularidade.
Estatísticas descritivas por competência; a coluna P97,5 é do PL original. Todos os demais indicadores estão no CSV completo.
| Competência | n válido | Mediana | Percentil 97,5 (P97,5) |
| --- | --- | --- | --- |
| 2021-02-28 | 2 | 165.580.619,04 | 183.712.930,54 |
| 2021-03-31 | 2 | 146.634.382,66 | 155.720.208,60 |
| 2021-04-30 | 2 | 148.122.305,38 | 157.366.707,32 |
| 2021-05-31 | 2 | 149.409.930,14 | 158.344.456,24 |
| 2021-06-30 | 2 | 149.370.648,61 | 157.049.918,28 |
| 2021-07-31 | 2 | 190.799.233,82 | 220.347.531,45 |
| 2021-08-31 | 2 | 224.057.171,01 | 224.932.011,23 |
| 2021-09-30 | 2 | 246.535.229,75 | 267.253.740,18 |
| 2021-10-31 | 2 | 269.310.230,86 | 310.565.839,38 |
| 2021-11-30 | 2 | 351.418.666,92 | 469.020.873,07 |
| 2021-12-31 | 2 | 357.110.668,62 | 673.595.754,03 |
| 2022-01-31 | 2 | 348.941.223,74 | 656.740.275,88 |
| 2022-02-28 | 2 | 332.965.096,59 | 625.369.101,10 |
| 2022-03-31 | 2 | 333.387.039,98 | 625.564.435,22 |
| 2022-04-30 | 2 | 336.161.209,70 | 630.692.473,72 |
| 2023-07-31 | 1 | 960.853.969,74 | 960.853.969,74 |
| 2023-08-31 | 1 | 976.608.803,14 | 976.608.803,14 |
| 2023-09-30 | 1 | 981.880.222,46 | 981.880.222,46 |
| 2023-11-30 | 1 | 956.300.076,12 | 956.300.076,12 |
| 2023-12-31 | 1 | 974.364.591,62 | 974.364.591,62 |
| 2024-01-31 | 1 | 963.318.035,28 | 963.318.035,28 |
| 2024-02-29 | 1 | 909.664.702,24 | 909.664.702,24 |
| 2024-03-31 | 1 | 944.048.041,96 | 944.048.041,96 |
| 2024-04-30 | 1 | 918.421.509,93 | 918.421.509,93 |
| 2024-07-31 | 1 | 787.319.658,48 | 787.319.658,48 |
| 2024-08-31 | 1 | 731.408.067,17 | 731.408.067,17 |
| 2024-09-30 | 1 | 754.766.883,68 | 754.766.883,68 |
| 2024-10-31 | 1820 | 41.766.759,14 | 1.045.665.907,55 |
| 2024-11-30 | 2168 | 44.559.931,34 | 1.092.386.524,22 |
| 2024-12-31 | 2931 | 50.763.898,43 | 1.369.297.459,13 |
| 2025-01-31 | 3027 | 50.006.546,68 | 1.316.320.561,60 |
| 2025-02-28 | 3102 | 51.297.698,22 | 1.354.241.559,48 |
| 2025-03-31 | 3180 | 50.988.713,46 | 1.327.505.614,68 |
| 2025-04-30 | 3238 | 51.041.773,47 | 1.310.033.733,51 |
| 2025-05-31 | 3315 | 51.566.290,10 | 1.337.340.850,91 |
| 2025-06-30 | 3406 | 51.615.007,77 | 1.412.331.430,42 |
| 2025-07-31 | 3521 | 51.106.263,81 | 1.375.081.454,12 |
| 2025-08-31 | 3597 | 51.549.616,65 | 1.377.306.410,49 |
| 2025-09-30 | 3672 | 50.880.831,88 | 1.444.474.394,01 |
| 2025-10-31 | 3793 | 50.105.147,87 | 1.399.248.601,46 |
| 2025-11-30 | 1834 | 34.311.877,62 | 1.397.943.301,90 |
| 2025-12-31 | 2126 | 37.714.936,89 | 1.395.930.855,09 |
| 2026-01-31 | 3447 | 46.868.665,25 | 1.554.819.117,76 |
| 2026-02-28 | 4090 | 49.127.582,80 | 1.427.487.232,74 |
| 2026-03-31 | 4137 | 48.821.442,09 | 1.407.130.633,24 |
| 2026-04-30 | 4210 | 50.054.110,98 | 1.515.977.451,14 |
| 2026-05-31 | 4249 | 50.314.812,67 | 1.536.815.023,42 |
| 2026-06-30 | 4328 | 49.709.231,12 | 1.490.850.969,33 |
| 2026-07-31 | 4369 | 48.496.954,03 | 1.537.008.596,65 |
| 2026-08-31 | 4375 | 48.538.183,49 | 1.494.443.796,24 |
| 2026-09-30 | 422 | 28.036.566,51 | 606.498.571,93 |

Concentração na última competência: top5 97,69% ; top10 100,00% ; top25 100,00% ; demais 0,00% ; HHI 4.377,17 . [Concentração por competência](concentracao.csv).
Top 25 por PL na competência 2026-09-30 — valores originais; participação sobre todos os administradores identificados.
| Posição | Administrador | PL | Participação | Fundos/classes |
| --- | --- | --- | --- | --- |
| 1 | QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 62285390000140 | 27.102.672.323,64 | 63,64% | 123 |
| 2 | ID CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A. 16695922000109 | 5.119.951.458,15 | 12,02% | 84 |
| 3 | LIMINE TRUST DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. 24361690000172 | 4.144.645.861,45 | 9,73% | 82 |
| 4 | BANCO DAYCOVAL S.A. 62232889000190 | 3.581.072.140,66 | 8,41% | 43 |
| 5 | AZUMI DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 40434681000110 | 1.658.465.537,50 | 3,89% | 74 |
| 6 | PLANNER CORRETORA DE VALORES S.A. 00806535000154 | 643.014.723,66 | 1,51% | 9 |
| 7 | INTER DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS 18945670000146 | 194.891.193,37 | 0,46% | 4 |
| 8 | VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 22610500000188 | 145.696.117,96 | 0,34% | 1 |
| 9 | HEMERA DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 39669186000101 | 0,00 | 0,00% | 1 |
| 10 | VERT DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 48967968000118 | 0,00 | 0,00% | 1 |

Ranking histórico por soma de posições mensais winsorizadas — meses observados por administrador, valores não representam patrimônio atual.
| Posição | Administrador | Soma | Participação | Meses |
| --- | --- | --- | --- | --- |
| 1 | QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 62285390000140 | 2.249.437.121.627,90 | 17,88% | 24 |
| 2 | BTG PACTUAL SERVIÇOS FINANCEIROS S/A DTVM 59281253000123 | 1.676.706.302.573,97 | 13,33% | 23 |
| 3 | BANCO DAYCOVAL S.A. 62232889000190 | 927.334.240.509,13 | 7,37% | 24 |
| 4 | OLIVEIRA TRUST DTVM S.A. 36113876000191 | 876.663.682.373,50 | 6,97% | 22 |
| 5 | CBSF DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL 34829992000186 | 827.355.702.897,90 | 6,58% | 23 |
| 6 | BANCO GENIAL S.A. 45246410000155 | 524.618.004.449,68 | 4,17% | 23 |
| 7 | BEM - DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 00066670000100 | 472.680.558.897,94 | 3,76% | 22 |
| 8 | HEMERA DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 39669186000101 | 433.434.716.972,21 | 3,45% | 36 |
| 9 | APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 13486793000142 | 376.711.259.322,87 | 2,99% | 31 |
| 10 | VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 22610500000188 | 295.364.573.540,26 | 2,35% | 24 |
| 11 | FINAXIS CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 03317692000194 | 293.373.856.085,86 | 2,33% | 30 |
| 12 | INTRAG DTVM LTDA. 62418140000131 | 289.611.143.026,89 | 2,30% | 23 |
| 13 | APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 36864992000142 | 256.468.176.990,23 | 2,04% | 23 |
| 14 | TRUSTEE DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 67030395000146 | 241.796.902.057,53 | 1,92% | 23 |
| 15 | ID CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A. 16695922000109 | 241.678.196.343,67 | 1,92% | 24 |
| 16 | LIMINE TRUST DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. 24361690000172 | 212.484.490.703,39 | 1,69% | 24 |
| 17 | BANVOX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 02671743000119 | 205.584.790.427,15 | 1,63% | 22 |
| 18 | XP INVESTIMENTOS CCTVM S.A. 02332886000104 | 191.524.879.664,45 | 1,52% | 23 |
| 19 | BNY MELLON SERVICOS FINANCEIROS DTVM S.A. 02201501000161 | 174.991.221.909,69 | 1,39% | 21 |
| 20 | PLANNER CORRETORA DE VALORES S.A. 00806535000154 | 165.437.980.508,50 | 1,32% | 24 |
| 21 | FIDD DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 37678915000160 | 159.830.812.854,20 | 1,27% | 23 |
| 22 | GENIAL INVESTIMENTOS CORRETORA DE VALORES MOBILIÁRIOS S.A. 27652684000162 | 159.246.678.358,52 | 1,27% | 21 |
| 23 | VERT DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 48967968000118 | 152.790.942.986,63 | 1,21% | 24 |
| 24 | SEFER INVESTIMENTOS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 00329598000167 | 140.744.024.914,45 | 1,12% | 23 |
| 25 | S3 CACEIS BRASIL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A 62318407000119 | 125.888.670.929,31 | 1,00% | 23 |

Líder por competência: QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. ; líder histórico: QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. . São medidas e populações temporais diferentes. [Rankings completos](ranking_por_competencia.csv).
Cobertura entre as duas últimas competências: 4375 posições em 2026-08-31 e 422 em 2026-09-30 ( 9,65% da quantidade anterior). Essa alteração da população observada impede interpretar a diferença dos totais como mudança de tamanho do mercado. A origem da ausência não foi determinada; não se presume liquidação.
Comparação homogênea 2026-08-31 → 2026-09-30 : 418 entidades com PL em ambas as datas; total inicial 40.979.679.287,49 ; final 41.910.081.924,78 ; diferença absoluta 930.402.637,29 . 4 entradas e 3957 saídas de registros na população observada. Entrada/saída não prova criação/liquidação; ausência de informe e mudança de leiaute também podem interferir.
Composição do ativo na última competência: razão de somas nas mesmas posições comparáveis, base ativo total positivo.
Reconciliação de quatro componentes do ativo: 421 de 422 posições reconciliadas; 0 sem dados completos; 1 com diferença acima da tolerância. Tolerância absoluta: 0,05 unidade da fonte, soma de cinco arredondamentos de centavos. Não foi criado residual para forçar 100%. Barras de 100% usam somente posições completas, não negativas e reconciliadas.
[Reconciliação por posição](reconciliacao_carteira.csv) | [Composição por administrador](carteira_por_administrador.csv)
| Categoria | Valor | % do ativo comparável | Posições cobertas |
| --- | --- | --- | --- |
| Disponibilidades | 140.115.262,64 | 0,33% | 389 |
| Carteira | 42.588.186.303,84 | 98,94% | 389 |
| Posição em derivativos | 86.429.655,45 | 0,20% | 389 |
| Outros ativos | 227.872.477,88 | 0,53% | 389 |

## Universo: Fundo
Cobertura observada: 2020-11-30 a 2026-09-30 ; 71 competências.
Na última competência 2026-09-30 : PL total 14.661.991,44 ; 6 valores válidos e 0 ausentes. Média 2.443.665,24 ; mediana 0,00 ; Percentil 97,5 (P97,5) 12.829.242,51 .
Maior total observado: 640.117.138.443,02 em 2024-09-30 . Primeiro total observado: 214.070.335.329,26 em 2020-11-30 . A população varia entre datas; a diferença não é rentabilidade.
Posições sem administrador validado na última data: 0 ; PL correspondente: Indisponível . PL coberto por administradores: 100,00% .
Distribuição original na última data: 0 PL negativos; 5 zeros; 1 potenciais outliers pelas cercas de 1,5×IQR; 1 valores alterados na visão winsorizada. Extremo estatístico não comprova erro ou irregularidade.
Estatísticas descritivas por competência; a coluna P97,5 é do PL original. Todos os demais indicadores estão no CSV completo.
| Competência | n válido | Mediana | Percentil 97,5 (P97,5) |
| --- | --- | --- | --- |
| 2020-11-30 | 1198 | 36.698.431,91 | 1.124.565.028,26 |
| 2020-12-31 | 1230 | 37.393.988,10 | 1.223.355.419,09 |
| 2021-01-31 | 1224 | 36.591.330,25 | 1.226.192.000,90 |
| 2021-02-28 | 1232 | 37.741.117,06 | 1.202.132.502,23 |
| 2021-03-31 | 1271 | 36.494.800,86 | 1.250.405.573,23 |
| 2021-04-30 | 1293 | 35.698.178,69 | 1.263.469.142,30 |
| 2021-05-31 | 1336 | 36.056.684,96 | 1.347.302.722,90 |
| 2021-06-30 | 1367 | 36.102.575,44 | 1.351.057.402,70 |
| 2021-07-31 | 1383 | 36.054.881,98 | 1.211.180.062,35 |
| 2021-08-31 | 1424 | 35.906.048,77 | 1.202.106.032,85 |
| 2021-09-30 | 1454 | 37.005.729,56 | 1.148.320.963,33 |
| 2021-10-31 | 1476 | 38.395.005,80 | 1.036.839.755,79 |
| 2021-11-30 | 1492 | 38.641.594,52 | 1.064.175.983,06 |
| 2021-12-31 | 1545 | 38.272.023,46 | 1.083.729.807,43 |
| 2022-01-31 | 1550 | 39.369.919,55 | 1.106.749.119,90 |
| 2022-02-28 | 1576 | 40.047.631,16 | 1.087.718.432,98 |
| 2022-03-31 | 1603 | 39.292.592,94 | 1.062.065.498,03 |
| 2022-04-30 | 1642 | 38.960.644,07 | 1.060.016.844,26 |
| 2022-05-31 | 1663 | 40.211.330,07 | 1.068.062.298,18 |
| 2022-06-30 | 1698 | 39.762.895,20 | 1.146.863.227,68 |
| 2022-07-31 | 1735 | 38.830.573,63 | 1.210.398.950,32 |
| 2022-08-31 | 1767 | 40.013.593,30 | 1.262.715.218,78 |
| 2022-09-30 | 1787 | 40.202.294,56 | 1.288.334.636,99 |
| 2022-10-31 | 1824 | 39.696.580,13 | 1.280.355.603,93 |
| 2022-11-30 | 1854 | 39.296.663,78 | 1.258.701.319,55 |
| 2022-12-31 | 1912 | 40.480.728,44 | 1.306.711.022,43 |
| 2023-01-31 | 1937 | 40.472.479,70 | 1.232.169.592,34 |
| 2023-02-28 | 1955 | 40.926.734,08 | 1.213.925.263,61 |
| 2023-03-31 | 2009 | 40.525.601,34 | 1.267.041.479,14 |
| 2023-04-30 | 2034 | 39.620.817,12 | 1.262.499.786,21 |
| 2023-05-31 | 2044 | 41.319.049,86 | 1.261.155.615,62 |
| 2023-06-30 | 2068 | 41.423.537,04 | 1.271.189.104,30 |
| 2023-07-31 | 2086 | 42.077.932,83 | 1.272.026.479,23 |
| 2023-08-31 | 2128 | 41.382.033,46 | 1.273.795.010,21 |
| 2023-09-30 | 2276 | 35.931.581,88 | 1.301.766.278,13 |
| 2023-10-31 | 2270 | 38.193.421,69 | 1.303.714.517,54 |
| 2023-11-30 | 2271 | 38.593.939,76 | 1.304.038.283,80 |
| 2023-12-31 | 2404 | 41.161.834,58 | 1.288.784.727,09 |
| 2024-01-31 | 2425 | 41.821.177,66 | 1.275.171.986,57 |
| 2024-02-29 | 2446 | 42.513.955,83 | 1.284.867.199,27 |
| 2024-03-31 | 2490 | 42.282.654,72 | 1.346.222.922,93 |
| 2024-04-30 | 2538 | 43.338.921,41 | 1.327.002.367,13 |
| 2024-05-31 | 2612 | 43.418.204,58 | 1.393.138.781,06 |
| 2024-06-30 | 2682 | 43.139.188,86 | 1.370.129.141,17 |
| 2024-07-31 | 2744 | 44.327.834,16 | 1.399.022.921,23 |
| 2024-08-31 | 2812 | 44.313.864,20 | 1.285.957.551,99 |
| 2024-09-30 | 2883 | 44.287.123,89 | 1.304.926.287,38 |
| 2024-10-31 | 1195 | 53.333.486,69 | 1.545.992.807,14 |
| 2024-11-30 | 906 | 54.541.591,91 | 1.690.493.348,91 |
| 2024-12-31 | 226 | 20.573.092,67 | 724.226.786,13 |
| 2025-01-31 | 187 | 23.446.391,81 | 708.698.316,16 |
| 2025-02-28 | 175 | 19.102.434,83 | 572.245.410,95 |
| 2025-03-31 | 160 | 21.197.186,23 | 508.409.560,14 |
| 2025-04-30 | 174 | 22.369.817,52 | 676.641.719,16 |
| 2025-05-31 | 174 | 24.961.509,08 | 526.478.424,53 |
| 2025-06-30 | 210 | 27.853.180,02 | 946.363.706,22 |
| 2025-07-31 | 150 | 27.951.282,48 | 590.822.294,00 |
| 2025-08-31 | 146 | 32.593.133,25 | 818.706.026,90 |
| 2025-09-30 | 104 | 25.260.076,45 | 618.690.826,21 |
| 2025-10-31 | 46 | 29.861.840,60 | 892.298.044,84 |
| 2025-11-30 | 2059 | 67.379.277,39 | 1.435.548.983,94 |
| 2025-12-31 | 1904 | 62.250.730,46 | 1.568.600.117,83 |
| 2026-01-31 | 632 | 55.997.363,87 | 1.094.540.880,51 |
| 2026-02-28 | 19 | 0,00 | 95.517.490,04 |
| 2026-03-31 | 23 | 6.193.335,14 | 858.769.456,17 |
| 2026-04-30 | 28 | 1.606.289,94 | 683.148.336,61 |
| 2026-05-31 | 26 | 2.274.521,17 | 182.441.283,27 |
| 2026-06-30 | 21 | 0,00 | 111.877.360,31 |
| 2026-07-31 | 21 | 0,00 | 40.862.776,43 |
| 2026-08-31 | 25 | 0,00 | 102.328.271,43 |
| 2026-09-30 | 6 | 0,00 | 12.829.242,51 |

Concentração na última competência: top5 100,00% ; top10 100,00% ; top25 100,00% ; demais 0,00% ; HHI 10.000,00 . [Concentração por competência](concentracao.csv).
Top 25 por PL na competência 2026-09-30 — valores originais; participação sobre todos os administradores identificados.
| Posição | Administrador | PL | Participação | Fundos/classes |
| --- | --- | --- | --- | --- |
| 1 | ID CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A. 16695922000109 | 14.661.991,44 | 100,00% | 3 |
| 2 | LIMINE TRUST DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. 24361690000172 | 0,00 | 0,00% | 1 |
| 3 | AZUMI DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 40434681000110 | 0,00 | 0,00% | 1 |
| 4 | VERT DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 48967968000118 | 0,00 | 0,00% | 1 |

Ranking histórico por soma de posições mensais winsorizadas — meses observados por administrador, valores não representam patrimônio atual.
| Posição | Administrador | Soma | Participação | Meses |
| --- | --- | --- | --- | --- |
| 1 | QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 62285390000140 | 2.533.885.115.978,08 | 18,78% | 70 |
| 2 | OLIVEIRA TRUST DTVM S.A. 36113876000191 | 1.897.491.441.177,47 | 14,06% | 65 |
| 3 | BTG PACTUAL SERVIÇOS FINANCEIROS S/A DTVM 59281253000123 | 1.281.609.316.320,57 | 9,50% | 63 |
| 4 | APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 13486793000142 | 997.070.293.093,78 | 7,39% | 70 |
| 5 | BANCO GENIAL S.A. 45246410000155 | 723.872.098.312,70 | 5,37% | 60 |
| 6 | BEM - DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 00066670000100 | 603.845.806.974,82 | 4,48% | 70 |
| 7 | BANCO DAYCOVAL S.A. 62232889000190 | 581.713.789.353,06 | 4,31% | 64 |
| 8 | CBSF DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL 34829992000186 | 555.478.122.121,67 | 4,12% | 59 |
| 9 | FINAXIS CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 03317692000194 | 398.172.579.443,03 | 2,95% | 60 |
| 10 | BANVOX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 02671743000119 | 335.146.443.096,39 | 2,48% | 52 |
| 11 | APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 36864992000142 | 330.864.225.166,53 | 2,45% | 53 |
| 12 | VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 22610500000188 | 268.579.369.305,31 | 1,99% | 62 |
| 13 | TRUSTEE DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 67030395000146 | 236.496.117.776,25 | 1,75% | 50 |
| 14 | HEMERA DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 39669186000101 | 229.500.507.620,71 | 1,70% | 42 |
| 15 | SEFER INVESTIMENTOS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 00329598000167 | 215.696.679.110,92 | 1,60% | 54 |
| 16 | INTRAG DTVM LTDA. 62418140000131 | 212.340.783.879,28 | 1,57% | 54 |
| 17 | S3 CACEIS BRASIL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A 62318407000119 | 202.520.835.862,01 | 1,50% | 61 |
| 18 | BNY MELLON SERVICOS FINANCEIROS DTVM S.A. 02201501000161 | 170.049.844.678,77 | 1,26% | 70 |
| 19 | ID CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A. 16695922000109 | 144.038.748.152,45 | 1,07% | 63 |
| 20 | MASTER S/A CORRETORA DE CAMBIO, TITULOS E VALORES MOBILIARIOS 33886862000112 | 143.320.154.757,59 | 1,06% | 55 |
| 21 | XP SERVIÇOS FINANCEIROS DTVM LTDA. 05389174000101 | 138.196.813.639,11 | 1,02% | 35 |
| 22 | BANCO FINAXIS S.A. 11758741000152 | 137.435.733.304,84 | 1,02% | 50 |
| 23 | RJI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 42066258000130 | 128.863.265.524,54 | 0,96% | 49 |
| 24 | FINVEST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 36266751000100 | 119.647.109.389,76 | 0,89% | 47 |
| 25 | XP INVESTIMENTOS CCTVM S.A. 02332886000104 | 89.111.615.071,74 | 0,66% | 46 |

Líder por competência: ID CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A. ; líder histórico: QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. . São medidas e populações temporais diferentes. [Rankings completos](ranking_por_competencia.csv).
Cobertura entre as duas últimas competências: 25 posições em 2026-08-31 e 6 em 2026-09-30 ( 24,00% da quantidade anterior). Essa alteração da população observada impede interpretar a diferença dos totais como mudança de tamanho do mercado. A origem da ausência não foi determinada; não se presume liquidação.
Comparação homogênea 2026-08-31 → 2026-09-30 : 6 entidades com PL em ambas as datas; total inicial 14.569.701,20 ; final 14.661.991,44 ; diferença absoluta 92.290,24 . 0 entradas e 19 saídas de registros na população observada. Entrada/saída não prova criação/liquidação; ausência de informe e mudança de leiaute também podem interferir.
Composição do ativo na última competência: razão de somas nas mesmas posições comparáveis, base ativo total positivo.
Reconciliação de quatro componentes do ativo: 6 de 6 posições reconciliadas; 0 sem dados completos; 0 com diferença acima da tolerância. Tolerância absoluta: 0,05 unidade da fonte, soma de cinco arredondamentos de centavos. Não foi criado residual para forçar 100%. Barras de 100% usam somente posições completas, não negativas e reconciliadas.
[Reconciliação por posição](reconciliacao_carteira.csv) | [Composição por administrador](carteira_por_administrador.csv)
| Categoria | Valor | % do ativo comparável | Posições cobertas |
| --- | --- | --- | --- |
| Disponibilidades | 1.886,76 | 0,01% | 1 |
| Carteira | 14.685.951,61 | 99,92% | 1 |
| Posição em derivativos | 0,00 | 0,00% | 1 |
| Outros ativos | 9.153,07 | 0,06% | 1 |

## Universo: Fundo legado
Cobertura observada: 2020-01-31 a 2020-10-31 ; 10 competências.
Na última competência 2020-10-31 : PL total 217.425.723.839,76 ; 1151 valores válidos e 0 ausentes. Média 188.901.584,57 ; mediana 38.848.538,66 ; Percentil 97,5 (P97,5) 1.184.019.398,77 .
Maior total observado: 242.883.196.486,54 em 2020-03-31 . Primeiro total observado: 231.083.445.014,66 em 2020-01-31 . A população varia entre datas; a diferença não é rentabilidade.
Posições sem administrador validado na última data: 8 ; PL correspondente: 8.083.765.161,89 . PL coberto por administradores: 96,28% .
Distribuição original na última data: 4 PL negativos; 7 zeros; 151 potenciais outliers pelas cercas de 1,5×IQR; 58 valores alterados na visão winsorizada. Extremo estatístico não comprova erro ou irregularidade.
Estatísticas descritivas por competência; a coluna P97,5 é do PL original. Todos os demais indicadores estão no CSV completo.
| Competência | n válido | Mediana | Percentil 97,5 (P97,5) |
| --- | --- | --- | --- |
| 2020-01-31 | 1052 | 38.708.852,71 | 1.123.449.615,69 |
| 2020-02-29 | 1061 | 38.681.288,83 | 1.151.136.927,85 |
| 2020-03-31 | 1069 | 39.325.661,88 | 1.189.365.726,01 |
| 2020-04-30 | 1075 | 39.863.371,48 | 1.216.018.981,15 |
| 2020-05-31 | 1087 | 37.982.561,66 | 1.172.765.736,16 |
| 2020-06-30 | 1090 | 37.575.526,63 | 1.201.086.520,87 |
| 2020-07-31 | 1115 | 36.199.105,95 | 1.184.774.143,85 |
| 2020-08-31 | 1129 | 36.618.837,54 | 1.181.146.622,76 |
| 2020-09-30 | 1142 | 37.009.122,72 | 1.196.512.784,53 |
| 2020-10-31 | 1151 | 38.848.538,66 | 1.184.019.398,77 |

Concentração na última competência: top5 58,16% ; top10 75,25% ; top25 94,97% ; demais 5,03% ; HHI 842,88 . [Concentração por competência](concentracao.csv).
Top 25 por PL na competência 2020-10-31 — valores originais; participação sobre todos os administradores identificados.
| Posição | Administrador | PL | Participação | Fundos/classes |
| --- | --- | --- | --- | --- |
| 1 | OLIVEIRA TRUST DTVM S.A. 36113876000191 | 37.122.197.549,55 | 17,73% | 76 |
| 2 | BB GESTAO DE RECURSOS DTVM S.A 30822936000169 | 27.980.947.806,17 | 13,37% | 3 |
| 3 | QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 62285390000140 | 24.411.049.049,80 | 11,66% | 342 |
| 4 | BEM - DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 00066670000100 | 17.716.233.982,02 | 8,46% | 24 |
| 5 | BTG PACTUAL SERVIÇOS FINANCEIROS S/A DTVM 59281253000123 | 14.529.390.579,68 | 6,94% | 80 |
| 6 | APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 13486793000142 | 10.019.904.778,79 | 4,79% | 68 |
| 7 | INTRAG DTVM LTDA. 62418140000131 | 8.083.905.466,96 | 3,86% | 10 |
| 8 | RJI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 42066258000130 | 5.995.551.410,55 | 2,86% | 12 |
| 9 | APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 36864992000142 | 5.898.119.306,15 | 2,82% | 19 |
| 10 | S3 CACEIS BRASIL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A 62318407000119 | 5.782.549.200,77 | 2,76% | 10 |
| 11 | TRUSTEE DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 67030395000146 | 5.146.908.688,95 | 2,46% | 30 |
| 12 | FINAXIS CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 03317692000194 | 4.731.316.970,95 | 2,26% | 46 |
| 13 | HEMERA DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 39669186000101 | 4.251.338.788,19 | 2,03% | 47 |
| 14 | GENIAL INVESTIMENTOS CORRETORA DE VALORES MOBILIÁRIOS S.A. 27652684000162 | 4.211.249.235,63 | 2,01% | 8 |
| 15 | BANCO FINAXIS S.A. 11758741000152 | 2.538.945.451,83 | 1,21% | 21 |
| 16 | TERRA INVESTIMENTOS DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 03751794000113 | 2.407.659.494,76 | 1,15% | 5 |
| 17 | PLANNER CORRETORA DE VALORES S.A. 00806535000154 | 2.350.019.689,39 | 1,12% | 30 |
| 18 | MONETAR DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 12063256000127 | 2.157.495.187,35 | 1,03% | 11 |
| 19 | VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 22610500000188 | 2.155.316.548,81 | 1,03% | 30 |
| 20 | BANCO GENIAL S.A. 45246410000155 | 2.151.782.250,03 | 1,03% | 17 |
| 21 | BANCO DAYCOVAL S.A. 62232889000190 | 2.101.063.654,25 | 1,00% | 32 |
| 22 | CAIXA ECONOMICA FEDERAL 00360305000104 | 2.085.300.381,27 | 1,00% | 5 |
| 23 | BNY MELLON SERVICOS FINANCEIROS DTVM S.A. 02201501000161 | 1.904.357.093,62 | 0,91% | 14 |
| 24 | LIMINE TRUST DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. 24361690000172 | 1.537.974.662,82 | 0,73% | 36 |
| 25 | CBSF DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL 34829992000186 | 1.537.220.626,98 | 0,73% | 8 |

Ranking histórico por soma de posições mensais winsorizadas — meses observados por administrador, valores não representam patrimônio atual.
| Posição | Administrador | Soma | Participação | Meses |
| --- | --- | --- | --- | --- |
| 1 | OLIVEIRA TRUST DTVM S.A. 36113876000191 | 233.396.175.306,10 | 16,49% | 10 |
| 2 | QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 62285390000140 | 218.013.379.039,54 | 15,40% | 10 |
| 3 | BEM - DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 00066670000100 | 131.423.083.606,06 | 9,28% | 10 |
| 4 | BTG PACTUAL SERVIÇOS FINANCEIROS S/A DTVM 59281253000123 | 125.702.605.630,11 | 8,88% | 10 |
| 5 | APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 13486793000142 | 83.889.737.063,36 | 5,93% | 10 |
| 6 | INTRAG DTVM LTDA. 62418140000131 | 67.303.597.620,68 | 4,75% | 10 |
| 7 | APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 36864992000142 | 52.677.831.618,38 | 3,72% | 10 |
| 8 | FINAXIS CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A. 03317692000194 | 47.014.044.254,07 | 3,32% | 10 |
| 9 | HEMERA DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 39669186000101 | 40.814.041.008,39 | 2,88% | 10 |
| 10 | S3 CACEIS BRASIL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A 62318407000119 | 32.502.099.101,50 | 2,30% | 10 |
| 11 | RJI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. 42066258000130 | 30.105.485.400,54 | 2,13% | 10 |
| 12 | PLANNER CORRETORA DE VALORES S.A. 00806535000154 | 23.103.440.962,06 | 1,63% | 10 |
| 13 | BANCO FINAXIS S.A. 11758741000152 | 21.846.381.523,80 | 1,54% | 10 |
| 14 | VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 22610500000188 | 21.470.834.612,88 | 1,52% | 10 |
| 15 | TRUSTEE DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 67030395000146 | 20.705.085.335,04 | 1,46% | 10 |
| 16 | GENIAL INVESTIMENTOS CORRETORA DE VALORES MOBILIÁRIOS S.A. 27652684000162 | 20.371.777.723,54 | 1,44% | 10 |
| 17 | CAIXA ECONOMICA FEDERAL 00360305000104 | 18.938.373.167,85 | 1,34% | 10 |
| 18 | BNY MELLON SERVICOS FINANCEIROS DTVM S.A. 02201501000161 | 18.745.821.800,52 | 1,32% | 10 |
| 19 | BANCO DAYCOVAL S.A. 62232889000190 | 16.207.471.625,91 | 1,14% | 10 |
| 20 | TERRA INVESTIMENTOS DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 03751794000113 | 15.920.053.172,81 | 1,12% | 10 |
| 21 | BB GESTAO DE RECURSOS DTVM S.A 30822936000169 | 15.681.733.026,92 | 1,11% | 10 |
| 22 | BANVOX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA 02671743000119 | 14.769.747.859,18 | 1,04% | 10 |
| 23 | MONETAR DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA. 12063256000127 | 13.550.547.273,99 | 0,96% | 10 |
| 24 | BANCO GENIAL S.A. 45246410000155 | 13.325.680.738,76 | 0,94% | 10 |
| 25 | LIMINE TRUST DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS S.A. 24361690000172 | 12.941.880.038,71 | 0,91% | 10 |

Líder por competência: OLIVEIRA TRUST DTVM S.A. ; líder histórico: OLIVEIRA TRUST DTVM S.A. . São medidas e populações temporais diferentes. [Rankings completos](ranking_por_competencia.csv).
Cobertura entre as duas últimas competências: 1144 posições em 2020-09-30 e 1151 em 2020-10-31 ( 100,61% da quantidade anterior). Essa alteração da população observada impede interpretar a diferença dos totais como mudança de tamanho do mercado. A origem da ausência não foi determinada; não se presume liquidação.
Comparação homogênea 2020-09-30 → 2020-10-31 : 1125 entidades com PL em ambas as datas; total inicial 229.735.157.112,36 ; final 216.706.488.946,64 ; diferença absoluta -13.028.668.165,72 . 25 entradas e 18 saídas de registros na população observada. Entrada/saída não prova criação/liquidação; ausência de informe e mudança de leiaute também podem interferir.
Composição do ativo na última competência: razão de somas nas mesmas posições comparáveis, base ativo total positivo.
Reconciliação de quatro componentes do ativo: 1151 de 1151 posições reconciliadas; 0 sem dados completos; 0 com diferença acima da tolerância. Tolerância absoluta: 0,05 unidade da fonte, soma de cinco arredondamentos de centavos. Não foi criado residual para forçar 100%. Barras de 100% usam somente posições completas, não negativas e reconciliadas.
[Reconciliação por posição](reconciliacao_carteira.csv) | [Composição por administrador](carteira_por_administrador.csv)
| Categoria | Valor | % do ativo comparável | Posições cobertas |
| --- | --- | --- | --- |
| Disponibilidades | 405.176.676,94 | 0,18% | 1147 |
| Carteira | 212.548.471.753,56 | 95,31% | 1147 |
| Posição em derivativos | 6.880.792,63 | 0,00% | 1147 |
| Outros ativos | 10.048.704.806,07 | 4,51% | 1147 |

## Evolução, distribuições e conclusões
As séries do painel cobrem todas as competências disponíveis por universo. Datas ausentes permanecem lacunas, sem zero/interpolação. Histórico Q4 é apenas preset de apresentação; trimestres são posições do último mês, sem soma de meses. 2026 é identificado como incompleto.
Média, mediana, dispersão e P97,5 descrevem a distribuição de PL entre posições na mesma competência. Boxplots por administrador usam fundos/classes, sem misturar meses como observações independentes. A visão winsorizada é transformação estatística claramente nomeada; as estatísticas descritivas originais permanecem acessíveis.
Os resultados permitem comparar tamanho e concentração do PL informado e composição contábil com cobertura registrada. A separação de universos e o aumento/redução de registros impedem interpretar diferenças de total como crescimento de coorte fixa. A comparação homogênea final compara apenas entidades observadas com PL nas duas datas; seleção e sobrevivência continuam limitando a interpretação.
Concentração e valores extremos não demonstram irregularidade, risco de crédito, eficiência, efeito tributário ou retorno de cota. Não há avaliação causal ou previsão. Investigações futuras: confirmar relação Fundo/Classe, total de cotistas distintos, unidades monetárias e mudanças de leiaute; comparar carteira em coorte estável e explicar divergências de reconciliação na fonte.
## Apêndice: fórmulas, linhagem e reprodução
Dados originais e consolidados não são editados. Números de CSV/JSON preservam precisão double (15–17 algarismos significativos); texto decimal original do PL também está no CSV de posições. Arredondamento a duas casas ocorre somente na apresentação. O resultado não garante aritmética decimal exata para todos os totais financeiros.
Pré-filtros: Todas as posições | desconhecidos: excluídos nos critérios ativos . A seleção é de posições mensais elegíveis; não é coorte fixa. No Pages filtros exploratórios somente selecionam dados já publicados. Configuração e processamento R ocorrem antes da publicação.
Reproduzir na raiz: Rscript --vanilla scripts/p08_resumo_dados.R dados/atualizacao_2020/configuracao.rds; depois powershell -File scripts/publicar_resumo.ps1. Para universo com pré-filtros, preparar P04 com config$filtros, reutilizar ZIPs íntegros e executar P06 antes do P08.
[Manifesto com schema, assinatura, hashes, período e volume](manifesto_publico.json) | [Estatísticas completas](estatisticas_por_competencia.csv) | [Ranking histórico completo](ranking_historico_completo.csv)
Biblioteca: Plotly.js 3.1.0 (MIT), arquivos locais. Escolhida por linhas, barras, quartis explícitos, eventos de clique, redimensionamento e exportação. [Documentação oficial](https://plotly.com/javascript/).
Dicionário oficial consultado em2026-10-07: [metadados CVM](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/meta_inf_mensal_fidc_txt.zip).
Tabela I : inf_mensal_fidc_tab_I.csv ; SHA-256 0b99d33140b2b9e2cc7be9c3ab14647663e165fd5767c077602e4c035c736d9c
Tabela IV : inf_mensal_fidc_tab_IV.csv ; SHA-256 06b10093835398f7fa9f318c3f2740ae01bae268cc015f0afa3e158c67778713
Tabela X_1 : inf_mensal_fidc_tab_X_1.csv ; SHA-256 c0eef7355cc318b9fd4275e92ff5f632413f45bc83e2bf75a18ab9fba7c54837
Tabela X_1_1 : inf_mensal_fidc_tab_X_1_1.csv ; SHA-256 9801d4b9594a7f2f990fd8d636482a5ef3c4d1a2fcf6243ba710c8bf7f6b5f79
