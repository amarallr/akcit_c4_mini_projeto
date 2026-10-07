# Publicação e estrutura do repositório

O repositório `amarallr/akcit_c4_mini_projeto`, branch `main`, reúne os prompts P01–P08, código, testes, documentação e evidências agregadas. P03 é um roteiro de preparação; não declara instalação real nem reprodução independente em computador limpo.

Os arquivos da raiz foram reduzidos aos elementos essenciais do projeto (`README.md`, arquivo RStudio, lockfile, configurações Git e exemplo de ambiente). O conteúdo foi agrupado por finalidade: `documentacao/` contém arquitetura, operação e relatórios; `referencias/cvm/` guarda dicionários e esquemas; `evidencias/` reúne provas agregadas; `resultados/estatisticas/` contém os CSVs e relatório público. `scripts/`, `tests/` e `prompts/` mantêm implementação, validações e instruções.

A atualização histórica consolidada cobre 2020–2026 e alimenta o README e a página do [GitHub Pages](https://amarallr.github.io/akcit_c4_mini_projeto/). P08 gera o resumo por competência, o ranking e a descrição dos metadados. O workflow `.github/workflows/pages.yml` publica a página e os dicionários CVM quando os artefatos públicos, suas fontes ou o publicador mudam. A página alinha valores e cabeçalhos numéricos à direita.

Dados brutos, saídas integrais, checkpoints, logs, bibliotecas, temporários, ferramentas locais e o `.env` real permanecem fora do Git. O repositório publica código, documentação, fixtures sintéticas, tabelas derivadas e evidências agregadas; P08 também publica posições estreitas de fundos/classes derivadas dos informes públicos CVM para permitir os detalhes do painel. Não há licença de distribuição declarada; consulte [como contribuir](como_contribuir.md).

Os testes locais mais recentes concluíram 56 casos e 471 verificações, sem falhas, erros, avisos ou skips. Os oito casos automatizados próprios de P08 passaram na suíte atual. A CI Windows/Linux usa fixtures e não equivale à reprodução histórica. A autorização para publicar esta atualização foi dada pelo usuário; após o push, o estado remoto e a execução do Pages serão verificados separadamente. A CLI P07 valida o aceite local, mas não executa commit, push nem consulta Git.
