# Prompts e rastreabilidade

Estes prompts especificam as responsabilidades dos fluxos FIDC e FII.
O vínculo entre prompt, implementação e testes está
resumido na tabela abaixo.

## Ordem de leitura e uso

Leia as regras comuns abaixo, escolha o prompt da responsabilidade afetada e
consulte os módulos e testes correspondentes. As etapas P01–P07 estão implementadas,
com subetapas para FIDC e FII nas famílias P05 e P06.
A presença de um prompt não
autoriza envio ao GitHub nem comprova aprovação de uma execução.

| Prompt | Responsabilidade | Código de referência | Verificação |
|---|---|---|---|
| [00 — Configuração inicial](00_configuracao_inicial_projetos_rstudio.txt) | Diagnóstico e preparação de projetos RStudio | README.md, estrutura e configuração do projeto | Diagnóstico e lista de pendências antes da implementação |
| [P01](01_orquestracao.txt) | Orquestração | `src/orchestration/p01_*.R` | Suíte P01 |
| [P02](02_utilitarios_dependencias_testes.txt) | Utilitários, dependências e testes | `src/utils/p02_*.R` | Suíte P02 |
| [P03](03_ambiente.txt) | Ambiente e preparação | `src/validation/p03_*` | Suíte P03 |
| [P04](04_configuracao_fidc.txt) | Configuração e fontes FIDC | `src/configuration/p04_configuracao_fidc.R` | Suíte P04 |
| [P05_01](05_01_download_fidc.txt) | Download FIDC | `src/download/p05_01_download_fidc.R` | Suíte P05_01 |
| [P05_02](05_02_download_fii.txt) | Download FII | `src/download/p05_02_download_fii.R` | Suíte P05_02 |
| [P06_01](06_01_consolidacao_fidc.txt) | Consolidação temporal FIDC | `src/consolidation/p06_01_*.R` | Suíte P06_01 |
| [P06_02](06_02_consolidacao_fii.txt) | Consolidação FII | `src/consolidation/p06_02_consolidacao_fii.R` | Suíte P06_02 |
| [P07](07_aceite_evidencias_fidc.txt) | Aceite e evidências | `src/acceptance/p07_*.R` | Suíte P07 |

Os cabeçalhos dos módulos públicos apontam para seu prompt. Os testes mantêm
seus IDs e nomes existentes. Execute a suíte selecionada com
`Rscript --vanilla src/utils/p02_testar.R P01`, substituindo P01 pela etapa
necessária; use `todas` para a regressão completa. As seleções `P05` e `P06`
executam as duas subetapas da família; as seleções com sufixo executam apenas
FIDC (`_01`) ou FII (`_02`).

A mesma hierarquia aparece em prompts (`05_01_*.txt`), código
(`p05_01_*.R`), testes (`test-p05_01-*.R`), documentos (`05_01_*.md`) e IDs
de requisitos (`P05_01-RF-*`). Os registros históricos e os arquivos oficiais
de dados mantêm seus nomes e conteúdo de origem.

## Método CO-STAR

Cada prompt contém Contexto, Objetivo, Estilo, Tom, Audiência e Resposta esperada.
O objetivo explicita requisitos; a resposta define entregáveis e critérios de
aceite. Estado implementado significa que existe código correspondente; sua
correção deve ser verificada pelos testes e pelo alcance da validação observada.

## Aplicação do SWEBOK

O [SWEBOK da IEEE Computer Society](https://www.computer.org/education/bodies-of-knowledge/software-engineering)
é a referência de organização das práticas. O
[sumário de áreas de conhecimento](https://www.computer.org/education/bodies-of-knowledge/software-engineering/topics)
orienta a seleção abaixo. Trata-se de uma aplicação ao projeto, sem declaração
de certificação ou de cobertura integral do guia.

| Prática aplicada | Evidência exigida no projeto |
|---|---|
| Requisitos | Escopo, IDs, entradas, restrições e critérios de aceite nos prompts |
| Arquitetura e projeto | Responsabilidades separadas e contratos entre etapas |
| Construção | Funções rastreáveis, erros explícitos e persistência recuperável |
| Testes | Fixtures locais, interrupções, corrupção e regressão entre etapas |
| Configuração | Dependências fixadas, hashes, versões e revisão de mudanças |
| Operações e manutenção | Diagnóstico, retomada, compatibilidade e registros locais |
| Qualidade e segurança | Validação antes de publicar e exclusão de dados confidenciais |

## Regras comuns

- Ler e respeitar as instruções locais antes de executar qualquer prompt.
- Conferir o código, seus comentários e os testes: os prompts resumem os
  contratos e não substituem a inspeção da implementação.
- Preservar IDs já usados. Uma mudança de escopo exige atualizar prompt, código,
  testes e documentação em conjunto, sem reutilizar IDs para outro significado.
- Manter geração flat, detalhes e cedentes fora do escopo desta versão.
- Manter código privado, fontes, produtos e resultados confidenciais fora dos
  arquivos públicos, dos logs versionados e dos serviços externos.
- Nunca abrir, percorrer, alterar ou publicar `restricted/`. A pasta da raiz é
  ultra confidencial e é distinta da área reservada `data/restricted/`.
- Usar dados fictícios nos testes públicos. Não registrar seleções pessoais,
  nomes, identificadores ou caminhos confidenciais.
- Não confundir execução parcial, teste com fixture e validação com fonte real.
- Registrar o que mudou, como foi verificado e as limitações que permanecerem.

As instruções das consolidações privadas permanecem exclusivamente na área
local ignorada, sem copiar seus scripts ou seus resultados para estes prompts.
