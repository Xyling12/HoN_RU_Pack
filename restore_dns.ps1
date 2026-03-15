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
    Write-Host "[DNS] Резервная копия DNS не найдена: $backupPath. Восстанавливать нечего."
    return
}

$backupEntries = Get-Content -Path $backupPath -Raw | ConvertFrom-Json

foreach ($entry in $backupEntries) {
    $ifIndex = $entry.InterfaceIndex
    $ifName  = $entry.InterfaceName
    $origDns = @($entry.OriginalDNS)

    # Проверяем, существует ли адаптер
    $adapter = Get-NetAdapter -InterfaceIndex $ifIndex -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-Host "[DNS] Адаптер '$ifName' (индекс $ifIndex) больше не существует. Пропускаю."
        continue
    }

    try {
        if ($origDns.Count -eq 0) {
            # Изначально использовался DHCP, без ручного DNS
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ResetServerAddresses
            Write-Host "[DNS] Адаптер '$ifName': DNS возвращен к DHCP (автоматически)."
        }
        else {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $origDns
            Write-Host "[DNS] Адаптер '$ifName': DNS восстановлен до $($origDns -join ', ')."
        }
    }
    catch {
        Write-Host "[DNS] Предупреждение: не удалось восстановить DNS для адаптера '$ifName': $_"
    }
}

# Удаляем резервную копию
Remove-Item -Path $backupPath -Force -ErrorAction SilentlyContinue
Write-Host "[DNS] Файл резервной копии удален."

# Очищаем кэш DNS
try {
    & ipconfig /flushdns | Out-Null
    Write-Host "[DNS] Кэш DNS очищен."
}
catch {
    Write-Host "[DNS] Предупреждение: не удалось очистить кэш DNS."
}

Write-Host "[DNS] Настройки DNS восстановлены."
