# hon_common.ps1 - Shared functions for HoN RU Pack scripts
# Usage: . "$PSScriptRoot\hon_common.ps1"

function Find-HoNLocalRoot {
    # Fixed well-known paths first (fast)
    $searchRoots = @(
        (Join-Path $env:LOCALAPPDATA   "Juvio\heroes of newerth"),
        (Join-Path $env:USERPROFILE    "AppData\Local\Juvio\heroes of newerth"),
        (Join-Path $env:USERPROFILE    "AppData\LocalLow\Juvio\heroes of newerth"),
        "C:\Games\Juvio\heroes of newerth",
        "D:\Games\Juvio\heroes of newerth",
        "E:\Games\Juvio\heroes of newerth",
        "C:\Program Files\Juvio\heroes of newerth",
        "C:\Program Files (x86)\Juvio\heroes of newerth",
        "D:\Program Files\Juvio\heroes of newerth",
        "D:\Program Files (x86)\Juvio\heroes of newerth",
        "D:\Juvio\heroes of newerth",
        "C:\Juvio\heroes of newerth",
        "E:\Juvio\heroes of newerth"
    )
    foreach ($candidate in $searchRoots) {
        try {
            if (((Test-Path (Join-Path $candidate "resources0.jz") -ErrorAction Stop) -or (Test-Path (Join-Path $candidate "resources0.s2z") -ErrorAction Stop) -or (Test-Path (Join-Path $candidate "game\\resources0.s2z") -ErrorAction Stop))) { return $candidate }
        } catch {}
    }

    # Drive scan with multiple sub-path patterns
    $subPaths = @(
        "Juvio\heroes of newerth",
        "Games\Juvio\heroes of newerth",
        "Games\Games\Juvio\heroes of newerth",
        "Program Files\Juvio\heroes of newerth",
        "Program Files (x86)\Juvio\heroes of newerth",
        "HoN\Juvio\heroes of newerth",
        "Software\Juvio\heroes of newerth"
    )
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($sub in $subPaths) {
            $tryPath = Join-Path $drive.Root $sub
            if (((Test-Path (Join-Path $tryPath "resources0.jz")) -or (Test-Path (Join-Path $tryPath "resources0.s2z")) -or (Test-Path (Join-Path $tryPath "game\\resources0.s2z")))) { return $tryPath }
        }
    }

    # Last resort: deep search for resources0.jz (limited depth=5, only game-named dirs)
    foreach ($scanRoot in @("C:\", "D:\", "E:\")) {
        if (-not (Test-Path $scanRoot)) { continue }
        $hit = Get-ChildItem -Path $scanRoot -Include "resources0.jz","resources0.s2z" -Recurse -Depth 5 -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -match "(?i)newerth|juvio" } |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }

    return $null
}

# Returns ALL Juvio game roots found on this machine (not just the first one)
# Use this when you need to sync to every installation (e.g. AppData + E:\Games\Juvio)
function Find-AllHoNLocalRoots {
    $found = [System.Collections.Generic.List[string]]::new()

    $subPaths = @(
        "Juvio\heroes of newerth",
        "Games\Juvio\heroes of newerth",
        "Games\Games\Juvio\heroes of newerth",
        "Program Files\Juvio\heroes of newerth",
        "Program Files (x86)\Juvio\heroes of newerth",
        "HoN\Juvio\heroes of newerth",
        "Software\Juvio\heroes of newerth"
    )

    $extraRoots = @(
        (Join-Path $env:LOCALAPPDATA "Juvio\heroes of newerth"),
        (Join-Path $env:USERPROFILE  "AppData\LocalLow\Juvio\heroes of newerth")
    )
    foreach ($p in $extraRoots) {
        try {
            if ((((Test-Path (Join-Path $p "resources0.jz") -ErrorAction Stop) -or (Test-Path (Join-Path $p "resources0.s2z") -ErrorAction Stop) -or (Test-Path (Join-Path $p "game\\resources0.s2z") -ErrorAction Stop))) -and ($found -notcontains $p)) {
                $found.Add($p)
            }
        } catch {}
    }

    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($sub in $subPaths) {
            $p = Join-Path $drive.Root $sub
            if ((((Test-Path (Join-Path $p "resources0.jz")) -or (Test-Path (Join-Path $p "resources0.s2z")) -or (Test-Path (Join-Path $p "game\\resources0.s2z")))) -and ($found -notcontains $p)) {
                $found.Add($p)
            }
        }
    }

    if ($found.Count -eq 0) {
        # Fallback: deep search
        foreach ($scanRoot in @("C:\", "D:\", "E:\", "F:\")) {
            if (-not (Test-Path $scanRoot)) { continue }
            Get-ChildItem -Path $scanRoot -Include "resources0.jz","resources0.s2z" -Recurse -Depth 5 -ErrorAction SilentlyContinue |
                Where-Object { $_.DirectoryName -match "(?i)newerth|juvio" } |
                ForEach-Object { if ($found -notcontains $_.DirectoryName) { $found.Add($_.DirectoryName) } }
        }
    }

    return $found.ToArray()
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
# Web UI override functions removed (caused ZStd/method-93 errors on new game versions, UI not translated)
