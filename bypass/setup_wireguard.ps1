<#
    HoN RU Pack — WireGuard Client Setup (Windows)
    Downloads WireGuard, installs silently, creates split-tunnel config for HoN.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "Stop"

$tunnelName = "HoN_RU_Pack"
$wgInstallDir = Join-Path $env:ProgramFiles "WireGuard"
$wgExe = Join-Path $wgInstallDir "wireguard.exe"
$configDir = Join-Path $DataRoot "wireguard"
$configFile = Join-Path $configDir "$tunnelName.conf"

# --- HoN Split-Tunnel Config ---
# IMPORTANT: These values must be replaced with actual keys from server setup.
# The build script or server API should inject them.
$wgConfig = @"
[Interface]
PrivateKey = qJiNn5LQA3xblyt67bzvhMxB+7bgN5pkvRBNONj5ikc=
Address = 10.66.66.2/32
DNS = 1.1.1.1
MTU = 1280

[Peer]
PublicKey = Bs5Fgzkk2LjrIQZ+0RXjdbfXYPgtvZHqpWZeKMeYbww=
Endpoint = 94.103.15.45:51820
AllowedIPs = 104.21.0.0/16, 172.67.0.0/16, 104.26.14.0/24, 104.26.15.0/24, 91.98.177.0/24, 157.180.81.53/32, 45.154.6.104/32, 185.237.185.232/32
PersistentKeepalive = 25
"@

# --- Step 1: Download WireGuard MSI ---
$msiUrl = "https://download.wireguard.com/windows-client/wireguard-installer.exe"
$msiPath = Join-Path $env:TEMP "wireguard-installer.exe"

if (-not (Test-Path $wgExe)) {
    Write-Host "[WireGuard] Downloading WireGuard installer..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing -TimeoutSec 120
    } catch {
        Write-Host "[WireGuard] ERROR: Download failed: $_"
        Write-Host "[WireGuard] Download manually from https://www.wireguard.com/install/"
        return
    }

    # --- Step 2: Silent install ---
    Write-Host "[WireGuard] Installing WireGuard..."
    Start-Process -FilePath $msiPath -ArgumentList "/S" -Wait
    if (-not (Test-Path $wgExe)) {
        # Try alternate install path
        $altExe = Join-Path ${env:ProgramFiles(x86)} "WireGuard\wireguard.exe"
        if (Test-Path $altExe) {
            $wgExe = $altExe
            $wgInstallDir = Split-Path $altExe -Parent
        } else {
            Write-Host "[WireGuard] ERROR: Installation failed. WireGuard.exe not found."
            return
        }
    }
    Write-Host "[WireGuard] WireGuard installed to: $wgInstallDir"

    # Kill WireGuard GUI that auto-starts after install — tunnel service works without it
    Start-Sleep -Seconds 1
    Stop-Process -Name "wireguard" -Force -ErrorAction SilentlyContinue

    # Remove WireGuard GUI auto-start from registry (user doesn't need to see it)
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WireGuard" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WireGuard" -ErrorAction SilentlyContinue

    # Cleanup installer
    Remove-Item -Path $msiPath -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "[WireGuard] WireGuard already installed at: $wgExe"
}

# --- Step 3: Write config file ---
Write-Host "[WireGuard] Writing tunnel config..."
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
Set-Content -Path $configFile -Value $wgConfig -Encoding ASCII
Write-Host "[WireGuard] Config saved to: $configFile"

# --- Step 4: Install and start the tunnel service ---
Write-Host "[WireGuard] Installing tunnel service..."

# Remove existing tunnel if present
$svcName = "WireGuardTunnel`$$tunnelName"
$existingSvc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
if ($existingSvc) {
    Write-Host "[WireGuard] Removing existing tunnel..."
    & $wgExe /uninstalltunnelservice $tunnelName 2>&1 | Out-Null
    Start-Sleep -Seconds 2
}

# Install tunnel service
try {
    & $wgExe /installtunnelservice $configFile
    Write-Host "[WireGuard] Tunnel service installed."
} catch {
    Write-Host "[WireGuard] WARNING: Could not install tunnel service via CLI."
    Write-Host "[WireGuard] Trying alternative method..."
    
    # Copy config to WireGuard's own config directory and let it manage
    $wgDataDir = Join-Path $env:ProgramFiles "WireGuard\Data\Configurations"
    if (Test-Path (Split-Path $wgDataDir -Parent)) {
        New-Item -ItemType Directory -Path $wgDataDir -Force | Out-Null
        Copy-Item -Path $configFile -Destination (Join-Path $wgDataDir "$tunnelName.conf.dpapi") -Force
        Write-Host "[WireGuard] Config copied to WireGuard data directory."
    }
}

# Wait for service to register, then start it
Start-Sleep -Seconds 2
$svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue

if ($svc) {
    # Explicitly start the tunnel service
    if ($svc.Status -ne "Running") {
        Write-Host "[WireGuard] Starting tunnel service..."
        try {
            Start-Service -Name $svcName -ErrorAction Stop
        } catch {
            Write-Host "[WireGuard] Retrying start in 3 seconds..."
            Start-Sleep -Seconds 3
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }
    
    # Verify it's running
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "[WireGuard] Tunnel is RUNNING!"
        Write-Host "[WireGuard] Split-tunnel active: only HoN traffic goes through VPN."
    } else {
        Write-Host "[WireGuard] WARNING: Tunnel service installed but not running (Status: $($svc.Status))."
        Write-Host "[WireGuard] Try rebooting or run: net start WireGuardTunnel`$$tunnelName"
    }
} else {
    Write-Host "[WireGuard] WARNING: Tunnel service not found after installation."
    Write-Host "[WireGuard] Try: `"$wgExe`" /installtunnelservice `"$configFile`""
}

Write-Host ""
Write-Host "[WireGuard] Setup complete!"
Write-Host "[WireGuard] Tunnel name: $tunnelName"
Write-Host "[WireGuard] Config: $configFile"
Write-Host "[WireGuard] Only HoN traffic is routed through VPN (split-tunnel)."
