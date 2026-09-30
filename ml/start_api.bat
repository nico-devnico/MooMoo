@echo off
setlocal
cd /d "%~dp0"

set HOST=127.0.0.1
set PORT=8000

echo [ml] Liberation du port %PORT% si occupe...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pids = Get-NetTCPConnection -LocalPort %PORT% -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique; if ($pids) { $pids | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }; Start-Sleep -Seconds 1; Write-Host '[ml] Ancien processus arrete.' } else { Write-Host '[ml] Port libre.' }"

echo [ml] Demarrage uvicorn sur http://%HOST%:%PORT% ...
".venv\Scripts\python.exe" -m uvicorn main:app --host %HOST% --port %PORT%
exit /b %ERRORLEVEL%
