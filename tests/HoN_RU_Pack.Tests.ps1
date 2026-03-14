<#
    HoN RU Pack — Project Integrity Tests (Pester 3.x compatible)
    Run:  Invoke-Pester -Path .\tests\HoN_RU_Pack.Tests.ps1
#>

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BundleDir   = Join-Path $ProjectRoot "bundle"

# --- Helper: parse .str file into hashtable of arrays (key -> @(line_numbers)) ---
function Get-StrKeyMap {
    param([string]$FilePath)
    $map = @{}
    $lineNum = 0
    foreach ($line in [System.IO.File]::ReadAllLines($FilePath)) {
        $lineNum++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.TrimStart().StartsWith("//"))  { continue }
        $m = [Regex]::Match($line, '^(?<k>\S+)')
        if ($m.Success) {
            $key = $m.Groups["k"].Value
            if (-not $map.ContainsKey($key)) {
                $map[$key] = @()
            }
            $map[$key] += $lineNum
        }
    }
    return $map
}

# ============================================================
Describe "Project structure" {

    It "version.txt exists and contains a valid semver" {
        $path = Join-Path $ProjectRoot "version.txt"
        $path | Should Exist
        $ver = (Get-Content $path -Raw).Trim()
        $ver | Should Match '^\d+\.\d+\.\d+'
    }

    It "update_config.json is valid JSON" {
        $path = Join-Path $ProjectRoot "update_config.json"
        $path | Should Exist
        { Get-Content $path -Raw | ConvertFrom-Json } | Should Not Throw
    }

    It "update_manifest.example.json is valid JSON" {
        $path = Join-Path $ProjectRoot "update_manifest.example.json"
        $path | Should Exist
        { Get-Content $path -Raw | ConvertFrom-Json } | Should Not Throw
    }

    It ".gitignore exists" {
        Join-Path $ProjectRoot ".gitignore" | Should Exist
    }

    $requiredScripts = @(
        "install_hon_ru_pack.ps1",
        "hon_auto_agent.ps1",
        "set_login_banner.ps1",
        "setup_dns_bypass.ps1",
        "restore_dns.ps1",
        "setup_amneziawg.ps1",
        "remove_amneziawg.ps1",
        "uninstall_hon_ru_pack.ps1",
        "update.ps1",
        "build_hon_ru_installer_exe.ps1"
    )
    foreach ($script in $requiredScripts) {
        It "script $script exists" {
            Join-Path $ProjectRoot $script | Should Exist
        }
    }
}

# ============================================================
Describe "Bundle files" {

    $bundleFiles = @(
        "entities_en.str",
        "interface_en.str",
        "client_messages_en.str",
        "game_messages_en.str",
        "bot_messages_en.str"
    )

    foreach ($file in $bundleFiles) {
        Context $file {
            $filePath = Join-Path $BundleDir $file

            It "exists" {
                $filePath | Should Exist
            }

            It "is not empty" {
                (Get-Item $filePath).Length | Should BeGreaterThan 0
            }

            It "is valid UTF-8 readable" {
                { [System.IO.File]::ReadAllText($filePath) } | Should Not Throw
            }

            It "every non-blank, non-comment line has a key" {
                $lines = [System.IO.File]::ReadAllLines($filePath)
                $bad = @()
                $lineNum = 0
                foreach ($line in $lines) {
                    $lineNum++
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    if ($line.TrimStart().StartsWith("//"))  { continue }
                    if ($line -notmatch '^\S+') {
                        $bad += $lineNum
                    }
                }
                $bad.Count | Should Be 0
            }
        }
    }
}

# ============================================================
Describe "Script syntax validation" {

    $scripts = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -File

    foreach ($script in $scripts) {
        It "$($script.Name) has no parse errors" {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                $script.FullName,
                [ref]$null,
                [ref]$errors
            )
            $errors.Count | Should Be 0
        }
    }
}

# ============================================================
Describe "Version consistency" {

    It "update_config.json latest_version should match version.txt" {
        $verFile = (Get-Content (Join-Path $ProjectRoot "version.txt") -Raw).Trim()
        $cfg = Get-Content (Join-Path $ProjectRoot "update_config.json") -Raw | ConvertFrom-Json
        $cfg.latest_version | Should Be $verFile
    }
}

# ============================================================
Describe "Duplicate .str keys" {

    # Chat command aliases — engine uses multiple values as command shortcuts
    $allowedDuplicates = @(
        "chat_command_whisper",
        "chat_command_reply"
    )

    $bundleFiles = @(
        "entities_en.str",
        "interface_en.str",
        "client_messages_en.str",
        "game_messages_en.str",
        "bot_messages_en.str"
    )

    foreach ($file in $bundleFiles) {
        It "$file has no duplicate keys" {
            $filePath = Join-Path $BundleDir $file
            if (-not (Test-Path $filePath)) { return }

            $map = Get-StrKeyMap -FilePath $filePath
            $dupes = @($map.GetEnumerator() |
                Where-Object { $_.Value.Count -gt 1 -and $allowedDuplicates -notcontains $_.Key })
            $dupes.Count | Should Be 0
        }
    }
}

# ============================================================
Describe "Shared module (hon_common.ps1)" {

    It "hon_common.ps1 exists" {
        Join-Path $ProjectRoot "hon_common.ps1" | Should Exist
    }

    It "hon_common.ps1 defines Find-HoNLocalRoot" {
        $content = Get-Content (Join-Path $ProjectRoot "hon_common.ps1") -Raw
        $content | Should Match 'function Find-HoNLocalRoot'
    }

    It "hon_common.ps1 defines Get-DirectDropboxUrl" {
        $content = Get-Content (Join-Path $ProjectRoot "hon_common.ps1") -Raw
        $content | Should Match 'function Get-DirectDropboxUrl'
    }

    $importingScripts = @(
        "install_hon_ru_pack.ps1",
        "hon_auto_agent.ps1",
        "uninstall_hon_ru_pack.ps1",
        "update.ps1",
        "set_login_banner.ps1"
    )
    foreach ($script in $importingScripts) {
        It "$script imports hon_common.ps1" {
            $content = Get-Content (Join-Path $ProjectRoot $script) -Raw
            $content | Should Match 'hon_common\.ps1'
        }
    }
}

# ============================================================
Describe "Build prerequisites" {

    $requiredForBuild = @(
        "install_hon_ru_pack.ps1",
        "hon_auto_agent.ps1",
        "set_login_banner.ps1",
        "setup_dns_bypass.ps1",
        "restore_dns.ps1",
        "setup_amneziawg.ps1",
        "remove_amneziawg.ps1",
        "hon_paths_override.example.ps1",
        "version.txt",
        "README.txt",
        "README_ONE_CLICK_INSTALL.txt"
    )
    $requiredBundle = @(
        "entities_en.str",
        "interface_en.str",
        "client_messages_en.str",
        "game_messages_en.str",
        "bot_messages_en.str"
    )

    foreach ($f in $requiredForBuild) {
        It "build requires $f" {
            Join-Path $ProjectRoot $f | Should Exist
        }
    }
    foreach ($f in $requiredBundle) {
        It "build requires bundle/$f" {
            Join-Path $BundleDir $f | Should Exist
        }
    }
}

# ============================================================
Describe "Login banner script" {

    It "set_login_banner.ps1 can find BannerKey in interface_en.str" {
        $interfacePath = Join-Path $BundleDir "interface_en.str"
        if (-not (Test-Path $interfacePath)) { return }
        $content = Get-Content $interfacePath -Raw
        $content | Should Match 'main_label_username'
    }

    It "set_login_banner.ps1 can find remember_me key in interface_en.str" {
        $interfacePath = Join-Path $BundleDir "interface_en.str"
        if (-not (Test-Path $interfacePath)) { return }
        $content = Get-Content $interfacePath -Raw
        ($content -match 'main_checkbox_remember_me' -or $content -match 'main_login_remember_me') |
            Should Be $true
    }
}

# ============================================================
Describe "Installer EXE" {

    It "dist/HoN_RU_Pack_Installer.exe exists" {
        $exe = Join-Path $ProjectRoot "dist\HoN_RU_Pack_Installer.exe"
        $exe | Should Exist
    }

    It "plain installer EXE is at least 500 KB (contains payload)" {
        $exe = Join-Path $ProjectRoot "dist\HoN_RU_Pack_Installer.exe"
        if (-not (Test-Path $exe)) { return }
        (Get-Item $exe).Length | Should BeGreaterThan 500000
    }

    It "dist/HoN_RU_Pack_Installer_Bypass.exe exists" {
        $exe = Join-Path $ProjectRoot "dist\HoN_RU_Pack_Installer_Bypass.exe"
        $exe | Should Exist
    }

    It "DNS installer EXE is at least 500 KB (contains payload)" {
        $exe = Join-Path $ProjectRoot "dist\HoN_RU_Pack_Installer_Bypass.exe"
        if (-not (Test-Path $exe)) { return }
        (Get-Item $exe).Length | Should BeGreaterThan 500000
    }
}
# ============================================================
Describe "Bypass scripts" {

    It "setup_dns_bypass.ps1 exists" {
        Join-Path $ProjectRoot "setup_dns_bypass.ps1" | Should Exist
    }

    It "restore_dns.ps1 exists" {
        Join-Path $ProjectRoot "restore_dns.ps1" | Should Exist
    }

    It "setup_amneziawg.ps1 exists" {
        Join-Path $ProjectRoot "setup_amneziawg.ps1" | Should Exist
    }

    It "remove_amneziawg.ps1 exists" {
        Join-Path $ProjectRoot "remove_amneziawg.ps1" | Should Exist
    }

    It "install_hon_ru_pack.ps1 accepts -SetupBypass parameter" {
        $content = Get-Content (Join-Path $ProjectRoot "install_hon_ru_pack.ps1") -Raw
        $content | Should Match 'SetupBypass'
    }

    It "install_hon_ru_pack.ps1 accepts routing parameters" {
        $content = Get-Content (Join-Path $ProjectRoot "install_hon_ru_pack.ps1") -Raw
        $content | Should Match 'RouteHoN'
        $content | Should Match 'RouteYouTube'
        $content | Should Match 'RouteDiscord'
        $content | Should Match 'RouteTelegram'
        $content | Should Match 'RouteOpenAI'
    }

    It "uninstall_hon_ru_pack.ps1 references amneziawg" {
        $content = Get-Content (Join-Path $ProjectRoot "uninstall_hon_ru_pack.ps1") -Raw
        $content | Should Match 'remove_amneziawg'
    }
}
