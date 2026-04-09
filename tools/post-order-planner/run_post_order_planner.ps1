param(
  [int]$Port = 8756,
  [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$script:PostsRoot = Join-Path $script:RepoRoot "content\posts"
$script:StaticRoot = $PSScriptRoot
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-PostFiles {
  $rootFiles = @(Get-ChildItem -LiteralPath $script:PostsRoot -File -Filter *.md)
  $bundleFiles = @(Get-ChildItem -LiteralPath $script:PostsRoot -Recurse -File -Filter index.md)
  return @($rootFiles.FullName + $bundleFiles.FullName) | Sort-Object -Unique
}

function Get-FrontMatterMatch {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Content
  )

  return [regex]::Match(
    $Content,
    '(?s)\A---(?<nl>\r?\n)(?<front>.*?)(?<frontNl>\r?\n)---(?<after>\r?\n?)'
  )
}

function Get-FrontMatterValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FrontMatter,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $match = [regex]::Match($FrontMatter, "(?m)^\s*$Name\s*:\s*(.+?)\s*(?:#.*)?$")
  if ($match.Success) {
    return $match.Groups[1].Value.Trim()
  }
  return $null
}

function Convert-YamlScalar {
  param(
    [AllowNull()]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  $trimmed = $Value.Trim()
  if (
    ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) -or
    ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'"))
  ) {
    return $trimmed.Substring(1, $trimmed.Length - 2)
  }

  return $trimmed
}

function Convert-YamlArray {
  param(
    [AllowNull()]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return @()
  }

  $trimmed = $Value.Trim()
  if (-not ($trimmed.StartsWith('[') -and $trimmed.EndsWith(']'))) {
    return @()
  }

  $inner = $trimmed.Substring(1, $trimmed.Length - 2).Trim()
  if ([string]::IsNullOrWhiteSpace($inner)) {
    return @()
  }

  return @(
    $inner.Split(',') |
      ForEach-Object { Convert-YamlScalar $_ } |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
}

function Convert-ToPostRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
  )

  $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
  $match = Get-FrontMatterMatch -Content $content
  if (-not $match.Success) {
    throw "文件缺少 front matter: $FilePath"
  }

  $frontMatter = $match.Groups["front"].Value
  $repoRelative = $FilePath.Substring($script:RepoRoot.Length + 1).Replace('\', '/')
  $title = Convert-YamlScalar (Get-FrontMatterValue -FrontMatter $frontMatter -Name "title")
  $dateRaw = Convert-YamlScalar (Get-FrontMatterValue -FrontMatter $frontMatter -Name "date")
  $weightRaw = Convert-YamlScalar (Get-FrontMatterValue -FrontMatter $frontMatter -Name "weight")
  $draftRaw = Convert-YamlScalar (Get-FrontMatterValue -FrontMatter $frontMatter -Name "draft")
  $featuredRaw = Convert-YamlScalar (Get-FrontMatterValue -FrontMatter $frontMatter -Name "featured")

  $weight = 0
  if (-not [string]::IsNullOrWhiteSpace($weightRaw)) {
    [void][int]::TryParse($weightRaw, [ref]$weight)
  }

  $dateValue = $null
  if (-not [string]::IsNullOrWhiteSpace($dateRaw)) {
    try {
      $dateValue = [DateTimeOffset]::Parse($dateRaw)
    } catch {
      $dateValue = $null
    }
  }

  return [PSCustomObject]@{
    id = $repoRelative
    title = if ([string]::IsNullOrWhiteSpace($title)) { [System.IO.Path]::GetFileNameWithoutExtension($FilePath) } else { $title }
    path = $repoRelative
    weight = $weight
    date = if ($dateValue) { $dateValue.ToString("yyyy-MM-dd") } else { "" }
    draft = ($draftRaw -eq "true")
    featured = ($featuredRaw -eq "true")
    series = Convert-YamlArray (Get-FrontMatterValue -FrontMatter $frontMatter -Name "series")
    tags = Convert-YamlArray (Get-FrontMatterValue -FrontMatter $frontMatter -Name "tags")
  }
}

function Get-PostRecords {
  $posts = foreach ($file in Get-PostFiles) {
    Convert-ToPostRecord -FilePath $file
  }

  return @(
    $posts | Sort-Object `
      @{ Expression = { if ($_.weight -gt 0) { 0 } else { 1 } }; Ascending = $true }, `
      @{ Expression = { if ($_.weight -gt 0) { $_.weight } else { [int]::MaxValue } }; Ascending = $true }, `
      @{ Expression = { $_.date }; Descending = $true }, `
      @{ Expression = { $_.title.ToLowerInvariant() }; Ascending = $true }
  )
}

function Set-WeightInContent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Content,
    [Parameter(Mandatory = $true)]
    [int]$Weight
  )

  $match = Get-FrontMatterMatch -Content $Content
  if (-not $match.Success) {
    throw "front matter 解析失败"
  }

  $newline = if ($Content.Contains("`r`n")) { "`r`n" } else { "`n" }
  $frontMatter = $match.Groups["front"].Value
  $after = $match.Groups["after"].Value
  $rest = $Content.Substring($match.Length)
  $lines = New-Object System.Collections.Generic.List[string]
  foreach ($line in ($frontMatter -split "\r?\n")) {
    [void]$lines.Add($line)
  }

  $updated = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*weight\s*:') {
      $lines[$i] = "weight: $Weight"
      $updated = $true
      break
    }
  }

  if (-not $updated) {
    $insertAt = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '^\s*draft\s*:') {
        $insertAt = $i + 1
        break
      }
      if ($insertAt -eq $lines.Count -and $lines[$i] -match '^\s*date\s*:') {
        $insertAt = $i + 1
      }
    }
    $lines.Insert($insertAt, "weight: $Weight")
  }

  $newFrontMatter = $lines -join $newline
  return "---$newline$newFrontMatter$newline---$after$rest"
}

function Save-PostOrder {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$OrderedIds
  )

  $posts = Get-PostRecords
  $postMap = @{}
  foreach ($post in $posts) {
    $postMap[$post.id] = $post
  }

  if ($OrderedIds.Count -ne $posts.Count) {
    throw "保存失败：文章数量不一致。"
  }

  $orderedSet = $OrderedIds | Sort-Object -Unique
  $allSet = $posts.id | Sort-Object -Unique
  if (($orderedSet -join '|') -ne ($allSet -join '|')) {
    throw "保存失败：排序列表和仓库文章集合不一致。"
  }

  $changed = 0
  for ($index = 0; $index -lt $OrderedIds.Count; $index++) {
    $id = $OrderedIds[$index]
    $weight = $index + 1
    $relativePath = $id.Replace('/', '\')
    $absolutePath = Join-Path $script:RepoRoot $relativePath
    $content = [System.IO.File]::ReadAllText($absolutePath, [System.Text.Encoding]::UTF8)
    $updatedContent = Set-WeightInContent -Content $content -Weight $weight

    if ($updatedContent -cne $content) {
      [System.IO.File]::WriteAllText($absolutePath, $updatedContent, $script:Utf8NoBom)
      $changed++
    }
  }

  return [PSCustomObject]@{
    changed = $changed
    total = $OrderedIds.Count
  }
}

function Write-JsonResponse {
  param(
    [Parameter(Mandatory = $true)]
    [System.Net.HttpListenerResponse]$Response,
    [Parameter(Mandatory = $true)]
    $Payload,
    [int]$StatusCode = 200
  )

  $json = $Payload | ConvertTo-Json -Depth 8
  $buffer = $script:Utf8NoBom.GetBytes($json)
  $Response.StatusCode = $StatusCode
  $Response.ContentType = "application/json; charset=utf-8"
  $Response.ContentEncoding = $script:Utf8NoBom
  $Response.ContentLength64 = $buffer.Length
  $Response.OutputStream.Write($buffer, 0, $buffer.Length)
  $Response.OutputStream.Close()
}

function Write-TextResponse {
  param(
    [Parameter(Mandatory = $true)]
    [System.Net.HttpListenerResponse]$Response,
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [int]$StatusCode = 200,
    [string]$ContentType = "text/plain; charset=utf-8"
  )

  $buffer = $script:Utf8NoBom.GetBytes($Text)
  $Response.StatusCode = $StatusCode
  $Response.ContentType = $ContentType
  $Response.ContentEncoding = $script:Utf8NoBom
  $Response.ContentLength64 = $buffer.Length
  $Response.OutputStream.Write($buffer, 0, $buffer.Length)
  $Response.OutputStream.Close()
}

function Get-MimeType {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".html" { return "text/html; charset=utf-8" }
    ".css" { return "text/css; charset=utf-8" }
    ".js" { return "application/javascript; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    default { return "application/octet-stream" }
  }
}

function Serve-StaticFile {
  param(
    [Parameter(Mandatory = $true)]
    [System.Net.HttpListenerResponse]$Response,
    [Parameter(Mandatory = $true)]
    [string]$RequestPath
  )

  $relativePath = if ($RequestPath -eq "/") { "index.html" } else { $RequestPath.TrimStart('/') }
  $target = [System.IO.Path]::GetFullPath((Join-Path $script:StaticRoot $relativePath))

  if (-not $target.StartsWith($script:StaticRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-TextResponse -Response $Response -Text "Forbidden" -StatusCode 403
    return
  }

  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    Write-TextResponse -Response $Response -Text "Not Found" -StatusCode 404
    return
  }

  $bytes = [System.IO.File]::ReadAllBytes($target)
  $Response.StatusCode = 200
  $Response.ContentType = Get-MimeType -Path $target
  $Response.ContentLength64 = $bytes.Length
  $Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $Response.OutputStream.Close()
}

function Invoke-SelfTest {
  $posts = Get-PostRecords
  if ($posts.Count -lt 1) {
    throw "未发现任何文章。"
  }

  $sample = @"
---
title: "sample"
date: 2026-01-01
draft: true
---

body
"@
  $rewritten = Set-WeightInContent -Content $sample -Weight 7
  if ($rewritten -notmatch '(?m)^weight:\s+7$') {
    throw "weight 写回测试失败。"
  }

  Write-Host "SelfTest OK - posts: $($posts.Count)"
}

if ($SelfTest) {
  Invoke-SelfTest
  exit 0
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host ""
Write-Host "Post Order Planner is running."
Write-Host "Open in browser: $prefix"
Write-Host "Press Ctrl+C to stop."
Write-Host ""

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    try {
      if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/api/posts") {
        Write-JsonResponse -Response $response -Payload @{ posts = Get-PostRecords }
        continue
      }

      if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/reorder") {
        $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
        $body = $reader.ReadToEnd()
        $reader.Close()

        $payload = $body | ConvertFrom-Json
        if (-not $payload.ids) {
          throw "请求缺少 ids。"
        }

        $result = Save-PostOrder -OrderedIds @($payload.ids)
        Write-JsonResponse -Response $response -Payload @{
          ok = $true
          changed = $result.changed
          total = $result.total
          posts = Get-PostRecords
        }
        continue
      }

      if ($request.HttpMethod -eq "GET") {
        Serve-StaticFile -Response $response -RequestPath $request.Url.AbsolutePath
        continue
      }

      Write-TextResponse -Response $response -Text "Method Not Allowed" -StatusCode 405
    } catch {
      Write-JsonResponse -Response $response -StatusCode 500 -Payload @{
        ok = $false
        error = $_.Exception.Message
      }
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
