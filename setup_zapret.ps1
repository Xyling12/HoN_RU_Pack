<#
    HoN RU Pack — Zapret DPI Bypass Setup
    Downloads Zapret from GitHub, enables Game Filter, installs as Windows service with ALT11 strategy.
    Requires elevation (Run as Administrator).
#>
param(
    [string]$DataRoot = (Join-Path $env:LOCALAPPDATA "HoN_RU_Pack")
)

$ErrorActionPreference = "Stop"

$zapretRoot = Join-Path $DataRoot "zapret"
$svcName = "zapret"

# --- Step 1: Download latest Zapret from GitHub ---
Write-Host "[Zapret] Downloading latest release from GitHub..."
$releaseApi = "https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest"
try {
    $release = Invoke-RestMethod -Uri $releaseApi -UseBasicParsing -TimeoutSec 15
} catch {
    Write-Host "[Zapret] ERROR: Failed to fetch release info: $_"
    Write-Host "[Zapret] Try downloading manually: https://github.com/Flowseal/zapret-discord-youtube/releases/latest"
    return
}

$asset = $release.assets | Where-Object { $_.name -match '\.zip$' } | Select-Object -First 1
if (-not $asset) {
    Write-Host "[Zapret] ERROR: No ZIP asset found in latest release."
    return
}

$zipUrl = $asset.browser_download_url
$zipPath = Join-Path $env:TEMP "zapret_download.zip"
Write-Host "[Zapret] Downloading: $($asset.name) ($([math]::Round($asset.size / 1MB, 1)) MB)..."

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 60
} catch {
    Write-Host "[Zapret] ERROR: Download failed: $_"
    return
}

# --- Step 2: Extract ---
Write-Host "[Zapret] Extracting to: $zapretRoot"
if (Test-Path $zapretRoot) { Remove-Item -Path $zapretRoot -Recurse -Force }
New-Item -ItemType Directory -Path $zapretRoot -Force | Out-Null

$extractTemp = Join-Path $env:TEMP "zapret_extract"
if (Test-Path $extractTemp) { Remove-Item -Path $extractTemp -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractTemp)

# Find the inner folder (ZIP usually contains a top-level folder)
$innerDirs = Get-ChildItem -Path $extractTemp -Directory
if ($innerDirs.Count -eq 1) {
    $innerDir = $innerDirs[0].FullName
} else {
    $innerDir = $extractTemp
}

# Move contents to zapretRoot
Get-ChildItem -Path $innerDir | Move-Item -Destination $zapretRoot -Force
Remove-Item -Path $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue

# --- Step 3: Enable Game Filter (all TCP+UDP ports) ---
$utilsDir = Join-Path $zapretRoot "utils"
New-Item -ItemType Directory -Path $utilsDir -Force | Out-Null
Set-Content -Path (Join-Path $utilsDir "game_filter.enabled") -Value "all" -Encoding ASCII
Write-Host "[Zapret] Game Filter enabled (all TCP+UDP ports)."

# --- Step 3b: Download ipset-all.txt (IP ranges for DPI bypass filtering) ---
$listsPath = Join-Path $zapretRoot "lists"
$ipsetUrl = "https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt"
$ipsetFile = Join-Path $listsPath "ipset-all.txt"
Write-Host "[Zapret] Downloading ipset list (blocked IP ranges)..."
try {
    New-Item -ItemType Directory -Path $listsPath -Force | Out-Null
    Invoke-WebRequest -Uri $ipsetUrl -OutFile $ipsetFile -UseBasicParsing -TimeoutSec 15
    $lineCount = (Get-Content $ipsetFile).Count
    Write-Host "[Zapret] ipset-all.txt updated: $lineCount IP ranges loaded."
} catch {
    Write-Host "[Zapret] WARNING: Failed to download ipset list: $_"
    Write-Host "[Zapret] DPI bypass will still work but may not cover all blocked IPs."
}

# --- Step 3c: Update hosts file (DNS entries for blocked services) ---
$hostsUrl = "https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/hosts"
$hostsFile = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
Write-Host "[Zapret] Updating hosts file with DNS bypass entries..."
try {
    $hostsContent = (Invoke-WebRequest -Uri $hostsUrl -UseBasicParsing -TimeoutSec 10).Content
    $currentHosts = ""
    if (Test-Path $hostsFile) {
        $currentHosts = [System.IO.File]::ReadAllText($hostsFile)
    }
    # Check if entries already exist (check first non-empty line)
    $firstEntry = ($hostsContent -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
    if ($currentHosts -notmatch [regex]::Escape($firstEntry)) {
        # Append new entries
        $separator = "`r`n`r`n# === Zapret DNS bypass (HoN RU Pack) ===`r`n"
        $endMarker = "`r`n# === End Zapret DNS bypass ===`r`n"
        [System.IO.File]::AppendAllText($hostsFile, $separator + $hostsContent + $endMarker)
        Write-Host "[Zapret] Hosts file updated with DNS bypass entries."
    } else {
        Write-Host "[Zapret] Hosts file already contains bypass entries."
    }
} catch {
    Write-Host "[Zapret] WARNING: Failed to update hosts file: $_"
    Write-Host "[Zapret] You may need to update it manually."
}

# --- Step 3d: Create user-list placeholder files (required by winws.exe) ---
# Matches service.bat :load_user_lists — without these files, winws.exe crashes
$userFiles = @{
    "ipset-exclude-user.txt" = "203.0.113.113/32"
    "list-general-user.txt" = "domain.example.abc"
    "list-exclude-user.txt" = "domain.example.abc"
}
foreach ($kv in $userFiles.GetEnumerator()) {
    $f = Join-Path $listsPath $kv.Key
    if (-not (Test-Path $f)) {
        Set-Content -Path $f -Value $kv.Value -Encoding ASCII
    }
}
Write-Host "[Zapret] User list files created."
# --- Step 4: Build winws.exe arguments (HoN community ALT11 strategy) ---
# These args are from the community-modified ALT11 that works for HoN.
# We hardcode them because the standard GitHub release uses different DPI
# strategies (fake,multisplit) that don't work for HoN game traffic.
# Key differences: syndata for TCP, --dpi-desync-any-protocol=1 for UDP game traffic.

$binPath = Join-Path $zapretRoot "bin"
$winwsExe = Join-Path $binPath "winws.exe"

if (-not (Test-Path $winwsExe)) {
    Write-Host "[Zapret] ERROR: winws.exe not found at $winwsExe"
    return
}

# Helper: quote path for service binPath
function Q($p) { "`"$p`"" }

$quicBin   = Join-Path $binPath "quic_initial_www_google_com.bin"
$tlsGoogle = Join-Path $binPath "tls_clienthello_www_google_com.bin"
$tlsMaxRu  = Join-Path $binPath "tls_clienthello_max_ru.bin"
$listGen   = Join-Path $listsPath "list-general.txt"
$listGenU  = Join-Path $listsPath "list-general-user.txt"
$listExcl  = Join-Path $listsPath "list-exclude.txt"
$listExclU = Join-Path $listsPath "list-exclude-user.txt"
$listGoog  = Join-Path $listsPath "list-google.txt"
$ipsetAll  = Join-Path $listsPath "ipset-all.txt"
$ipsetExcl = Join-Path $listsPath "ipset-exclude.txt"
$ipsetExclU = Join-Path $listsPath "ipset-exclude-user.txt"

# Game filter: all ports 1024-65535
$GF = "1024-65535"

# Build arguments exactly matching community ALT11 (1.9.6)
$rawArgs = @(
    "--wf-tcp=80,443,2053,2083,2087,2096,8443,$GF",
    "--wf-udp=443,19294-19344,50000-50100,$GF",
    # Rule 1: UDP 443 with hostlist
    "--filter-udp=443", "--hostlist=$(Q $listGen)", "--hostlist=$(Q $listGenU)",
    "--hostlist-exclude=$(Q $listExcl)", "--hostlist-exclude=$(Q $listExclU)",
    "--ipset-exclude=$(Q $ipsetExcl)", "--ipset-exclude=$(Q $ipsetExclU)",
    "--dpi-desync=fake", "--dpi-desync-repeats=6", "--dpi-desync-fake-quic=$(Q $quicBin)",
    "--new",
    # Rule 2: Discord UDP
    "--filter-udp=19294-19344,50000-50100", "--filter-l7=discord,stun",
    "--dpi-desync=fake", "--dpi-desync-repeats=6",
    "--new",
    # Rule 3: Discord TCP alt ports
    "--filter-tcp=2053,2083,2087,2096,8443", "--hostlist-domains=discord.media",
    "--dpi-desync=fake,multisplit", "--dpi-desync-split-seqovl=681", "--dpi-desync-split-pos=1",
    "--dpi-desync-fooling=ts", "--dpi-desync-repeats=8",
    "--dpi-desync-split-seqovl-pattern=$(Q $tlsGoogle)", "--dpi-desync-fake-tls=$(Q $tlsGoogle)",
    "--new",
    # Rule 4: Google TCP 443
    "--filter-tcp=443", "--hostlist=$(Q $listGoog)", "--ip-id=zero",
    "--dpi-desync=fake,multisplit", "--dpi-desync-split-seqovl=681", "--dpi-desync-split-pos=1",
    "--dpi-desync-fooling=ts", "--dpi-desync-repeats=8",
    "--dpi-desync-split-seqovl-pattern=$(Q $tlsGoogle)", "--dpi-desync-fake-tls=$(Q $tlsGoogle)",
    "--new",
    # Rule 5: General TCP hostlist
    "--filter-tcp=80,443", "--hostlist=$(Q $listGen)", "--hostlist=$(Q $listGenU)",
    "--hostlist-exclude=$(Q $listExcl)", "--hostlist-exclude=$(Q $listExclU)",
    "--ipset-exclude=$(Q $ipsetExcl)", "--ipset-exclude=$(Q $ipsetExclU)",
    "--dpi-desync=fake,multisplit", "--dpi-desync-split-seqovl=654", "--dpi-desync-split-pos=1",
    "--dpi-desync-fooling=ts", "--dpi-desync-repeats=8",
    "--dpi-desync-split-seqovl-pattern=$(Q $tlsMaxRu)", "--dpi-desync-fake-tls=$(Q $tlsMaxRu)",
    "--new",
    # Rule 6: UDP 443 ipset (Cloudflare IPs)
    "--filter-udp=443", "--ipset=$(Q $ipsetAll)",
    "--hostlist-exclude=$(Q $listExcl)", "--hostlist-exclude=$(Q $listExclU)",
    "--ipset-exclude=$(Q $ipsetExcl)", "--ipset-exclude=$(Q $ipsetExclU)",
    "--dpi-desync=fake", "--dpi-desync-repeats=11", "--dpi-desync-fake-quic=$(Q $quicBin)",
    "--new",
    # Rule 7: TCP ipset - SYNDATA strategy (key for HoN!)
    "--filter-tcp=80,443,$GF", "--ipset=$(Q $ipsetAll)",
    "--hostlist-exclude=$(Q $listExcl)", "--hostlist-exclude=$(Q $listExclU)",
    "--ipset-exclude=$(Q $ipsetExcl)", "--ipset-exclude=$(Q $ipsetExclU)",
    "--dpi-desync=syndata",
    "--new",
    # Rule 8: UDP game traffic ipset - any-protocol (key for HoN!)
    "--filter-udp=$GF", "--ipset=$(Q $ipsetAll)",
    "--ipset-exclude=$(Q $ipsetExcl)", "--ipset-exclude=$(Q $ipsetExclU)",
    "--dpi-desync=fake", "--dpi-desync-autottl=2", "--dpi-desync-repeats=10",
    "--dpi-desync-any-protocol=1", "--dpi-desync-fake-unknown-udp=$(Q $quicBin)",
    "--dpi-desync-cutoff=n2",
    "--new",
    # Rule 9: HoN-specific UDP ports 10000-10100
    "--filter-udp=10000-10100",
    "--dpi-desync=fake", "--dpi-desync-repeats=6", "--dpi-desync-cutoff=n2",
    "--dpi-desync-fake-quic=$(Q $quicBin)"
) -join " "

Write-Host "[Zapret] Strategy: HoN Community ALT11 (syndata + any-protocol)"
Write-Host "[Zapret] Args length: $($rawArgs.Length) chars"

# --- Step 5: Remove old service if exists ---
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
& net stop $svcName 2>&1 | Out-Null
& sc.exe delete $svcName 2>&1 | Out-Null
& net stop "WinDivert" 2>&1 | Out-Null
& sc.exe delete "WinDivert" 2>&1 | Out-Null
& net stop "WinDivert14" 2>&1 | Out-Null
& sc.exe delete "WinDivert14" 2>&1 | Out-Null
& taskkill /IM winws.exe /F 2>&1 | Out-Null
& netsh interface tcp set global timestamps=enabled 2>&1 | Out-Null
$ErrorActionPreference = $prevEAP
Write-Host "[Zapret] Old services cleaned up."

# --- Step 6: Create and start service ---
$binPathArg = "`"$winwsExe`" $rawArgs"
Write-Host "[Zapret] Creating service..."
$scResult = & sc.exe create $svcName binPath= "$binPathArg" DisplayName= "zapret" start= auto 2>&1
Write-Host "[Zapret] sc create: $scResult"

& sc.exe description $svcName "Zapret DPI bypass (HoN RU Pack)" 2>&1 | Out-Null

Write-Host "[Zapret] Starting service..."
$startResult = & sc.exe start $svcName 2>&1
Write-Host "[Zapret] sc start: $startResult"

# Save which strategy was installed
Set-Content -Path (Join-Path $zapretRoot "installed_strategy.txt") -Value $alt11Bat.Name -Encoding UTF8

Write-Host "[Zapret] Zapret installed and running!"
Write-Host "[Zapret] Location: $zapretRoot"
