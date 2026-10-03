# Incremento de robustez — 02/10/2026

Referência ddd8b1e; instrução doit: ler tmp/tmp.txt. Contratos e validação recentes em [INCREMENTO_ROBUSTEZ.md](INCREMENTO_ROBUSTEZ.md). Sete prompts preservados; regras comuns centralizadas em P02 e versões substituídas em prompts/historico. P03 continua documental e ARQUITETURA contém somente um DFD. Não reescrever histórico nem usar force push.

Validação local concluída: **47 casos e 402 verificações**, zero falhas/erros/avisos/skips. Produtor operacional aprovado com dados reais locais em quatro processos R: checkpoint novo 1, retomada reutilizando 1; repetição e execução solicitada têm hashes iguais. **412 arquivos normais** permaneceram com hashes idênticos. Comparação do piloto preservou os **42 arquivos** byte a byte. R 4.5.1 e dependências conferidas com renv.lock. A biblioteca testthat informa compilação em R 4.5.3 ao carregar, com versões fixadas e sem avisos nos casos. Publicação autorizada pelo usuário e confirmada no GitHub: os três commits do incremento chegaram ao main, com HEAD local/remoto ba7564354a2d819adcff54abe9efa4b1bb449889. CI do incremento aprovada em Windows e Linux (47 casos/401 verificações em cada ambiente, zero falhas/erros/avisos/skips; suíte local: 47/402, com uma verificação adicional do Parquet opcional instalado): https://github.com/amarallr/akcit_c4_mini_projeto/actions/runs/37091112129. Aceite completo do piloto confirmado após conferir sincronização e evidências locais. Detalhes em P07_SINCRONIZACAO_GITHUB.json. Dados, checkpoints, gerações e bibliotecas permanecem locais e ignorados pelo Git. O commit seguinte registra somente este fechamento documental; o resultado de CI acima refere-se exatamente ao commit informado. P03 não foi reativado.

---

Registro anterior, preservado como histórico; suas aprovações não validam o incremento atual.

# Retomada — 02/10/2026

O projeto transforma informes mensais FIDC da CVM em datasets temporais, cedentes e, opcionalmente, flat por CNPJ/competência. P01 coordena etapas explícitas; P02 reúne utilitários, dependências e testes; P04 configura a seleção; P05 baixa e extrai originais; P06 normaliza e consolida; P07 verifica a entrega. P03 permanece exclusivamente documental, sem reativar instalação, VM ou prova de reprodução independente.

O incremento autorizado foi implementado e validado localmente: dependências fixadas com renv, CI com fixtures Windows/Linux, recuperação de arquivos interrompidos, diagnóstico de qualidade, modo temporal sem flat, medições e evidências automatizadas. O fechamento remoto requer publicação e conferência de sincronização; resultados de CI são consultados separadamente em [Actions](https://github.com/amarallr/akcit_c4_mini_projeto/actions).

O piloto julho/agosto de 2026 leu dois ZIPs e 36 CSVs, produzindo 18 datasets temporais, flat com 8.783 linhas e 14.749 colunas e cedentes com 7.004 registros. No modo completo são 40 arquivos de dados e dois de qualidade, todos CSV/RDS. O modo temporal omite os dois arquivos do flat. Originais, gerações e checkpoints continuam locais e ignorados pelo Git.

A suíte local aprovou 36 casos e 275 verificações, sem falhas, erros, avisos de testes ou skips. O produtor de evidências realizou interrupção, retomada e repetição em processos novos; reutilizou 36 checkpoints e confirmou hashes iguais nos 42 arquivos. A otimização preservou os bytes dos 21 CSVs; o flat RDS preservou colunas, tipos e valores, embora seu hash binário tenha mudado. Consulte [aceite](P07_ACEITE_ENTREGA.md), [evidências](P07_EVIDENCIAS_INCREMENTO.json) e [desempenho](DESEMPENHO.md).

Para reproduzir o desenvolvimento, siga os sete prompts. Para executar a implementação existente, siga o segundo caminho do [README](README.md), restaurando dependências antes das etapas P04–P07. A configuração completa é necessária para produzir evidências próprias; provas desta execução não aprovam outra seleção ou outro código. O DFD em [ARQUITETURA](ARQUITETURA.md) explica como os fluxos correspondem aos prompts.

Tentativas incompletas ou falhas não apresentam sucesso anterior como atual. Backups e gerações válidas são preservados, com recuperação conservadora e diagnóstico. Limites continuam explícitos: heap R medido não equivale a pico RSS; unidades monetárias e escala percentual não foram confirmadas; leiautes históricos não estão homologados; CI com fixtures não reproduz o piloto CVM em computador limpo.

Até concluir publicação e verificação, a bola está com o agente, que informa progresso e estimativa de conclusão. Após esse fechamento, fica com o usuário para revisão acadêmica ou escolha de novo incremento. `doit` significa ler e executar as instruções atuais de `tmp/tmp.txt`.
