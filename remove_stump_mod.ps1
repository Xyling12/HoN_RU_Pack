param(
    [string]$GameRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\hon_common.ps1"

if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Find-HoNLocalRoot
    if (-not $GameRoot) { throw "HoN installation not found. Specify -GameRoot manually." }
}

$treesDir = Join-Path $GameRoot "world\rprops\trees"
if (Test-Path $treesDir) {
    Remove-Item -Path $treesDir -Recurse -Force
    Write-Host "[StumpMod] Removed: $treesDir"
    Write-Host "[StumpMod] Restart HoN to restore original trees."
} else {
    Write-Host "[StumpMod] No stump mod found at: $treesDir"
}

# Also remove old archive if present
$oldArchive = Join-Path $GameRoot "resources999.s2z"
if (Test-Path $oldArchive) { Remove-Item $oldArchive -Force; Write-Host "[StumpMod] Removed old resources999.s2z" }
