# Prompt responsável: P03 | P03-RF-003; encaminha ao GitHub CLI externo.
# Distribuicao oficial portatil; encaminha argumentos sem registrar credenciais.
$ghExecutavel = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools/github-cli/bin/gh.exe'
if (-not (Test-Path -LiteralPath $ghExecutavel)) {
    throw 'GitHub CLI portatil ausente em tools/github-cli/bin/gh.exe.'
}
& $ghExecutavel @args
exit $LASTEXITCODE
