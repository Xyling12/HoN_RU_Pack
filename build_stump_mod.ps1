param(
    [string]$GameRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\hon_common.ps1"

if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Find-HoNLocalRoot
    if (-not $GameRoot) { throw "HoN installation not found." }
}
Write-Host "[StumpMod] Game root: $GameRoot"

$archivePath = Join-Path $GameRoot "resources0.jz"
if (-not (Test-Path $archivePath)) { throw "resources0.jz not found" }

$sevenZip = $null
foreach ($c in @("C:\Program Files\7-Zip\7z.exe","C:\Program Files (x86)\7-Zip\7z.exe")) {
    if (Test-Path $c) { $sevenZip = $c; break }
}
if (-not $sevenZip) { throw "7-Zip not found." }

$treeTypes = @(
    "ashtree","deadtree1","deadtree2","deepwoodpine","deepwoodpine2",
    "deepwoodtree","deepwoodtreeblue","jungle1","jungle2","jungle3","jungle4",
    "legion1","legion2","legion3","legion4","legion5",
    "lushtree2","swamp1","swamp2","swamp3","waterfalltree1"
)

# --- Backup ---
$backupPath = Join-Path $GameRoot "resources0.jz.bak"
if (-not (Test-Path $backupPath)) {
    Write-Host "[StumpMod] Creating backup ($([math]::Round((Get-Item $archivePath).Length/1GB,1)) GB)..."
    Copy-Item $archivePath $backupPath
    Write-Host "[StumpMod] Backup created: $backupPath"
} else {
    Write-Host "[StumpMod] Backup already exists: $backupPath"
}

# --- Extract stump.model from archive ---
$extractDir = Join-Path ([System.IO.Path]::GetTempPath()) "hon_stump_patch"
if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
New-Item -ItemType Directory $extractDir -Force | Out-Null

Write-Host "[StumpMod] Extracting stump.model..."
& $sevenZip e $archivePath "buildings/neutral/midwars_objective/legion/stump.model" "-o$extractDir" -y | Out-Null
$stumpModelSrc = Join-Path $extractDir "stump.model"
if (-not (Test-Path $stumpModelSrc)) { throw "Failed to extract stump.model" }

# --- Build override directory tree for 7-Zip update ---
# 7z u archive.zip file.txt -si means: update specific files inside archive
# We build a temp dir mirroring the archive's tree structure, then use 7z u

$stagingDir = Join-Path $extractDir "staging"

# MDF content
$stumpMdf = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`r`n<model name=`"stump`" file=`"stump.model`" type=`"K2`">`r`n</model>`r`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($tree in $treeTypes) {
    $treeStaging = Join-Path $stagingDir "world\rprops\trees\$tree"
    New-Item -ItemType Directory $treeStaging -Force | Out-Null

    # model.mdf
    [System.IO.File]::WriteAllText((Join-Path $treeStaging "model.mdf"), $stumpMdf, $utf8NoBom)

    # stump.model
    Copy-Item $stumpModelSrc (Join-Path $treeStaging "stump.model") -Force
}

Write-Host "[StumpMod] Staging dir ready: $stagingDir"
Write-Host "[StumpMod] Updating archive with 7-Zip (updating only changed files)..."

# Use 7z u to update specific files inside the archive
# -r = recurse, work from staging dir
Push-Location $stagingDir
$result = & $sevenZip u $archivePath "." -r 2>&1
Pop-Location

Write-Host $result

Write-Host ""
Write-Host "=========================================="
Write-Host "[StumpMod] Archive patched!"
Write-Host "[StumpMod] Trees replaced: $($treeTypes.Count)"
Write-Host "[StumpMod] Restart HoN to see changes."
Write-Host "[StumpMod] To restore: copy resources0.jz.bak -> resources0.jz"
Write-Host "=========================================="

Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

# Clean up old loose files (from previous attempts)
$oldLooseDir = Join-Path $GameRoot "world\rprops\trees"
if (Test-Path $oldLooseDir) {
    Remove-Item $oldLooseDir -Recurse -Force
    Write-Host "[StumpMod] Removed old loose override files"
}
