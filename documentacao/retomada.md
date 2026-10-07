# Retomada do projeto

O projeto transforma informes mensais de Fundos de Investimento em Direitos Creditórios (FIDC) publicados pela CVM em conjuntos temporais por tabela, registros derivados de cedentes e, opcionalmente, uma tabela flat. P01 coordena o pipeline; P02 reúne funções comuns, dependências e testes; P04 seleciona os dados; P05 obtém os arquivos; P06 consolida; P07 verifica a entrega; P08 calcula estatísticas e documenta os metadados do conjunto. P03 continua sendo um roteiro documental.

## Estado da atualização histórica

A consolidação temporal cobre janeiro de 2020 a setembro de 2026: 81 competências, 18 tabelas, 8.420.840 linhas temporais e 431.215 registros derivados de cedentes. A seleção usa `gerar_flat=FALSE`. A tabela X não consta dos pacotes anuais oficiais de 2020–2022; as outras tabelas esperadas foram consolidadas. A configuração e as saídas integrais ficam localmente em `dados/`, `saidas/` e `checkpoints/` e não são versionadas.

P08 produz o relatório em `resultados/estatisticas/relatorio_estatisticas.md`, o resumo por competência e o ranking dos 25 administradores. A chave analítica combina CNPJ normalizado, tipo Fundo/Classe e data de competência. Uma repetição em cada uma das tabelas I e IV foi removida porque o campo analítico correspondente coincidia; conflitos interrompem o cálculo. Registros sem administrador continuam nas estatísticas por competência, mas ficam fora do ranking e de seu denominador. A unidade monetária e a escala percentual não foram confirmadas.

## Documentação e validação

Os metadados do conjunto, as fontes, os leiautes, a linhagem e as limitações estão explicados na introdução do [README](../README.md) e na [página pública do Pages](https://amarallr.github.io/akcit_c4_mini_projeto/). Documentos estão em `documentacao/`, dicionários em `referencias/cvm/`, evidências agregadas em `evidencias/` e tabelas públicas em `resultados/estatisticas/`.

A suíte de regressão local concluiu 48 casos e 413 verificações, sem falhas, erros, avisos ou skips. Os testes automatizados específicos de P08 continuam planejados; a geração P08 foi executada e conferida localmente. A CI com fixtures testa o código sem reproduzir a extração CVM histórica. Consulte [aceite](aceite_entrega.md), [desempenho](desempenho.md) e [evidências P07](../evidencias/p07/evidencias_incremento.json).

## Continuidade

Para reproduzir a análise, siga o caminho de execução no [README](../README.md): restaure as dependências, use a configuração de seleção, execute P04–P06 e, após uma consolidação temporal concluída, rode `Rscript --vanilla scripts/p08_resumo_dados.R <caminho-da-configuracao.rds>`. O pacote de prompts vigente está descrito em [LEIA_ME](../prompts/LEIA_ME.md). Os arquivos de dados, gerações, logs e checkpoints desta execução não são incluídos no Git.
