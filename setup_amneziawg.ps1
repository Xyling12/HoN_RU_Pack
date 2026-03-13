<#
    HoN RU Pack — AmneziaWG Client Setup (Windows)
    Downloads AmneziaWG client, installs silently, creates split-tunnel config for HoN.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack"),
    [switch]$RouteHoN,
    [switch]$RouteYouTube,
    [switch]$RouteDiscord
)

$ErrorActionPreference = "Stop"

$tunnelName = "HoN_RU_Pack"
$awgInstallDir = Join-Path $env:ProgramFiles "AmneziaWG"
$awgExe = Join-Path $awgInstallDir "amneziawg.exe"
$configDir = Join-Path $DataRoot "amneziawg"
$configFile = Join-Path $configDir "$tunnelName.conf"

# --- Build AllowedIPs dynamically based on service selection ---
$allowedIPs = @()

if ($RouteHoN) {
    # HoN game servers (Cloudflare + direct)
    $allowedIPs += @(
        "104.21.0.0/16", "172.67.0.0/16", "104.26.14.0/24", "104.26.15.0/24",
        "91.98.177.0/24", "157.180.81.53/32", "45.154.6.104/32", "185.237.185.232/32"
    )
}
if ($RouteYouTube) {
    # Google/YouTube CDN ranges
    $allowedIPs += @(
        "142.250.0.0/15", "172.217.0.0/16", "216.58.0.0/16",
        "74.125.0.0/16", "173.194.0.0/16", "209.85.128.0/17",
        "64.233.160.0/19", "108.177.0.0/17", "35.190.0.0/16", "34.0.0.0/8"
    )
}
if ($RouteDiscord) {
    # Discord IP ranges
    $allowedIPs += @(
        "66.22.192.0/20", "162.159.0.0/16"
    )
}

if ($allowedIPs.Count -eq 0) {
    Write-Host "[Bypass] No services selected, skipping bypass setup."
    return
}

$allowedIPsStr = $allowedIPs -join ", "

# --- HoN Split-Tunnel Config with obfuscation ---
$awgConfig = @"
[Interface]
PrivateKey = wB6yoJjq1DcpetmqaWe5JLpNIKlKS3FwhznN9xTqhEs=
Address = 10.66.66.2/32
DNS = 1.1.1.1
MTU = 1400
Jc = 4
Jmin = 50
Jmax = 1000
S1 = 68
S2 = 84
H1 = 981756423
H2 = 725841693
H3 = 412685937
H4 = 158973264

[Peer]
PublicKey = DJt5YKkQ2EozLk+VpR2uPQUCD5qL+zFgVwFRASRmqzk=
PresharedKey = 86Bx0jRcClChx/jV8ECjwNQEy0vIq+oCItx8jk00PMI=
Endpoint = 94.103.15.45:51820
AllowedIPs = $allowedIPsStr
PersistentKeepalive = 25
"@

# --- Step 1: Download AmneziaWG MSI ---
$msiUrl = "https://github.com/amnezia-vpn/amneziawg-windows-client/releases/download/2.0.0/amneziawg-amd64-2.0.0.msi"
$msiPath = Join-Path $env:TEMP "amneziawg-amd64.msi"

if (-not (Test-Path $awgExe)) {
    Write-Host "[AmneziaWG] Downloading AmneziaWG installer..."
    $downloaded = $false
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing -TimeoutSec 120
        if ((Get-Item $msiPath).Length -gt 100000) { $downloaded = $true }
    } catch {}

    # Fallback: download from VPS (in case GitHub is blocked by DPI)
    if (-not $downloaded) {
        Write-Host "[AmneziaWG] GitHub blocked, trying VPS mirror..."
        try {
            Invoke-WebRequest -Uri "http://94.103.15.45:8080/amneziawg-amd64.msi" -OutFile $msiPath -UseBasicParsing -TimeoutSec 120
            if ((Get-Item $msiPath).Length -gt 100000) { $downloaded = $true }
        } catch {}
    }

    if (-not $downloaded) {
        Write-Host "[AmneziaWG] ERROR: Download failed."
        Write-Host "[AmneziaWG] Download manually from https://amnezia.org/en/downloads"
        return
    }

    # --- Step 2: Silent MSI install ---
    Write-Host "[AmneziaWG] Installing AmneziaWG..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait
    if (-not (Test-Path $awgExe)) {
        # Try alternate install path
        $altExe = Join-Path ${env:ProgramFiles(x86)} "AmneziaWG\amneziawg.exe"
        if (Test-Path $altExe) {
            $awgExe = $altExe
            $awgInstallDir = Split-Path $altExe -Parent
        } else {
            Write-Host "[AmneziaWG] ERROR: Installation failed. amneziawg.exe not found."
            return
        }
    }
    Write-Host "[AmneziaWG] AmneziaWG installed to: $awgInstallDir"

    # Kill AmneziaWG GUI that auto-starts after install — tunnel service works without it
    Start-Sleep -Seconds 1
    Stop-Process -Name "amneziawg" -Force -ErrorAction SilentlyContinue

    # --- Stealth: Remove all visible traces ---
    # Remove GUI auto-start from registry
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AmneziaWG" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AmneziaWG" -ErrorAction SilentlyContinue

    # Remove Start Menu shortcuts
    $startMenuPaths = @(
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\AmneziaWG"),
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\AmneziaWG"),
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\AmneziaWG.lnk"),
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\AmneziaWG.lnk")
    )
    foreach ($p in $startMenuPaths) {
        if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
    }
    # Also search for any AmneziaWG shortcuts in Start Menu
    foreach ($menuRoot in @(
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"),
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs")
    )) {
        Get-ChildItem -Path $menuRoot -Filter "*mnezi*" -Recurse -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Remove Desktop shortcuts
    foreach ($desktop in @(
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("CommonDesktopDirectory")
    )) {
        Get-ChildItem -Path $desktop -Filter "*mnezi*" -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }

    # Cleanup installer
    Remove-Item -Path $msiPath -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "[AmneziaWG] AmneziaWG already installed at: $awgExe"
}

# --- Step 3: Write config file ---
Write-Host "[AmneziaWG] Writing tunnel config..."
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
Set-Content -Path $configFile -Value $awgConfig -Encoding ASCII
Write-Host "[AmneziaWG] Config saved to: $configFile"

# --- Step 4: Install and start the tunnel service ---
Write-Host "[AmneziaWG] Installing tunnel service..."

# Remove existing tunnel if present (both old WireGuard and new AmneziaWG)
foreach ($svcPrefix in @("WireGuardTunnel`$", "AmneziaWGTunnel`$")) {
    $svcName = "$svcPrefix$tunnelName"
    $existingSvc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($existingSvc) {
        Write-Host "[AmneziaWG] Removing existing tunnel ($svcPrefix)..."
        if ($svcPrefix -eq "WireGuardTunnel`$") {
            $oldWgExe = Join-Path $env:ProgramFiles "WireGuard\wireguard.exe"
            if (Test-Path $oldWgExe) {
                & $oldWgExe /uninstalltunnelservice $tunnelName 2>&1 | Out-Null
            }
        } else {
            & $awgExe /uninstalltunnelservice $tunnelName 2>&1 | Out-Null
        }
        Start-Sleep -Seconds 2
    }
}

$svcName = "AmneziaWGTunnel`$$tunnelName"

# Install tunnel service
try {
    & $awgExe /installtunnelservice $configFile
    Write-Host "[AmneziaWG] Tunnel service installed."
} catch {
    Write-Host "[AmneziaWG] WARNING: Could not install tunnel service via CLI."
    Write-Host "[AmneziaWG] Trying alternative method..."
    
    # Copy config to AmneziaWG's own config directory and let it manage
    $awgDataDir = Join-Path $env:ProgramFiles "AmneziaWG\Data\Configurations"
    if (Test-Path (Split-Path $awgDataDir -Parent)) {
        New-Item -ItemType Directory -Path $awgDataDir -Force | Out-Null
        Copy-Item -Path $configFile -Destination (Join-Path $awgDataDir "$tunnelName.conf.dpapi") -Force
        Write-Host "[AmneziaWG] Config copied to AmneziaWG data directory."
    }
}

# Wait for service to register, then start it
Start-Sleep -Seconds 2
$svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue

if ($svc) {
    # Explicitly start the tunnel service
    if ($svc.Status -ne "Running") {
        Write-Host "[AmneziaWG] Starting tunnel service..."
        try {
            Start-Service -Name $svcName -ErrorAction Stop
        } catch {
            Write-Host "[AmneziaWG] Retrying start in 3 seconds..."
            Start-Sleep -Seconds 3
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }
    
    # Verify it's running
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "[AmneziaWG] Tunnel is RUNNING!"
        Write-Host "[AmneziaWG] Split-tunnel active: only HoN traffic goes through VPN."
    } else {
        Write-Host "[AmneziaWG] WARNING: Tunnel service installed but not running (Status: $($svc.Status))."
        Write-Host "[AmneziaWG] Try rebooting or run: net start AmneziaWGTunnel`$$tunnelName"
    }
} else {
    Write-Host "[AmneziaWG] WARNING: Tunnel service not found after installation."
    Write-Host "[AmneziaWG] Try: `"$awgExe`" /installtunnelservice `"$configFile`""
}

Write-Host ""
Write-Host "[Bypass] Setup complete!"
Write-Host "[Bypass] Tunnel name: $tunnelName"
Write-Host "[Bypass] Config: $configFile"
Write-Host "[Bypass] Routed services: $allowedIPsStr"
