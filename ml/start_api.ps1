# Demarre l'API ML en liberant d'abord le port (evite WinError 10048).
param(
  [string]$HostAddress = "127.0.0.1",
  [int]$Port = 8000
)

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

function Stop-PortListeners([int]$Port) {
  $killed = @()
  # Methode 1 : Get-NetTCPConnection
  try {
    $pids = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique |
      Where-Object { $_ -and $_ -ne 0 }
    foreach ($procId in $pids) {
      Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
      $killed += $procId
    }
  } catch {}

  # Methode 2 : netstat (fiable sous Windows si Get-NetTCPConnection rate)
  try {
    $lines = netstat -ano | Select-String ":$Port\s"
    foreach ($line in $lines) {
      $parts = ($line.ToString() -split '\s+') | Where-Object { $_ -ne '' }
      if ($parts.Count -lt 5) { continue }
      $procId = [int]$parts[-1]
      if ($procId -le 0) { continue }
      if ($killed -contains $procId) { continue }
      Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
      $killed += $procId
    }
  } catch {}

  return $killed
}

$killed = Stop-PortListeners -Port $Port
if ($killed.Count -gt 0) {
  Start-Sleep -Seconds 1
  # Double passe si le port reste pris.
  $again = Stop-PortListeners -Port $Port
  if ($again.Count -gt 0) { Start-Sleep -Seconds 1 }
  Write-Host "[ml] Port $Port libere (PID: $($killed -join ', '))."
} else {
  Write-Host "[ml] Port $Port libre."
}

$python = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
  Write-Error "Environnement .venv introuvable. Creez-le avec: python -m venv .venv"
  exit 1
}

Write-Host "[ml] uvicorn sur http://${HostAddress}:$Port ..."
Write-Host "[ml] Astuce: utilisez toujours start_api.ps1 / start_api.bat (pas uvicorn seul)."
& $python -m uvicorn main:app --host $HostAddress --port $Port
