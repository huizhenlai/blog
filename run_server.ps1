$ErrorActionPreference = "Stop"
$cacheDir = Join-Path $PSScriptRoot ".hugo_cache"
hugo server -D --disableFastRender --cacheDir "$cacheDir"
