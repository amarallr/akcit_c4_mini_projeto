# Fases do Ciclo de Desenvolvimento de Software SWEBOK

Mini projeto didático da especialização em Engenharia de Software com IA Generativa, com R, RStudio, Codex, Git e GitHub. Revisão: 01/10/2026.

## Referência e organização adotada

O SWEBOK é o guia de conhecimentos de engenharia de software da IEEE Computer Society. A edição consultada é a **v4.0a**, organizada em **18 áreas de conhecimento**. Áreas de conhecimento abrangem disciplinas; não equivalem a uma sequência de fases. [Apresentação oficial do SWEBOK](https://www.computer.org/education/bodies-of-knowledge/software-engineering).

O capítulo 10 aborda ciclos de vida, modelos de processo e sua adaptação. As **dez etapas abaixo são uma organização didática deste projeto**, apoiada nessas áreas, e não uma lista oficial de dez fases do SWEBOK. A numeração facilita o acompanhamento; requisitos, projeto, construção e testes podem ser revisitados em cada incremento. Preparação do ambiente recebe uma etapa explícita por causa do objetivo de reprodução desde uma máquina limpa. [SWEBOK v4.0a, capítulo 10, seção 2](https://ieeecs-media.computer.org/media/education/swebok/swebok-v4.pdf).

Os nomes das áreas e capítulos usados no mapeamento podem ser conferidos no [sumário oficial](https://www.computer.org/education/bodies-of-knowledge/software-engineering/topics). As aplicações, artefatos e critérios abaixo são decisões deste mini projeto.

## 1. Etapas enumeradas e explicadas

1. **Concepção, planejamento e viabilidade.** Definir problema, público, objetivo, limites, recursos e ordem dos incrementos. Avaliar se o trabalho é realizável no contexto acadêmico.
2. **Levantamento, análise e especificação de requisitos.** Transformar necessidades em comportamentos e restrições verificáveis, com prioridades, dependências e critérios de aceite.
3. **Arquitetura e projeto do software.** Definir componentes, responsabilidades, interfaces e fluxo de dados; detalhar contratos e decisões antes de construir.
4. **Preparação do ambiente e configuração inicial.** Disponibilizar ferramentas, contas e estrutura de trabalho; confirmar condições para executar os incrementos.
5. **Construção e implementação.** Produzir código conforme os contratos, integrando componentes progressivamente e preservando trabalho válido.
6. **Verificação, validação e testes.** Conferir conformidade com requisitos e adequação às necessidades do usuário, registrando resultados e limitações.
7. **Entrega, implantação local e aceite.** Disponibilizar uma versão utilizável, explicar sua instalação e execução e confrontar a entrega com os critérios de aceite.
8. **Operação e acompanhamento.** Executar o software no uso previsto e acompanhar resultados, falhas, recursos e continuidade.
9. **Manutenção e evolução.** Corrigir defeitos, adaptar dependências e dados e melhorar o software com análise de impacto e regressão.
10. **Encerramento ou retirada e preservação.** Registrar o estado final, preservar materiais úteis e orientar a descontinuação ou transição, quando necessária.

Essa descrição é uma síntese didática. O apoio conceitual está nas áreas de requisitos, arquitetura, projeto, construção, testes, operações e manutenção do [sumário SWEBOK](https://www.computer.org/education/bodies-of-knowledge/software-engineering/topics), e nos modelos de ciclo de vida do [capítulo 10 do guia](https://ieeecs-media.computer.org/media/education/swebok/swebok-v4.pdf).

## 2. Como cada etapa é atendida no projeto

| Etapa | Atendimento concreto e participação da IA | Evidências e estado vigente |
|---|---|---|
| 1 — Concepção, planejamento e viabilidade | Objetivo acadêmico, FIDC e piloto julho/agosto definidos com o estudante; IA decompõe entregas e limites | Sete prompts e RETOMADA; piloto executado e viável nesta máquina, sem generalizar para todo o histórico ou estudo econômico formal |
| 2 — Requisitos | Pedidos são transformados pela IA em RF/RNF, IDs estáveis, contratos e testes; revisão humana define escopo e autorizações | Catálogo/matriz/registro atualizados; CSV temporal e flat obrigatórios, chave CNPJ/competência e preservação de origens; semânticas desconhecidas explicitadas |
| 3 — Arquitetura e projeto | Responsabilidades P01/P02/P04–P07, entradas explícitas, persistência e recuperação; IA propõe interfaces e compara riscos | ARQUITETURA com um DFD e contratos implementados; pivot antes de join 1:1 preserva detalhes, sem assumir equivalência cadastral |
| 4 — Preparação | P03 explica ordem, fontes oficiais e ambiente inicialmente sem R, RStudio, Git, Codex ou contas; IA redige orientação revisada | Roteiro documental entregue; nenhuma instalação, VM ou teste de execução exigido; P03-RF-006/P03-TST-004 cancelados |
| 5 — Construção | IA escreve/revisa funções por prompt, código legível, chamadas sem efeitos em source, utilitários compartilhados e controles de caminhos | Scripts P01/P02/P04–P07 implementados; scripts P03 são histórico opcional; diff e commits registram o incremento |
| 6 — Verificação, validação e testes | IA constrói cenários e investiga falhas; execução real verifica propriedades de dados, retomada e preservação | Suíte completa, integração CVM, hashes e equivalência de 20 CSVs; P07_ACEITE_ENTREGA relata contagens/limites; CI Windows/Linux configurada com fixtures; sem TDD estrito, cobertura percentual ou reprodução independente comprovados |
| 7 — Entrega e aceite | Código/documentação revisados e publicados; P07 distingue aceite local de sincronização, sem inferir funcionamento apenas do push | README, PUBLICACAO, relatório P07 e HEAD local/remoto no fechamento; dados/resultados permanecem locais; não se comprova máquina limpa |
| 8 — Operação e acompanhamento | P05/P06 registram estados, origem, falhas, assinaturas e checkpoints; IA auxilia a interpretação dos diagnósticos | Piloto real, interrupção em um processo e retomada em outro, 36 checkpoints reutilizados, saídas determinísticas; serviço contínuo/produção não implementados |
| 9 — Manutenção e evolução | Correções analisam impacto nos requisitos, código, testes, nomes e documentos; IA localiza dependências e executa regressão | Correções e regressões registradas; mudanças futuras de lógica exigem versão da transformação, layouts exigem mapa e novos testes; todo o histórico CVM não homologado |
| 10 — Encerramento e preservação | P07 consolida inventário, instruções, resultados, limites e próximo movimento; o estudante mantém a decisão de aceite acadêmico | Fechamento do incremento piloto documentado; originais/checkpoints preservados; retirada futura é condicional, sem etapa P08 ou exclusão automática |

A quarta etapa significa orientar a preparação, conforme a mudança de P03. A instalação real é decisão futura do leitor para executar o código que ele gerar. Os testes históricos P03 podem continuar na suíte de regressão, mas não testam o roteiro nem constituem seu critério de aceite.

## 3. Atividades transversais e limites

Gestão, qualidade, versionamento, segurança, documentação e prática profissional acompanham os incrementos. Neste projeto: revisão de diffs, IDs rastreáveis, fontes oficiais, testes pertinentes, exclusão de segredos e registro de decisões. IA generativa participa de todo o desenvolvimento; o produto R não incorpora modelo de IA em execução. A autorização do estudante e a revisão dos resultados são distintas da geração automática.

Requisitos e arquitetura foram refinados antes de implementar os novos contratos. Construção, testes e documentação voltaram a ocorrer durante correções: o ciclo é incremental. Não se afirma aplicação integral de todas as áreas SWEBOK, certificação, produção ou reprodução em computador limpo.

## 4. Prompts e continuidade

P01 coordena, P02 mantém práticas comuns, P03 orienta preparação, P04 configura, P05 obtém dados, P06 transforma/retoma e P07 verifica/entrega. Prompt não equivale a fase: um incremento pode atravessar requisitos, projeto, código, testes e documentação.

Na primeira reprodução este documento deve ser gerado a partir dos sete prompts e das fontes oficiais. Evidências desta cópia pertencem à execução do autor. As versões anteriores com P04 parcial e P05–P07 não iniciados são histórico superado pela autorização de implementação. Requisitos P01-RF-004/P02-RNF-009, revisão P02-TST-009; estado atual em RETOMADA e relatório P07.

## Incremento de 02/10/2026

As etapas 2, 3, 5, 6, 7 e 9 foram revisitadas para fixar dependências, implantar CI com fixtures, recuperar arquivos interrompidos, acrescentar modo temporal sem flat, qualidade por competência, medições e evidências automáticas. Os requisitos novos P02-RF-007/008, P04-RF-006, P06-RF-012/013 e P07-RF-004 constam de catálogo/matriz. As provas locais e a CI são distintas; resultados observados ficam no relatório de aceite e em DESEMPENHO. P03 não foi reativado e a configuração de CI não comprova reprodução independente. O usuário autorizou substituir todo o histórico pelo versão de referência ao finalizar.
