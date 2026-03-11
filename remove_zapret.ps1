<#
    HoN RU Pack — Zapret Removal
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
    Write-Host "[Zapret] Removing service..."
    & sc.exe delete $svcName 2>&1 | Out-Null
} else {
    Write-Host "[Zapret] Service '$svcName' not found - nothing to remove."
}

# Kill any running winws.exe
& taskkill /IM winws.exe /F 2>&1 | Out-Null

# Clean up WinDivert
& net stop "WinDivert" 2>&1 | Out-Null
& sc.exe delete "WinDivert" 2>&1 | Out-Null
& net stop "WinDivert14" 2>&1 | Out-Null
& sc.exe delete "WinDivert14" 2>&1 | Out-Null

# Clean up hosts file entries
$hostsFile = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
if (Test-Path $hostsFile) {
    try {
        $content = [System.IO.File]::ReadAllText($hostsFile)
        $pattern = '(?s)\r?\n?\r?\n?# === Zapret DNS bypass \(HoN RU Pack\) ===.*?# === End Zapret DNS bypass ===\r?\n?'
        $cleaned = [regex]::Replace($content, $pattern, '')
        if ($cleaned -ne $content) {
            [System.IO.File]::WriteAllText($hostsFile, $cleaned)
            Write-Host "[Zapret] Hosts file cleaned up."
        }
    } catch {
        Write-Host "[Zapret] WARNING: Could not clean hosts file: $_"
    }
}

# Remove Zapret files
if (Test-Path $zapretRoot) {
    Remove-Item -Path $zapretRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[Zapret] Files removed: $zapretRoot"
}

Write-Host "[Zapret] Zapret removed."
