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
