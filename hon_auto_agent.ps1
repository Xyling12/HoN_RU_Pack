param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [int]$LaunchSyncDelayMilliseconds = 300,
    [int]$RunningSyncDelayMilliseconds = 2000,
    [int]$IdleDelayMilliseconds = 3000,
    [int]$LocaleRefreshSeconds = 30,
    [int]$LaunchBurstSeconds = 120,
    [int]$IdleRefreshSeconds = 300
)
$ErrorActionPreference = "SilentlyContinue"

$logFile = Join-Path $PackageRoot "agent.log"

function Write-Log {
    param([string]$msg, [string]$level = "INF")
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts][$level] $msg"
    Write-Host $line
    try { Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

try {
    if ((Test-Path $logFile) -and (Get-Item $logFile).Length -gt 512000) {
        Move-Item $logFile "$logFile.bak" -Force -ErrorAction SilentlyContinue
    }
} catch {}

Write-Log "Agent started. PackageRoot=$PackageRoot" "INF"

try {
    . "$PSScriptRoot\hon_common.ps1"
    Write-Log "hon_common.ps1 loaded OK" "INF"
} catch {
    Write-Log "FATAL: cannot load hon_common.ps1 - $_" "ERR"
    exit 1
}

$docsRoot = Find-HoNDocsRoot
if (-not $docsRoot) { $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth" }

$allGameRoots = Find-AllHoNLocalRoots
if (-not $gameRoot) { $gameRoot = if ($allGameRoots.Count -gt 0) { $allGameRoots[0] } else { Join-Path $env:LOCALAPPDATA "Juvio\heroes of newerth" } }

Write-Log "gameRoot=$gameRoot" "INF"
Write-Log "docsRoot=$docsRoot" "INF"
if ($allGameRoots.Count -gt 1) {
    Write-Log "Additional game roots found: $(($allGameRoots | Select-Object -Skip 1) -join ', ')" "INF"
}

$dataBundle      = Join-Path $PackageRoot "bundle"
$webOverrideRoot = Join-Path $PackageRoot "web_override"
$localeVariants  = @(".str", "_en.str", "_ru.str", "_th.str")
$strBases        = @("entities", "interface", "client_messages", "game_messages", "bot_messages")

# Build strTargets from ALL found game roots + docsRoot
$strTargets = [System.Collections.Generic.List[string]]::new()
foreach ($gr in $allGameRoots) {
    $strTargets.Add((Join-Path $gr "stringtables"))
    $strTargets.Add((Join-Path $gr "game\stringtables"))
}
$strTargets.Add((Join-Path $docsRoot "stringtables"))
$strTargets.Add((Join-Path $docsRoot "game\stringtables"))
$strTargets = $strTargets | Select-Object -Unique


$startupCfgTargets = @(
    (Join-Path $docsRoot "startup.cfg")
)

$sourceMeta = @{}
foreach ($base in $strBases) {
    $src = Join-Path $dataBundle ($base + "_en.str")
    if (Test-Path $src) {
        $sourceMeta[$base] = [pscustomobject]@{
            Path   = $src
            Length = (Get-Item $src).Length
        }
    }
}

# ─── Force-write single file ────────────────────────────────────────────────
function Write-StrFile {
    param([string]$src, [string]$dst)
    try {
        Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ─── Sync all string files ───────────────────────────────────────────────────
function Sync-Strings {
    param([switch]$Force)
    $synced = 0
    foreach ($target in $strTargets) {
        if (-not (Test-Path $target)) {
            try { New-Item -ItemType Directory -Path $target -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
        foreach ($base in $strBases) {
            $srcInfo = $sourceMeta[$base]
            if (-not $srcInfo) { continue }
            foreach ($suffix in $localeVariants) {
                $dst = Join-Path $target ($base + $suffix)
                $needCopy = $Force
                if (-not $needCopy) {
                    if (-not (Test-Path $dst)) {
                        $needCopy = $true
                    } else {
                        try {
                            $dstLen = (Get-Item $dst -ErrorAction SilentlyContinue).Length
                            if ($dstLen -ne $srcInfo.Length) { $needCopy = $true }
                        } catch { $needCopy = $true }
                    }
                }
                if ($needCopy) {
                    Write-StrFile $srcInfo.Path $dst
                    $synced++
                }
            }
        }
    }
    if ($synced -gt 0) { Write-Log "Sync-Strings: wrote $synced files" "INF" }
}

# ─── FileSystemWatcher: instantly restore overwritten .str files ─────────────
$watchers = [System.Collections.Generic.List[object]]::new()

foreach ($target in $strTargets) {
    if (-not (Test-Path $target)) {
        try { New-Item -ItemType Directory -Path $target -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
    if (-not (Test-Path $target)) { continue }
    try {
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path   = $target
        $watcher.Filter = "*.str"
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
        $watcher.EnableRaisingEvents = $true

        # Capture vars for closure
        $capturedTarget  = $target
        $capturedSrcMeta = $sourceMeta
        $capturedBases   = $strBases
        $capturedSuffixes = $localeVariants
        $capturedLog     = $logFile

        $handler = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
            $changedFile = $Event.SourceEventArgs.FullPath
            $changedName = $Event.SourceEventArgs.Name
            # Find which base matches
            foreach ($base in $using:capturedBases) {
                foreach ($suffix in $using:capturedSuffixes) {
                    if ($changedName -eq ($base + $suffix)) {
                        $srcInfo = ($using:capturedSrcMeta)[$base]
                        if ($srcInfo) {
                            try {
                                $curLen = (Get-Item $changedFile -ErrorAction SilentlyContinue).Length
                                if ($curLen -ne $srcInfo.Length) {
                                    Copy-Item -Path $srcInfo.Path -Destination $changedFile -Force -ErrorAction SilentlyContinue
                                    $ts = Get-Date -Format "HH:mm:ss"
                                    Add-Content -Path $using:capturedLog -Value "[$ts][INF] FSW restored: $changedName" -Encoding UTF8 -ErrorAction SilentlyContinue
                                }
                            } catch {}
                        }
                    }
                }
            }
        }

        $watchers.Add([pscustomobject]@{ Watcher = $watcher; Handler = $handler; Path = $target })
        Write-Log "FSW watching: $target" "INF"
    } catch {
        Write-Log "FSW setup error for ${target}: $_" "WRN"
    }
}

# ─── Sync locale config ───────────────────────────────────────────────────────
function Sync-LocaleConfig {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($startupCfg in $startupCfgTargets) {
        if (-not (Test-Path $startupCfg)) { continue }
        try {
            $cfgText    = [System.IO.File]::ReadAllText($startupCfg)
            $cfgUpdated = $cfgText
            $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"login_refreshToken"\s+"[^"]*"\s*\r?\n?', '')
            $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^set\s+login_refreshToken\s+"[^"]*"\s*\r?\n?', '')
            $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"host_locale"\s+"[^"]*"',       'SetSave "host_locale" "en"')
            $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"host_backuplocale"\s+"[^"]*"', 'SetSave "host_backuplocale" "en"')
            $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^SetSave\s+"language"\s+"[^"]*"',          'SetSave "language" "en"')
            $cfgUpdated = [Regex]::Replace($cfgUpdated, '(?im)^set\s+host_locale\s+"[^"]*"',             'set host_locale "en"')
            if ($cfgUpdated -notmatch '(?im)^set\s+host_locale\s+"en"\s*$') {
                if ($cfgUpdated.Length -gt 0 -and -not $cfgUpdated.EndsWith([Environment]::NewLine)) {
                    $cfgUpdated += [Environment]::NewLine
                }
                $cfgUpdated += 'set host_locale "en"' + [Environment]::NewLine
            }
            if ($cfgUpdated -ne $cfgText) {
                [System.IO.File]::WriteAllText($startupCfg, $cfgUpdated, $utf8NoBom)
                Write-Log "startup.cfg updated: $startupCfg" "INF"
            }
        } catch {
            Write-Log "Sync-LocaleConfig error ($startupCfg): $_" "WRN"
        }
    }
}

# ─── Nav patch: auto-repatch nav tab names in resources0.jz ─────────────────
function Sync-NavPatch {
    try {
        $archivePath = Join-Path $gameRoot "resources0.jz"
        if (-not (Test-Path $archivePath)) { return }

        $sevenZip = $null
        foreach ($c in @("C:\Program Files\7-Zip\7z.exe","C:\Program Files (x86)\7-Zip\7z.exe")) {
            if (Test-Path $c) { $sevenZip = $c; break }
        }
        if (-not $sevenZip) { return }

        # Extract stringtables/interface_en.str to temp
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "hon_nav_patch"
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory $tmpDir -Force | Out-Null

        & $sevenZip e $archivePath "stringtables/interface_en.str" "-o$tmpDir" -y 2>&1 | Out-Null
        $strFile = Join-Path $tmpDir "interface_en.str"
        if (-not (Test-Path $strFile)) { return }

        # Check marker: is ЛЕСТНИЦА already in the file?
        $bytes = [System.IO.File]::ReadAllBytes($strFile)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        if ($content -match "ЛЕСТНИЦА") {
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
            return  # already patched
        }

        Write-Log "NavPatch: archive was updated, re-patching nav tabs..." "INF"

        # Apply Russian nav tab names
        $content = $content -replace '(?m)^(main_menu_ladder\t+)LADDER\r?$',        '${1}ЛЕСТНИЦА'
        $content = $content -replace '(?m)^(main_menu_leanatorium\t+)LEARN\r?$',    '${1}ОБУЧЕНИЕ'
        $content = $content -replace '(?m)^(main_menu_plinko\t+)PLINKO\r?$',        '${1}ПЛИНКО'
        $content = $content -replace '(?m)^(main_menu_store\t+)STORE\r?$',          '${1}МАГАЗИН'

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($strFile, $content, $utf8NoBom)

        # Stage and update archive
        $stagingDir = Join-Path $tmpDir "staging"
        $stTablesDir = Join-Path $stagingDir "stringtables"
        New-Item -ItemType Directory $stTablesDir -Force | Out-Null
        Copy-Item $strFile (Join-Path $stTablesDir "interface_en.str") -Force

        Push-Location $stagingDir
        & $sevenZip u $archivePath "stringtables\interface_en.str" -r 2>&1 | Out-Null
        Pop-Location

        Write-Log "NavPatch: re-patch complete (ЛЕСТНИЦА/ОБУЧЕНИЕ/ПЛИНКО/МАГАЗИН)" "INF"
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Log "Sync-NavPatch error: $_" "WRN"
    }
}

# ─── Stump mod: auto-repatch resources0.jz after game updates ───────────────
function Sync-StumpMod {
    try {
        $archivePath = Join-Path $gameRoot "resources0.jz"
        if (-not (Test-Path $archivePath)) { return }

        $sevenZip = $null
        foreach ($c in @("C:\Program Files\7-Zip\7z.exe","C:\Program Files (x86)\7-Zip\7z.exe")) {
            if (Test-Path $c) { $sevenZip = $c; break }
        }
        if (-not $sevenZip) { return }

        $buildScript = Join-Path $PackageRoot "build_stump_mod.ps1"
        if (-not (Test-Path $buildScript)) { return }

        # Check if our stump override is already in the archive by looking for a marker entry
        $markerEntry = "world/rprops/trees/legion1/stump.model"
        $listing = & $sevenZip l $archivePath $markerEntry 2>&1 | Out-String

        if ($listing -notmatch 'stump\.model') {
            Write-Log "StumpMod: archive was updated, re-patching..." "INF"
            & powershell -NoProfile -ExecutionPolicy Bypass -File $buildScript -GameRoot $gameRoot 2>&1 | ForEach-Object { Write-Log "StumpMod: $_" "INF" }
            Write-Log "StumpMod: re-patch complete" "INF"
        }
    } catch {
        Write-Log "Sync-StumpMod error: $_" "WRN"
    }
}

# ─── Web override ─────────────────────────────────────────────────────────────
function Sync-WebOverride {
    param([switch]$ForceCopy)
    try {
        if (-not (Test-Path (Join-Path $webOverrideRoot "index.html"))) {
            Prepare-HoNWebOverride -GameRoot $gameRoot -OutputRoot $webOverrideRoot | Out-Null
        }
        $changed = Sync-HoNWebOverride -SourceRoot $webOverrideRoot -GameRoot $gameRoot -ForceCopy:$ForceCopy
        if ($changed) { Write-Log "Sync-WebOverride: files updated (ForceCopy=$ForceCopy)" "INF" }
    } catch {
        Write-Log "Sync-WebOverride error: $_" "WRN"
    }
}

function Test-JuvioRunning {
    return [bool](Get-Process -Name "juvio" -ErrorAction SilentlyContinue | Select-Object -First 1)
}

# --- Version Check & MOTD Notification ---
$lastVersionCheck = [DateTime]::MinValue
$versionCheckIntervalHours = 12
$localVersionFile = Join-Path $PackageRoot "version.txt"
$cachedUpdateMsg = ""

function Check-RemoteUpdate {
    if (-not (Test-Path $localVersionFile)) { return }
    $localVerStr = (Get-Content $localVersionFile -Raw).Trim()
    
    try {
        $wr = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Xyling12/HoN_RU_Pack/master/version.txt" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        $remoteVerStr = $wr.Content.Trim()
        
        # Strip letter suffix (e.g. '1.9.9l' → '1.9.9') for System.Version compatibility
        $lvStr = $localVerStr  -replace '[a-zA-Z]+$',''
        $rvStr = $remoteVerStr -replace '[a-zA-Z]+$',''
        $lv = [version]$lvStr
        $rv = [version]$rvStr
        
        if ($rv -gt $lv) {
            $msg = "^r[RU Pack] D0ступн0 o6нoвлeниe: v" + $remoteVerStr + " !^* Cкачайте новую версию на ^obooky.to/xyling^*"
            if ($msg -ne $script:cachedUpdateMsg) {
                $script:cachedUpdateMsg = $msg
                Write-Log "Update available: $remoteVerStr (Local: $localVerStr)" "INF"
                return $true
            }
        } else {
            if ($script:cachedUpdateMsg -ne "") {
                $script:cachedUpdateMsg = ""
                return $true
            }
        }
    } catch {
        Write-Log "Check-RemoteUpdate failed: $_" "WRN"
    }
    return $false
}

function Apply-UpdateMOTD {
    if ([string]::IsNullOrEmpty($script:cachedUpdateMsg)) { return }
    
    foreach ($target in $strTargets) {
        $interfaceFile = Join-Path $target "interface_en.str"
        if (Test-Path $interfaceFile) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($interfaceFile)
                $content = [System.Text.Encoding]::UTF8.GetString($bytes)
                
                # Check if it already has the exact message
                if ($content -match "\[RU Pack\].*?$($script:cachedUpdateMsg)") { continue }
                
                $motdLine = "mainlogin_motd_title`t`t$($script:cachedUpdateMsg)"
                
                if ($content -notmatch "mainlogin_motd_title") {
                    $motdBytes = [System.Text.Encoding]::UTF8.GetBytes("`n$motdLine`n")
                    $newBytes = [byte[]]::new($bytes.Length + $motdBytes.Length)
                    [System.Array]::Copy($bytes, 0, $newBytes, 0, $bytes.Length)
                    [System.Array]::Copy($motdBytes, 0, $newBytes, $bytes.Length, $motdBytes.Length)
                    [System.IO.File]::WriteAllBytes($interfaceFile, $newBytes)
                } else {
                    $newContent = [Regex]::Replace($content, '(?m)^mainlogin_motd_title\s*.*?$', $motdLine)
                    # Hack: since we don't have GetBytes that removes BOM reliably, we just write it without BOM
                    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    [System.IO.File]::WriteAllText($interfaceFile, $newContent, $utf8NoBom)
                }
            } catch {
                Write-Log "Apply-UpdateMOTD error: $_" "WRN"
            }
        }
    }
}

# ─── Bootstrap ────────────────────────────────────────────────────────────────
$lastLocaleRefresh = [DateTime]::MinValue
$lastWebOverride   = [DateTime]::MinValue
$launchBurstUntil  = [DateTime]::MinValue
$lastIdleSync      = [DateTime]::MinValue
$wasRunning        = $false

Write-Log "Bootstrap sync..." "INF"
try { Sync-Strings -Force } catch { Write-Log "Bootstrap Sync-Strings error: $_" "WRN" }
try { Sync-WebOverride -ForceCopy } catch { Write-Log "Bootstrap Sync-WebOverride error: $_" "WRN" }
try { Sync-LocaleConfig } catch { Write-Log "Bootstrap Sync-LocaleConfig error: $_" "WRN" }
try { Sync-StumpMod } catch { Write-Log "Bootstrap Sync-StumpMod error: $_" "WRN" }
try { Sync-NavPatch } catch { Write-Log "Bootstrap Sync-NavPatch error: $_" "WRN" }

if (Check-RemoteUpdate) { Apply-UpdateMOTD }
$lastVersionCheck = Get-Date

$lastLocaleRefresh = Get-Date
Write-Log "Bootstrap done. FSW active. Entering main loop." "INF"

# ─── Main loop ────────────────────────────────────────────────────────────────
while ($true) {
    try {
        $now       = Get-Date
        $isRunning = Test-JuvioRunning

        if ($isRunning) {
            if (-not $wasRunning) {
                Write-Log "Juvio LAUNCHED - burst sync" "INF"
                $launchBurstUntil = $now.AddSeconds($LaunchBurstSeconds)
                # Force-write all strings immediately on launch (catch any FSW miss)
                try { Sync-Strings -Force } catch { Write-Log "Launch Sync-Strings error: $_" "WRN" }
                try { Sync-WebOverride -ForceCopy } catch { Write-Log "Launch Sync-WebOverride error: $_" "WRN" }
                try { Sync-LocaleConfig } catch { Write-Log "Launch Sync-LocaleConfig error: $_" "WRN" }
                try { Sync-StumpMod } catch { Write-Log "Launch Sync-StumpMod error: $_" "WRN" }
                try { Sync-NavPatch } catch { Write-Log "Launch Sync-NavPatch error: $_" "WRN" }
                $lastLocaleRefresh = $now
                $lastWebOverride   = $now
            } else {
                # Running: size-check sync (FSW handles instant restores)
                try { Sync-Strings } catch {}

                $inBurst = ($now -lt $launchBurstUntil)
                if ($inBurst -and ($now - $lastWebOverride).TotalSeconds -ge 10) {
                    try { Sync-WebOverride -ForceCopy } catch {}
                    $lastWebOverride = $now
                } elseif (-not $inBurst) {
                    try { Sync-WebOverride } catch {}
                }

                if (($now - $lastLocaleRefresh).TotalSeconds -ge $LocaleRefreshSeconds) {
                    try { Sync-LocaleConfig } catch {}
                    $lastLocaleRefresh = $now
                }
            }

            $sleepMs = if ($now -lt $launchBurstUntil) { $LaunchSyncDelayMilliseconds } else { $RunningSyncDelayMilliseconds }
        } else {
            if ($wasRunning) {
                Write-Log "Juvio STOPPED - final sync" "INF"
                try { Sync-Strings -Force } catch {}
                try { Sync-WebOverride -ForceCopy } catch {}
                try { Sync-LocaleConfig } catch {}
                $lastLocaleRefresh = $now
                $lastWebOverride   = $now
            } else {
                # Idle: size-check sync, but throttled to once every 30s to avoid feedback loop
                if (($now - $lastIdleSync).TotalSeconds -ge 30) {
                    try { Sync-Strings } catch {}
                    $lastIdleSync = $now
                }
                
                # Update Check (every 12 hours)
                if (($now - $lastVersionCheck).TotalHours -ge $versionCheckIntervalHours) {
                    Write-Log "Running periodic version check..." "INF"
                    if (Check-RemoteUpdate) {
                        try { Sync-Strings -Force } catch {}
                        Apply-UpdateMOTD
                    }
                    $lastVersionCheck = $now
                }
                
                if (($now - $lastLocaleRefresh).TotalSeconds -ge $LocaleRefreshSeconds) {
                    try { Sync-LocaleConfig } catch {}
                    $lastLocaleRefresh = $now
                }
            }
            $sleepMs = $IdleDelayMilliseconds
        }

        $wasRunning = $isRunning
        Start-Sleep -Milliseconds $sleepMs
    } catch {
        Write-Log "MAIN LOOP ERROR: $_" "ERR"
        Start-Sleep -Milliseconds 3000
    }
}
