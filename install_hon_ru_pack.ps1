param(
    [Alias("PackageRoot")]
    [string]$SourceRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$InstallRoot = "",
    [switch]$NoStart,
    [switch]$SetupBypass,
    [switch]$RouteHoN,
    [switch]$RouteYouTube,
    [switch]$RouteDiscord,
    [switch]$RouteTelegram,
    [switch]$RouteOpenAI
)

$ErrorActionPreference = "Stop"

# --- KILLS EXISTING BACKGROUND AGENT BEFORE INSTALLATION ---
# This prevents the old agent's FileSystemWatcher from reverting 
# .str file modifications while the installer is copying the new files.
$agentScriptPath = Join-Path (Join-Path $env:LOCALAPPDATA 'HoN_RU_Pack') 'hon_auto_agent.ps1'
$runningAgents = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -and $_.CommandLine -match [regex]::Escape($agentScriptPath) }
foreach ($proc in $runningAgents) {
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
}

. "$PSScriptRoot\hon_common.ps1"

function Resolve-InstallRoot {
    param([string]$RequestedRoot)

    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) {
        $normalizedRoot = $RequestedRoot.Trim().TrimEnd('\', '/')
        if ((Split-Path $normalizedRoot -Leaf) -ieq "game") {
            $parentRoot = Split-Path $normalizedRoot -Parent
            if (-not [string]::IsNullOrWhiteSpace($parentRoot)) {
                $normalizedRoot = $parentRoot
            }
        }
        return $normalizedRoot
    }

    $autoLocalRoot = Find-HoNLocalRoot
    if ($autoLocalRoot) {
        return $autoLocalRoot
    }

    return (Join-Path $env:LOCALAPPDATA "Juvio\heroes of newerth")
}

$InstallRoot = Resolve-InstallRoot -RequestedRoot $InstallRoot

$archivePathJZ = Join-Path $InstallRoot "resources0.jz"
$archivePathS2Z = Join-Path $InstallRoot "resources0.s2z"
if ((-not (Test-Path $archivePathJZ)) -and (-not (Test-Path $archivePathS2Z))) {
    $gameArchiveJZ = Join-Path $InstallRoot "game\resources0.jz"
    $gameArchiveS2Z = Join-Path $InstallRoot "game\resources0.s2z"
    if ((-not (Test-Path $gameArchiveJZ)) -and (-not (Test-Path $gameArchiveS2Z))) {
        throw "Invalid game folder: resources0.jz or resources0.s2z not found at $InstallRoot or $InstallRoot\game"
    }
}

$dataRoot = Join-Path $env:LOCALAPPDATA "HoN_RU_Pack"
$dataBundle = Join-Path $dataRoot "bundle"
$webOverrideRoot = Join-Path $dataRoot "web_override"
$modRoot = Join-Path $InstallRoot "mod\HoN_RU_Pack"
$bundleSrc = Join-Path $SourceRoot "bundle"
$bundleDst = Join-Path $modRoot "bundle"

$bundleFiles = @(
    "entities_en.str",
    "interface_en.str",
    "client_messages_en.str",
    "game_messages_en.str",
    "bot_messages_en.str"
)

if (-not (Test-Path $bundleSrc)) {
    $flatOk = $true
    foreach ($name in $bundleFiles) {
        if (-not (Test-Path (Join-Path $SourceRoot $name))) {
            $flatOk = $false
            break
        }
    }
    if ($flatOk) {
        $bundleSrc = $SourceRoot
    } else {
        throw "Bundle folder not found: $bundleSrc"
    }
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
New-Item -ItemType Directory -Path $dataBundle -Force | Out-Null
New-Item -ItemType Directory -Path $webOverrideRoot -Force | Out-Null
New-Item -ItemType Directory -Path $modRoot -Force | Out-Null
New-Item -ItemType Directory -Path $bundleDst -Force | Out-Null

foreach ($file in $bundleFiles) {
    $src = Join-Path $bundleSrc $file
    if (-not (Test-Path $src)) {
        throw "Missing bundle file: $src"
    }
    Copy-Item -Path $src -Destination (Join-Path $dataBundle $file) -Force
    Copy-Item -Path $src -Destination (Join-Path $bundleDst $file) -Force
}

$payloadFiles = @(
    "hon_common.ps1",
    "hon_auto_agent.ps1",
    "set_login_banner.ps1",
    "setup_dns_bypass.ps1",
    "restore_dns.ps1",
    "setup_amneziawg.ps1",
    "remove_amneziawg.ps1",
    "hon_paths_override.example.ps1",
    "version.txt",
    "README.txt",
    "README_ONE_CLICK_INSTALL.txt"
)
foreach ($file in $payloadFiles) {
    $src = Join-Path $SourceRoot $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $dataRoot $file) -Force
        Copy-Item -Path $src -Destination (Join-Path $modRoot $file) -Force
    }
}

$overrideSrc = Join-Path $dataRoot "hon_paths_override.example.ps1"
$overrideDst = Join-Path $dataRoot "hon_paths_override.ps1"
if ((Test-Path $overrideSrc) -and (-not (Test-Path $overrideDst))) {
    Copy-Item -Path $overrideSrc -Destination $overrideDst -Force
}
$legacyOverride = Join-Path $modRoot "hon_paths_override.ps1"
if ((-not (Test-Path $overrideDst)) -and (Test-Path $legacyOverride)) {
    Copy-Item -Path $legacyOverride -Destination $overrideDst -Force
}

$docsRoot = Find-HoNDocsRoot
if (-not $docsRoot) {
    $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth"
}

# Build strTargets from ALL found Juvio installations + docsRoot
$allGameRoots = Find-AllHoNLocalRoots
$strTargetsList = [System.Collections.Generic.List[string]]::new()
$strTargetsList.Add((Join-Path $InstallRoot "stringtables"))  # always include primary
foreach ($gr in $allGameRoots) {
    foreach ($sub in @("stringtables", "game\stringtables")) {
        $p = Join-Path $gr $sub
        if (-not $strTargetsList.Contains($p)) { $strTargetsList.Add($p) }
    }
}
$strTargetsList.Add((Join-Path $docsRoot "game\stringtables"))
$strTargetsList.Add((Join-Path $docsRoot "stringtables"))
$strTargets = $strTargetsList | Select-Object -Unique

$localeVariants = @(".str", "_en.str", "_ru.str", "_th.str")
$strBases = @("entities", "interface", "client_messages", "game_messages", "bot_messages")

foreach ($target in $strTargets) {
    New-Item -ItemType Directory -Path $target -Force -ErrorAction SilentlyContinue | Out-Null
    foreach ($base in $strBases) {
        $src = Join-Path $bundleSrc ($base + "_en.str")
        if (Test-Path $src) {
            foreach ($suffix in $localeVariants) {
                Copy-Item -Path $src -Destination (Join-Path $target ($base + $suffix)) -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
if ($allGameRoots.Count -gt 1) {
    Write-Host "[Install] Placed .str files in $($allGameRoots.Count) game installations: $($allGameRoots -join ', ')"
} else {
    Write-Host "[Install] Placed .str files in active game stringtables."
}

foreach ($legacyArchive in @(
    (Join-Path $InstallRoot "resources999.s2z"),
    (Join-Path $docsRoot "resources999.s2z"),
    (Join-Path $InstallRoot "game\resources999.s2z"),
    (Join-Path $docsRoot "game\resources999.s2z")
)) {
    if (Test-Path $legacyArchive) {
        Remove-Item -Path $legacyArchive -Force -ErrorAction SilentlyContinue
    }
}

$legacyModStringtables = Join-Path $modRoot "stringtables"
if (Test-Path $legacyModStringtables) {
    Remove-Item -Path $legacyModStringtables -Recurse -Force -ErrorAction SilentlyContinue
}

$startupCfgTargets = @(
    (Join-Path $docsRoot "startup.cfg")
) | Select-Object -Unique
foreach ($startupCfg in $startupCfgTargets) {
    if (-not (Test-Path $startupCfg)) { continue }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $cfgText = [System.IO.File]::ReadAllText($startupCfg)
    $cfgUpdated = $cfgText
    $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"login_refreshToken"\s+"[^"]*"\s*\r?\n?', '')
    $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^set\s+login_refreshToken\s+"[^"]*"\s*\r?\n?', '')
    $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"host_locale"\s+"[^"]*"', 'SetSave "host_locale" "en"')
    $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"host_backuplocale"\s+"[^"]*"', 'SetSave "host_backuplocale" "en"')
    $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"language"\s+"[^"]*"', 'SetSave "language" "en"')
    $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^set\s+host_locale\s+"[^"]*"', 'set host_locale "en"')
    if ($cfgUpdated -eq $cfgText) {
        if ($cfgUpdated.Length -gt 0 -and -not $cfgUpdated.EndsWith([Environment]::NewLine)) {
            $cfgUpdated += [Environment]::NewLine
        }
        $cfgUpdated += 'set host_locale "en"' + [Environment]::NewLine
    }
    [System.IO.File]::WriteAllText($startupCfg, $cfgUpdated, $utf8NoBom)
    Write-Host "[Install] startup.cfg locale set to English: $startupCfg"
}

foreach ($cacheRoot in @($docsRoot, (Join-Path $docsRoot "game")) | Select-Object -Unique) {
    foreach ($cacheName in @("filecache", "webcache")) {
        $cacheDir = Join-Path $cacheRoot $cacheName
        if (Test-Path $cacheDir) {
            Get-ChildItem -Path $cacheDir -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "[Install] Cleared game $cacheName."
        }
    }
}

$webOverridePrepared = Prepare-HoNWebOverride -GameRoot $InstallRoot -OutputRoot $webOverrideRoot
if ($webOverridePrepared) {
    $webOverrideSynced = Sync-HoNWebOverride -SourceRoot $webOverrideRoot -GameRoot $InstallRoot
    if ($webOverrideSynced) {
        Write-Host "[Install] Placed web override files in game root."
    } else {
        Write-Host "[Install] Web override files already present in game root."
    }
} else {
    Write-Host "[Install] Web override preparation skipped."
}

$bannerScript = Join-Path $dataRoot "set_login_banner.ps1"
if (Test-Path $bannerScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bannerScript -PackageRoot $dataRoot
}

$agentScript = Join-Path $dataRoot "hon_auto_agent.ps1"
if (-not (Test-Path $agentScript)) {
    throw "Agent script not found after copy: $agentScript"
}

$taskName = "HoN_RU_Pack_AutoAgent"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

$startupDir = [Environment]::GetFolderPath("Startup")
$agentArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$agentScript`""
$legacyCmd = $null
if (-not [string]::IsNullOrWhiteSpace($startupDir)) {
    $legacyCmd = Join-Path $startupDir "HoN_RU_Pack_AutoAgent.cmd"
    if (Test-Path $legacyCmd) {
        Remove-Item -Path $legacyCmd -Force -ErrorAction SilentlyContinue
    }
}
$startupCmd = $null
$autoStartStatus = "Autostart disabled"
$scheduledTaskRegistered = $false

try {
    $scheduledTaskUser = if (-not [string]::IsNullOrWhiteSpace($env:USERDOMAIN)) {
        "$($env:USERDOMAIN)\$($env:USERNAME)"
    } else {
        $env:USERNAME
    }

    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument $agentArgs

    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

    $principal = New-ScheduledTaskPrincipal `
        -UserId $scheduledTaskUser `
        -LogonType Interactive `
        -RunLevel Limited

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -RestartCount 999 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "HoN RU Pack - background agent that keeps Russian translation files in sync." `
        -ErrorAction Stop `
        -Force | Out-Null

    $scheduledTaskRegistered = $true
    $autoStartStatus = "ScheduledTask: $taskName"
} catch {
    if (-not $legacyCmd) {
        Write-Warning "Autostart registration skipped: $($_.Exception.Message)"
    }
}

if ((-not $scheduledTaskRegistered) -and $legacyCmd) {
    @(
        "@echo off"
        "start """" /b powershell.exe $agentArgs"
    ) | Set-Content -Path $legacyCmd -Encoding ASCII
    $startupCmd = $legacyCmd
    $autoStartStatus = "StartupCmd: $startupCmd"
}

if (-not $NoStart) {
    Start-Process -FilePath "powershell.exe" -ArgumentList $agentArgs -WindowStyle Hidden
}

if ($SetupBypass) {
    $awgScript = Join-Path $SourceRoot "setup_amneziawg.ps1"
    if (Test-Path $awgScript) {
        Write-Host "Setting up bypass..."
        $awgParams = @{ DataRoot = $dataRoot }
        if ($RouteHoN)      { $awgParams["RouteHoN"] = $true }
        if ($RouteYouTube)  { $awgParams["RouteYouTube"] = $true }
        if ($RouteDiscord)  { $awgParams["RouteDiscord"] = $true }
        if ($RouteTelegram) { $awgParams["RouteTelegram"] = $true }
        if ($RouteOpenAI)   { $awgParams["RouteOpenAI"] = $true }
        & $awgScript @awgParams
    } else {
        Write-Host "[Bypass] setup script not found, skipping."
    }
}

Write-Host "install_ok"
Write-Host "Install completed."
Write-Host "GameRoot: $InstallRoot"
Write-Host "DataRoot: $dataRoot"
Write-Host "ModRoot: $modRoot"
Write-Host "Autostart: $autoStartStatus"
$agentLog = Join-Path $dataRoot "agent.log"
Write-Host "Agent log: $agentLog"
