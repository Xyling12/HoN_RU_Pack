<#
    HoN RU Pack — WireGuard Removal
    Stops and removes the WireGuard tunnel service and config.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "SilentlyContinue"

$tunnelName = "HoN_RU_Pack"
$svcName = "WireGuardTunnel`$$tunnelName"
$wgExe = Join-Path $env:ProgramFiles "WireGuard\wireguard.exe"
$configDir = Join-Path $DataRoot "wireguard"

# --- Step 1: Stop and remove tunnel service ---
$svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "[WireGuard] Stopping tunnel service..."
    if ($svc.Status -eq "Running") {
        Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    if (Test-Path $wgExe) {
        Write-Host "[WireGuard] Uninstalling tunnel service..."
        & $wgExe /uninstalltunnelservice $tunnelName 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    } else {
        # Fallback: remove service via sc.exe
        & sc.exe stop $svcName 2>&1 | Out-Null
        & sc.exe delete $svcName 2>&1 | Out-Null
    }
    Write-Host "[WireGuard] Tunnel service removed."
} else {
    Write-Host "[WireGuard] Tunnel service '$svcName' not found - nothing to remove."
}

# --- Step 2: Remove config files ---
if (Test-Path $configDir) {
    Remove-Item -Path $configDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[WireGuard] Config directory removed: $configDir"
}

# Also clean up from WireGuard's own data directory
$wgDataConf = Join-Path $env:ProgramFiles "WireGuard\Data\Configurations\$tunnelName.conf.dpapi"
if (Test-Path $wgDataConf) {
    Remove-Item -Path $wgDataConf -Force -ErrorAction SilentlyContinue
    Write-Host "[WireGuard] Removed config from WireGuard data directory."
}

# --- Step 3: Note about WireGuard itself ---
# We do NOT uninstall WireGuard itself — user may use it for other purposes.
# If they want to remove it completely, they can do so via Settings > Apps.

Write-Host ""
Write-Host "[WireGuard] HoN RU Pack tunnel removed."
Write-Host "[WireGuard] WireGuard application was NOT uninstalled (may be used for other purposes)."
Write-Host "[WireGuard] To fully remove WireGuard: Settings > Apps > WireGuard > Uninstall"
