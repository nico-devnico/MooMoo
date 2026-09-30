@echo off
setlocal
cd /d "%~dp0"

set HOST=127.0.0.1
set PORT=8000

echo [ml] Liberation du port %PORT% si occupe...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_api.ps1" -HostAddress "%HOST%" -Port %PORT%
exit /b %ERRORLEVEL%
