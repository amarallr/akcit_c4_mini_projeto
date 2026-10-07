# Contribuição

Abra o projeto no RStudio e leia README, DFD e os prompts responsáveis pela mudança. Proponha incrementos pequenos, com requisitos e testes proporcionais ao comportamento alterado. Preserve identificadores textuais, valores originais, proveniência e detalhes das tabelas; P03 continua documental.

Restaure as dependências com `gerenciar_dependencias('restaurar')` e execute `Rscript --vanilla scripts/p02_testar.R todas`. Os testes devem usar fixtures, sem credenciais ou downloads da CVM. Integrações reais e medidas de desempenho precisam de evidências próprias. Atualize catálogo, matriz, documentação e versão da transformação quando os contratos mudarem.

Para alterar dependências, registre a necessidade, instale a versão escolhida no ambiente de desenvolvimento e use `gerenciar_dependencias('fixar')`. Revise `renv.lock`, teste a restauração e a suíte. Arrow/Parquet é opcional e não deve entrar no conjunto obrigatório por acidente.

Não envie `.env`, dados, resultados, checkpoints, logs, bibliotecas ou temporários. Descreva o problema, a mudança e os testes executados na proposta de contribuição. Não reescreva o histórico ou faça push sem autorização. A substituição do histórico neste marco zero foi uma decisão específica do usuário.

## Licença

Na revisão de 02/10/2026, não foi encontrado arquivo LICENSE nem uma licença declarada nos arquivos versionados. Esta revisão não atribui uma licença em nome do autor. Uma licença de distribuição poderá ser incluída após sua escolha explícita. As licenças dos pacotes R são próprias de cada dependência; os informes da CVM devem ser tratados conforme as condições da fonte oficial.
