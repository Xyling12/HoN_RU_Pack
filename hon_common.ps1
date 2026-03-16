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
            if (Test-Path (Join-Path $candidate "resources0.jz") -ErrorAction Stop) { return $candidate }
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
            if (Test-Path (Join-Path $tryPath "resources0.jz")) { return $tryPath }
        }
    }

    # Last resort: deep search for resources0.jz (limited depth=5, only game-named dirs)
    foreach ($scanRoot in @("C:\", "D:\", "E:\")) {
        if (-not (Test-Path $scanRoot)) { continue }
        $hit = Get-ChildItem -Path $scanRoot -Filter "resources0.jz" -Recurse -Depth 5 -ErrorAction SilentlyContinue |
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
            if ((Test-Path (Join-Path $p "resources0.jz") -ErrorAction Stop) -and ($found -notcontains $p)) {
                $found.Add($p)
            }
        } catch {}
    }

    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($sub in $subPaths) {
            $p = Join-Path $drive.Root $sub
            if ((Test-Path (Join-Path $p "resources0.jz")) -and ($found -notcontains $p)) {
                $found.Add($p)
            }
        }
    }

    if ($found.Count -eq 0) {
        # Fallback: deep search
        foreach ($scanRoot in @("C:\", "D:\", "E:\", "F:\")) {
            if (-not (Test-Path $scanRoot)) { continue }
            Get-ChildItem -Path $scanRoot -Filter "resources0.jz" -Recurse -Depth 5 -ErrorAction SilentlyContinue |
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
function Get-HoNWebOverrideJsReplacements {
    return @(
        [pscustomobject]@{ Source = '"Username"'; Target = '"\u0418\u043c\u044f \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f"' }
        [pscustomobject]@{ Source = '"Password"'; Target = '"\u041f\u0430\u0440\u043e\u043b\u044c"' }
        [pscustomobject]@{ Source = '"Remember Me"'; Target = '"\u0417\u0430\u043f\u043e\u043c\u043d\u0438\u0442\u044c \u043c\u0435\u043d\u044f"' }
        [pscustomobject]@{ Source = '"Login"'; Target = '"\u0412\u043e\u0439\u0442\u0438"' }
        [pscustomobject]@{ Source = '"Message of the Day"'; Target = '"\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435 \u0434\u043d\u044f"' }
        [pscustomobject]@{ Source = '"Latest Updates"'; Target = '"\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"' }
        [pscustomobject]@{ Source = '"Quick Links"'; Target = '"\u0411\u044b\u0441\u0442\u0440\u044b\u0435 \u0441\u0441\u044b\u043b\u043a\u0438"' }
        [pscustomobject]@{ Source = '"Join the community"'; Target = '"\u041f\u0440\u0438\u0441\u043e\u0435\u0434\u0438\u043d\u044f\u0439\u0442\u0435\u0441\u044c \u043a \u0441\u043e\u043e\u0431\u0449\u0435\u0441\u0442\u0432\u0443"' }
        [pscustomobject]@{ Source = '"Website"'; Target = '"\u0421\u0430\u0439\u0442"' }
        [pscustomobject]@{ Source = '"Support"'; Target = '"\u041f\u043e\u0434\u0434\u0435\u0440\u0436\u043a\u0430"' }
        [pscustomobject]@{ Source = '"Get help"'; Target = '"\u041f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u043f\u043e\u043c\u043e\u0449\u044c"' }
        [pscustomobject]@{ Source = '"Watch on Twitch"'; Target = '"\u0421\u043c\u043e\u0442\u0440\u0435\u0442\u044c \u043d\u0430 Twitch"' }
        [pscustomobject]@{ Source = '"View Announcement"'; Target = '"\u041e\u0442\u043a\u0440\u044b\u0442\u044c \u0430\u043d\u043e\u043d\u0441"' }
        [pscustomobject]@{ Source = '"Read Patch Notes"'; Target = '"\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439"' }
        [pscustomobject]@{ Source = '"Vote Now"'; Target = '"\u0413\u043e\u043b\u043e\u0441\u043e\u0432\u0430\u0442\u044c"' }
        [pscustomobject]@{ Source = '"A new update is available!"'; Target = '"\u0414\u043e\u0441\u0442\u0443\u043f\u043d\u043e \u043d\u043e\u0432\u043e\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435!"' }
        [pscustomobject]@{ Source = '"Downloading update"'; Target = '"\u0417\u0430\u0433\u0440\u0443\u0437\u043a\u0430 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"' }
        [pscustomobject]@{ Source = '"Check for update"'; Target = '"\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"' }
        [pscustomobject]@{ Source = '"Update now"'; Target = '"\u041e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u0441\u0435\u0439\u0447\u0430\u0441"' }
        [pscustomobject]@{ Source = '"Number of active download jobs:"'; Target = '"\u0410\u043a\u0442\u0438\u0432\u043d\u044b\u0445 \u0437\u0430\u0433\u0440\u0443\u0437\u043e\u043a:"' }
        [pscustomobject]@{ Source = '"Current download size:"'; Target = '"\u0420\u0430\u0437\u043c\u0435\u0440 \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0438:"' }
        [pscustomobject]@{ Source = '"Downloaded:"'; Target = '"\u0417\u0430\u0433\u0440\u0443\u0436\u0435\u043d\u043e:"' }
        [pscustomobject]@{ Source = '"Download speed:"'; Target = '"\u0421\u043a\u043e\u0440\u043e\u0441\u0442\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0438:"' }
        [pscustomobject]@{ Source = '"Version:"'; Target = '"\u0412\u0435\u0440\u0441\u0438\u044f:"' }
        [pscustomobject]@{ Source = '"Update size:"'; Target = '"\u0420\u0430\u0437\u043c\u0435\u0440 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f:"' }
    )
}

function Get-HoNRemoteMotdReplacements {
    return @(
        [pscustomobject]@{ Source = "Message of the Day"; Target = "\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435 \u0434\u043d\u044f" }
        [pscustomobject]@{ Source = "Latest Updates"; Target = "\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f" }
        [pscustomobject]@{ Source = "Quick Links"; Target = "\u0411\u044b\u0441\u0442\u0440\u044b\u0435 \u0441\u0441\u044b\u043b\u043a\u0438" }
        [pscustomobject]@{ Source = "Join the community"; Target = "\u041f\u0440\u0438\u0441\u043e\u0435\u0434\u0438\u043d\u044f\u0439\u0442\u0435\u0441\u044c \u043a \u0441\u043e\u043e\u0431\u0449\u0435\u0441\u0442\u0432\u0443" }
        [pscustomobject]@{ Source = "Website"; Target = "\u0421\u0430\u0439\u0442" }
        [pscustomobject]@{ Source = "Support"; Target = "\u041f\u043e\u0434\u0434\u0435\u0440\u0436\u043a\u0430" }
        [pscustomobject]@{ Source = "Get help"; Target = "\u041f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u043f\u043e\u043c\u043e\u0449\u044c" }
        [pscustomobject]@{ Source = "Upcoming"; Target = "\u0421\u043a\u043e\u0440\u043e" }
        [pscustomobject]@{ Source = "Vote Now"; Target = "\u0413\u043e\u043b\u043e\u0441\u043e\u0432\u0430\u0442\u044c" }
        [pscustomobject]@{ Source = "'Vote Now'"; Target = "'\u0413\u043e\u043b\u043e\u0441\u043e\u0432\u0430\u0442\u044c'" }
        [pscustomobject]@{ Source = "'Read Patch Notes'"; Target = "'\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439'" }
        [pscustomobject]@{ Source = "'Event'"; Target = "'\u0421\u043e\u0431\u044b\u0442\u0438\u0435'" }
        [pscustomobject]@{ Source = "'Patch'"; Target = "'\u041f\u0430\u0442\u0447'" }
    )
}

function Prepare-HoNWebOverride {
    param(
        [string]$GameRoot,
        [string]$OutputRoot
    )

    $archivePath = Join-Path $GameRoot "resources0.jz"
    if (-not (Test-Path $archivePath)) { return $false }

    $entries = @(
        "html/auto-load.js",
        "preact/dist/index.html",
        "preact/dist/index.js",
        "preact/dist/assets/index.css",
        "preact-remote/index.html",
        "preact-remote/src/main.tsx",
        "preact-remote/src/app.tsx",
        "preact-remote/src/compat/engine.ts",
        "preact-remote/src/components/motd.tsx",
        "preact-remote/src/components/motd.css",
        "preact-remote/src/styles/global.css"
    )

    $extractRoot = Join-Path $env:TEMP "hon_ru_web_override_extract"
    if (Test-Path $extractRoot) {
        Remove-Item -Path $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
        foreach ($entry in $zip.Entries) {
            # Convert backslash to forward slash for standard matching
            $entryName = $entry.FullName -replace '\\', '/'
            if ($entries -contains $entryName) {
                $destFile = Join-Path $extractRoot $entry.FullName
                $destDir = Split-Path $destFile
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destFile, $true)
            }
        }
        $zip.Dispose()
    } catch {
        Write-Host "[WRN] Failed to extract Web UI resources: $_"
        return $false
    }

    $srcIndexHtml = Join-Path $extractRoot "preact\dist\index.html"
    $srcIndexJs = Join-Path $extractRoot "preact\dist\index.js"
    $srcIndexCss = Join-Path $extractRoot "preact\dist\assets\index.css"
    $srcAutoLoad = Join-Path $extractRoot "html\auto-load.js"
    if ((-not (Test-Path $srcIndexHtml)) -or (-not (Test-Path $srcIndexJs)) -or (-not (Test-Path $srcIndexCss)) -or (-not (Test-Path $srcAutoLoad))) {
        return $false
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $indexHtmlText = [System.IO.File]::ReadAllText($srcIndexHtml, [System.Text.Encoding]::UTF8)
    $indexJsText = [System.IO.File]::ReadAllText($srcIndexJs, [System.Text.Encoding]::UTF8)
    foreach ($pair in (Get-HoNWebOverrideJsReplacements)) {
        $indexJsText = $indexJsText.Replace($pair.Source, $pair.Target)
    }

    $outputAssetsRoot = Join-Path $OutputRoot "assets"
    $outputHtmlRoot = Join-Path $OutputRoot "html"
    $outputRemoteRoot = Join-Path $OutputRoot "preact-remote"
    $outputRemoteSrcRoot = Join-Path $outputRemoteRoot "src"
    $outputRemoteComponentsRoot = Join-Path $outputRemoteSrcRoot "components"
    $outputRemoteCompatRoot = Join-Path $outputRemoteSrcRoot "compat"
    $outputRemoteStylesRoot = Join-Path $outputRemoteSrcRoot "styles"
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $outputAssetsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $outputHtmlRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $outputRemoteComponentsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $outputRemoteCompatRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $outputRemoteStylesRoot -Force | Out-Null

    [System.IO.File]::WriteAllText((Join-Path $OutputRoot "index.html"), $indexHtmlText, $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $OutputRoot "index.js"), $indexJsText, $utf8NoBom)
    Copy-Item -Path $srcAutoLoad -Destination (Join-Path $OutputRoot "auto-load.js") -Force
    Copy-Item -Path $srcIndexCss -Destination (Join-Path $outputAssetsRoot "index.css") -Force

    Copy-Item -Path $srcAutoLoad -Destination (Join-Path $outputHtmlRoot "auto-load.js") -Force

    $srcRemoteIndexHtml = Join-Path $extractRoot "preact-remote\index.html"
    $srcRemoteMainTsx = Join-Path $extractRoot "preact-remote\src\main.tsx"
    $srcRemoteAppTsx = Join-Path $extractRoot "preact-remote\src\app.tsx"
    $srcRemoteEngineTs = Join-Path $extractRoot "preact-remote\src\compat\engine.ts"
    $srcRemoteMotdTsx = Join-Path $extractRoot "preact-remote\src\components\motd.tsx"
    $srcRemoteMotdCss = Join-Path $extractRoot "preact-remote\src\components\motd.css"
    $srcRemoteGlobalCss = Join-Path $extractRoot "preact-remote\src\styles\global.css"

    if ((Test-Path $srcRemoteIndexHtml) -and (Test-Path $srcRemoteMainTsx) -and (Test-Path $srcRemoteAppTsx) -and (Test-Path $srcRemoteEngineTs) -and (Test-Path $srcRemoteMotdTsx)) {
        $remoteMotdText = [System.IO.File]::ReadAllText($srcRemoteMotdTsx, [System.Text.Encoding]::UTF8)
        foreach ($pair in (Get-HoNRemoteMotdReplacements)) {
            $remoteMotdText = $remoteMotdText.Replace($pair.Source, $pair.Target)
        }

        Copy-Item -Path $srcRemoteIndexHtml -Destination (Join-Path $outputRemoteRoot "index.html") -Force
        $remoteMainText = [System.IO.File]::ReadAllText($srcRemoteMainTsx, [System.Text.Encoding]::UTF8)
        if ($remoteMainText -notmatch '\[HoN_RU_REMOTE\] main loaded') {
            $remoteMainText = "console.log('[HoN_RU_REMOTE] main loaded');" + [Environment]::NewLine + $remoteMainText
        }
        [System.IO.File]::WriteAllText((Join-Path $outputRemoteSrcRoot "main.tsx"), $remoteMainText, $utf8NoBom)
        Copy-Item -Path $srcRemoteAppTsx -Destination (Join-Path $outputRemoteSrcRoot "app.tsx") -Force
        Copy-Item -Path $srcRemoteEngineTs -Destination (Join-Path $outputRemoteCompatRoot "engine.ts") -Force
        [System.IO.File]::WriteAllText((Join-Path $outputRemoteComponentsRoot "motd.tsx"), $remoteMotdText, $utf8NoBom)
        if (Test-Path $srcRemoteMotdCss) {
            Copy-Item -Path $srcRemoteMotdCss -Destination (Join-Path $outputRemoteComponentsRoot "motd.css") -Force
        }
        if (Test-Path $srcRemoteGlobalCss) {
            Copy-Item -Path $srcRemoteGlobalCss -Destination (Join-Path $outputRemoteStylesRoot "global.css") -Force
        }
    }

    return $true
}

function Sync-HoNWebOverride {
    param(
        [string]$SourceRoot,
        [string]$GameRoot,
        [switch]$ForceCopy
    )

    $files = Get-ChildItem -Path $SourceRoot -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
            [pscustomobject]@{
                Source = $_.FullName
                Target = (Join-Path $GameRoot $relativePath)
            }
        }

    $changed = $false
    foreach ($file in $files) {
        if (-not (Test-Path $file.Source)) { continue }
        $targetDir = Split-Path -Parent $file.Target
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force -ErrorAction SilentlyContinue | Out-Null
        }

        $copyNeeded = $true
        if ((-not $ForceCopy) -and (Test-Path $file.Target)) {
            try {
                $srcItem = Get-Item $file.Source -ErrorAction Stop
                $dstItem = Get-Item $file.Target -ErrorAction Stop
                if ($srcItem.Length -ne $dstItem.Length) {
                    $copyNeeded = $true
                } else {
                    $srcBytes = [System.IO.File]::ReadAllBytes($file.Source)
                    $dstBytes = [System.IO.File]::ReadAllBytes($file.Target)
                    $copyNeeded = (-not [System.Linq.Enumerable]::SequenceEqual($srcBytes, $dstBytes))
                }
            } catch {
                $copyNeeded = $true
            }
        }

        if ($copyNeeded) {
            Copy-Item -Path $file.Source -Destination $file.Target -Force -ErrorAction SilentlyContinue
            $changed = $true
        }
    }

    return $changed
}
