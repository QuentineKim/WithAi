@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "GAME_DIR=%SCRIPT_DIR%project\src"
set "LOCAL_WIN_LOVE=%SCRIPT_DIR%..\love-11.5-win64\lovec.exe"

if exist "%LOCAL_WIN_LOVE%" (
  "%LOCAL_WIN_LOVE%" "%GAME_DIR%"
  exit /b %errorlevel%
)

where love >nul 2>nul
if %errorlevel%==0 (
  love "%GAME_DIR%"
  exit /b %errorlevel%
)

echo LOVE2D executable not found.
echo Install LOVE 11.5 or place love-11.5-win64 in the parent directory.
exit /b 1
