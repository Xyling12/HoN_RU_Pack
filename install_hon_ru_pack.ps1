param(
    [string]$SourceRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$InstallRoot = "",
    [switch]$NoStart
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

$archivePath = Join-Path $InstallRoot "resources0.jz"
if (-not (Test-Path $archivePath)) {
    throw "Invalid game folder: resources0.jz not found at $archivePath"
}

$dataRoot = Join-Path $env:LOCALAPPDATA "HoN_RU_Pack"
$dataBundle = Join-Path $dataRoot "bundle"
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
    "hon_paths_override.example.ps1",
    "version.txt",
    "README.txt"
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

$bannerScript = Join-Path $dataRoot "set_login_banner.ps1"
if (Test-Path $bannerScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bannerScript -PackageRoot $dataRoot
}

$agentScript = Join-Path $dataRoot "hon_auto_agent.ps1"
if (-not (Test-Path $agentScript)) {
    throw "Agent script not found after copy: $agentScript"
}

$runningAgents = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -and $_.CommandLine -match [regex]::Escape($agentScript) }
foreach ($proc in $runningAgents) {
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
}

# Remove legacy Startup .cmd if present
$startupDir = [Environment]::GetFolderPath("Startup")
$legacyCmd = Join-Path $startupDir "HoN_RU_Pack_AutoAgent.cmd"
if (Test-Path $legacyCmd) { Remove-Item -Path $legacyCmd -Force -ErrorAction SilentlyContinue }

# Register a Scheduled Task for reliable autostart with auto-restart on failure
$taskName = "HoN_RU_Pack_AutoAgent"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$agentScript`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

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
    -Settings $settings `
    -Description "HoN RU Pack - background agent that keeps Russian translation files in sync." `
    -Force | Out-Null

if (-not $NoStart) {
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$agentScript`"" -WindowStyle Hidden
}

Write-Host "Install completed."
Write-Host "GameRoot: $InstallRoot"
Write-Host "DataRoot: $dataRoot"
Write-Host "ModRoot: $modRoot"
Write-Host "ScheduledTask: $taskName"
$agentLog = Join-Path $dataRoot "agent.log"
Write-Host "Agent log: $agentLog"
