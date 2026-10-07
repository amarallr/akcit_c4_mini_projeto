# P03 — Roteiro de preparação do ambiente do zero

Entrega documental do mini projeto da Especialização em Engenharia de Software com IA Generativa. O roteiro parte somente dos oito prompts P01–P08, sem ferramentas, contas, código ou documentos preexistentes. Os passos abaixo são orientações para uso futuro: **não foram executados ou testados nesta revisão**. A conclusão de P03 exige revisão do documento, não instalação, VM ou teste de execução.

## 1. Conhecer as ferramentas e a ordem

| Recurso | Finalidade | Dependência para uso futuro |
|---|---|---|
| R | Executar a linguagem e pacotes do protótipo | Instalação autorizada no computador |
| RStudio | Editar scripts e trabalhar com projetos R | R disponível |
| Git | Registrar versões locais | Instalação e identidade do autor |
| GitHub | Hospedar o repositório e colaborar | Conta própria, Git para envio por terminal |
| Codex | Apoiar requisitos, código, revisão e documentação com IA | Acesso próprio e modalidade de uso escolhida |
| Node.js/npm | Disponibilizar a modalidade CLI do Codex | Necessário somente se essa modalidade for escolhida |
| PowerShell | Executar comandos de terminal no Windows | Terminal disponível e políticas do computador respeitadas |
| Pacotes R | Testes, acesso HTTP, hashes, leitura e configuração | R e biblioteca com permissão de escrita |

Leia P01, P02 e P03. A leitura humana inicia a preparação antes de existir Codex. Identifique o sistema operacional, as políticas do computador e a pasta de trabalho. As instruções não autorizam instalações ou mudanças administrativas por parte do agente.

## 2. Tratar a ausência de administrador

Este roteiro deve poder ser lido e aceito sem credenciais administrativas. Uma instalação por usuário só deve ser escolhida quando oferecida e documentada pelo fornecedor e permitida pela organização. Se o instalador, Node.js, RStudio ou uma política exigir elevação, solicite ao responsável pelo computador a preparação autorizada ou escolha outro computador permitido. Não contorne políticas de acesso. A ausência de administrador não é pendência do aceite de P03. Não é necessária VM e não se planeja sua criação.

## 3. Obter R

Consulte o [CRAN oficial](https://cran.r-project.org/), selecione o sistema e leia as instruções do instalador. No Windows, consulte as [perguntas de instalação do R](https://cran.r-project.org/bin/windows/base/rw-FAQ.html). Escolha destino autorizado e anote o caminho: `Rscript` pode não estar no PATH. Não fixar a versão histórica do autor como mínimo. Verificação sugerida para uso futuro no console R: `R.version.string`. Nenhum resultado dessa expressão é exigido nesta entrega.

## 4. Obter RStudio

Consulte a [distribuição oficial do RStudio Desktop](https://posit.co/download/rstudio-desktop/), seus requisitos e a compatibilidade com R/sistema. Após instalação autorizada, escolha a instalação de R. Para uso futuro, um projeto RStudio organiza o diretório de trabalho por arquivo `.Rproj`; não é necessário existir um agora.

## 5. Obter Git e configurar a identidade

Consulte os [downloads oficiais do Git](https://git-scm.com/downloads) e as opções autorizadas para o sistema. No futuro terminal, `git --version` sugere uma verificação do executável. Na pasta do futuro repositório, após `git init`, a identidade pode ser configurada apenas nele:

```powershell
git config user.name "Seu Nome"
git config user.email "seu-email-publico@example.com"
```

Esses comandos são exemplos, não foram executados para preparar o ambiente do leitor. Preferir endereço público apropriado, inclusive a opção de privacidade fornecida pelo GitHub.

## 6. Preparar conta GitHub e acesso próprio

Leia a [documentação inicial do GitHub](https://docs.github.com/en/get-started). Crie ou reutilize uma conta própria e decida nome/visibilidade do repositório. O repositório do autor é referência, não destino obrigatório. Planeje autenticação por mecanismo oficial, sem colocar senhas ou tokens na conversa, nos prompts ou no Git. GitHub CLI é opcional: consulte sua [documentação](https://cli.github.com/manual/) caso essa modalidade seja escolhida.

## 7. Escolher como usar Codex

Consulte a [documentação oficial do Codex](https://developers.openai.com/codex/) para acesso, requisitos e modalidade apropriada. Se escolher CLI, leia a [instalação oficial](https://developers.openai.com/codex/cli/) e os requisitos de Node.js/npm e do Windows antes de instalar. Consulte o [Node.js oficial](https://nodejs.org/en/download) quando necessário. Não presumir que CLI, WSL, extensão ou aplicação já existem. Escolha somente uma modalidade viável e autorizada; não exigir instalação de todas. A primeira leitura dos prompts continua sendo humana.

## 8. Planejar a pasta e os artefatos

Escolha uma pasta com escrita permitida, por exemplo `C:/projetos/mini-fidc`, sem adotar caminho pessoal do autor. Disponibilize inicialmente somente os sete prompts em `prompts/`. A partir deles, peça à IA para gerar progressivamente README, RETOMADA, arquitetura, registros e roteiro, conforme o incremento autorizado. A criação de `.Rproj`, `scripts/`, `tests/`, `dados/`, `saidas/` e `checkpoints/` é orientação para a construção futura. P03 não exige criar ou executar scripts. Clonar a implementação do autor é consulta opcional, não requisito de partida.

## 9. Planejar locale e pacotes

Para uma futura sessão RStudio, as expressões `Sys.getlocale()`, `l10n_info()` e `getwd()` ajudam a observar UTF-8 e a pasta. Não impor `C.UTF-8` no Windows. Para executar P04–P07 após gerar o código, preparar `data.table`, `httr2` e `digest`; para testes, `testthat` e `dotenv`. `readr` e `curl` pertencem também ao diagnóstico histórico opcional. A instalação é uma ação futura do leitor, fora do aceite documental de P03. Preferir biblioteca gravável do usuário/projeto e distinguir instalar de carregar. Não instalar pacotes como atividade de P03 e não exigir saída desses comandos para aceitar o roteiro.

## 10. Planejar versionamento e proteção de arquivos

Antes de futura publicação, preparar `.gitignore` para credenciais, `.env` real, bibliotecas locais, arquivos de sessão, dados, saídas e checkpoints. Rever conteúdo a publicar, usar caminhos relativos e registrar somente evidências observadas. Git registra localmente; GitHub recebe os commits enviados. Publicação documental deste projeto não prepara automaticamente o computador de outro leitor.

## 11. Revisar a entrega e combinar o próximo incremento

P03-TST-005 é revisão documental: conferir ferramentas, finalidade, ordem, fontes oficiais, ponto de partida e opções para ausência de administrador. Não executar instalações, scripts ou testes do roteiro. P03-RF-006 e P03-TST-004 foram cancelados; não há pendência de VM ou reprodução limpa. Não se afirma que as instruções foram testadas. Os scripts/testes anteriores permanecem como histórico opcional. P04–P07 dependem de autorização própria; quando houver execução futura, seus pré-requisitos reais deverão ser avaliados nessa etapa.
