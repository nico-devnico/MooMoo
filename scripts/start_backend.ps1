# Demarre l'API backend (port 3001) apres s'assurer que le ML repond.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Root "backend"

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -UseBasicParsing -TimeoutSec 3
} catch {
  Write-Warning "ML (8000) injoignable — lance d'abord scripts/start_ml.ps1"
}

Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

Set-Location $Backend
Write-Host "API via node on http://127.0.0.1:3001"
node src/index.js
