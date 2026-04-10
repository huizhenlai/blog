$ErrorActionPreference = "Stop"
$cacheDir = Join-Path $PSScriptRoot ".hugo_cache"
hugo --gc --minify --cleanDestinationDir --cacheDir "$cacheDir"
