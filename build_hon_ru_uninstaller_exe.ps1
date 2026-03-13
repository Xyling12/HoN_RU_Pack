param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$OutputExe = ""
)

$ErrorActionPreference = "Stop"

$distRoot = Join-Path $PackageRoot "dist"
New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

# Scripts needed for uninstall
$uninstallScripts = @(
    "uninstall_hon_ru_pack.ps1",
    "hon_common.ps1",
    "remove_amneziawg.ps1",
    "restore_dns.ps1"
)

foreach ($name in $uninstallScripts) {
    $src = Join-Path $PackageRoot $name
    if (-not (Test-Path $src)) { throw "Missing required file: $src" }
}

# Stage uninstaller payload
$stageRoot = Join-Path $distRoot "uninstaller_payload_stage"
$payloadZip = Join-Path $distRoot "uninstaller_payload.zip"

if (Test-Path $stageRoot) { Remove-Item -Path $stageRoot -Recurse -Force }
if (Test-Path $payloadZip) { Remove-Item -Path $payloadZip -Force }
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

foreach ($name in $uninstallScripts) {
    $src = Join-Path $PackageRoot $name
    Copy-Item -Path $src -Destination (Join-Path $stageRoot $name) -Force
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

# Load C# template
$templatePath = Join-Path $PackageRoot "uninstaller_template.cs"
if (-not (Test-Path $templatePath)) { throw "C# template not found: $templatePath" }
$programTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)

# Inject payload and version
$version = (Get-Content (Join-Path $PackageRoot "version.txt") -Raw).Trim()
$programCode = $programTemplate.Replace("__PAYLOAD__", $payloadCode).Replace("__VERSION__", $version)

# Find csc.exe
$cscPath = Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "csc.exe"
if (-not (Test-Path $cscPath)) { throw "csc.exe not found at: $cscPath" }

$iconPath = Join-Path $distRoot "uninstaller_icon.ico"
$outExe = if ([string]::IsNullOrWhiteSpace($OutputExe)) {
    Join-Path $distRoot "HoN_RU_Pack_Uninstaller.exe"
} else { $OutputExe }
$sourceDump = Join-Path $distRoot "uninstaller_program.cs"

Set-Content -Path $sourceDump -Value $programCode -Encoding UTF8
if (Test-Path $outExe) { Remove-Item -Path $outExe -Force }

$manifestPath = Join-Path $PackageRoot "admin.manifest"

$cscArgs = @(
    "/target:winexe",
    "/out:`"$outExe`"",
    "/codepage:65001",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.Drawing.dll",
    "/reference:System.IO.Compression.dll",
    "/reference:System.IO.Compression.FileSystem.dll",
    "/optimize+"
)
if (Test-Path $manifestPath) { $cscArgs += "/win32manifest:`"$manifestPath`"" }
if (Test-Path $iconPath) { $cscArgs += "/win32icon:`"$iconPath`"" }
$cscArgs += "`"$sourceDump`""

Write-Host "Compiling: $outExe"
$result = & $cscPath $cscArgs 2>&1
$result | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { throw "csc.exe compilation failed (exit code $LASTEXITCODE)" }

Write-Host ""
Write-Host "Uninstaller built: $outExe"
Write-Host "Done."
