$ErrorActionPreference = "Stop"
$cacheDir = Join-Path $PSScriptRoot ".hugo_cache"

hugo server -D --disableFastRender --cacheDir "$cacheDir"
$hugoSucceeded = $?
if (-not $hugoSucceeded) {
    $hugoExitCode = if ($null -eq $LASTEXITCODE) { "unknown" } else { $LASTEXITCODE }
    throw "Hugo development server stopped with exit code $hugoExitCode."
}
