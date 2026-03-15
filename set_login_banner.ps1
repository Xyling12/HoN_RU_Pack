param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\hon_common.ps1"

$docsRoot = Find-HoNDocsRoot
if (-not $docsRoot) { $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth" }
$startupCfg = Join-Path $docsRoot "startup.cfg"

$versionFile = Join-Path $PackageRoot "version.txt"
if (-not (Test-Path $versionFile)) { $versionFile = Join-Path $PSScriptRoot "version.txt" }
$version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "?" }
$banner = "RU v$version | boosty.to/xyling"

if (Test-Path $startupCfg) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $cfgText = [System.IO.File]::ReadAllText($startupCfg)
    if ($cfgText -match 'SetSave "ui_login_banner"') {
        $cfgUpdated = [Regex]::Replace($cfgText, 'SetSave "ui_login_banner" "[^"]*"', "SetSave `"ui_login_banner`" `"$banner`"")
    } else {
        $cfgUpdated = $cfgText + "`r`nSetSave `"ui_login_banner`" `"$banner`""
    }
    
    if ($cfgUpdated -ne $cfgText) {
        [System.IO.File]::WriteAllText($startupCfg, $cfgUpdated, $utf8NoBom)
    }
}
