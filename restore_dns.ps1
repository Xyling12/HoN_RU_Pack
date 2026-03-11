<#
    HoN RU Pack — DNS Restore
    Restores DNS settings from backup created by setup_dns_bypass.ps1.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "Stop"

$backupPath = Join-Path $DataRoot "dns_backup.json"

if (-not (Test-Path $backupPath)) {
    Write-Host "[DNS] No DNS backup found at: $backupPath - nothing to restore."
    return
}

$backupEntries = Get-Content -Path $backupPath -Raw | ConvertFrom-Json

foreach ($entry in $backupEntries) {
    $ifIndex = $entry.InterfaceIndex
    $ifName  = $entry.InterfaceName
    $origDns = @($entry.OriginalDNS)

    # Check if adapter still exists
    $adapter = Get-NetAdapter -InterfaceIndex $ifIndex -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-Host "[DNS] Adapter '$ifName' (index $ifIndex) no longer exists. Skipping."
        continue
    }

    try {
        if ($origDns.Count -eq 0) {
            # Original was DHCP (no manual DNS)
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ResetServerAddresses
            Write-Host "[DNS] Adapter '$ifName': DNS reset to DHCP (automatic)."
        }
        else {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $origDns
            Write-Host "[DNS] Adapter '$ifName': DNS restored to $($origDns -join ', ')."
        }
    }
    catch {
        Write-Host "[DNS] WARNING: Failed to restore DNS for adapter '$ifName': $_"
    }
}

# Remove backup file
Remove-Item -Path $backupPath -Force -ErrorAction SilentlyContinue
Write-Host "[DNS] Backup file removed."

# Flush DNS cache
try {
    & ipconfig /flushdns | Out-Null
    Write-Host "[DNS] DNS cache flushed."
}
catch {
    Write-Host "[DNS] WARNING: Failed to flush DNS cache."
}

Write-Host "[DNS] DNS settings restored."
