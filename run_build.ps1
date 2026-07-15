$ErrorActionPreference = "Stop"
$cacheDir = Join-Path $PSScriptRoot ".hugo_cache"

# Windows PowerShell 不会自动把原生命令的失败转成脚本失败。
Write-Output "Building Hugo site..."
hugo --gc --minify --cleanDestinationDir --cacheDir "$cacheDir"
$hugoSucceeded = $?
if (-not $hugoSucceeded) {
    $hugoExitCode = if ($null -eq $LASTEXITCODE) { "unknown" } else { $LASTEXITCODE }
    throw "Hugo production build failed with exit code $hugoExitCode."
}
