$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent
$destino = Join-Path $raiz 'site'
New-Item -ItemType Directory -Path $destino -Force | Out-Null
function Formatar-Inline([string]$texto) {
    $texto = [System.Net.WebUtility]::HtmlEncode($texto)
    $texto = [regex]::Replace($texto, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $texto = $texto.Replace('../../referencias/cvm/', 'referencias/cvm/')
    $texto = [regex]::Replace($texto, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
    return $texto
}
$html = New-Object System.Collections.Generic.List[string]
$emTabela = $false
$alinhamentos = @()
$inicioCabecalho = -1
$rotulosCabecalho = @()
foreach ($linha in Get-Content -LiteralPath (Join-Path $raiz 'resultados/estatisticas/relatorio_analise_fidc.md') -Encoding UTF8) {
    if ($linha.StartsWith('|')) {
        if ($linha -match '^\|[\s:|\-]+\|$') {
            $alinhamentos = @($linha.Trim().Trim('|').Split('|') | ForEach-Object {
                $celula = $_.Trim()
                if ($celula.StartsWith(':') -and $celula.EndsWith(':')) { 'center' }
                elseif ($celula.EndsWith(':')) { 'right' }
                elseif ($celula.StartsWith(':')) { 'left' }
                else { 'left' }
            })
            if ($emTabela -and $inicioCabecalho -ge 0) {
                for ($i = 0; $i -lt $alinhamentos.Count; $i++) {
                    $indice = $inicioCabecalho + $i
                    $html[$indice] = $html[$indice].Replace('class="align-left"', 'class="align-' + $alinhamentos[$i] + '"')
                }
                $inicioCabecalho = -1
            }
            continue
        }
        $celulas = $linha.Trim().Trim('|').Split('|')
        if (!$emTabela) {
            $html.Add('<div class="table-viewport" tabindex="0" role="region" aria-label="Tabela de dados"><table><thead><tr>')
            $inicioCabecalho = $html.Count
            $rotulosCabecalho = @($celulas | ForEach-Object { (Formatar-Inline $_.Trim()) })
            for ($i = 0; $i -lt $celulas.Count; $i++) {
                $html.Add('<th scope="col" class="align-left">' + $rotulosCabecalho[$i] + '</th>')
            }
            $html.Add('</tr></thead><tbody>')
            $emTabela = $true
        } else {
            $html.Add('<tr>')
            for ($i = 0; $i -lt $celulas.Count; $i++) {
                $alinhamento = if ($i -lt $alinhamentos.Count) { $alinhamentos[$i] } else { 'left' }
                $html.Add('<td data-label="' + $rotulosCabecalho[$i] + '" class="align-' + $alinhamento + '">' + (Formatar-Inline $celulas[$i].Trim()) + '</td>')
            }
            $html.Add('</tr>')
        }
        continue
    }
    if ($emTabela) { $html.Add('</tbody></table></div>'); $emTabela = $false }
    if ([string]::IsNullOrWhiteSpace($linha)) { continue }
    if ($linha -match '^(#{1,2}) (.+)$') {
        $nivel = $Matches[1].Length
        $html.Add("<h$nivel>" + (Formatar-Inline $Matches[2]) + "</h$nivel>")
    } else { $html.Add('<p>' + (Formatar-Inline $linha) + '</p>') }
}
if ($emTabela) { $html.Add('</tbody></table></div>') }
$pagina = @'
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Metadados e estatísticas dos informes mensais de FIDC da CVM, incluindo patrimônio líquido e ranking de administradores.">
<title>Estatísticas dos FIDC</title>
<style>
:root{color-scheme:light;--ink:#172c38;--accent:#007f78;--muted:#506470;--line:#dce5e9}
*{box-sizing:border-box}body{margin:0;background:#f4f7f8;color:var(--ink);font:16px/1.7 system-ui,sans-serif}
header{background:#123340;color:white;padding:28px max(24px,calc((100% - 1200px)/2))}header span{font-size:.8rem;letter-spacing:.14em;text-transform:uppercase}header a{color:#b0eee6}
main{max-width:1250px;margin:36px auto;padding:32px;background:white;border:1px solid var(--line);border-radius:12px}
h1{font-size:clamp(1.8rem,4vw,2.8rem);line-height:1.2;margin:0 0 24px}h2{margin-top:48px;border-top:1px solid var(--line);padding-top:24px;font-size:1.5rem}p{max-width:100ch}a{color:var(--accent);text-underline-offset:3px}
 .table-viewport{max-height:32rem;overflow-y:auto;overflow-x:hidden;scrollbar-gutter:stable;margin:24px 0;border:1px solid var(--line);border-radius:8px}.table-viewport:focus-visible{outline:3px solid var(--accent)}table{border-collapse:collapse;table-layout:fixed;width:100%;margin:0;font-size:.78rem;font-variant-numeric:tabular-nums;overflow-wrap:anywhere}th{position:sticky;top:0;z-index:2;background:#e7f3f1;color:#17473f;text-align:left}th,td{padding:8px 7px;border-bottom:1px solid var(--line)}th.align-right,td.align-right{text-align:right}th.align-center,td.align-center{text-align:center}td{vertical-align:top}tbody tr:nth-child(even){background:#f7fafb}tbody tr:hover{background:#edf7f5}footer{max-width:1200px;margin:24px auto 48px;padding:0 24px;color:var(--muted);font-size:.9rem}
@media(max-width:760px){main{margin:16px 12px;padding:20px 16px}header{padding:20px 24px}table,thead,tbody,tr,th,td{display:block;width:100%}thead{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}tbody tr{margin:12px 0;border:1px solid var(--line);border-radius:8px;overflow:hidden}tbody td{display:grid;grid-template-columns:minmax(7.5em,40%) minmax(0,1fr);gap:8px;padding:8px 10px;text-align:right!important}tbody td::before{content:attr(data-label);font-weight:600;text-align:left;color:var(--muted)} }
</style>
</head>
<body>
<header><span>Mini projeto · Informes mensais CVM</span><br><a href="https://github.com/amarallr/akcit_c4_mini_projeto">Código, metodologia e documentação ↗</a></header>
<main>
<!-- CONTEUDO -->
</main>
<footer>Fonte: informes mensais de FIDCs da CVM. Cobertura e limitações desta geração estão descritas nos metadados acima. <a href="relatorio_estatisticas.md">Baixar relatório em Markdown</a>.</footer>
</body>
</html>
'@
$pagina = $pagina.Replace('<!-- CONTEUDO -->', ($html -join "`n"))
[System.IO.File]::WriteAllText((Join-Path $destino 'relatorio_analise_fidc.html'), $pagina, (New-Object System.Text.UTF8Encoding($false)))
foreach ($arquivo in @('relatorio_estatisticas.md','estatisticas_por_competencia.csv','top25_administradores.csv')) {
    $origem = Join-Path $raiz ('resultados/estatisticas/' + $arquivo)
    if ($arquivo -eq 'relatorio_estatisticas.md') {
        $conteudo = [System.IO.File]::ReadAllText($origem,[System.Text.Encoding]::UTF8).Replace('../../referencias/cvm/','referencias/cvm/')
        [System.IO.File]::WriteAllText((Join-Path $destino $arquivo),$conteudo,(New-Object System.Text.UTF8Encoding($false)))
    } else { Copy-Item -LiteralPath $origem -Destination $destino -Force }
}
foreach ($arquivo in @('dicionario_campos_declarados.csv','esquema_observado_piloto.csv')) {
    $siteRef = Join-Path $destino 'referencias/cvm'
    New-Item -ItemType Directory -Path $siteRef -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $raiz ('referencias/cvm/' + $arquivo)) -Destination $siteRef -Force
}
# P08-MOD-005 | P08-RF-015: todos os derivados, assets e caminhos relativos.
Copy-Item -Path (Join-Path $raiz 'resultados/estatisticas/*') -Destination $destino -Recurse -Force
Copy-Item -Path (Join-Path $raiz 'web/*') -Destination $destino -Recurse -Force
$relatorioPath = Join-Path $destino 'relatorio_analise_fidc.html'
$relatorioHtml = [IO.File]::ReadAllText($relatorioPath,[Text.Encoding]::UTF8)
$relatorioHtml = $relatorioHtml.Replace('<main>','<main class="report"><p><a href="index.html">← Voltar ao painel FIDC</a> · <button onclick="window.print()">Imprimir relatório</button></p>')
$relatorioHtml = $relatorioHtml.Replace('</head>','<link rel="stylesheet" href="painel.css"></head>')
[IO.File]::WriteAllText($relatorioPath,$relatorioHtml,(New-Object Text.UTF8Encoding($false)))
$commitPublicacao = $env:GITHUB_SHA
if ([string]::IsNullOrWhiteSpace($commitPublicacao)) { $commitPublicacao = (git -C $raiz rev-parse HEAD).Trim() }
$versaoPublicacao = @{ sha=$commitPublicacao; schema='p08-v2026-10-07' } | ConvertTo-Json -Compress
[IO.File]::WriteAllText((Join-Path $destino 'versao_publicacao.json'),$versaoPublicacao,(New-Object Text.UTF8Encoding($false)))
Write-Output 'Painel e relatório gerados em site/index.html e site/relatorio_analise_fidc.html.'
