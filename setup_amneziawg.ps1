<#
    HoN RU Pack — AmneziaWG Client Setup (Windows)
    Downloads AmneziaWG client, installs silently, creates split-tunnel config for HoN.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack"),
    [switch]$RouteHoN,
    [switch]$RouteYouTube,
    [switch]$RouteDiscord,
    [switch]$RouteTelegram,
    [switch]$RouteOpenAI
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
if ($RouteTelegram) {
    # Telegram IP ranges (ASN 62041)
    $allowedIPs += @(
        "91.108.4.0/22", "91.108.8.0/21", "91.108.16.0/21", "91.108.56.0/22",
        "149.154.160.0/20", "91.105.192.0/23", "95.161.64.0/20",
        "185.76.151.0/24"
    )
}
if ($RouteOpenAI) {
    # OpenAI/ChatGPT — Cloudflare-fronted + Azure API ranges
    $allowedIPs += @(
        "104.18.0.0/16", "104.16.0.0/14", "172.64.0.0/13",
        "23.102.140.112/28", "13.66.11.96/28", "104.210.133.240/28",
        "23.98.142.176/28", "40.84.180.224/28"
    )
}

if ($allowedIPs.Count -eq 0) {
    Write-Host "[Bypass] Не выбрано ни одного сервиса. Настройка обхода пропущена."
    return
}

$allowedIPsStr = $allowedIPs -join ", "

# --- Server info (fixed) ---
$serverPubKey = "DJt5YKkQ2EozLk+VpR2uPQUCD5qL+zFgVwFRASRmqzk="
$serverEndpoint = "94.103.15.45:51820"
$registerUrl = "http://94.103.15.45:8085/register"
$registerToken = "HoNRUPack2026SecretToken"

# --- AmneziaWG obfuscation params (must match server) ---
$awgJc = 4; $awgJmin = 50; $awgJmax = 1000
$awgS1 = 68; $awgS2 = 84
$awgH1 = 981756423; $awgH2 = 725841693; $awgH3 = 412685937; $awgH4 = 158973264

# --- Check for existing registration ---
$regFile = Join-Path $configDir "registration.json"
$clientPrivKey = $null
$clientPSK = $null
$clientIP = $null

if (Test-Path $regFile) {
    try {
        $reg = Get-Content $regFile -Raw | ConvertFrom-Json
        $clientPrivKey = $reg.privkey
        $clientPSK = $reg.psk
        $clientIP = $reg.ip
        Write-Host "[AmneziaWG] Найдена существующая регистрация: $clientIP"
    } catch {
        Write-Host "[AmneziaWG] Файл регистрации поврежден или некорректен. Регистрирую заново..."
    }
}

if (-not $clientPrivKey) {
    # --- Generate unique keys ---
    # AmneziaWG must be installed first (done below), but we need keys now.
    # Use the awg.exe command-line tool if available, otherwise generate after install.
    $awgToolExe = Join-Path $awgInstallDir "awg.exe"
    $wgExe = $null
    
    # Try to find a key generation tool
    foreach ($candidate in @($awgToolExe, (Join-Path $awgInstallDir "wg.exe"), "wg.exe")) {
        if (Test-Path $candidate -ErrorAction SilentlyContinue) { $wgExe = $candidate; break }
        $found = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($found) { $wgExe = $found.Source; break }
    }
    
    # If no tool found yet, we'll generate after AmneziaWG install — set a flag
    $needKeysAfterInstall = (-not $wgExe)
}

# Config will be written after key generation/registration (see below)

# --- Step 1: Download AmneziaWG MSI ---
$msiUrl = "https://github.com/amnezia-vpn/amneziawg-windows-client/releases/download/2.0.0/amneziawg-amd64-2.0.0.msi"
$msiPath = Join-Path $env:TEMP "amneziawg-amd64.msi"

if (-not (Test-Path $awgExe)) {
    Write-Host "[AmneziaWG] Загружаю установщик AmneziaWG..."
    $downloaded = $false
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing -TimeoutSec 120
        if ((Get-Item $msiPath).Length -gt 100000) { $downloaded = $true }
    } catch {}

    # Fallback: download from VPS (in case GitHub is blocked by DPI)
    if (-not $downloaded) {
        Write-Host "[AmneziaWG] GitHub недоступен, пробую зеркало на VPS..."
        try {
            Invoke-WebRequest -Uri "http://94.103.15.45:8080/amneziawg-amd64.msi" -OutFile $msiPath -UseBasicParsing -TimeoutSec 120
            if ((Get-Item $msiPath).Length -gt 100000) { $downloaded = $true }
        } catch {}
    }

    if (-not $downloaded) {
        Write-Host "[AmneziaWG] Ошибка: загрузка не удалась."
        Write-Host "[AmneziaWG] Скачайте клиент вручную: https://amnezia.org/en/downloads"
        return
    }

    # --- Step 2: Silent MSI install ---
    Write-Host "[AmneziaWG] Устанавливаю AmneziaWG..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait
    if (-not (Test-Path $awgExe)) {
        # Try alternate install path
        $altExe = Join-Path ${env:ProgramFiles(x86)} "AmneziaWG\amneziawg.exe"
        if (Test-Path $altExe) {
            $awgExe = $altExe
            $awgInstallDir = Split-Path $altExe -Parent
        } else {
            Write-Host "[AmneziaWG] Ошибка: установка не удалась. Файл amneziawg.exe не найден."
            return
        }
    }
    Write-Host "[AmneziaWG] AmneziaWG установлен в: $awgInstallDir"

    # Kill AmneziaWG GUI that auto-starts after install — tunnel service works without it
    Start-Sleep -Seconds 1
    Stop-Process -Name "amneziawg" -Force -ErrorAction SilentlyContinue

    # --- Stealth: Disable manager services that auto-start the GUI tray icon ---
    foreach ($mgr in @("AmneziaWGManager", "AmneziaVPN-service")) {
        $mgrSvc = Get-Service -Name $mgr -ErrorAction SilentlyContinue
        if ($mgrSvc) {
            Write-Host "[AmneziaWG] Отключаю службу $mgr..."
            Stop-Service -Name $mgr -Force -ErrorAction SilentlyContinue
            Set-Service -Name $mgr -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }

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
    Write-Host "[AmneziaWG] AmneziaWG уже установлен: $awgExe"
}

# --- Step 3: Generate keys and register with server ---
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

if (-not $clientPrivKey) {
    # Find awg.exe or wg.exe for key generation (AmneziaWG should be installed by now)
    if ($needKeysAfterInstall -or -not $wgExe) {
        $awgToolExe = Join-Path $awgInstallDir "awg.exe"
        foreach ($candidate in @($awgToolExe, (Join-Path $awgInstallDir "wg.exe"))) {
            if (Test-Path $candidate) { $wgExe = $candidate; break }
        }
        # Fallback: try WireGuard's wg.exe
        if (-not $wgExe) {
            $wgFallback = Join-Path $env:ProgramFiles "WireGuard\wg.exe"
            if (Test-Path $wgFallback) { $wgExe = $wgFallback }
        }
    }

    if (-not $wgExe) {
        Write-Host "[AmneziaWG] Ошибка: не удалось найти awg.exe или wg.exe для генерации ключей."
        return
    }

    Write-Host "[AmneziaWG] Генерирую уникальные ключи..."
    $clientPrivKey = (& $wgExe genkey).Trim()
    $clientPubKey = ($clientPrivKey | & $wgExe pubkey).Trim()
    $clientPSK = (& $wgExe genpsk).Trim()

    Write-Host "[AmneziaWG] Регистрирую клиента на сервере..."
    $body = @{
        token = $registerToken
        pubkey = $clientPubKey
        psk = $clientPSK
    } | ConvertTo-Json

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $response = Invoke-RestMethod -Uri $registerUrl -Method POST -Body $body -ContentType "application/json" -TimeoutSec 15
        $clientIP = $response.ip
        Write-Host "[AmneziaWG] Регистрация завершена. Назначенный IP: $clientIP"
    } catch {
        Write-Host "[AmneziaWG] Ошибка: регистрация не удалась: $_"
        Write-Host "[AmneziaWG] Возможно, сервер временно недоступен. Попробуйте позже."
        return
    }

    # Save registration for future reinstalls
    @{ privkey = $clientPrivKey; psk = $clientPSK; ip = $clientIP; pubkey = $clientPubKey } |
        ConvertTo-Json | Set-Content -Path $regFile -Encoding UTF8
    Write-Host "[AmneziaWG] Данные регистрации сохранены: $regFile"
}

# --- Step 4: Write config file ---
$awgConfig = @"
[Interface]
PrivateKey = $clientPrivKey
Address = $clientIP/32
DNS = 1.1.1.1
MTU = 1400
Jc = $awgJc
Jmin = $awgJmin
Jmax = $awgJmax
S1 = $awgS1
S2 = $awgS2
H1 = $awgH1
H2 = $awgH2
H3 = $awgH3
H4 = $awgH4

[Peer]
PublicKey = $serverPubKey
PresharedKey = $clientPSK
Endpoint = $serverEndpoint
AllowedIPs = $allowedIPsStr
PersistentKeepalive = 25
"@

Write-Host "[AmneziaWG] Записываю конфигурацию туннеля..."
Set-Content -Path $configFile -Value $awgConfig -Encoding ASCII
Write-Host "[AmneziaWG] Конфигурация сохранена: $configFile"

# --- Step 4: Install and start the tunnel service ---
Write-Host "[AmneziaWG] Устанавливаю службу туннеля..."

# Remove existing tunnel if present (both old WireGuard and new AmneziaWG)
foreach ($svcPrefix in @("WireGuardTunnel`$", "AmneziaWGTunnel`$")) {
    $svcName = "$svcPrefix$tunnelName"
    $existingSvc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($existingSvc) {
        Write-Host "[AmneziaWG] Удаляю существующий туннель ($svcPrefix)..."
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
    Write-Host "[AmneziaWG] Служба туннеля установлена."
} catch {
    Write-Host "[AmneziaWG] Предупреждение: не удалось установить службу туннеля через CLI."
    Write-Host "[AmneziaWG] Пробую альтернативный способ..."
    
    # Copy config to AmneziaWG's own config directory and let it manage
    $awgDataDir = Join-Path $env:ProgramFiles "AmneziaWG\Data\Configurations"
    if (Test-Path (Split-Path $awgDataDir -Parent)) {
        New-Item -ItemType Directory -Path $awgDataDir -Force | Out-Null
        Copy-Item -Path $configFile -Destination (Join-Path $awgDataDir "$tunnelName.conf.dpapi") -Force
        Write-Host "[AmneziaWG] Конфигурация скопирована в каталог данных AmneziaWG."
    }
}

# Wait for service to register, then start it
Start-Sleep -Seconds 2
$svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue

if ($svc) {
    # Explicitly start the tunnel service
    if ($svc.Status -ne "Running") {
        Write-Host "[AmneziaWG] Запускаю службу туннеля..."
        try {
            Start-Service -Name $svcName -ErrorAction Stop
        } catch {
            Write-Host "[AmneziaWG] Повторяю запуск через 3 секунды..."
            Start-Sleep -Seconds 3
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }
    
    # Verify it's running
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "[AmneziaWG] Туннель запущен."
        Write-Host "[AmneziaWG] Раздельная маршрутизация активна: через VPN идет только выбранный трафик."
    } else {
        Write-Host "[AmneziaWG] Предупреждение: служба туннеля установлена, но не запущена (состояние: $($svc.Status))."
        Write-Host "[AmneziaWG] Попробуйте перезагрузить ПК или выполнить: net start AmneziaWGTunnel`$$tunnelName"
    }
} else {
    Write-Host "[AmneziaWG] Предупреждение: после установки служба туннеля не найдена."
    Write-Host "[AmneziaWG] Попробуйте выполнить: `"$awgExe`" /installtunnelservice `"$configFile`""
}

Write-Host ""
Write-Host "[Bypass] Настройка завершена."
Write-Host "[Bypass] Имя туннеля: $tunnelName"
Write-Host "[Bypass] Конфигурация: $configFile"
Write-Host "[Bypass] Направляемые сервисы: $allowedIPsStr"
