# hon_common.ps1 - Shared functions for HoN RU Pack scripts
# Usage: . "$PSScriptRoot\hon_common.ps1"

function Find-HoNLocalRoot {
    $searchRoots = @(
        (Join-Path $env:USERPROFILE "AppData\Local\Juvio\heroes of newerth"),
        "C:\Games\Juvio\heroes of newerth",
        "D:\Games\Juvio\heroes of newerth",
        "C:\Program Files\Juvio\heroes of newerth",
        "C:\Program Files (x86)\Juvio\heroes of newerth",
        "D:\Juvio\heroes of newerth",
        "C:\Juvio\heroes of newerth"
    )
    foreach ($candidate in $searchRoots) {
        if (Test-Path (Join-Path $candidate "resources0.jz")) { return $candidate }
    }
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {
        $tryPath = Join-Path $drive.Root "Juvio\heroes of newerth"
        if (Test-Path (Join-Path $tryPath "resources0.jz")) { return $tryPath }
        $tryPath2 = Join-Path $drive.Root "Games\Juvio\heroes of newerth"
        if (Test-Path (Join-Path $tryPath2 "resources0.jz")) { return $tryPath2 }
    }
    return $null
}

function Find-HoNDocsRoot {
    $searchRoots = @(
        (Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth"),
        (Join-Path $env:USERPROFILE "Documents\Heroes of Newerth"),
        (Join-Path $env:USERPROFILE "AppData\Local\Juvio\Heroes of Newerth")
    )
    foreach ($candidate in $searchRoots) {
        if (Test-Path (Join-Path $candidate "startup.cfg")) { return $candidate }
    }

    $deepRoots = @(
        (Join-Path $env:USERPROFILE "Documents"),
        (Join-Path $env:USERPROFILE "AppData\Local")
    )
    foreach ($root in $deepRoots) {
        if (-not (Test-Path $root)) { continue }
        $hit = Get-ChildItem -Path $root -Recurse -Filter "startup.cfg" -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -match "(?i)heroes.of.newerth" } |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

function Get-DirectDropboxUrl([string]$url) {
    if ([string]::IsNullOrWhiteSpace($url)) {
        return $url
    }
    if ($url -match "dropbox\.com") {
        if ($url -match "\?") {
            $clean = $url -replace "([&?])dl=0", ""
            if ($clean -match "\?") {
                return ($clean + "&dl=1")
            }
            return ($clean + "?dl=1")
        }
        return ($url + "?dl=1")
    }
    return $url
}
