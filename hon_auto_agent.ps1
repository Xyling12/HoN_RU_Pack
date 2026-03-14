param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\hon_common.ps1"

$docsRoot = Find-HoNDocsRoot
if (-not $docsRoot) { $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth" }

$gameRoot = Find-HoNLocalRoot
if (-not $gameRoot) { $gameRoot = Join-Path $env:LOCALAPPDATA "Juvio\heroes of newerth" }

$dataBundle = Join-Path $PackageRoot "bundle"
$localeVariants = @(".str", "_en.str", "_ru.str", "_th.str")
$strBases = @("entities", "interface", "client_messages", "game_messages", "bot_messages")

$strTargets = @(
    (Join-Path $docsRoot "stringtables"),
    (Join-Path $docsRoot "game\stringtables"),
    (Join-Path $gameRoot "stringtables"),
    (Join-Path $gameRoot "game\stringtables")
)

# Mod bundle path - game may wipe this on startup, agent must recreate it
$modBundle = Join-Path $gameRoot "mod\HoN_RU_Pack\bundle"

function Sync-Strings {
    # Sync to stringtable directories (all locale variants)
    foreach ($target in $strTargets) {
        if (-not (Test-Path $target)) { continue }
        foreach ($base in $strBases) {
            $src = Join-Path $dataBundle ($base + "_en.str")
            if (Test-Path $src) {
                foreach ($suffix in $localeVariants) {
                    $dst = Join-Path $target ($base + $suffix)
                    if (Test-Path $dst) {
                        try {
                            $srcHash = (Get-FileHash $src -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                            $dstHash = (Get-FileHash $dst -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                            if ($srcHash -and $dstHash -and ($srcHash -ne $dstHash)) {
                                Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
                            }
                        } catch { }
                    } else {
                        Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
    
    # Sync to mod bundle (only _en.str, recreate dir if game deleted it)
    if (-not (Test-Path $modBundle)) {
        New-Item -ItemType Directory -Path $modBundle -Force -ErrorAction SilentlyContinue | Out-Null
    }
    foreach ($base in $strBases) {
        $src = Join-Path $dataBundle ($base + "_en.str")
        if (Test-Path $src) {
            $dst = Join-Path $modBundle ($base + "_en.str")
            try {
                $srcHash = (Get-FileHash $src -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                $dstHash = if (Test-Path $dst) { (Get-FileHash $dst -Algorithm MD5 -ErrorAction SilentlyContinue).Hash } else { "" }
                if ($srcHash -ne $dstHash) {
                    Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
                }
            } catch { }
        }
    }
}

while ($true) {
    Sync-Strings
    Start-Sleep -Seconds 10
}

