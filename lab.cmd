@echo off
rem DevOps and Cloud Lab launcher: double-click this file (Windows).
rem It checks Docker, then opens the lab in a Git Bash window.
cd /d "%~dp0"
where docker >nul 2>nul || (echo Docker was not found. Install Docker Desktop first: https://www.docker.com/products/docker-desktop & pause & exit /b 1)
docker info >nul 2>nul || (echo Docker Desktop is not running. Start it, wait for "Engine running", then double-click this file again. & pause & exit /b 1)
set "GITBASH=%ProgramFiles%\Git\git-bash.exe"
if exist "%GITBASH%" (
  start "DevOps Lab" "%GITBASH%" --cd="%~dp0." -c "export MSYS_NO_PATHCONV=1; bash lab.sh; echo; read -p 'Press Enter to close this window'"
  exit /b 0
)
echo Git for Windows (Git Bash) was not found. Install it from https://git-scm.com/download/win and try again.
pause
