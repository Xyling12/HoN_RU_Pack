<#
    HoN RU Pack — AmneziaWG Removal
    Stops and removes the AmneziaWG tunnel service and config.
    Also cleans up legacy WireGuard tunnel if present.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "SilentlyContinue"

$tunnelName = "HoN_RU_Pack"

# --- Remove AmneziaWG tunnel ---
$awgSvcName = "AmneziaWGTunnel`$$tunnelName"
$awgExe = Join-Path $env:ProgramFiles "AmneziaWG\amneziawg.exe"
$awgConfigDir = Join-Path $DataRoot "amneziawg"

$svc = Get-Service -Name $awgSvcName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "[AmneziaWG] Stopping tunnel service..."
    if ($svc.Status -eq "Running") {
        Stop-Service -Name $awgSvcName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    if (Test-Path $awgExe) {
        Write-Host "[AmneziaWG] Uninstalling tunnel service..."
        & $awgExe /uninstalltunnelservice $tunnelName 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    } else {
        & sc.exe stop $awgSvcName 2>&1 | Out-Null
        & sc.exe delete $awgSvcName 2>&1 | Out-Null
    }
    Write-Host "[AmneziaWG] Tunnel service removed."
} else {
    Write-Host "[AmneziaWG] Tunnel service not found - nothing to remove."
}

if (Test-Path $awgConfigDir) {
    Remove-Item -Path $awgConfigDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[AmneziaWG] Config directory removed: $awgConfigDir"
}

$awgDataConf = Join-Path $env:ProgramFiles "AmneziaWG\Data\Configurations\$tunnelName.conf.dpapi"
if (Test-Path $awgDataConf) {
    Remove-Item -Path $awgDataConf -Force -ErrorAction SilentlyContinue
    Write-Host "[AmneziaWG] Removed config from AmneziaWG data directory."
}

# --- Also clean up legacy WireGuard tunnel if still present ---
$wgSvcName = "WireGuardTunnel`$$tunnelName"
$wgExe = Join-Path $env:ProgramFiles "WireGuard\wireguard.exe"
$wgConfigDir = Join-Path $DataRoot "wireguard"

$wgSvc = Get-Service -Name $wgSvcName -ErrorAction SilentlyContinue
if ($wgSvc) {
    Write-Host "[WireGuard] Cleaning up legacy WireGuard tunnel..."
    if ($wgSvc.Status -eq "Running") {
        Stop-Service -Name $wgSvcName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    if (Test-Path $wgExe) {
        & $wgExe /uninstalltunnelservice $tunnelName 2>&1 | Out-Null
    } else {
        & sc.exe stop $wgSvcName 2>&1 | Out-Null
        & sc.exe delete $wgSvcName 2>&1 | Out-Null
    }
    Write-Host "[WireGuard] Legacy tunnel removed."
}
if (Test-Path $wgConfigDir) {
    Remove-Item -Path $wgConfigDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "[AmneziaWG] HoN RU Pack tunnel removed."
Write-Host "[AmneziaWG] AmneziaWG application was NOT uninstalled (may be used for other purposes)."
Write-Host "[AmneziaWG] To fully remove: Settings > Apps > AmneziaWG > Uninstall"
