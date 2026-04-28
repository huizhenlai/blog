param(
  [int]$Port = 8756,
  [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$serverPath = Join-Path $PSScriptRoot "server.py"

$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
  if ($SelfTest) {
    & $python.Source $serverPath --self-test
  } else {
    & $python.Source $serverPath --port $Port
  }
  exit $LASTEXITCODE
}

$py = Get-Command py -ErrorAction SilentlyContinue
if ($py) {
  if ($SelfTest) {
    & $py.Source -3 $serverPath --self-test
  } else {
    & $py.Source -3 $serverPath --port $Port
  }
  exit $LASTEXITCODE
}

throw "Python 3 is required to run this tool."
