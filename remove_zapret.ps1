<#
    HoN RU Pack - Zapret Removal
    Stops and removes the Zapret service and cleans up WinDivert.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "SilentlyContinue"

$zapretRoot = Join-Path $DataRoot "zapret"
$svcName = "zapret"

# Stop and delete zapret service
& sc.exe query $svcName 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[Zapret] Stopping service..."
    & net stop $svcName 2>&1 | Out-Null
    Start-Sleep -Milliseconds 500
    Write-Host "[Zapret] Removing service..."
    & sc.exe delete $svcName 2>&1 | Out-Null
} else {
    Write-Host "[Zapret] Service '$svcName' not found - nothing to remove."
}

# Kill winws.exe and all related processes
Write-Host "[Zapret] Killing related processes..."
foreach ($procName in @("winws", "winws.exe", "cygwin1")) {
    & taskkill /IM "$procName" /F 2>&1 | Out-Null
}

# Kill any process using files from zapret folder
if (Test-Path $zapretRoot) {
    $zapretPath = (Resolve-Path $zapretRoot).Path.ToLower()
    Get-Process | Where-Object {
        try {
            $_.Path -and $_.Path.ToLower().StartsWith($zapretPath)
        } catch { $false }
    } | ForEach-Object {
        Write-Host "[Zapret] Killing process: $($_.ProcessName) (PID $($_.Id))"
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}

# Clean up WinDivert services and drivers
& net stop "WinDivert" 2>&1 | Out-Null
& sc.exe delete "WinDivert" 2>&1 | Out-Null
& net stop "WinDivert14" 2>&1 | Out-Null
& sc.exe delete "WinDivert14" 2>&1 | Out-Null

# Wait for file locks to release after killing everything
Write-Host "[Zapret] Waiting for file locks to release..."
Start-Sleep -Seconds 3

# Clean up hosts file entries
$hostsFile = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
if (Test-Path $hostsFile) {
    try {
        $content = [System.IO.File]::ReadAllText($hostsFile, [System.Text.Encoding]::UTF8)
        $pattern = '(?s)\r?\n?\r?\n?# === Zapret DNS bypass \(HoN RU Pack\) ===.*?# === End Zapret DNS bypass ===\r?\n?'
        $cleaned = [regex]::Replace($content, $pattern, '')
        if ($cleaned -ne $content) {
            [System.IO.File]::WriteAllText($hostsFile, $cleaned, [System.Text.Encoding]::UTF8)
            Write-Host "[Zapret] Hosts file cleaned up."
        }
    } catch {
        Write-Host "[Zapret] WARNING: Could not clean hosts file (may need admin rights)."
    }
}

# Remove Zapret files with retry
if (Test-Path $zapretRoot) {
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Remove-Item -Path $zapretRoot -Recurse -Force -ErrorAction Stop
            Write-Host "[Zapret] Files removed: $zapretRoot"
            break
        } catch {
            if ($attempt -lt 3) {
                Write-Host "[Zapret] Retry $attempt/3 - files still locked..."
                Start-Sleep -Seconds 2
            } else {
                Write-Host "[Zapret] Removing individual files..."
                Get-ChildItem -Path $zapretRoot -Recurse -Force -ErrorAction SilentlyContinue |
                    Sort-Object -Property FullName -Descending |
                    ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue }
                Remove-Item -Path $zapretRoot -Force -ErrorAction SilentlyContinue
                if (Test-Path $zapretRoot) {
                    Write-Host "[Zapret] Some locked files remain - will be cleaned after reboot."
                } else {
                    Write-Host "[Zapret] Files removed: $zapretRoot"
                }
            }
        }
    }
}

Write-Host "[Zapret] Zapret removed."
