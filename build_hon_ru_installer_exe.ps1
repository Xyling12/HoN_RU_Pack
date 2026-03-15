param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$OutputExe = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputExe)) {
    $OutputExe = Join-Path $PackageRoot "dist\HoN_RU_Pack_Installer.exe"
}
if (-not (Test-Path $PackageRoot)) {
    throw "PackageRoot not found: $PackageRoot"
}

$requiredScripts = @(
    "install_hon_ru_pack.ps1",
    "hon_common.ps1",
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

$distRoot = Join-Path $PackageRoot "dist"
$assetsRoot = Join-Path $PackageRoot "assets"
$stageRoot = Join-Path $distRoot "installer_payload_stage"
$stageBundle = Join-Path $stageRoot "bundle"
$payloadZip = Join-Path $distRoot "installer_payload.zip"
$sourceDump = Join-Path $distRoot "installer_program.cs"

if (Test-Path $stageRoot) { Remove-Item -Path $stageRoot -Recurse -Force }
if (Test-Path $payloadZip) { Remove-Item -Path $payloadZip -Force }
New-Item -ItemType Directory -Path $stageBundle -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $OutputExe) -Force | Out-Null

foreach ($name in $requiredScripts) {
    $src = Join-Path $PackageRoot $name
    if (-not (Test-Path $src)) { throw "Missing required file: $src" }
    Copy-Item -Path $src -Destination (Join-Path $stageRoot $name) -Force
}
foreach ($name in $requiredBundle) {
    $src = Join-Path (Join-Path $PackageRoot "bundle") $name
    if (-not (Test-Path $src)) { throw "Missing required bundle file: $src" }
    Copy-Item -Path $src -Destination (Join-Path $stageBundle $name) -Force
}

# Include pre-built resources999.s2z in the payload root
$s2zSrc = Join-Path $PackageRoot "resources999.s2z"
if (-not (Test-Path $s2zSrc)) { throw "Missing resources999.s2z - build it first with 7z" }
Copy-Item -Path $s2zSrc -Destination (Join-Path $stageRoot "resources999.s2z") -Force

Compress-Archive -Path (Join-Path $stageRoot "*") -DestinationPath $payloadZip -Force

# Load WinForms C# template from external file
$templatePath = Join-Path $PackageRoot "installer_template.cs"
if (-not (Test-Path $templatePath)) { throw "C# template not found: $templatePath" }
$programTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)

# Inject version
$version = (Get-Content (Join-Path $PackageRoot "version.txt") -Raw).Trim()
$versionParts = $version.Split('.')
while ($versionParts.Length -lt 4) { $versionParts += "0" }
$versionFull = ($versionParts[0..3]) -join "."
$programBase = $programTemplate.Replace("__VERSION__", $version).Replace("__VERSION_FULL__", $versionFull)

# Find csc.exe from .NET Framework
$cscPath = Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "csc.exe"
if (-not (Test-Path $cscPath)) {
    # Fallback: search .NET Framework directories (for CI runners / PowerShell 7)
    $fwDir = Join-Path $env:SystemRoot "Microsoft.NET\Framework64"
    if (Test-Path $fwDir) {
        $cscPath = Get-ChildItem $fwDir -Recurse -Filter "csc.exe" -ErrorAction SilentlyContinue |
            Sort-Object { $_.Directory.Name } -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }
    }
    if (-not $cscPath -or -not (Test-Path $cscPath)) {
        $fwDir32 = Join-Path $env:SystemRoot "Microsoft.NET\Framework"
        if (Test-Path $fwDir32) {
            $cscPath = Get-ChildItem $fwDir32 -Recurse -Filter "csc.exe" -ErrorAction SilentlyContinue |
                Sort-Object { $_.Directory.Name } -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }
        }
    }
}
if (-not $cscPath -or -not (Test-Path $cscPath)) { throw "csc.exe not found" }

$iconPath = Join-Path $assetsRoot "installer_icon.ico"
if (-not (Test-Path $iconPath)) { $iconPath = Join-Path $distRoot "installer_icon.ico" }

function Build-InstallerExe {
    param([string]$Code, [string]$OutExe, [string]$SourceDumpPath)
    Set-Content -Path $SourceDumpPath -Value $Code -Encoding UTF8
    if (Test-Path $OutExe) { Remove-Item -Path $OutExe -Force }
    $cscArgs = @(
        "/target:winexe",
        "/out:$OutExe",
        "/codepage:65001",
        "/reference:System.Windows.Forms.dll",
        "/reference:System.Drawing.dll",
        "/reference:System.IO.Compression.dll",
        "/reference:System.IO.Compression.FileSystem.dll",
        "/optimize+",
        "/resource:$payloadZip,payload.zip"
    )
    if (Test-Path $iconPath) { $cscArgs += "/win32icon:$iconPath" }
    $manifestPath = Join-Path $assetsRoot "installer.manifest"
    if (-not (Test-Path $manifestPath)) { $manifestPath = Join-Path $distRoot "installer.manifest" }
    if (Test-Path $manifestPath) { $cscArgs += "/win32manifest:$manifestPath" }
    $cscArgs += $SourceDumpPath
    Write-Host "Compiling: $OutExe"
    $result = & $cscPath $cscArgs 2>&1
    $result | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "csc.exe compilation failed for $OutExe (exit code $LASTEXITCODE)" }
}

# --- Build 1: plain installer (no DNS) ---
$exePlain = if ([string]::IsNullOrWhiteSpace($OutputExe)) {
    Join-Path $distRoot "HoN_RU_Pack_Installer.exe"
} else { $OutputExe }
$codePlain = $programBase.Replace("__DNS_VISIBLE__", "false")
$dumpPlain = Join-Path $distRoot "installer_program.cs"
Build-InstallerExe -Code $codePlain -OutExe $exePlain -SourceDumpPath $dumpPlain
Write-Host "Plain installer built: $exePlain"

# --- Build 2: installer + DNS bypass ---
$exeDns = Join-Path $distRoot "HoN_RU_Pack_Installer_Bypass.exe"
$codeDns = $programBase.Replace("__DNS_VISIBLE__", "true")
$dumpDns = Join-Path $distRoot "installer_program_dns.cs"
Build-InstallerExe -Code $codeDns -OutExe $exeDns -SourceDumpPath $dumpDns
Write-Host "DNS bypass installer built: $exeDns"

Write-Host ""
Write-Host "Payload zip: $payloadZip"
Write-Host "Done. Two installers produced."
