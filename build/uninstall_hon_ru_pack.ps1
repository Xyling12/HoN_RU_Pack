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

# Kill agent: search by script name (any path), also kill cmd wrappers
$runningAgents = Get-CimInstance Win32_Process |
    Where-Object {
        $_.CommandLine -and $_.CommandLine -match "hon_auto_agent"
    }
foreach ($proc in $runningAgents) {
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "[Agent] Killed process: $($proc.Name) (PID $($proc.ProcessId))"
}

# Remove AmneziaWG tunnel if installed (also cleans up legacy WireGuard)
$removeAmnezia = Join-Path $PSScriptRoot "remove_amneziawg.ps1"
if (-not (Test-Path $removeAmnezia)) {
    $removeAmnezia = Join-Path $dataRoot "remove_amneziawg.ps1"
}
if (Test-Path $removeAmnezia) {
    Write-Host "Removing AmneziaWG tunnel..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $removeAmnezia -DataRoot $dataRoot
}

# Legacy: Remove Zapret service if still installed from older version
$zapretDir = Join-Path $dataRoot "zapret"
if (Test-Path $zapretDir) {
    $removeZapret = Join-Path $PSScriptRoot "remove_zapret.ps1"
    if (-not (Test-Path $removeZapret)) {
        $removeZapret = Join-Path $dataRoot "remove_zapret.ps1"
    }
    if (Test-Path $removeZapret) {
        Write-Host "Removing legacy Zapret..."
        & powershell -NoProfile -ExecutionPolicy Bypass -File $removeZapret -DataRoot $dataRoot
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
    Remove-Item -Path $modRoot -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not $KeepFiles -and (Test-Path $dataRoot)) {
    # Retry with delay - Zapret cygwin1.dll may still be locked after service stop
    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Remove-Item -Path $dataRoot -Recurse -Force -ErrorAction Stop
            break
        } catch {
            if ($i -lt $maxRetries) {
                Write-Host "[Cleanup] Retry $i/$maxRetries - waiting for file locks to release..."
                Start-Sleep -Seconds 2
            } else {
                Write-Host "[Cleanup] WARNING: Some files could not be deleted (may be locked)."
                Write-Host "[Cleanup] Removing what we can..."
                Get-ChildItem -Path $dataRoot -Recurse -Force -ErrorAction SilentlyContinue |
                    Sort-Object -Property FullName -Descending |
                    ForEach-Object {
                        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                    }
                Remove-Item -Path $dataRoot -Recurse -Force -ErrorAction SilentlyContinue
                if (Test-Path $dataRoot) {
                    Write-Host "[Cleanup] Locked files will be removed after reboot: $dataRoot"
                }
            }
        }
    }
}

# ─── Remove .str files from ALL game stringtable locations ──────────────────
if (-not $KeepFiles) {
    $strBases    = @("entities", "interface", "client_messages", "game_messages", "bot_messages")
    $strSuffixes = @(".str", "_en.str", "_ru.str", "_th.str")

    $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth"
    $strDirs = @(
        (Join-Path $InstallRoot "stringtables"),
        (Join-Path $InstallRoot "game\stringtables"),
        (Join-Path $docsRoot   "stringtables"),
        (Join-Path $docsRoot   "game\stringtables")
    )
    foreach ($dir in $strDirs) {
        if (-not (Test-Path $dir)) { continue }
        foreach ($base in $strBases) {
            foreach ($suf in $strSuffixes) {
                $f = Join-Path $dir ($base + $suf)
                if (Test-Path $f) {
                    Remove-Item $f -Force -ErrorAction SilentlyContinue
                    Write-Host "[Cleanup] Removed: $f"
                }
            }
        }
    }
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
