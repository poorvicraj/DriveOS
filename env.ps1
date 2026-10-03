# DriveOS Developer Environment Setup Script
# Loads Qt 6.6.3, MinGW 13.1.0, Ninja, CMake, and Python CAN tooling into current session PATH.

$QtBin = "D:\automotive\tools\Qt\6.6.3\mingw_64\bin"
$MinGWBin = "D:\automotive\tools\Qt\Tools\mingw1310_64\bin"
$NinjaBin = "D:\automotive\tools\ninja"
$PyScripts = "$env:LOCALAPPDATA\Programs\Python\Python313\Scripts"

$env:QT_DIR = "D:\automotive\tools\Qt\6.6.3\mingw_64"
$env:CMAKE_PREFIX_PATH = "D:\automotive\tools\Qt\6.6.3\mingw_64"
$env:TEMP = "D:\automotive\temp"
$env:TMP = "D:\automotive\temp"

$PathsToAdd = @($QtBin, $MinGWBin, $NinjaBin, $PyScripts)
foreach ($p in $PathsToAdd) {
    if ($env:PATH -notmatch [regex]::Escape($p)) {
        $env:PATH = "$p;$env:PATH"
    }
}

Write-Host "=== DriveOS Environment Initialized ===" -ForegroundColor Cyan
Write-Host "  Qt 6.6.3:   $QtBin"
Write-Host "  MinGW GCC:  $MinGWBin"
Write-Host "  Ninja:      $NinjaBin"
Write-Host "  CMake:      $(cmake --version | Select-Object -First 1)"
Write-Host "  Compiler:   $(g++ --version | Select-Object -First 1)"
Write-Host "========================================" -ForegroundColor Cyan
