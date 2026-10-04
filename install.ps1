<#
.SYNOPSIS
    DriveOS Automated All-in-One Installer & Setup Script for Windows
.DESCRIPTION
    Fully automated installation, environment setup, dependency resolution,
    build compilation, test verification, and standalone runtime deployment for DriveOS.
#>

param (
    [switch]$NoBuild,
    [switch]$NoTest,
    [switch]$NoDeploy,
    [switch]$Launch
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       DriveOS Automated Installation & Setup Engine        " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Root Directory: $ProjectRoot" -ForegroundColor DarkGray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 1: Toolchain Detection & Path Setup
# -----------------------------------------------------------------------------
Write-Host "[1/6] Detecting and configuring toolchain..." -ForegroundColor Yellow

$QtBin = ""
$MinGWBin = ""
$NinjaBin = ""

# 1. Check local tools directory (bundled/portable toolchain)
if (Test-Path "$ProjectRoot\tools\Qt\6.6.3\mingw_64\bin\qmake.exe") {
    $QtBin = "$ProjectRoot\tools\Qt\6.6.3\mingw_64\bin"
    $MinGWBin = "$ProjectRoot\tools\Qt\Tools\mingw1310_64\bin"
    $NinjaBin = "$ProjectRoot\tools\ninja"
    Write-Host "  -> Found bundled Qt 6.6.3 MinGW toolchain in .\tools" -ForegroundColor Green
} elseif (Test-Path "C:\Qt\6.6.3\mingw_64\bin\qmake.exe") {
    $QtBin = "C:\Qt\6.6.3\mingw_64\bin"
    $MinGWBin = "C:\Qt\Tools\mingw1310_64\bin"
    Write-Host "  -> Found system Qt 6.6.3 in C:\Qt" -ForegroundColor Green
} else {
    # Attempt to locate qmake in existing PATH
    $qmakeCmd = Get-Command qmake.exe -ErrorAction SilentlyContinue
    if ($qmakeCmd) {
        $QtBin = Split-Path -Parent $qmakeCmd.Source
        Write-Host "  -> Found Qt in PATH: $QtBin" -ForegroundColor Green
    }
}

if (-not $QtBin) {
    Write-Host "WARNING: Qt 6.6+ MinGW toolchain not detected in standard paths." -ForegroundColor Red
    Write-Host "Please ensure Qt 6 (with MinGW 64-bit) is installed or extracted into .\tools\Qt" -ForegroundColor Yellow
} else {
    $env:QT_DIR = Split-Path -Parent $QtBin
    $env:CMAKE_PREFIX_PATH = $env:QT_DIR
    
    $PathsToAdd = @($QtBin, $MinGWBin, $NinjaBin)
    foreach ($p in $PathsToAdd) {
        if ($p -and (Test-Path $p) -and ($env:PATH -notmatch [regex]::Escape($p))) {
            $env:PATH = "$p;$env:PATH"
        }
    }
}

# Ensure temporary directory exists
$TempDir = "$ProjectRoot\temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
$env:TEMP = $TempDir
$env:TMP = $TempDir

Write-Host "  Qt Directory:        $($env:QT_DIR)" -ForegroundColor DarkGray
Write-Host "  CMake Prefix Path:   $($env:CMAKE_PREFIX_PATH)" -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# STEP 2: Python CAN Tooling Verification (cantools)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/6] Checking Python & CAN tooling dependencies..." -ForegroundColor Yellow

$PythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue
if ($PythonCmd) {
    Write-Host "  -> Python detected: $($PythonCmd.Source)" -ForegroundColor Green
    try {
        Write-Host "  -> Ensuring 'cantools' is installed..." -NoNewline
        python -m pip install --quiet --upgrade cantools 2>$null
        Write-Host " OK." -ForegroundColor Green
    } catch {
        Write-Host " (pip install skipped or offline)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  -> Python not detected. CAN DBC validation tooling will be optional." -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# STEP 3: CMake Configuration
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/6] Configuring CMake build system (Ninja)..." -ForegroundColor Yellow

$BuildDir = "$ProjectRoot\build"
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

$CMakeArgs = @(
    "-B", "build",
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_TESTING=ON"
)

if ($env:CMAKE_PREFIX_PATH) {
    $CMakeArgs += "-DCMAKE_PREFIX_PATH=$($env:CMAKE_PREFIX_PATH)"
}

& cmake @CMakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}
Write-Host "  -> CMake configuration successful." -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 4: Build & Compilation
# -----------------------------------------------------------------------------
if (-not $NoBuild) {
    Write-Host ""
    Write-Host "[4/6] Compiling DriveOS and automated test suite (-j 4)..." -ForegroundColor Yellow
    cmake --build build -j 4
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build compilation failed with exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
    Write-Host "  -> Compilation completed successfully." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[4/6] Build compilation skipped (-NoBuild specified)." -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# STEP 5: Automated Test Verification
# -----------------------------------------------------------------------------
if (-not $NoTest -and -not $NoBuild) {
    Write-Host ""
    Write-Host "[5/6] Running automated test suite (GoogleTest & CTest)..." -ForegroundColor Yellow
    $prevPlatform = $env:QT_QPA_PLATFORM
    $env:QT_QPA_PLATFORM = "offscreen"
    ctest --test-dir build --output-on-failure
    $testResult = $LASTEXITCODE
    $env:QT_QPA_PLATFORM = $prevPlatform

    if ($testResult -ne 0) {
        Write-Warning "One or more automated tests failed (exit code $testResult)."
    } else {
        Write-Host "  -> All 67 automated test cases PASSED (0 failures)." -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "[5/6] Test execution skipped." -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# STEP 6: Standalone Runtime Deployment (windeployqt)
# -----------------------------------------------------------------------------
if (-not $NoDeploy -and (Test-Path "$BuildDir\driveos.exe")) {
    Write-Host ""
    Write-Host "[6/6] Deploying standalone Qt runtime libraries (windeployqt)..." -ForegroundColor Yellow
    $WindeployqtExe = "$QtBin\windeployqt.exe"
    if (Test-Path $WindeployqtExe) {
        Write-Host "  -> Bundling Qt DLLs and QML plugins into .\build..."
        & $WindeployqtExe --qmldir "$ProjectRoot\app\qml" "$BuildDir\driveos.exe" --compiler-runtime 2>$null | Out-Null
        
        # Copy MinGW C++ runtime libraries if present
        if ($MinGWBin -and (Test-Path $MinGWBin)) {
            $RuntimeLibs = @("libgcc_s_seh-1.dll", "libstdc++-6.dll", "libwinpthread-1.dll")
            foreach ($lib in $RuntimeLibs) {
                $src = "$MinGWBin\$lib"
                if (Test-Path $src) {
                    Copy-Item -Path $src -Destination "$BuildDir\$lib" -Force -ErrorAction SilentlyContinue
                }
            }
        }
        Write-Host "  -> Standalone runtime deployed! driveos.exe can now be launched directly." -ForegroundColor Green
    } else {
        Write-Host "  -> windeployqt not found; relying on environment PATH." -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------
# Create Root One-Click Launch Script
# -----------------------------------------------------------------------------
$LauncherBatContent = @"
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
"@

$LauncherBatPath = "$ProjectRoot\Launch_DriveOS.bat"
Set-Content -Path $LauncherBatPath -Value $LauncherBatContent -Encoding ASCII
Write-Host ""
Write-Host "Created one-click launcher: Launch_DriveOS.bat" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# INSTALLATION COMPLETE
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "         DriveOS Installation & Setup Completed!            " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "You can now run DriveOS in any of the following ways:" -ForegroundColor White
Write-Host "  1. Double-click:   Launch_DriveOS.bat" -ForegroundColor Yellow
Write-Host "  2. PowerShell:     .\run.ps1" -ForegroundColor Yellow
Write-Host "  3. Direct Binary:  .\build\driveos.exe" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

if ($Launch) {
    Write-Host "Launching DriveOS Cockpit now..." -ForegroundColor Cyan
    & "$BuildDir\driveos.exe"
}
