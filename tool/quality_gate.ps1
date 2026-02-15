param(
  [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

$tempRoot = "D:\budgetwise_temp"
if (-not (Test-Path $tempRoot)) {
  New-Item -Path $tempRoot -ItemType Directory | Out-Null
}

$env:TEMP = $tempRoot
$env:TMP = $tempRoot
$env:GRADLE_USER_HOME = "D:\gradle_cache"

if (-not (Test-Path $env:GRADLE_USER_HOME)) {
  New-Item -Path $env:GRADLE_USER_HOME -ItemType Directory | Out-Null
}

Write-Host "Using TEMP: $env:TEMP"
Write-Host "Using GRADLE_USER_HOME: $env:GRADLE_USER_HOME"

function Invoke-CheckedCommand {
  param(
    [scriptblock]$Command,
    [string]$Description
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Description failed with exit code $LASTEXITCODE."
  }
}

Write-Host "Running flutter pub get..."
Invoke-CheckedCommand -Description "flutter pub get" -Command { flutter pub get }

Write-Host "Checking dependency drift..."
Invoke-CheckedCommand -Description "flutter pub outdated" -Command {
  flutter pub outdated
}

Write-Host "Checking formatting..."
Invoke-CheckedCommand -Description "dart format check" -Command {
  dart format --output=none --set-exit-if-changed lib test
}

Write-Host "Running analyzer..."
Invoke-CheckedCommand -Description "flutter analyze" -Command { flutter analyze }

Write-Host "Running tests..."
Invoke-CheckedCommand -Description "flutter test" -Command { flutter test -j 1 }

if (-not $SkipBuild) {
  Write-Host "Running Android debug smoke build..."
  Invoke-CheckedCommand -Description "flutter build apk --debug" -Command {
    flutter build apk --debug
  }
}

Write-Host "Quality gate passed."
