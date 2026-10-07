# P08 — Painel exploratório e relatório de análise

O incremento de 07/10/2026 amplia o P08 existente. A referência visual é **1920 × 1080 em paisagem**, com zoom proporcional de 50% a 200% por +, − e Restaurar. Gráficos ajustam suas dimensões após zoom/expansão. A versão também se adapta a telas menores. O preset Histórico Q4 substitui a antiga limitação aos últimos cinco quartos trimestres; a navegação padrão usa todo o período disponível.

R calcula estatísticas e artefatos antes da publicação. HTML/CSS/JavaScript estáticos fazem seleção e navegação no navegador; GitHub Pages não executa P06 ou servidor R. Clique no administrador para ver seu agregado e abrir todos os fundos/classes; selecione uma entidade para consultar PL histórico, administrador por data e carteira. Voltar remove primeiro a seleção da entidade, depois do administrador. Limpar restaura todo o período. O escopo ativo permanece visível.

## Pré-filtros em R/RStudio/CLI

Os critérios são aplicados por **posição mensal**, antes da consolidação das demais tabelas, flat e cedentes. A leitura seletiva de I e, quando necessário, X_1 produz um índice CNPJ/tipo/data; semijoin preserva todas as linhas legítimas sem multiplicação. A expressão é exibida antes de materializar os derivados. Configuração, versão de regras, assinatura do índice e entradas entram nos checkpoints e manifesto; mudar filtros não exige novos downloads íntegros.

```r
source('scripts/p01_pipeline_fidc.R')
config <- list(inicio='2026-07-01', fim='2026-08-31',
  dados='dados', saidas='saidas/minha_selecao',
  checkpoints='checkpoints/minha_selecao', gerar_flat=FALSE,
  filtros=list(interesse='Sim', exclusivo='Sim', operador='OU',
    condominio=c('ABERTO','FECHADO'),
    incluir_desconhecidos=FALSE, cotistas_min=1, cotistas_max=10))
# Em nova seleção, registrar P04; P05 reaproveita ZIPs íntegros quando atualizar=FALSE.
executar_pipeline_etapa('P04', config)
executar_pipeline_etapa('P05', config)
executar_pipeline_etapa('P06', config)
system2('Rscript',c('--vanilla','scripts/p08_resumo_dados.R',
  'dados/configuracao.rds'))
```

Para preservar a configuração existente, use diretórios `dados`, `saidas` e `checkpoints` próprios em uma nova seleção. Não há interface local de configuração além do R/RStudio/CLI neste projeto. Os filtros do Pages somente exploram a geração publicada; seus controles não refazem a consolidação.

| Opção | Valores e significado |
|---|---|
| `interesse` | `Todos`, `Sim`, `Não`; I/`COTST_INTERESSE`, interesse único e indissociável, domínio S/N |
| `exclusivo` | `Todos`, `Sim`, `Não`; I/`FUNDO_EXCLUSIVO`, domínio S/N; independente do primeiro indicador |
| `operador` | `E` ou `OU` entre indicadores ativos; um indicador inativo não interfere |
| `condominio` | Vetor de `ABERTO`/`FECHADO`; vazio desativa; demais valores observados, incluindo erros da fonte, são desconhecidos |
| `cotistas_igual` | Inteiro não negativo; usar igualdade **ou** intervalo |
| `cotistas_min`, `cotistas_max` | Limites inclusivos opcionais; mínimo ≤ máximo |
| `incluir_desconhecidos` | FALSE por padrão; TRUE aceita desconhecidos nos critérios ativos, sem interpretá-los como Não/zero |

Condomínio e quantidade combinam-se por E com o grupo dos indicadores. X_1 informa `TAB_X_NR_COTST` por classe/série, não comprova cotistas distintos entre séries. Apenas uma linha para a chave permite usar seu valor diretamente; múltiplas linhas ficam desconhecidas. O filtro exige X_1 e bloqueia seleção se nenhuma quantidade puder ser confirmada. Seleção vazia produz `sem_registros_elegiveis`; não substitui a última geração concluída nem gera análise fictícia. Originais e gerações anteriores permanecem preservados.

## Contrato analítico

Fundo, Classe e Fundo legado são apresentados separadamente. O último identifica leiautes antigos com `CNPJ_FUNDO` e tipo não preenchido. Não se somam patrimônios entre universos sem vínculo comprovado. Quantidade de fundos/classes usa CNPJ/tipo; CNPJs distintos são outra contagem. I↔IV usa CNPJ/tipo/data, com cardinalidade verificada e interrupção em conflitos. Administrador é o CNPJ válido vigente na competência; variações de nome entre datas não criam nova identidade. Ausentes/inválidos permanecem nas estatísticas gerais e ficam fora do ranking/denominador.

Quantis tipo 7 de R: `quantile(x, probs=0.975, type=7, na.rm=TRUE)`. P97,5 é calculado nos PL originais por grupo, aparece nas tabelas, relatório e CSV. Na distribuição por administrador, descreve seus fundos/classes, não sua soma. Os limiares de winsorização são globais por universo/tipo/data, anteriores ao filtro de administrador. O ranking histórico soma posições mensais winsorizadas; o ranking padrão soma PL original na mesma competência para todos. Denominadores incluem todos os administradores identificados antes do top25. Empates: CNPJ crescente. Histórico do recorte usa o mesmo período/preset, com contagem distinta de entidades via índice de vínculos.

Carteira usa quatro componentes exclusivos do ativo e nível separado de detalhes I.2.a–I.2.j. Componentes pais e filhos não são somados. Provisões não viram ativos positivos. Razão agregada é soma dos numeradores/soma das bases das mesmas posições presentes e com base positiva. Nulo não é zero; negativos são preservados e não usados em barras de 100%. Tolerância de reconciliação: 0,05 unidade da fonte (cinco arredondamentos de centavos). Somente posições completas, não negativas e reconciliadas entram em 100%; não se fabrica residual. Unidade monetária não foi confirmada pelo metadado, portanto não se aplica prefixo R$.

Os cálculos numéricos usam double; CSV/JSON preservam 15–17 algarismos significativos e o PL também mantém o texto decimal original. Isso não promete precisão decimal arbitrária. Alguns CSVs consolidados antigos mantêm nomes com bytes Latin-1 sem marca: o P08 converte somente textos inválidos em UTF-8 para exibição, sem modificar as entradas ou seus hashes.

## Artefatos e reprodução

```powershell
Rscript --vanilla scripts/p08_resumo_dados.R dados/atualizacao_2020/configuracao.rds
powershell -File scripts/publicar_resumo.ps1
node scripts/p08_validar_publicacao.cjs site
node scripts/p08_testar_navegador.cjs
```

Node é necessário apenas para verificações, não para o site. O teste de navegador usa Chrome headless e CDP local, abre servidor apenas durante os testes e salva screenshots/evidências. Não usa serviços externos ou dados simulados como análise pública. R usa os pacotes fixados em `renv.lock` e biblioteca `.R-library`. CI Linux/Windows executa P01–P08; Pages valida JavaScript, hashes, dados e links antes do deploy.

O relatório fixo é `resultados/estatisticas/relatorio_analise_fidc.md`, com HTML imprimível. CSVs existentes mantêm nomes e colunas compatíveis quando aplicável, mas **agora têm linhas separadas por `tipo`**, e top25 histórico possui até 25 por universo. Consumidores devem selecionar o tipo, não somar suas linhas. Colunas novas incluem `p97_5`, `p2_5`, dispersão, cobertura e reconciliação. O código legado de documentação P08 foi substituído pelo gerador compartilhado para impedir que recrie o recorte Q4 antigo.

`manifesto_publico.json` registra geração, schema, fonte, período, assinaturas, hashes e volume. Dados mensais e histórico por sufixo CNPJ são carregados sob demanda. A carteira longa tem CSV por competência, evitando um arquivo único excessivo; a base de posições mantém todos os campos utilizados. Séries da carteira e vínculos de administrador também são consultados sob demanda. O mapa/dicionário distinguem original, derivado, ausência e significado não confirmado.

Plotly.js **3.1.0**, MIT, é incluído como asset local. A [documentação oficial](https://plotly.com/javascript/) confirma os tipos e a API usados; [quartis e cercas explícitos](https://plotly.com/javascript/box-plots/) permitem compartilhar a convenção R. A escolha mantém a arquitetura HTML/CSS/JavaScript e oferece clique, redimensionamento e download SVG. Os arquivos de biblioteca conservam cabeçalho/licença; nenhuma imagem gerada é usada para dados.

A comparação entre competências exige observar cobertura. Setembro de 2026 tem bem menos registros que agosto; o relatório quantifica a mudança e compara também entidades comuns. Não atribuir mudança de total a retorno, criação/liquidação ou mudança do mercado sem outros dados. Concentração e outliers não provam irregularidade, risco, eficiência ou efeito tributário.

## Comunicação visual e navegação em celular — 07/10/2026

O cabeçalho informa o intervalo disponível e a quantidade de competências. Cada análise tem título e orientação próprios. Cartões distinguem PL original, identidades CNPJ/tipo, CNPJs distintos e P97,5; rótulos dos eixos monetários usam milhões da unidade da fonte e datas em mês/ano, conservando valores integrais para cálculo, tooltip e CSV. Tabelas alinham medidas numéricas e mantêm fontes e denominadores próximos da visualização.

Em celular, um seletor reúne as análises e o relatório permanece acessível ao lado. Universo e competência ficam visíveis; Série e administrador abre os filtros secundários, com estado acessível. Controles de toque têm pelo menos 44px; tabelas reorganizam os valores em cartões. A navegação também responde à largura efetiva após zoom. Gráficos de barras abreviam rótulos quando necessário e mantêm os nomes nas tabelas. A evolução da carteira apresenta todas as categorias disponíveis do nível escolhido, incluindo as dez categorias de detalhes.

O guia em Dados e metodologia explica a leitura do PL, do ativo e dos agregados por administrador, com referência à página oficial da Resolução CVM 175 e seu Anexo II. As entradas usadas não fundamentam cálculo de tributo ou enquadramento tributário. Dados contábeis, classificação regulatória e situação tributária exigem análises distintas.

A suíte local atual tem 56 casos e 471 verificações, incluindo oito casos P08. O navegador concluiu 45 verificações nos cinco tamanhos previstos, zoom 50/200%, navegação celular, filtros recolhíveis, dez categorias da carteira, modal/Esc/foco e relatório. Capturas podem refletir a posição de rolagem da análise durante o teste. Evidências atuais em `evidencias/p08`; a falha de inicialização anterior do Chromium no sandbox foi superada com a execução autorizada fora dele e não integra o aceite vigente.