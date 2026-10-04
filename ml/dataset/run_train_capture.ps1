# Lance l'entrainement fingerspell avec logs + env webcam-aug.
$ErrorActionPreference = "Continue"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $PSScriptRoot "train.py"))) {
  $dataset = "D:\projets\MooMoo\ml\dataset"
} else {
  $dataset = $PSScriptRoot
}
$ml = Split-Path $dataset -Parent
$py = Join-Path $ml ".venv\Scripts\python.exe"
$captures = "D:\projets\MooMoo\assets\captures"
$log = Join-Path $captures "11_train_log.txt"

$env:MOOMOO_FS_MAX_PER_CLASS = "800"
$env:MOOMOO_FS_EPOCHS = "25"
$env:TF_CPP_MIN_LOG_LEVEL = "2"
$env:TF_ENABLE_ONEDNN_OPTS = "0"
$env:PYTHONUNBUFFERED = "1"

"=== fingerspell train log ===" | Set-Content -Encoding utf8 $log
"date: $(Get-Date -Format o)" | Add-Content -Encoding utf8 $log
"python: $py" | Add-Content -Encoding utf8 $log
"MAX_PER_CLASS=$env:MOOMOO_FS_MAX_PER_CLASS EPOCHS=$env:MOOMOO_FS_EPOCHS" | Add-Content -Encoding utf8 $log
"---" | Add-Content -Encoding utf8 $log

Set-Location $dataset
& $py -u train.py 2>&1 | Tee-Object -FilePath $log -Append
$exit = $LASTEXITCODE
"`n=== exit_code=$exit at $(Get-Date -Format o) ===" | Add-Content -Encoding utf8 $log
exit $exit
