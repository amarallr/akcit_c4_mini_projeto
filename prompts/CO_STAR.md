# Como interpretar o CO-STAR dos prompts

CO-STAR organiza a orientação de cada prompt em seis partes. No projeto,
essas partes explicam a situação de trabalho, o resultado esperado e como
o agente deve comunicar sua execução. Os requisitos com IDs, contratos e
testes continuam sendo os critérios verificáveis da implementação.

| Parte | Pergunta orientadora | Aplicação no projeto |
|---|---|---|
| C — Context | Em qual situação o trabalho acontece? | Mini projeto acadêmico, oito prompts, ferramentas e artefatos a criar |
| O — Objective | Qual resultado este incremento deve produzir? | Entrega da etapa, seu limite e condições para encerrá-la |
| S — Style | Como apresentar explicações e código? | Português, exemplos pequenos, tabelas de status e código simples |
| T — Tone | Qual postura manter na conversa? | Colaboração, paciência, precisão e transparência sobre falhas |
| A — Audience | Quem executará, revisará e lerá a entrega? | Estudantes da especialização, leitores e revisores, sem ferramentas ou código presumidos |
| R — Response | O que deve constar na entrega e na resposta? | Arquivos, execução, resultados, provas, pendências e próximo movimento |

## Contexto e objetivo

Contexto descreve as condições de partida, inclusive o que já existe e as
dependências. Objetivo define a mudança a realizar e o resultado a entregar.
Em P03, o contexto é um ambiente sem R, RStudio, Git ou Codex instalados; o objetivo
é apresentar o roteiro de preparação, sem realizar ou testar sua execução. Em P04, o contexto é o dataset FIDC
e suas fontes; o objetivo é produzir uma seleção e contratos confirmados.
O contexto não comprova que uma ação foi executada: consultar os registros.

## Estilo e tom

Estilo determina a forma do conteúdo: estrutura, linguagem, nível de detalhe,
exemplos e organização do código. Tom determina a postura ao falar com o
usuário: colaboração, clareza e cuidado com o que é afirmado.
Por exemplo, uma tabela por unidade é uma escolha de estilo em P05;
explicar uma falha com calma e sem afirmar causa não comprovada é tom.
Os dois precisam permitir entender o resultado e decidir o próximo passo.

## Público

O público influencia a explicação. O executor pode estar começando com as ferramentas,
mas isso não pressupõe domínio de PowerShell, Git ou todos os formatos CVM.
Por isso, os prompts pedem comandos com ambiente de execução identificado.
Leitores básicos precisam entender o significado e os limites dos dados;
revisores precisam localizar requisitos, funções, testes e evidências.
A documentação deve atender a esses usos sem exigir a conversa completa.

## Resposta

Resposta especifica o conteúdo da entrega do incremento. Não é uma previsão
de resultados positivos: registrar o que foi observado, inclusive falhas,
parcialidade e testes não executados. Quando houver código, indicar arquivos
e comandos reproduzíveis; quando houver validação, citar provas e limitações.
Encerrar dizendo explicitamente com quem está a bola e qual é o próximo
movimento. Se ainda há trabalho autorizado do agente, ele deve continuá-lo.

## Aplicação por prompt

| Prompt | Foco do objetivo | Conteúdo principal da resposta |
|---|---|---|
| P01 | Coordenar o incremento autorizado | Status, dependências, decisões e continuidade |
| P02 | Aplicar contratos compartilhados | Regras usadas, utilitários e testes comuns pertinentes |
| P03 | Documentar como preparar o ambiente | Roteiro revisado, limitações e ações futuras explicadas |
| P04 | Selecionar e definir contratos FIDC | Configuração, inventário, fontes, esquema e limites |
| P05 | Obter originais e extrações válidas | Estados por unidade, hashes, manifestos e retomada |
| P06 | Transformar e consolidar com rastreabilidade | Saídas, qualidade, conflitos, checkpoints e equivalência |
| P07 | Avaliar e demonstrar a entrega | Inventário final, provas e aceite local/completo separado |
| P08 | Analisar uma série consolidada | Estatísticas por competência, ranking winsorizado e limites interpretativos |

P01 coordena; P02 é comum; P03 a P08 acrescentam orientação específica.
Ler CO-STAR não autoriza avançar de etapa. O estado vigente continua em
documentacao/retomada.md e registro_projeto.txt. Especificação documental não substitui
implementação, consulta oficial, execução de teste ou publicação confirmada.

## Exemplo de fechamento de um incremento

Uma resposta de P04 pode indicar a configuração validada, os arquivos e os
comandos utilizados, os testes executados, os campos ainda sem contrato e
a decisão necessária para o próximo incremento. Se a seleção ainda depende
de informação do usuário, isso fica explícito. Esse é um exemplo de formato;
não significa que P04 já tenha sido iniciada ou que seus testes passaram.

## Premissa acadêmica e ponto de partida obrigatório

Este é um mini projeto didático da especialização em Engenharia de Software com IA Generativa. R, RStudio, Codex, Git e GitHub têm instalação/configuração descrita no roteiro; P03 não executa essas ações; ferramentas auxiliares terão seus próprios pré-requisitos explicados. O leitor parte somente dos oito prompts atuais. Não precisa de códigos, scripts, documentos, contas ou repositórios previamente configurados. Guias, registros e artefatos desta cópia são resultados da execução do autor, não entradas obrigatórias para outra reprodução.

A IA participa de todo o ciclo, com decisões e revisão humana: requisitos, planejamento, ambiente, código, testes, revisão, documentação e versionamento. O CO-STAR deve traduzir esse processo em instruções verificáveis. Contexto explicita a ausência inicial de recursos; Objetivo define o incremento; Estilo identifica onde executar cada comando; Tom explica dificuldades; Público inclui estudantes iniciantes nas ferramentas; Resposta entrega artefatos, evidências e responsabilidade pelo próximo movimento.

Consultar AMBIENTE_DO_ZERO.md como apoio opcional. Na primeira execução, gerar progressivamente os artefatos ausentes a partir dos contratos dos prompts. Na retomada, consultar e preservar os registros da própria execução. Não exigir scripts externos, clonagem do repositório do autor ou anexos de análise. Só registrar uma prática como aplicada quando existirem suas evidências. O teste independente P03-TST-004 e a infraestrutura P03-RF-006 foram cancelados. A revisão documental P03-TST-005 conclui o roteiro, sem comprovar instalação.

Nomenclatura (P02-RNF-008): scripts próprios usam pNN_nome_da_funcao.ext; testes usam test-pNN-finalidade.R. O prefixo registra responsabilidade; cabeçalhos, chamadas e matriz explicam dependências. Uma renomeação preserva IDs e exige atualização e validação das referências.

Mapa SWEBOK: documento documentacao/ciclo_desenvolvimento_swebok.md na raiz; dez etapas didáticas explicadas e aplicadas ao projeto. Regras P01-RF-004/P02-RNF-009 e revisão P02-TST-009. Fonte e adaptação são distintas; não comprova conclusão integral do ciclo. Na primeira reprodução, gerar esse documento a partir dos prompts vigentes, sem exigir sua existência prévia.

Arquitetura detalhada em [documentacao/arquitetura.md](../documentacao/arquitetura.md): quatro diagramas, ferramentas, contratos, chamadas, sequência, persistência e limites. Regras P01-RF-005/P02-RNF-010; revisão P02-TST-010. Novos pedidos devem atualizar os requisitos responsáveis antes da implementação dependente. Na reprodução inicial, gerar o documento; não exigir sua existência prévia.

Incremento inicial P04: Contexto = fontes oficiais ainda a confirmar, Objetivo = levantamento externo, Estilo = evidências/limites tabulados, Tom = precisão sobre o não verificado, Público = estudante/revisor, Resposta = documento de fontes e status parcial, sem implementação ou download. Próxima decisão humana: escolher o incremento seguinte.

Incremento de leitura P04: Objetivo limitado ao dicionário oficial, com julho/agosto de 2026 confirmado; Resposta documenta 18 textos/455 definições e suas lacunas. Tipos declarados não são contrato validado contra informes, não autorizam download nem implementação automática. A decisão humana limita o próximo incremento.

## Incremento vigente P04–P08

Os exemplos de incrementos P04 acima são históricos. A série analítica desta atualização vai de janeiro de 2020 a setembro de 2026. P08 associa administradores por CNPJ, tipo Fundo/Classe e data; produz estatísticas, ranking winsorizado e metadados da fonte, período, leiautes, campos, linhagem e limites, descritos no README e no Pages. Contexto identifica o mini projeto didático; Objetivo limita cada chamada à etapa pedida; Estilo ensina comandos e contratos; Tom distingue dados observados e hipóteses; Público parte de ambiente sem ferramentas; Resposta traz resultados, testes realmente executados, limites e responsável. IA participa de requisitos, arquitetura, código, testes e revisão/publicação, com decisões humanas registradas. P03 permanece roteiro sem testar sua execução. Uma análise não homologa todo o histórico CVM nem aprova outra reprodução.
