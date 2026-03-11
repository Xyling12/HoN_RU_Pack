param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Read-JsonFile($path) {
    if (-not (Test-Path $path)) {
        throw "Config not found: $path"
    }
    return Get-Content $path -Raw | ConvertFrom-Json
}

. "$PSScriptRoot\hon_common.ps1"

function Get-FileSha256($path) {
    return (Get-FileHash $path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Resolve-PackageRoot($extractDir) {
    $directMarker = Join-Path $extractDir "install_hon_ru_pack.ps1"
    $directBundle = Join-Path $extractDir "bundle"
    if ((Test-Path $directMarker) -and (Test-Path $directBundle)) {
        return $extractDir
    }

    $dirs = Get-ChildItem $extractDir -Directory
    if ($dirs.Count -eq 1) {
        $candidate = $dirs[0].FullName
        $nestedMarker = Join-Path $candidate "install_hon_ru_pack.ps1"
        $nestedBundle = Join-Path $candidate "bundle"
        if ((Test-Path $nestedMarker) -and (Test-Path $nestedBundle)) {
            return $candidate
        }
    }

    throw "Cannot detect package root inside extracted archive."
}

function Copy-Package($srcRoot, $dstRoot) {
    $items = Get-ChildItem $srcRoot -Force
    foreach ($item in $items) {
        $target = Join-Path $dstRoot $item.Name

        # Preserve user-specific path override.
        if ($item.Name -ieq "hon_paths_override.ps1" -and (Test-Path $target)) {
            Write-Host "Preserved local hon_paths_override.ps1"
            continue
        }

        Copy-Item $item.FullName -Destination $target -Recurse -Force
    }
}

$root = $PSScriptRoot
$configPath = Join-Path $root "update_config.json"
$localVersionPath = Join-Path $root "version.txt"

$config = Read-JsonFile $configPath

$zipUrl = ""
$remoteVersion = ""
$remoteSha256 = ""

$manifestUrl = ""
if ($null -ne $config.manifest_url) {
    $manifestUrl = [string]$config.manifest_url
}

if (-not [string]::IsNullOrWhiteSpace($manifestUrl)) {
    $manifestUrl = Get-DirectDropboxUrl $manifestUrl
    Write-Host ("Fetching manifest: {0}" -f $manifestUrl)
    $manifest = Invoke-RestMethod -Uri $manifestUrl -Method Get

    $zipUrl = Get-DirectDropboxUrl ([string]$manifest.download_url)
    $remoteVersion = [string]$manifest.version
    $remoteSha256 = [string]$manifest.sha256
} else {
    $zipUrl = Get-DirectDropboxUrl ([string]$config.latest_zip_url)
    if ($null -ne $config.latest_version) {
        $remoteVersion = [string]$config.latest_version
    }
    if ($null -ne $config.latest_sha256) {
        $remoteSha256 = [string]$config.latest_sha256
    }
}

if ([string]::IsNullOrWhiteSpace($zipUrl)) {
    throw "No download URL configured. Check update_config.json"
}

$localVersion = ""
if (Test-Path $localVersionPath) {
    $localVersion = (Get-Content $localVersionPath -Raw).Trim()
}

if (-not $Force -and -not [string]::IsNullOrWhiteSpace($remoteVersion) -and $remoteVersion -eq $localVersion) {
    Write-Host ("Already up to date. Version: {0}" -f $localVersion)
    exit 0
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("hon_ru_update_" + [guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $tempRoot "update.zip"
$extractDir = Join-Path $tempRoot "extract"
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

try {
    Write-Host ("Downloading: {0}" -f $zipUrl)
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

    if (-not [string]::IsNullOrWhiteSpace($remoteSha256)) {
        $actualSha = Get-FileSha256 $zipPath
        $expectedSha = $remoteSha256.ToUpperInvariant()
        if ($actualSha -ne $expectedSha) {
            throw "SHA256 mismatch. Expected: $expectedSha, actual: $actualSha"
        }
    }

    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    $pkgRoot = Resolve-PackageRoot $extractDir

    Copy-Package -srcRoot $pkgRoot -dstRoot $root

    if (-not [string]::IsNullOrWhiteSpace($remoteVersion)) {
        Set-Content -Path $localVersionPath -Value $remoteVersion -Encoding UTF8
        Write-Host ("Updated to version: {0}" -f $remoteVersion)
    } else {
        Write-Host "Update applied."
    }
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item $tempRoot -Recurse -Force
    }
}
