@echo off
setlocal
cd /d "%~dp0"
if exist "build\driveos.exe" (
    start "" "build\driveos.exe"
) else (
    echo [ERROR] driveos.exe not found in build directory.
    echo Please run install.bat first to build the application.
    pause
)
