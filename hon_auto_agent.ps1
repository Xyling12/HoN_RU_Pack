param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [int]$LoopDelaySeconds = 2
)

$ErrorActionPreference = "Stop"

$trackedBases = @(
    "entities",
    "interface",
    "client_messages",
    "game_messages",
    "bot_messages"
)

$sourceDir = Join-Path $PackageRoot "bundle"
$startupLog = Join-Path $PackageRoot "agent.log"

function Write-Log([string]$message) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $message"
    Add-Content -Path $startupLog -Value $line -Encoding UTF8
}

. "$PSScriptRoot\hon_common.ps1"

function Get-SourceMeta([string]$dirPath) {
    function Get-Sha256([string]$path) {
        return (Get-FileHash -Path $path -Algorithm SHA256).Hash
    }

    $map = @{}
    foreach ($base in $trackedBases) {
        $candidate = Join-Path $dirPath ($base + "_en.str")
        if (-not (Test-Path $candidate)) {
            throw "Missing source file: $candidate"
        }
        $map[$base] = [pscustomobject]@{
            Path = $candidate
            Length = (Get-Item $candidate).Length
            Hash = Get-Sha256 -path $candidate
        }
    }
    return $map
}

function Copy-SourceSetToTarget([string]$targetDir, $sourceMap) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    foreach ($base in $trackedBases) {
        $src = $sourceMap[$base].Path
        foreach ($name in @(
            ($base + ".str"),
            ($base + "_en.str"),
            ($base + "_ru.str"),
            ($base + "_th.str")
        )) {
            $dst = Join-Path $targetDir $name
            Copy-Item -Path $src -Destination $dst -Force
        }
    }
}

function Ensure-SourceSetInTarget([string]$targetDir, $sourceMap) {
    function Get-Sha256([string]$path) {
        return (Get-FileHash -Path $path -Algorithm SHA256).Hash
    }

    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    foreach ($base in $trackedBases) {
        $srcMeta = $sourceMap[$base]
        $src = $srcMeta.Path
        $srcLength = $srcMeta.Length
        $srcHash = $srcMeta.Hash
        foreach ($name in @(
            ($base + ".str"),
            ($base + "_en.str"),
            ($base + "_ru.str"),
            ($base + "_th.str")
        )) {
            $dst = Join-Path $targetDir $name
            $needsCopy = $true
            if (Test-Path $dst) {
                $dstLength = (Get-Item $dst).Length
                if ($dstLength -eq $srcLength) {
                    $dstHash = Get-Sha256 -path $dst
                    if ($dstHash -eq $srcHash) {
                        $needsCopy = $false
                    }
                }
            }
            if ($needsCopy) {
                Copy-Item -Path $src -Destination $dst -Force
                Write-Log "Restored: $dst"
            }
        }
    }
}

function Force-EnglishLocale([string]$startupCfgPath) {
    if (-not (Test-Path $startupCfgPath)) { return }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $text = [System.IO.File]::ReadAllText($startupCfgPath)
    $updated = $text
    $updated = [Regex]::Replace($updated, 'SetSave "host_locale" "[^"]*"', 'SetSave "host_locale" "en"')
    $updated = [Regex]::Replace($updated, 'SetSave "host_backuplocale" "[^"]*"', 'SetSave "host_backuplocale" "en"')
    $updated = [Regex]::Replace($updated, 'SetSave "language" "[^"]*"', 'SetSave "language" "en"')
    if ($updated -ne $text) {
        [System.IO.File]::WriteAllText($startupCfgPath, $updated, $utf8NoBom)
        Write-Log "startup.cfg normalized to en."
    }
}

function Clear-CacheIfExists([string]$dirPath, [string]$label) {
    if (-not (Test-Path $dirPath)) { return }
    Get-ChildItem -Path $dirPath -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log ("Cleared {0}: {1}" -f $label, $dirPath)
}

try {
    if (-not (Test-Path $sourceDir)) {
        throw "Bundle folder not found: $sourceDir"
    }
    $sourceMap = Get-SourceMeta -dirPath $sourceDir

    $pathsOverride = Join-Path $PackageRoot "hon_paths_override.ps1"
    if (Test-Path $pathsOverride) { . $pathsOverride }

    $docsRoot = if ($HoNDocsRoot) { $HoNDocsRoot } else { Find-HoNDocsRoot }
    $localRoot = if ($HoNLocalRoot) { $HoNLocalRoot } else { Find-HoNLocalRoot }

    if (-not $docsRoot) { $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth" }
    if (-not $localRoot) { $localRoot = Join-Path $env:USERPROFILE "AppData\Local\Juvio\heroes of newerth" }

    $targets = @(
        (Join-Path $docsRoot "stringtables"),
        (Join-Path $docsRoot "game\stringtables"),
        (Join-Path $localRoot "stringtables"),
        (Join-Path $localRoot "game\stringtables")
    )
    $startupCfg = Join-Path $docsRoot "startup.cfg"
    $fileCacheDir = Join-Path $docsRoot "filecache"
    $webCacheDir = Join-Path $docsRoot "webcache"

    Write-Log "Agent start. DocsRoot=$docsRoot LocalRoot=$localRoot"

    foreach ($target in $targets) {
        Copy-SourceSetToTarget -targetDir $target -sourceMap $sourceMap
        Write-Log "Initial sync: $target"
    }
    Force-EnglishLocale -startupCfgPath $startupCfg
    Clear-CacheIfExists -dirPath $fileCacheDir -label "filecache"
    Clear-CacheIfExists -dirPath $webCacheDir -label "webcache"

    $lastLocaleFix = Get-Date
    while ($true) {
        foreach ($target in $targets) {
            Ensure-SourceSetInTarget -targetDir $target -sourceMap $sourceMap
        }
        if (((Get-Date) - $lastLocaleFix).TotalMinutes -ge 10) {
            Force-EnglishLocale -startupCfgPath $startupCfg
            $lastLocaleFix = Get-Date
        }
        Start-Sleep -Seconds $LoopDelaySeconds
    }
} catch {
    Write-Log ("Agent error: " + $_.Exception.Message)
    throw
}
