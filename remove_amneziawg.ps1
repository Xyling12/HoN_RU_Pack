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

# --- Stop and disable manager services ---
foreach ($mgr in @("AmneziaWGManager", "AmneziaVPN-service")) {
    $mgrSvc = Get-Service -Name $mgr -ErrorAction SilentlyContinue
    if ($mgrSvc) {
        Write-Host "[AmneziaWG] Stopping $mgr..."
        Stop-Service -Name $mgr -Force -ErrorAction SilentlyContinue
    }
}
Stop-Process -Name "amneziawg" -Force -ErrorAction SilentlyContinue

# --- Uninstall AmneziaWG MSI ---
$awgInstallDir = Join-Path $env:ProgramFiles "AmneziaWG"
$uninstalled = $false
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($regPath in $uninstallPaths) {
    Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*AmneziaWG*" } |
        ForEach-Object {
            $productCode = $_.PSChildName
            Write-Host "[AmneziaWG] Uninstalling MSI ($productCode)..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x `"$productCode`" /quiet /norestart" -Wait -ErrorAction SilentlyContinue
            $uninstalled = $true
        }
}
if (-not $uninstalled) {
    Write-Host "[AmneziaWG] MSI entry not found in registry, cleaning manually..."
}

# Remove leftover program files
if (Test-Path $awgInstallDir) {
    Remove-Item -Path $awgInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[AmneziaWG] Removed: $awgInstallDir"
}

# --- Clean autorun and shortcuts ---
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AmneziaWG" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AmneziaWG" -ErrorAction SilentlyContinue
foreach ($menuRoot in @(
    (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"),
    (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs")
)) {
    Get-ChildItem -Path $menuRoot -Filter "*mnezi*" -Recurse -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($desktop in @(
    [Environment]::GetFolderPath("Desktop"),
    [Environment]::GetFolderPath("CommonDesktopDirectory")
)) {
    Get-ChildItem -Path $desktop -Filter "*mnezi*" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
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
Write-Host "[AmneziaWG] Full removal complete."
Write-Host "[AmneziaWG] AmneziaWG application, tunnel, and all configs have been removed."
