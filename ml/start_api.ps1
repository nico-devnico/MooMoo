# Demarre l'API ML en liberant d'abord le port (evite WinError 10048).
param(
  [string]$HostAddress = "127.0.0.1",
  [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$pids = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique
if ($pids) {
  foreach ($procId in $pids) {
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Seconds 1
  Write-Host "[ml] Ancien processus sur le port $Port arrete."
} else {
  Write-Host "[ml] Port $Port libre."
}

$python = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
  Write-Error "Environnement .venv introuvable. Creez-le avec: python -m venv .venv"
}

Write-Host "[ml] uvicorn sur http://${HostAddress}:$Port ..."
& $python -m uvicorn main:app --host $HostAddress --port $Port
