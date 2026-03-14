# Apply all polishes to agent bundle files WITHOUT touching agent script
# Step 1: Copy original files to temp, apply passes, copy back

$agentBundle = Join-Path $env:LOCALAPPDATA "HoN_RU_Pack\bundle"
$scripts = "d:\HoN_RU_Pack\dist"

# Run Pass 1 on agent bundle files directly
Write-Host "=== Step 1: Backup agent files to our bundle ==="
$bundleDir = "d:\HoN_RU_Pack\bundle"
foreach ($f in (Get-ChildItem "$agentBundle\*_en.str")) {
    Copy-Item $f.FullName (Join-Path $bundleDir $f.Name) -Force
    Write-Host "Backed up $($f.Name) ($($f.Length) bytes)"
}

Write-Host "`n=== Step 2: Apply Pass 1 (binary) ==="
& powershell -NoProfile -EP Bypass -File "$scripts\_pass1_binary.ps1"

Write-Host "`n=== Step 3: Apply version bump (binary) ==="
& powershell -NoProfile -EP Bypass -File "$scripts\_version_and_sync.ps1"

Write-Host "`n=== Step 4: Apply Pass 2+3 (binary) ==="
& powershell -NoProfile -EP Bypass -File "$scripts\_pass23_binary.ps1"

Write-Host "`n=== Step 5: Apply Pass 4 (binary) ==="
& powershell -NoProfile -EP Bypass -File "$scripts\_pass4_binary.ps1"

Write-Host "`n=== Step 6: Copy polished files back to agent bundle ==="
foreach ($f in (Get-ChildItem "$bundleDir\*_en.str")) {
    Copy-Item $f.FullName (Join-Path $agentBundle $f.Name) -Force
    Write-Host "Updated agent: $($f.Name) ($($f.Length) bytes)"
}

Write-Host "`nDone! Agent will sync polished files on next cycle (30s)."
Write-Host "Restart HoN twice to see v1.7.1."
