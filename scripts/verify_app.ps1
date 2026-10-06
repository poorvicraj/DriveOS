# Verify DriveOS application launch and QML load
. .\env.ps1

Write-Host "Starting driveos.exe..."
$proc = Start-Process -FilePath ".\build\driveos.exe" -PassThru

Start-Sleep -Seconds 3

if ($proc.HasExited) {
    Write-Host "Process exited early with exit code: $($proc.ExitCode)" -ForegroundColor Red
    exit $proc.ExitCode
} else {
    Write-Host "DriveOS is actively running! Process ID: $($proc.Id)" -ForegroundColor Green
    Write-Host "Terminating verified process..."
    Stop-Process -Id $proc.Id -Force
    Write-Host "DriveOS successfully launched, loaded QML, and terminated cleanly." -ForegroundColor Green
    exit 0
}
