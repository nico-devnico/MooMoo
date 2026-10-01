# Demarre le service ML avec un Python qui a MediaPipe.
# Preferer ml/.venv si mediapipe y est installe, sinon Python systeme.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Ml = Join-Path $Root "ml"
$VenvPy = Join-Path $Ml ".venv\Scripts\python.exe"
$SysPy = "C:\Users\Hp\AppData\Local\Programs\Python\Python312\python.exe"

function Test-MediaPipe([string]$py) {
  if (-not (Test-Path $py)) { return $false }
  & $py -c "import mediapipe" 2>$null
  return ($LASTEXITCODE -eq 0)
}

$Py = $null
if (Test-MediaPipe $VenvPy) { $Py = $VenvPy }
elseif (Test-MediaPipe $SysPy) { $Py = $SysPy }
elseif (Test-MediaPipe "python") { $Py = "python" }
else {
  Write-Error "MediaPipe introuvable. Dans ml/.venv : pip install -r requirements.txt"
}

Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

Set-Location $Ml
$env:PYTHONPATH = $Ml
Write-Host "ML via $Py on http://127.0.0.1:8000"
& $Py -m uvicorn main:app --host 127.0.0.1 --port 8000
