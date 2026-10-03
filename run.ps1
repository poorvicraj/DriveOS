<#
.SYNOPSIS
    DriveOS Cockpit Launcher
.DESCRIPTION
    Activates Qt6/MinGW toolchain environment and launches driveos.exe
#>
param (
    [switch]$BuildFirst
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Load toolchain environment
. .\env.ps1

if ($BuildFirst) {
    Write-Host "Building DriveOS..." -ForegroundColor Yellow
    cmake --build build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed. Aborting launch."
        exit $LASTEXITCODE
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Launching DriveOS Automotive Cockpit    " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Resolution: 1920x720 (Automotive Wide Display)" -ForegroundColor DarkGray
Write-Host "Press Ctrl+C or close window to exit." -ForegroundColor DarkGray

& ".\build\driveos.exe"
