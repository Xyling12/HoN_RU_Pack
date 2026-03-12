<#
    HoN RU Pack — Zapret DPI Bypass Setup (HoN-modified ALT11)
    Downloads Zapret from GitHub, patches with HoN IPs, installs as Windows service.
    Based on community HoN Zapret mod by stalker31.
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
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
} catch {
    Write-Host "[Zapret] ERROR: Download failed: $_"
    return
}

# --- Step 2: Extract (with proper DLL handling) ---
Write-Host "[Zapret] Extracting to: $zapretRoot"
if (Test-Path $zapretRoot) { Remove-Item -Path $zapretRoot -Recurse -Force }
New-Item -ItemType Directory -Path $zapretRoot -Force | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

# Find the common root prefix in the ZIP (e.g. "zapret-discord-youtube-1.9.7b/")
$prefix = ""
$firstEntry = $zip.Entries | Where-Object { $_.FullName -match '/' } | Select-Object -First 1
if ($firstEntry) {
    $prefix = ($firstEntry.FullName -split '/')[0] + "/"
}

foreach ($entry in $zip.Entries) {
    # Skip directories
    if ($entry.FullName.EndsWith('/')) { continue }

    # Strip the top-level folder prefix
    $relativePath = $entry.FullName
    if ($prefix -and $relativePath.StartsWith($prefix)) {
        $relativePath = $relativePath.Substring($prefix.Length)
    }
    if ([string]::IsNullOrEmpty($relativePath)) { continue }

    $destPath = Join-Path $zapretRoot ($relativePath -replace '/', '\')
    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
}
$zip.Dispose()
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue

# Verify critical files
$binDir = Join-Path $zapretRoot "bin"
$criticalFiles = @("winws.exe", "cygwin1.dll", "WinDivert.dll", "WinDivert64.sys")
foreach ($f in $criticalFiles) {
    if (-not (Test-Path (Join-Path $binDir $f))) {
        Write-Host "[Zapret] ERROR: Critical file missing: $f"
        return
    }
}
Write-Host "[Zapret] All files extracted successfully."

# --- Step 3: Enable Game Filter (all TCP+UDP ports for HoN) ---
$utilsDir = Join-Path $zapretRoot "utils"
New-Item -ItemType Directory -Path $utilsDir -Force | Out-Null
Set-Content -Path (Join-Path $utilsDir "game_filter.enabled") -Value "all" -Encoding ASCII
Write-Host "[Zapret] Game Filter enabled (all TCP+UDP ports)."

# --- Step 4: Patch ipset-all.txt with HoN server IPs ---
# HoN/Juvio servers use IPs not in the standard Zapret ipset.
# These IPs are required for the DPI bypass to cover game traffic.
$listsPath = Join-Path $zapretRoot "lists"
New-Item -ItemType Directory -Path $listsPath -Force | Out-Null
$ipsetFile = Join-Path $listsPath "ipset-all.txt"

# Download standard ipset from GitHub
$ipsetUrl = "https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt"
Write-Host "[Zapret] Downloading ipset list..."
try {
    Invoke-WebRequest -Uri $ipsetUrl -OutFile $ipsetFile -UseBasicParsing -TimeoutSec 15
} catch {
    Write-Host "[Zapret] WARNING: Failed to download ipset list: $_"
}

# Append HoN-specific IPs
$honIPs = @(
    "# === HoN/Juvio Server IPs ==="
    "91.98.177.0/24"
    "157.180.81.53"
    "45.154.06.104"
    "104.26.14.10"
    "185.237.185.232"
)
Add-Content -Path $ipsetFile -Value ($honIPs -join "`n") -Encoding ASCII
Write-Host "[Zapret] Added HoN server IPs to ipset."

# --- Step 5: Create user-list placeholder files ---
$userFiles = @{
    "ipset-exclude-user.txt" = "203.0.113.113/32"
    "list-general-user.txt"  = "domain.example.abc"
    "list-exclude-user.txt"  = "domain.example.abc"
}
foreach ($kv in $userFiles.GetEnumerator()) {
    $f = Join-Path $listsPath $kv.Key
    if (-not (Test-Path $f)) {
        Set-Content -Path $f -Value $kv.Value -Encoding ASCII
    }
}
Write-Host "[Zapret] User list files ready."

# --- Step 6: Update hosts file ---
$hostsUrl = "https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/hosts"
$hostsFile = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
Write-Host "[Zapret] Updating hosts file..."
try {
    $hostsContent = (Invoke-WebRequest -Uri $hostsUrl -UseBasicParsing -TimeoutSec 10).Content
    $currentHosts = ""
    if (Test-Path $hostsFile) {
        $currentHosts = [System.IO.File]::ReadAllText($hostsFile)
    }
    $firstEntry = ($hostsContent -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
    if ($currentHosts -notmatch [regex]::Escape($firstEntry)) {
        $separator = "`r`n`r`n# === Zapret DNS bypass (HoN RU Pack) ===`r`n"
        $endMarker = "`r`n# === End Zapret DNS bypass ===`r`n"
        [System.IO.File]::AppendAllText($hostsFile, $separator + $hostsContent + $endMarker)
        Write-Host "[Zapret] Hosts file updated."
    } else {
        Write-Host "[Zapret] Hosts file already contains bypass entries."
    }
} catch {
    Write-Host "[Zapret] WARNING: Failed to update hosts file: $_"
}

# --- Step 7: Remove old service ---
Write-Host "[Zapret] Cleaning up old services..."
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
Start-Sleep -Seconds 1

# --- Step 8: Install service (HoN-modified ALT11 strategy) ---
# Exact args from community HoN ALT11 by stalker31.
# Key rules:
#   - Rules 1-6: Standard DPI bypass for Discord, YouTube, etc.
#   - Rule 7 (syndata): TCP ipset bypass — works because HoN IPs are in ipset
#   - Rule 8: UDP game traffic with any-protocol
#   - Rule 9: HoN-specific UDP ports 10000-10100

$Q = '"'  # quote char
$GF = "1024-65535"  # Game Filter ports

$argsStr = @(
    "--wf-tcp=80,443,2053,2083,2087,2096,8443,$GF",
    "--wf-udp=443,19294-19344,50000-50100,$GF",
    # Rule 1: UDP 443 hostlist
    "--filter-udp=443",
    "--hostlist=$Q$listsPath\list-general.txt$Q",
    "--hostlist-exclude=$Q$listsPath\list-exclude.txt$Q",
    "--ipset-exclude=$Q$listsPath\ipset-exclude.txt$Q",
    "--dpi-desync=fake", "--dpi-desync-repeats=6",
    "--dpi-desync-fake-quic=$Q$binDir\quic_initial_www_google_com.bin$Q",
    "--new",
    # Rule 2: Discord UDP
    "--filter-udp=19294-19344,50000-50100",
    "--filter-l7=discord,stun",
    "--dpi-desync=fake", "--dpi-desync-repeats=6",
    "--new",
    # Rule 3: Discord TCP alt ports
    "--filter-tcp=2053,2083,2087,2096,8443",
    "--hostlist-domains=discord.media",
    "--dpi-desync=fake,multisplit",
    "--dpi-desync-split-seqovl=681", "--dpi-desync-split-pos=1",
    "--dpi-desync-fooling=ts", "--dpi-desync-repeats=8",
    "--dpi-desync-split-seqovl-pattern=$Q$binDir\tls_clienthello_www_google_com.bin$Q",
    "--dpi-desync-fake-tls=$Q$binDir\tls_clienthello_www_google_com.bin$Q",
    "--new",
    # Rule 4: Google TCP 443
    "--filter-tcp=443",
    "--hostlist=$Q$listsPath\list-google.txt$Q",
    "--ip-id=zero",
    "--dpi-desync=fake,multisplit",
    "--dpi-desync-split-seqovl=681", "--dpi-desync-split-pos=1",
    "--dpi-desync-fooling=ts", "--dpi-desync-repeats=8",
    "--dpi-desync-split-seqovl-pattern=$Q$binDir\tls_clienthello_www_google_com.bin$Q",
    "--dpi-desync-fake-tls=$Q$binDir\tls_clienthello_www_google_com.bin$Q",
    "--new",
    # Rule 5: General TCP hostlist
    "--filter-tcp=80,443",
    "--hostlist=$Q$listsPath\list-general.txt$Q",
    "--hostlist-exclude=$Q$listsPath\list-exclude.txt$Q",
    "--ipset-exclude=$Q$listsPath\ipset-exclude.txt$Q",
    "--dpi-desync=fake,multisplit",
    "--dpi-desync-split-seqovl=654", "--dpi-desync-split-pos=1",
    "--dpi-desync-fooling=ts", "--dpi-desync-repeats=8",
    "--dpi-desync-split-seqovl-pattern=$Q$binDir\tls_clienthello_max_ru.bin$Q",
    "--dpi-desync-fake-tls=$Q$binDir\tls_clienthello_max_ru.bin$Q",
    "--new",
    # Rule 6: UDP 443 ipset
    "--filter-udp=443",
    "--ipset=$Q$listsPath\ipset-all.txt$Q",
    "--hostlist-exclude=$Q$listsPath\list-exclude.txt$Q",
    "--ipset-exclude=$Q$listsPath\ipset-exclude.txt$Q",
    "--dpi-desync=fake", "--dpi-desync-repeats=11",
    "--dpi-desync-fake-quic=$Q$binDir\quic_initial_www_google_com.bin$Q",
    "--new",
    # Rule 7: TCP ipset — syndata (HoN servers in ipset)
    "--filter-tcp=80,443,$GF",
    "--ipset=$Q$listsPath\ipset-all.txt$Q",
    "--hostlist-exclude=$Q$listsPath\list-exclude.txt$Q",
    "--ipset-exclude=$Q$listsPath\ipset-exclude.txt$Q",
    "--dpi-desync=syndata",
    "--new",
    # Rule 8: UDP game traffic — any-protocol
    "--filter-udp=$GF",
    "--ipset=$Q$listsPath\ipset-all.txt$Q",
    "--ipset-exclude=$Q$listsPath\ipset-exclude.txt$Q",
    "--dpi-desync=fake", "--dpi-desync-autottl=2", "--dpi-desync-repeats=10",
    "--dpi-desync-any-protocol=1",
    "--dpi-desync-fake-unknown-udp=$Q$binDir\quic_initial_www_google_com.bin$Q",
    "--dpi-desync-cutoff=n2",
    "--new",
    # Rule 9: HoN-specific UDP ports 10000-10100
    "--filter-udp=10000-10100",
    "--dpi-desync=fake", "--dpi-desync-repeats=6", "--dpi-desync-cutoff=n2",
    "--dpi-desync-fake-quic=$Q$binDir\quic_initial_www_google_com.bin$Q"
) -join " "

$winwsExe = Join-Path $binDir "winws.exe"
$binPathArg = "`"$winwsExe`" $argsStr"
Write-Host "[Zapret] Strategy: HoN ALT11 (syndata + HoN UDP 10000-10100)"
Write-Host "[Zapret] binPath length: $($binPathArg.Length) chars"

Write-Host "[Zapret] Creating service..."
$scResult = & sc.exe create $svcName binPath= "$binPathArg" DisplayName= "zapret" start= auto 2>&1
Write-Host "[Zapret] sc create: $scResult"

& sc.exe description $svcName "Zapret DPI bypass (HoN RU Pack ALT11)" 2>&1 | Out-Null

Write-Host "[Zapret] Starting service..."
$startResult = & sc.exe start $svcName 2>&1
Write-Host "[Zapret] sc start: $startResult"

Start-Sleep -Seconds 2
$queryResult = & sc.exe query $svcName 2>&1 | Out-String
if ($queryResult -match "RUNNING") {
    Write-Host "[Zapret] Service is RUNNING!"
} else {
    Write-Host "[Zapret] WARNING: Service may not be running. Check: sc query zapret"
    Write-Host $queryResult
}

Write-Host ""
Write-Host "[Zapret] Zapret installed and running!"
Write-Host "[Zapret] Location: $zapretRoot"
Write-Host "[Zapret] Strategy: HoN Community ALT11"
