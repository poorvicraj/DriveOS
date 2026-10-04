@echo off
setlocal EnableDelayedExpansion

title DriveOS Installation ^& Setup Engine
color 0B

echo ============================================================
echo        DriveOS Automated One-Click Installation
echo ============================================================
echo.
echo Initializing PowerShell installation engine...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo ============================================================
    echo [ERROR] Installation failed with exit code %ERRORLEVEL%.
    echo ============================================================
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
pause
exit /b 0
