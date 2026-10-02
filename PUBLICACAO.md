# Publicação — revisão de 02/10/2026

A entrega em `amarallr/akcit_c4_mini_projeto`, branch `main`, reúne implementação P01/P02/P04–P07, sete prompts, arquitetura com um único DFD, documentação, testes e evidências agregadas. P03 permanece roteiro documental, sem exigência de execução ou reprodução em computador limpo.

A suíte local aprovou 36 casos e 275 verificações. Interrupção, retomada e repetição em processos distintos demonstraram reutilização de 36 checkpoints e hashes iguais nos 42 arquivos CSV/RDS de dados e qualidade. [P07_EVIDENCIAS_INCREMENTO.json](P07_EVIDENCIAS_INCREMENTO.json) vincula provas à configuração, geração e conteúdo de código, testes e lockfile. Consulte [DESEMPENHO](DESEMPENHO.md) para medidas e limites.

O workflow Windows/Linux restaura dependências fixadas e executa fixtures sem CVM ou credenciais. Resultados remotos são consultados em [Actions](https://github.com/amarallr/akcit_c4_mini_projeto/actions), separadamente das provas do piloto. Configurar o workflow não comprova sua execução.

Dados, saídas, checkpoints, logs, bibliotecas, temporários, ferramentas locais e `.env` real ficam fora do Git. Publicam-se somente código, documentação, fixtures sintéticas e evidências agregadas, sem registros individuais. Não há licença de distribuição declarada; consulte [CONTRIBUICAO](CONTRIBUICAO.md).

O fechamento exige comparar `git rev-parse HEAD` com `git ls-remote origin refs/heads/main` e conferir `git status --short`. Hashes iguais e árvore limpa comprovam sincronização dos arquivos versionados. A CLI P07 verifica o aceite local e não executa commit, push ou consulta Git. Após publicação conferida, o usuário revisa os resultados para aceite acadêmico e indica eventual próximo incremento.
