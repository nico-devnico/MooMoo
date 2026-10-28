# Fine-tune ASL for live camera domain, then publish + activate the new version.
$ErrorActionPreference = "Stop"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path "$PSScriptRoot\finetune_live.py")) { $Root = Split-Path $PSScriptRoot -Parent }
$Ml = Split-Path $PSScriptRoot -Parent
$Py = Join-Path $Ml ".venv\Scripts\python.exe"
if (-not (Test-Path $Py)) { $Py = "python" }

$env:MOOMOO_FS_MAX_PER_CLASS = if ($env:MOOMOO_FS_MAX_PER_CLASS) { $env:MOOMOO_FS_MAX_PER_CLASS } else { "1200" }
$env:MOOMOO_FS_EPOCHS = if ($env:MOOMOO_FS_EPOCHS) { $env:MOOMOO_FS_EPOCHS } else { "16" }
$env:MOOMOO_FS_LR = if ($env:MOOMOO_FS_LR) { $env:MOOMOO_FS_LR } else { "2.5e-4" }
$env:TF_CPP_MIN_LOG_LEVEL = "2"

Set-Location $PSScriptRoot
Write-Host "Fine-tune live domain with $Py (max/class=$env:MOOMOO_FS_MAX_PER_CLASS epochs=$env:MOOMOO_FS_EPOCHS)"
& $Py finetune_live.py
if ($LASTEXITCODE -ne 0) { throw "finetune_live.py failed: $LASTEXITCODE" }

Set-Location $Ml
Write-Host "Publishing new fingerspell version..."
& $Py -c "from moomoo_ml.fingerspell.train_job import publish_from_dataset_outputs; import json; print(json.dumps(publish_from_dataset_outputs(), indent=2, ensure_ascii=False))"
if ($LASTEXITCODE -ne 0) { throw "publish failed: $LASTEXITCODE" }
Write-Host "DONE — restart uvicorn to reload the predictor if --reload is not active."
