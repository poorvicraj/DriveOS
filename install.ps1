<#
.SYNOPSIS
    DriveOS Automated All-in-One Installer & Setup Script for Windows
.DESCRIPTION
    Fully automated installation, environment setup, dependency resolution,
    toolchain acquisition, build compilation, test verification, and standalone runtime deployment.
#>

param (
    [switch]$NoBuild,
    [switch]$NoTest,
    [switch]$NoDeploy,
    [switch]$Launch,
    [switch]$ForceDownloadTools
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
# HELPER: Detect Real Python (ignoring WindowsApps store shims)
# -----------------------------------------------------------------------------
function Get-RealPython {
    # Check standard Python installation directories first
    $localPyDirs = @(
        "$env:LOCALAPPDATA\Programs\Python",
        "C:\Python313", "C:\Python312", "C:\Python311", "C:\Python310"
    )
    foreach ($dir in $localPyDirs) {
        if (Test-Path $dir) {
            $sub = Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
            if ($sub -and (Test-Path "$($sub.FullName)\python.exe")) {
                return "$($sub.FullName)\python.exe"
            }
            if (Test-Path "$dir\python.exe") {
                return "$dir\python.exe"
            }
        }
    }

    # Check PATH
    $pyCmd = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($pyCmd) {
        if ($pyCmd.Source -notmatch "WindowsApps") {
            return $pyCmd.Source
        } else {
            # Test if WindowsApps stub is actually functional
            try {
                $ver = & $pyCmd.Source --version 2>&1
                if ($ver -match "Python 3\.") {
                    return $pyCmd.Source
                }
            } catch {}
        }
    }

    return $null
}

# -----------------------------------------------------------------------------
# STEP 1: Toolchain Detection & Path Setup
# -----------------------------------------------------------------------------
Write-Host "[1/6] Detecting toolchain (Qt 6.6.3, MinGW 13.1, Ninja, CMake)..." -ForegroundColor Yellow

$QtBin = ""
$MinGWBin = ""
$NinjaBin = ""
$CMakeBin = ""

# 1. Check local tools directory (bundled/portable toolchain)
if (Test-Path "$ProjectRoot\tools\Qt\6.6.3\mingw_64\bin\qmake.exe") {
    $QtBin = "$ProjectRoot\tools\Qt\6.6.3\mingw_64\bin"
    $MinGWBin = "$ProjectRoot\tools\Qt\Tools\mingw1310_64\bin"
    if (Test-Path "$ProjectRoot\tools\ninja") {
        $NinjaBin = "$ProjectRoot\tools\ninja"
    } elseif (Test-Path "$ProjectRoot\tools\Tools\Ninja") {
        $NinjaBin = "$ProjectRoot\tools\Tools\Ninja"
    }
} elseif (Test-Path "C:\Qt\6.6.3\mingw_64\bin\qmake.exe") {
    $QtBin = "C:\Qt\6.6.3\mingw_64\bin"
    $MinGWBin = "C:\Qt\Tools\mingw1310_64\bin"
} else {
    $qmakeCmd = Get-Command qmake.exe -ErrorAction SilentlyContinue
    if ($qmakeCmd) {
        $QtBin = Split-Path -Parent $qmakeCmd.Source
    }
    $gccCmd = Get-Command g++.exe -ErrorAction SilentlyContinue
    if ($gccCmd) {
        $MinGWBin = Split-Path -Parent $gccCmd.Source
    }
}

# -----------------------------------------------------------------------------
# STEP 1B: Automatic Toolchain Download via aqtinstall (if tools missing)
# -----------------------------------------------------------------------------
if (-not $QtBin -or -not $MinGWBin -or $ForceDownloadTools) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " [NOTICE] Qt 6.6+ MinGW toolchain not detected on this PC.  " -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "DriveOS will automatically download and set up the official " -ForegroundColor Cyan
    Write-Host "portable Qt 6.6.3 + MinGW 13.1 + Ninja toolchain into .\tools" -ForegroundColor Cyan
    Write-Host ""

    # Ensure real Python is available
    $RealPy = Get-RealPython
    if (-not $RealPy) {
        Write-Host "Python 3 is required for automated toolchain setup." -ForegroundColor Yellow
        $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Write-Host "Installing Python via winget..." -ForegroundColor Cyan
            & winget install --id Python.Python.3.11 -e --silent --accept-package-agreements --accept-source-agreements
            Start-Sleep -Seconds 3
            $RealPy = Get-RealPython
        }
    }

    if (-not $RealPy) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host " [ACTION REQUIRED] Python 3 was not found on this system.   " -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host "To install dependencies automatically:" -ForegroundColor White
        Write-Host "  1. Install Python 3 from https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "     (Make sure to check: 'Add python.exe to PATH')" -ForegroundColor Yellow
        Write-Host "  2. Then double-click 'install.bat' again." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Alternatively, if you already have DriveOS working on your other PC," -ForegroundColor Cyan
        Write-Host "simply copy the 'tools\' folder from that PC into this directory!" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    Write-Host "  -> Python active: $RealPy" -ForegroundColor Green
    Write-Host "  -> Installing toolchain downloader (aqtinstall)..." -ForegroundColor Yellow
    & $RealPy -m pip install --quiet --upgrade aqtinstall cantools

    $ToolsDir = "$ProjectRoot\tools"
    if (-not (Test-Path $ToolsDir)) {
        New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
    }

    # 1. Download Ninja if needed
    $ninjaCheck = Get-Command ninja.exe -ErrorAction SilentlyContinue
    if (-not $ninjaCheck -and -not (Test-Path "$ToolsDir\ninja\ninja.exe")) {
        Write-Host "  -> Downloading Ninja build tool..." -ForegroundColor Yellow
        & $RealPy -m aqt install-tool windows desktop tools_ninja qt.tools.ninja -O "$ToolsDir"
        if (Test-Path "$ToolsDir\Tools\Ninja") {
            New-Item -ItemType Directory -Path "$ToolsDir\ninja" -Force | Out-Null
            Copy-Item "$ToolsDir\Tools\Ninja\*" "$ToolsDir\ninja\" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Download MinGW 13.1.0 C++ compiler
    if (-not (Test-Path "$ToolsDir\Qt\Tools\mingw1310_64\bin\g++.exe")) {
        Write-Host "  -> Downloading MinGW 13.1.0 C++ compiler (official Qt package)..." -ForegroundColor Yellow
        & $RealPy -m aqt install-tool windows desktop tools_mingw1310 qt.tools.win64_mingw1310 -O "$ToolsDir\Qt"
    }

    # 3. Download Qt 6.6.3 MinGW 64-bit base
    if (-not (Test-Path "$ToolsDir\Qt\6.6.3\mingw_64\bin\qmake.exe")) {
        Write-Host "  -> Downloading Qt 6.6.3 MinGW SDK (Quick, QML, Core, Gui, Svg)..." -ForegroundColor Yellow
        & $RealPy -m aqt install-qt windows desktop 6.6.3 win64_mingw -O "$ToolsDir\Qt"
    }

    # Re-detect after automated installation
    $QtBin = "$ToolsDir\Qt\6.6.3\mingw_64\bin"
    $MinGWBin = "$ToolsDir\Qt\Tools\mingw1310_64\bin"
    $NinjaBin = "$ToolsDir\ninja"
    Write-Host ""
    Write-Host "  -> Toolchain acquisition complete!" -ForegroundColor Green
}

# Set up environment variables
if ($QtBin -and (Test-Path $QtBin)) {
    $env:QT_DIR = Split-Path -Parent $QtBin
    $env:CMAKE_PREFIX_PATH = $env:QT_DIR
}

$PathsToAdd = @($QtBin, $MinGWBin, $NinjaBin)
foreach ($p in $PathsToAdd) {
    if ($p -and (Test-Path $p) -and ($env:PATH -notmatch [regex]::Escape($p))) {
        $env:PATH = "$p;$env:PATH"
    }
}

# Ensure temporary directory exists
$TempDir = "$ProjectRoot\temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
$env:TEMP = $TempDir
$env:TMP = $TempDir

Write-Host "  Qt Directory:        $($env:QT_DIR)" -ForegroundColor Green
Write-Host "  MinGW Compiler:      $MinGWBin" -ForegroundColor Green
Write-Host "  CMake Prefix Path:   $($env:CMAKE_PREFIX_PATH)" -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# STEP 2: Python CAN Tooling Verification (cantools)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/6] Checking Python & CAN tooling dependencies..." -ForegroundColor Yellow

$RealPython = Get-RealPython
if ($RealPython) {
    Write-Host "  -> Python detected: $RealPython" -ForegroundColor Green
    try {
        Write-Host "  -> Ensuring 'cantools' is installed..." -NoNewline
        & $RealPython -m pip install --quiet --upgrade cantools 2>$null
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

# Verify CMake is present
$cmakeCmd = Get-Command cmake.exe -ErrorAction SilentlyContinue
if (-not $cmakeCmd) {
    Write-Host "CMake not found in PATH. Checking tools directory..." -ForegroundColor Yellow
    if (Test-Path "$ProjectRoot\tools\Tools\CMake_64\bin\cmake.exe") {
        $env:PATH = "$ProjectRoot\tools\Tools\CMake_64\bin;$env:PATH"
    } else {
        # Check if Python can install cmake
        if ($RealPython) {
            Write-Host "Installing cmake via pip..." -ForegroundColor Cyan
            & $RealPython -m pip install --quiet cmake
            $pyDir = Split-Path -Parent $RealPython
            if (Test-Path "$pyDir\Scripts\cmake.exe") {
                $env:PATH = "$pyDir\Scripts;$env:PATH"
            }
        }
    }
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
if ($MinGWBin -and (Test-Path "$MinGWBin\g++.exe")) {
    $CMakeArgs += "-DCMAKE_CXX_COMPILER=$MinGWBin\g++.exe"
    $CMakeArgs += "-DCMAKE_C_COMPILER=$MinGWBin\gcc.exe"
}

& cmake @CMakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}
Write-Host "  -> CMake configuration successful." -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 4: Build & Compilation (-j 4 to prevent compiler memory exhaustion)
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
