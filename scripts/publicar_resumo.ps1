$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent
$destino = Join-Path $raiz 'site'
New-Item -ItemType Directory -Path $destino -Force | Out-Null
function Formatar-Inline([string]$texto) {
    $texto = [System.Net.WebUtility]::HtmlEncode($texto)
    $texto = [regex]::Replace($texto, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $texto = [regex]::Replace($texto, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
    return $texto
}
$html = New-Object System.Collections.Generic.List[string]
$emTabela = $false
foreach ($linha in Get-Content -LiteralPath (Join-Path $raiz 'RESUMO_DADOS.md') -Encoding UTF8) {
    if ($linha.StartsWith('|')) {
        if ($linha -match '^\|[\s:|\-]+\|$') { continue }
        $celulas = $linha.Trim().Trim('|').Split('|')
        if (!$emTabela) {
            $html.Add('<div class="table-scroll" tabindex="0" role="region" aria-label="Tabela de dados"><table><thead><tr>')
            foreach ($celula in $celulas) { $html.Add('<th scope="col">' + (Formatar-Inline $celula.Trim()) + '</th>') }
            $html.Add('</tr></thead><tbody>')
            $emTabela = $true
        } else {
            $html.Add('<tr>')
            foreach ($celula in $celulas) { $html.Add('<td>' + (Formatar-Inline $celula.Trim()) + '</td>') }
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
<meta name="description" content="Análises do piloto FIDC: estatísticas de patrimônio líquido e ranking dos 25 maiores administradores, julho e agosto de 2026.">
<title>Estatísticas dos FIDC</title>
<style>
:root{color-scheme:light;--ink:#172c38;--accent:#007f78;--muted:#506470;--line:#dce5e9}
*{box-sizing:border-box}body{margin:0;background:#f4f7f8;color:var(--ink);font:16px/1.7 system-ui,sans-serif}
header{background:#123340;color:white;padding:28px max(24px,calc((100% - 1200px)/2))}header span{font-size:.8rem;letter-spacing:.14em;text-transform:uppercase}header a{color:#b0eee6}
main{max-width:1250px;margin:36px auto;padding:32px;background:white;border:1px solid var(--line);border-radius:12px}
h1{font-size:clamp(1.8rem,4vw,2.8rem);line-height:1.2;margin:0 0 24px}h2{margin-top:48px;border-top:1px solid var(--line);padding-top:24px;font-size:1.5rem}p{max-width:100ch}a{color:var(--accent);text-underline-offset:3px}
.table-scroll{overflow-x:auto;margin:24px 0;border:1px solid var(--line);border-radius:8px}.table-scroll:focus-visible{outline:3px solid var(--accent)}table{border-collapse:collapse;width:100%;font-size:.85rem;font-variant-numeric:tabular-nums}th{background:#e7f3f1;color:#17473f;text-align:left}th,td{padding:12px 14px;border-bottom:1px solid var(--line)}td{vertical-align:top}tbody tr:nth-child(even){background:#f7fafb}tbody tr:hover{background:#edf7f5}td:not(:first-child){min-width:100px}footer{max-width:1200px;margin:24px auto 48px;padding:0 24px;color:var(--muted);font-size:.9rem}
@media(max-width:650px){main{margin:16px 12px;padding:20px 16px}th,td{padding:10px}header{padding:20px 24px}}
</style>
</head>
<body>
<header><span>Mini projeto · Informes mensais CVM</span><br><a href="https://github.com/amarallr/akcit_c4_mini_projeto">Código, metodologia e documentação ↗</a></header>
<main>
<!-- CONTEUDO -->
</main>
<footer>Fonte: informes mensais de FIDCs da CVM. Piloto de julho e agosto de 2026. <a href="RESUMO_DADOS.md">Baixar relatório em Markdown</a>.</footer>
</body>
</html>
'@
$pagina = $pagina.Replace('<!-- CONTEUDO -->', ($html -join "`n"))
[System.IO.File]::WriteAllText((Join-Path $destino 'index.html'), $pagina, (New-Object System.Text.UTF8Encoding($false)))
foreach ($arquivo in @('RESUMO_DADOS.md','P07_RESUMO_COMPETENCIAS.csv','P07_TOP25_ADMINISTRADORES.csv')) {
    Copy-Item -LiteralPath (Join-Path $raiz $arquivo) -Destination $destino -Force
}
Write-Output 'Página gerada em site/index.html.'
