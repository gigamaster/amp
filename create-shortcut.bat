@echo off
setlocal

:: ---------------------------------------------------------
:: Shortcut Creator for AMP-MANAGER
:: Creates:
::   1) Desktop shortcut
::   2) Project-local shortcut: \amp\amp-manager.lnk
::
:: Author: Nuno Luciano
:: Date: 2026-02-25
:: Version: 1.11.3
:: LICENSE: MIT
:: ---------------------------------------------------------

:: Detect project folder (where this script is located)
set "PROJECT_PATH=%~dp0"
set "PROJECT_PATH=%PROJECT_PATH:~0,-1%"

:: Paths
set "TARGET=%PROJECT_PATH%\config\AMP-MANAGER.bat"
set "ICON=%PROJECT_PATH%\favicon\favicon.ico"
set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT_DESKTOP=%DESKTOP%\AMP Manager.lnk"
set "SHORTCUT_LOCAL=%PROJECT_PATH%\amp-manager.lnk"

:: Create amp folder if missing
::if not exist "%PROJECT_PATH%\amp" mkdir "%PROJECT_PATH%\amp"

echo Creating shortcuts...

:: Create Desktop shortcut
powershell -NoProfile -Command ^
  "$s=(New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT_DESKTOP%');" ^
  "$s.TargetPath='%TARGET%';" ^
  "$s.IconLocation='%ICON%';" ^
  "$s.WorkingDirectory='%PROJECT_PATH%';" ^
  "$s.Save()"

:: Create local project shortcut
powershell -NoProfile -Command ^
  "$s=(New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT_LOCAL%');" ^
  "$s.TargetPath='%TARGET%';" ^
  "$s.IconLocation='%ICON%';" ^
  "$s.WorkingDirectory='%PROJECT_PATH%';" ^
  "$s.Save()"

echo Shortcuts created successfully.
pause
