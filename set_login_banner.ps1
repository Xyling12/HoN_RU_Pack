param(
    [string]$PackageRoot = "",
    [string]$FollowUrl = "https://boosty.to/xyling",
    [string]$Version = "",
    [string]$BannerKey = "main_label_username"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = $PSScriptRoot
}

$root = [System.IO.Path]::GetFullPath($PackageRoot)
$versionPath = Join-Path $root "version.txt"
$configPath = Join-Path $root "update_config.json"
$interfacePath = Join-Path $root "bundle\interface_en.str"

if (-not (Test-Path $interfacePath)) {
    throw "interface_en.str not found: $interfacePath"
}

. "$PSScriptRoot\hon_common.ps1"

function Get-VersionFromZipUrl([string]$url) {
    if ([string]::IsNullOrWhiteSpace($url)) {
        return ""
    }
    $m = [Regex]::Match($url, '(?i)[_\-]v(?<v>\d+(?:\.\d+){1,4}(?:[-_A-Za-z0-9]+)?)')
    if ($m.Success) {
        return $m.Groups["v"].Value
    }
    return ""
}

function Resolve-Version {
    param(
        [string]$ExplicitVersion,
        [string]$VersionFilePath,
        [string]$UpdateConfigPath
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitVersion)) {
        return $ExplicitVersion
    }

    $fileVersion = ""
    if (Test-Path $VersionFilePath) {
        $fileVersion = (Get-Content $VersionFilePath -Raw).Trim()
    }

    $resolved = ""
    if (Test-Path $UpdateConfigPath) {
        try {
            $cfg = Get-Content $UpdateConfigPath -Raw | ConvertFrom-Json

            if ($null -ne $cfg.manifest_url -and -not [string]::IsNullOrWhiteSpace([string]$cfg.manifest_url)) {
                try {
                    $manifestUrl = Get-DirectDropboxUrl ([string]$cfg.manifest_url)
                    $manifest = Invoke-RestMethod -Uri $manifestUrl -Method Get -TimeoutSec 6
                    if ($null -ne $manifest.version -and -not [string]::IsNullOrWhiteSpace([string]$manifest.version)) {
                        $resolved = [string]$manifest.version
                    }
                } catch {
                    # fallback to local values
                }
            }

            if ([string]::IsNullOrWhiteSpace($resolved) -and $null -ne $cfg.latest_version -and -not [string]::IsNullOrWhiteSpace([string]$cfg.latest_version)) {
                $resolved = [string]$cfg.latest_version
            }

            if ([string]::IsNullOrWhiteSpace($resolved) -and $null -ne $cfg.latest_zip_url) {
                $resolved = Get-VersionFromZipUrl ([string]$cfg.latest_zip_url)
            }
        } catch {
            # fallback to local values
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = $fileVersion
    }
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = "0.0.0"
    }

    if ($resolved -ne $fileVersion) {
        Set-Content -Path $VersionFilePath -Value $resolved -Encoding UTF8
        Write-Host ("Synced version.txt: {0}" -f $resolved)
    }

    return $resolved
}

$version = Resolve-Version -ExplicitVersion $Version -VersionFilePath $versionPath -UpdateConfigPath $configPath
$followVisible = $FollowUrl -replace '^https?://', ''
$tipText = "RU localization version: v$version. Updates: $FollowUrl"
$bannerText = "RU v$version | $followVisible"

$lines = [System.IO.File]::ReadAllLines($interfacePath)

$rememberBase = $null
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $m = [Regex]::Match($line, '^(?<k>\S+)(?<sep>[ \t]+)(?<v>.*)$')
    if (-not $m.Success) {
        continue
    }
    if ($m.Groups["k"].Value -eq "main_checkbox_remember_me") {
        $rememberBase = [Regex]::Replace($m.Groups["v"].Value, '\s+\|\s+RU(?:\s+Pack)?\s+v[0-9A-Za-z\.\-_]+(?:\s+\|\s+\S+)?$', '')
        break
    }
}

if ([string]::IsNullOrWhiteSpace($rememberBase)) {
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $m = [Regex]::Match($line, '^(?<k>\S+)(?<sep>[ \t]+)(?<v>.*)$')
        if (-not $m.Success) {
            continue
        }
        if ($m.Groups["k"].Value -eq "main_login_remember_me") {
            $rememberBase = [Regex]::Replace($m.Groups["v"].Value, '\s+\|\s+RU(?:\s+Pack)?\s+v[0-9A-Za-z\.\-_]+(?:\s+\|\s+\S+)?$', '')
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($rememberBase)) {
    $rememberBase = "Remember me"
}

$changed = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $m = [Regex]::Match($line, '^(?<k>\S+)(?<sep>[ \t]+)(?<v>.*)$')
    if (-not $m.Success) {
        continue
    }

    $key = $m.Groups["k"].Value
    $sep = $m.Groups["sep"].Value
    $newVal = $null

    if ($key -eq "main_checkbox_remember_me" -or $key -eq "main_login_remember_me") {
        $newVal = $rememberBase
    }
    elseif ($key -eq "main_login_remember_me_tip") {
        $newVal = $tipText
    }
    elseif ($key -eq $BannerKey) {
        $newVal = $bannerText
    }

    if ($null -ne $newVal) {
        $newLine = "{0}{1}{2}" -f $key, $sep, $newVal
        if ($newLine -ne $line) {
            $lines[$i] = $newLine
            $changed++
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($interfacePath, $lines, $utf8NoBom)

Write-Host ("Updated login banner keys: {0}" -f $changed)
Write-Host ("Version: {0}" -f $version)
Write-Host ("Banner key: {0}" -f $BannerKey)
Write-Host ("File: {0}" -f $interfacePath)
