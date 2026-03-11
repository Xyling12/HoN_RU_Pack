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
    "hon_auto_agent.ps1",
    "set_login_banner.ps1",
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

Compress-Archive -Path (Join-Path $stageRoot "*") -DestinationPath $payloadZip -Force
$payloadBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($payloadZip))

$chunks = New-Object System.Collections.Generic.List[string]
$chunkSize = 24000
for ($offset = 0; $offset -lt $payloadBase64.Length; $offset += $chunkSize) {
    $len = [Math]::Min($chunkSize, $payloadBase64.Length - $offset)
    $chunks.Add($payloadBase64.Substring($offset, $len))
}

$payloadBuilder = New-Object System.Text.StringBuilder
[void]$payloadBuilder.AppendLine("string payloadBase64 =")
for ($i = 0; $i -lt $chunks.Count; $i++) {
    $suffix = if ($i -eq $chunks.Count - 1) { ";" } else { " +" }
    [void]$payloadBuilder.AppendLine(('    "{0}"{1}' -f $chunks[$i], $suffix))
}
$payloadCode = $payloadBuilder.ToString()

# Load WinForms C# template from external file
$templatePath = Join-Path $PackageRoot "installer_template.cs"
if (-not (Test-Path $templatePath)) { throw "C# template not found: $templatePath" }
$programTemplate = Get-Content -Path $templatePath -Raw

# Inject payload and version
$version = (Get-Content (Join-Path $PackageRoot "version.txt") -Raw).Trim()
$programCode = $programTemplate.Replace("__PAYLOAD__", $payloadCode).Replace("__VERSION__", $version)
Set-Content -Path $sourceDump -Value $programCode -Encoding UTF8

if (Test-Path $OutputExe) { Remove-Item -Path $OutputExe -Force }

# Find csc.exe from .NET Framework
$cscPath = Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "csc.exe"
if (-not (Test-Path $cscPath)) { throw "csc.exe not found at: $cscPath" }

$iconPath = Join-Path $distRoot "installer_icon.ico"
$cscArgs = @(
    "/target:winexe",
    "/out:`"$OutputExe`"",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.Drawing.dll",
    "/reference:System.IO.Compression.dll",
    "/reference:System.IO.Compression.FileSystem.dll",
    "/optimize+"
)
if (Test-Path $iconPath) { $cscArgs += "/win32icon:`"$iconPath`"" }
$cscArgs += "`"$sourceDump`""

Write-Host "Compiling with: $cscPath"
$cscResult = & $cscPath $cscArgs 2>&1
$cscResult | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { throw "csc.exe compilation failed with exit code $LASTEXITCODE" }

Write-Host "Installer built: $OutputExe"
Write-Host "Payload zip: $payloadZip"
Write-Host "Source dump: $sourceDump"
