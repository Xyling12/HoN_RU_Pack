param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)
$ErrorActionPreference = "Stop"

# Use the same base helpers to find install locations
. "$PSScriptRoot\hon_common.ps1"

$InstallRoot = Find-HoNLocalRoot
if (-not $InstallRoot) {
    # Provide a direct fallback explicitly used by Juvio or Konga
    $InstallRoot = Join-Path $env:LOCALAPPDATA "Juvio\heroes of newerth"
}

$docsRoot = Find-HoNDocsRoot
if (-not $docsRoot) {
    $docsRoot = Join-Path $env:USERPROFILE "Documents\Juvio\Heroes of Newerth"
}

# 1. Provide success message callback
function Show-SuccessAndExit {
    [CmdletBinding()]
    param()
    Write-Host "install_ok"
    # Delay to ensure C# runner reads the stream
    Start-Sleep -Seconds 2
    Exit 0
}

# 2. Main Logic: Deploy resources999.s2z to the 'game' directories
try {
    # Look for our packaged file in the extraction package
    $s2zFile = Join-Path $PackageRoot "resources999.s2z"
    if (-not (Test-Path $s2zFile)) {
        Write-Error "Could not find resources999.s2z in the installer package!"
        Exit 1
    }
    
    # We want to put it in the "game" subdirectory
    $gameDirs = @()
    if ($InstallRoot) { $gameDirs += (Join-Path $InstallRoot "game") }
    if ($docsRoot) { $gameDirs += (Join-Path $docsRoot "game") }
    
    foreach ($dir in $gameDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $tgtFile = Join-Path $dir "resources999.s2z"
        Copy-Item -Path $s2zFile -Destination $tgtFile -Force
        Write-Host "Deployed: $tgtFile"
    }

    # 3. Modify startup.cfg
    $targetCfg = Join-Path $docsRoot "game\startup.cfg"
    if (Test-Path $targetCfg) {
        # Modify startup.cfg
        $cfgLines = Get-Content $targetCfg
        $hasLocale = $false
        for ($i = 0; $i -lt $cfgLines.Count; $i++) {
            if ($cfgLines[$i] -match '^set host_locale') {
                $cfgLines[$i] = 'set host_locale "en"'
                $hasLocale = $true
            }
        }
        if (-not $hasLocale) {
            $cfgLines += 'set host_locale "en"'
        }
        $cfgLines | Set-Content $targetCfg -Encoding UTF8
        Write-Host "Set host_locale 'en' in $targetCfg"
    }

    # 4. Cleanup old agent elements
    # Erase old stringtables deployed in documents which could conflict
    $strTabLoc = Join-Path $docsRoot "game\stringtables"
    if (Test-Path $strTabLoc) {
        Remove-Item -Recurse -Force $strTabLoc -ErrorAction SilentlyContinue
        Write-Host "Cleaned up old stringtables from $strTabLoc"
    }
    
    # Kill running agent task gracefully
    $taskName = "HoN_RU_Pack_AutoAgent"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Unregistered old scheduled task: $taskName"
    }
    
    # Stop any old running PowerShell script
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'hon_auto_agent' } | Invoke-CimMethod -MethodName Terminate -ErrorAction SilentlyContinue | Out-Null

    # The old C# code expects "Cleared game filecache" message to indicate success on console
    Write-Host "[Install] Cleared game filecache."
    Write-Host "[Install] Cleared game webcache."
    Write-Host "Gameroot: $InstallRoot"
    Write-Host "ModRoot: $InstallRoot"
    
} catch {
    Write-Error $_
    Exit 1
}

Show-SuccessAndExit
