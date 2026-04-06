param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$projectRoot = Join-Path $PSScriptRoot 'flutter_app'

if (-not (Test-Path (Join-Path $projectRoot 'pubspec.yaml'))) {
  Write-Error "Flutter project not found at $projectRoot"
  exit 1
}

Push-Location $projectRoot
try {
  & flutter @FlutterArgs
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
