param(
    [string]$GameRoot,
    [string]$BundleDir,
    [switch]$NoBackup
)
$ErrorActionPreference = "Stop"

$archive = Join-Path $GameRoot "resources0.jz"
if (-not (Test-Path $archive)) { throw "resources0.jz not found at $GameRoot" }

$sevenZip = $null
foreach ($c in @("C:\Program Files\7-Zip\7z.exe","C:\Program Files (x86)\7-Zip\7z.exe")) {
    if (Test-Path $c) { $sevenZip = $c; break }
}
if (-not $sevenZip) { throw "7-Zip not found" }

# Backup
if (-not $NoBackup) {
    $backup = "$archive.bak"
    if (-not (Test-Path $backup)) {
        Copy-Item $archive $backup -Force
        Write-Host "[Patch] Backup: $backup"
    }
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) "hon_str_patch"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
New-Item "$tmp\archive" -Force -ItemType Directory | Out-Null

# Extract original _en.str from archive
& $sevenZip e $archive "stringtables\*_en.str" "-o$tmp\archive" -y 2>&1 | Out-Null

$bases = @("entities","interface","client_messages","game_messages","bot_messages")
$totalMerged = 0

foreach ($base in $bases) {
    $archiveFile = Join-Path "$tmp\archive" ($base + "_en.str")
    $bundleFile = Join-Path $BundleDir ($base + "_en.str")
    if (-not (Test-Path $archiveFile) -or -not (Test-Path $bundleFile)) { continue }

    $ruMap = @{}
    $bLines = [System.IO.File]::ReadAllLines($bundleFile, [System.Text.Encoding]::UTF8)
    foreach ($line in $bLines) {
        if ($line.StartsWith("//") -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $tabPos = $line.IndexOf("`t")
        if ($tabPos -lt 0) { continue }
        $key = $line.Substring(0, $tabPos).Trim()
        $val = $line.Substring($tabPos).Trim()
        if ($val.Length -gt 0) { $ruMap[$key] = $val }
    }

    $aLines = [System.IO.File]::ReadAllLines($archiveFile, [System.Text.Encoding]::UTF8)
    $merged = 0
    for ($i = 0; $i -lt $aLines.Count; $i++) {
        $aLine = $aLines[$i]
        if ($aLine.StartsWith("//") -or [string]::IsNullOrWhiteSpace($aLine)) { continue }
        $tabPos = $aLine.IndexOf("`t")
        if ($tabPos -lt 0) { continue }
        $aKey = $aLine.Substring(0, $tabPos).Trim()
        if ($ruMap.ContainsKey($aKey) -and $ruMap[$aKey].Length -gt 0) {
            $aLines[$i] = $aKey + "`t`t" + $ruMap[$aKey]
            $merged++
        }
    }

    $bom = [byte[]]@(0xEF,0xBB,0xBF)
    $noBom = New-Object System.Text.UTF8Encoding($false)
    $out = ($aLines -join "`r`n")
    [System.IO.File]::WriteAllBytes($archiveFile, $bom + $noBom.GetBytes($out))
    Write-Host "[Patch] $($base)_en.str : $merged keys"
    $totalMerged += $merged
}

# Stage and update archive
New-Item "$tmp\staging\stringtables" -Force -ItemType Directory | Out-Null
Copy-Item "$tmp\archive\*_en.str" "$tmp\staging\stringtables\" -Force

Push-Location "$tmp\staging"
& $sevenZip u $archive "stringtables" -r 2>&1 | Out-Null
Pop-Location

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[Patch] Done: $totalMerged keys total"
