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

# Получаем активные сетевые адаптеры с IP-подключением
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Loopback" }
if (-not $adapters) {
    Write-Host "[DNS] Активные сетевые адаптеры не найдены. Настройка DNS пропущена."
    return
}

$backupEntries = @()

foreach ($adapter in $adapters) {
    $ifIndex = $adapter.InterfaceIndex
    $ifName  = $adapter.Name

    # Читаем текущие DNS-серверы для этого адаптера
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

    # Устанавливаем DNS Cloudflare (1.1.1.1) и Google (8.8.8.8)
    try {
        Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @("1.1.1.1", "8.8.8.8")
        Write-Host "[DNS] Адаптер '$ifName': DNS установлен на 1.1.1.1, 8.8.8.8"
    }
    catch {
        Write-Host "[DNS] Предупреждение: не удалось настроить DNS для адаптера '$ifName': $_"
    }
}

# Сохраняем резервную копию
New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null
$backupEntries | ConvertTo-Json -Depth 3 | Set-Content -Path $backupPath -Encoding UTF8
Write-Host "[DNS] Резервная копия сохранена: $backupPath"

# Очищаем кэш DNS
try {
    & ipconfig /flushdns | Out-Null
    Write-Host "[DNS] Кэш DNS очищен."
}
catch {
    Write-Host "[DNS] Предупреждение: не удалось очистить кэш DNS."
}

Write-Host "[DNS] Настройка DNS-обхода завершена."
