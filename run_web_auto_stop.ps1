param(
    [string]$Device = "edge"
)

$browserProcessName = if ($Device -eq "chrome") { "chrome.exe" } else { "msedge.exe" }
$browserPattern = if ($Device -eq "chrome") { "flutter_tools_chrome_device" } else { "flutter_tools_edge_device" }

$flutterArgs = @("run", "-d", $Device)
$flutterProcess = Start-Process -FilePath "flutter" -ArgumentList $flutterArgs -PassThru -WindowStyle Normal

Write-Host "Started Flutter web. Waiting for $browserProcessName window from Flutter..."

$seenBrowserWindow = $false

try {
    while (-not $flutterProcess.HasExited) {
        Start-Sleep -Seconds 2

        $browserProcesses = Get-CimInstance Win32_Process -Filter "name = '$browserProcessName'" |
            Where-Object { $_.CommandLine -like "*$browserPattern*" }

        if ($browserProcesses) {
            $seenBrowserWindow = $true
            continue
        }

        if ($seenBrowserWindow) {
            Write-Host "Flutter browser window was closed. Stopping Flutter frontend..."
            Stop-Process -Id $flutterProcess.Id -Force -ErrorAction SilentlyContinue
            break
        }
    }
}
finally {
    if (-not $flutterProcess.HasExited) {
        Stop-Process -Id $flutterProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
