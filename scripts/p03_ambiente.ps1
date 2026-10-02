# Prompt responsável: P03 | P03-MOD-001; chama preparação e diagnóstico P03.
param([switch]$Instalar)
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    # Remover locale incompatível somente deste processo; restaurar no fim.
    $localeAnterior = @{}
    foreach ($nomeLocale in @('LANG', 'LC_ALL', 'LC_CTYPE')) {
        $localeAnterior[$nomeLocale] = [Environment]::GetEnvironmentVariable($nomeLocale, 'Process')
        [Environment]::SetEnvironmentVariable($nomeLocale, $null, 'Process')
    }
    if ($Instalar) {
        Rscript --vanilla scripts/p03_preparar_ambiente.R
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao preparar dependencias R.' }
    }
    Rscript --vanilla scripts/p03_diagnosticar_ambiente.R
    if ($LASTEXITCODE -ne 0) { throw 'Falha na verificacao do ambiente R.' }
} finally {
    foreach ($nomeLocale in $localeAnterior.Keys) {
        [Environment]::SetEnvironmentVariable($nomeLocale, $localeAnterior[$nomeLocale], 'Process')
    }
    Pop-Location
}
