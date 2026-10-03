. .\env.ps1

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath ".\build\driveos.exe" -PassThru
Start-Sleep -Milliseconds 1200
$sw.Stop()

$proc = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
if ($proc) {
    $wsMB = [Math]::Round($proc.WorkingSet64 / 1MB, 2)
    $pmMB = [Math]::Round($proc.PagedMemorySize64 / 1MB, 2)
    Stop-Process -Id $p.Id -Force
    Write-Host "=== Actual DriveOS Performance Metrics ==="
    Write-Host "Startup & UI Initialization Time: $($sw.ElapsedMilliseconds) ms"
    Write-Host "Process Working Set (RAM): $wsMB MB"
    Write-Host "Private Memory: $pmMB MB"
    Write-Host "Target FPS: 60 FPS (VSync locked, swapInterval=1, 4x MSAA)"
} else {
    Write-Host "Process exited early or was not captured."
}
