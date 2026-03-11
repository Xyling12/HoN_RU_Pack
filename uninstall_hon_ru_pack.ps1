param(
    [string]$InstallRoot = "",
    [switch]$KeepFiles
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\hon_common.ps1"

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $autoLocalRoot = Find-HoNLocalRoot
    if ($autoLocalRoot) {
        $InstallRoot = $autoLocalRoot
    } else {
        $InstallRoot = Join-Path $env:LOCALAPPDATA "Juvio\heroes of newerth"
    }
}

$modRoot = Join-Path $InstallRoot "mod\HoN_RU_Pack"
$dataRoot = Join-Path $env:LOCALAPPDATA "HoN_RU_Pack"
$agentScriptData = Join-Path $dataRoot "hon_auto_agent.ps1"
$agentScriptMod = Join-Path $modRoot "hon_auto_agent.ps1"
$startupDir = [Environment]::GetFolderPath("Startup")
$startupCmd = Join-Path $startupDir "HoN_RU_Pack_AutoAgent.cmd"
if (Test-Path $startupCmd) {
    Remove-Item -Path $startupCmd -Force
}

Unregister-ScheduledTask -TaskName "HoN_RU_Pack_AutoAgent" -Confirm:$false -ErrorAction SilentlyContinue

$runningAgents = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object {
        $_.CommandLine -and (
            $_.CommandLine -match [regex]::Escape($agentScriptData) -or
            $_.CommandLine -match [regex]::Escape($agentScriptMod)
        )
    }
foreach ($proc in $runningAgents) {
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
}

# Remove Zapret service if installed
$zapretDir = Join-Path $dataRoot "zapret"
if (Test-Path $zapretDir) {
    $removeZapret = Join-Path $PSScriptRoot "remove_zapret.ps1"
    if (-not (Test-Path $removeZapret)) {
        $removeZapret = Join-Path $dataRoot "remove_zapret.ps1"
    }
    if (Test-Path $removeZapret) {
        Write-Host "Removing Zapret..."
        & powershell -NoProfile -ExecutionPolicy Bypass -File $removeZapret -DataRoot $dataRoot
    } else {
        Write-Host "[Zapret] remove_zapret.ps1 not found, skipping."
    }
}

# Restore DNS settings if backup exists
$dnsBackup = Join-Path $dataRoot "dns_backup.json"
if (Test-Path $dnsBackup) {
    $restoreScript = Join-Path $PSScriptRoot "restore_dns.ps1"
    if (-not (Test-Path $restoreScript)) {
        $restoreScript = Join-Path $dataRoot "restore_dns.ps1"
    }
    if (Test-Path $restoreScript) {
        Write-Host "Restoring DNS settings..."
        & powershell -NoProfile -ExecutionPolicy Bypass -File $restoreScript -DataRoot $dataRoot
    } else {
        Write-Host "[DNS] restore_dns.ps1 not found, skipping DNS restore."
    }
}

if (-not $KeepFiles -and (Test-Path $modRoot)) {
    Remove-Item -Path $modRoot -Recurse -Force
}
if (-not $KeepFiles -and (Test-Path $dataRoot)) {
    Remove-Item -Path $dataRoot -Recurse -Force
}

Write-Host "Uninstall completed."
Write-Host "Scheduled task removed: HoN_RU_Pack_AutoAgent"
if ($KeepFiles) {
    Write-Host "Files kept at: $modRoot"
    Write-Host "Files kept at: $dataRoot"
} else {
    Write-Host "Files removed from: $modRoot"
    Write-Host "Files removed from: $dataRoot"
}
