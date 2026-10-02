> Evidência histórica do primeiro incremento P04. Os limites e próximos passos abaixo descrevem aquele momento. Estado atual: P04–P07 implementados, piloto executado; consulte P07_ACEITE_ENTREGA.md, P04_ESQUEMA_OBSERVADO_PILOTO.csv e RETOMADA.md.

# P04 — Levantamento inicial das fontes oficiais da CVM

**Atualização vigente:** julho/agosto de 2026 confirmado pelo usuário; dicionário lido no incremento seguinte. Consulte [leitura e limites](P04_LEITURA_DICIONARIO_CVM.md). O conteúdo abaixo registra a observação do primeiro incremento, anterior à autorização de leitura.

Consulta em 01/10/2026. Incremento autorizado: item 1, levantamento de catálogo, listagens e localização do dicionário. Base: P04-RF-001 e P04-RNF-001. A IA consultou páginas oficiais e organizou as evidências; o usuário decidirá o próximo incremento. Não houve download de ZIP, extração, execução R, implementação de configuração ou início de P05.

## Fontes e evidências

| Fonte oficial consultada | Resultado observado | Limite |
|---|---|---|
| [Catálogo FIDC — Informe Mensal](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal) | Descreve a política semanal de atualização dos últimos doze meses e sinaliza mudanças de layout em 2019/2023, incluindo tabela X | Descrição do catálogo não substitui inspeção dos arquivos |
| [Listagem DADOS](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/) | 20 ZIPs mensais, de 202501 a 202608; tamanho exibido de 3M por arquivo | Nome e tamanho arredondado não comprovam conteúdo, cobertura de linhas ou integridade |
| [Listagem HIST](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/HIST/) | 12 ZIPs anuais, de 2013 a 2024; tamanhos exibidos de 3M a 26M | Organização observada nesta data, sem regra permanente de corte por ano |
| [Listagem META](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/META/) | `meta_inf_mensal_fidc_txt.zip`, tamanho exibido 16K, data da listagem 26/09/2026 | Dicionário localizado, conteúdo não lido |
| [Página do recurso dicionário](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal/resource/e44f6341-9827-4599-baf3-ac5e298e55f7) | Formato ZIP; datas cadastrais de dados em 2017 e metadados em 2022 | Datas cadastrais diferem da data da listagem; não presumir versão do conteúdo |

O catálogo apresenta os doze meses de setembro/2025 a agosto/2026, enquanto DADOS lista também meses anteriores. A janela de atualização descrita no catálogo e a disponibilidade da pasta são conceitos distintos. A indicação de HIST como arquivo fora da política corrente deve ser preservada na seleção futura. [Catálogo](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal).

## Candidatos ao piloto — sem seleção definitiva

| Competência sugerida nos prompts | Arquivo listado | Tamanho exibido | Evidência complementar |
|---|---|---|---|
| Julho/2026 | `inf_mensal_fidc_202607.zip` | 3M | [Recurso julho](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal/resource/4be3d31e-0f70-4ecd-a936-d3acfe568564): dados/metadados cadastrados em 28/09/2026 |
| Agosto/2026 | `inf_mensal_fidc_202608.zip` | 3M | [Recurso agosto](https://dados.cvm.gov.br/dataset/fidc-doc-inf_mensal/resource/bc06acc6-a7a8-4217-a41b-1f1666f5d648): dados/metadados cadastrados em 28/09/2026 |

Disponibilidade dos nomes confirmada na [listagem DADOS](https://dados.cvm.gov.br/dados/FIDC/DOC/INF_MENSAL/DADOS/). O total aproximado dos dois ZIPs é 6 MB, inferido dos tamanhos arredondados da página. Não mede tamanho descompactado, linhas, memória ou tempo de processamento. As datas de listagem dos arquivos são 26/09/2026, diferentes das datas cadastrais dos recursos; nenhuma delas foi tratada como prova da versão interna do ZIP.

## O que permanece pendente

1. Confirmar com o usuário período e objetivo do piloto; julho/agosto continuam propostos.
2. Autorizar a leitura do dicionário em outro incremento. Sua disponibilização em ZIP foi identificada, mas não há contrato de campos validado.
3. Inventariar membros e tabelas reais quando houver autorização de inspeção dos arquivos. I–IX e X são escopo previsto nos prompts; presença, nomes e obrigatoriedade ainda não foram verificados.
4. Confirmar tipos, separador, encoding, decimais, unidades, granularidade e chaves; não inferir propriedades pelos nomes dos arquivos.
5. Implementar configuração, funções e testes de P04 somente em incremento posterior autorizado.

## Situação dos requisitos e testes

P04-RF-001: levantamento parcial realizado. Política e organização externas observadas; leitura do dicionário e cobertura interna pendentes. P04-RNF-001: consultas oficiais realizadas conforme o prompt, sem uso de código externo. P04-RF-002 a RF-005: sem implementação, com pendências acima. P04-TST-004: consulta manual parcial registrada, não aprovado como teste da função `inventariar_recursos_fidc`, que ainda não existe. P04-TST-001/002/003: não executados.

Fases SWEBOK relacionadas: requisitos, viabilidade e arquitetura/projeto. Construção e testes funcionais permanecem futuros. O levantamento não conclui P04 nem autoriza P05. A bola fica com o usuário para escolher o próximo incremento.
