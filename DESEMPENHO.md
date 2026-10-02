# Desempenho e formato opcional

As medidas de 02/10/2026 usam os ZIPs locais de julho/agosto de 2026, as 18 tabelas selecionadas e R 4.5.1 no Windows. Nenhuma medição fez novo download da CVM. Elas descrevem esta máquina e este piloto, sem estabelecer SLA ou estimar a viabilidade de todo o histórico.

`scripts/p06_medir.R` executa P06 nos modos temporal e completo, nessa ordem, e termina com a geração completa como atual. O tempo é a diferença de `proc.time()[['elapsed']]` entre início e fim, incluindo validação de entradas, montagem e gravação. O tamanho soma os bytes dos CSVs/RDSs de dados e qualidade publicados, sem incluir ZIPs, checkpoints, logs ou manifesto. Os contadores distinguem intermediários processados de reutilizados.

Antes de cada execução, `gc(reset=TRUE)` reinicia os máximos do heap observado pelo R. Ao final, somam-se as colunas em MB dos máximos de Ncells e Vcells. Essa soma é uma medida conservadora dos máximos independentes do heap R: **não é pico RSS, memória residente do processo ou consumo total do sistema**, e não inclui toda alocação nativa das bibliotecas. O script não mede CPU isoladamente nem executa várias repetições estatísticas.

| Medição | Modo | Tempo de parede | Bytes de saída | Máximos do heap R |
|---|---|---:|---:|---:|
| Antes de reduzir cópias do flat | Temporal | 115,33 s | 148.055.166 | 301,7 MB |
| Antes de reduzir cópias do flat | Completo | 161,62 s | 408.613.075 | 6.200,6 MB |
| Revisão final | Temporal | 38,20 s | 148.055.166 | 298,9 MB |
| Revisão final | Completo | 130,55 s | 408.613.036 | 4.180,2 MB |

A revisão final reutilizou 36 checkpoints e processou zero membros em cada modo. Uma medição intermediária do modo completo levou 72,92 s, indicando variação relevante dos tempos; carga concorrente e OneDrive não foram controlados. Não se atribui uma aceleração geral apenas a esses resultados. A redução observada na medida de heap do modo completo foi de aproximadamente 33%; o modo temporal mantém um volume de memória muito menor ao evitar a montagem do flat.

As alterações reduzem cópias em três pontos: as partes de cada tabela são concatenadas uma vez; a união de chaves do flat é calculada uma vez e suas colunas são atribuídas por referência; a validação estrutural do CSV lê o cabeçalho e uma coluna para conferir nomes/linhas, materializando o conjunto inteiro somente quando há validador personalizado. A validação RDS compara hashes do conteúdo serializado, evitando manter simultaneamente dois vetores completos de serialização.

Os 21 CSVs comparados — 18 temporais, flat, cedentes e qualidade — mantiveram SHA-256. O flat continua com 8.783 linhas e 14.749 colunas. [P06_EQUIVALENCIA_OTIMIZACAO.csv](P06_EQUIVALENCIA_OTIMIZACAO.csv) registra a comparação dos arquivos; diferença de hash RDS é tratada separadamente de equivalência de colunas, tipos e valores. [P06_MEDICOES_PILOTO.csv](P06_MEDICOES_PILOTO.csv) registra os números e hashes do conteúdo do código/testes observado; os logs detalhados permanecem locais. Houve alterações de testes durante a série de medições, por isso os hashes registrados podem diferir mesmo quando o processamento medido permaneceu igual.

## Avaliação de Parquet

Arrow **25.0.1**, já disponível no ambiente do autor, foi usado para exportar e reler as tabelas IV e VIII reais. O round-trip preservou as colunas, os valores, as datas e os identificadores textuais. Os tempos abaixo incluem escrita e validação da releitura, sem constituir comparação de velocidade de consulta.

| Tabela | Registros | CSV | RDS | Parquet | Escrita + validação Parquet |
|---|---:|---:|---:|---:|---:|
| IV | 8.783 | 2.532.348 bytes | 362.279 bytes | 612.126 bytes | 0,53 s |
| VIII | 84.044 | 22.296.105 bytes | 1.172.659 bytes | 2.045.572 bytes | 1,17 s |

Parquet ficou menor que CSV nesses dois exemplos, mas maior que RDS comprimido. A avaliação não abrange o flat nem demonstra ganho de desempenho em consultas. Por isso, `exportar_parquet=TRUE` permanece opcional, exige Arrow instalado e acrescenta arquivos sem substituir CSV/RDS. Arrow não compõe as dependências obrigatórias fixadas. Os resultados estão em [P06_AVALIACAO_PARQUET.csv](P06_AVALIACAO_PARQUET.csv); a interface segue a [documentação oficial de Arrow](https://arrow.apache.org/docs/r/reference/write_parquet.html).

Para repetir: restaure as dependências, execute P04/P05 para obter a seleção própria e rode `Rscript --vanilla scripts/p06_medir.R`. Use a mesma configuração em todas as etapas e registre o estado dos checkpoints. Ao comparar revisões, confirme primeiro a equivalência dos datasets e mantenha explícitos o método de memória, a versão do código e a diferença entre execução fria e retomada.
