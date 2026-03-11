<#
    HoN RU Pack — DNS Bypass Setup
    Sets DNS servers to Cloudflare + Google to bypass RKN blocks.
    Backs up current DNS settings before making changes.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "Stop"

$backupPath = Join-Path $DataRoot "dns_backup.json"

# Get active network adapters with IP connectivity
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Loopback" }
if (-not $adapters) {
    Write-Host "[DNS] No active network adapters found. Skipping DNS setup."
    return
}

$backupEntries = @()

foreach ($adapter in $adapters) {
    $ifIndex = $adapter.InterfaceIndex
    $ifName  = $adapter.Name

    # Read current DNS servers for this adapter
    $currentDns = Get-DnsClientServerAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $currentServers = @()
    if ($currentDns -and $currentDns.ServerAddresses) {
        $currentServers = @($currentDns.ServerAddresses)
    }

    $backupEntries += @{
        InterfaceIndex = $ifIndex
        InterfaceName  = $ifName
        OriginalDNS    = $currentServers
    }

    # Set DNS to Cloudflare (1.1.1.1) + Google (8.8.8.8)
    try {
        Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @("1.1.1.1", "8.8.8.8")
        Write-Host "[DNS] Adapter '$ifName': DNS set to 1.1.1.1, 8.8.8.8"
    }
    catch {
        Write-Host "[DNS] WARNING: Failed to set DNS for adapter '$ifName': $_"
    }
}

# Save backup
New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null
$backupEntries | ConvertTo-Json -Depth 3 | Set-Content -Path $backupPath -Encoding UTF8
Write-Host "[DNS] Backup saved to: $backupPath"

# Flush DNS cache
try {
    & ipconfig /flushdns | Out-Null
    Write-Host "[DNS] DNS cache flushed."
}
catch {
    Write-Host "[DNS] WARNING: Failed to flush DNS cache."
}

Write-Host "[DNS] DNS bypass setup completed."
