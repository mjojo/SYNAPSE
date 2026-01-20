# Patch bin\synapse.exe template to fix Import RVA

$bytes = [System.IO.File]::ReadAllBytes("bin\synapse.exe")

Write-Host "=== Patching bin\synapse.exe PE template ===" -ForegroundColor Cyan

# Template at 0xDF0
$mzOffset = 0xDF0
$ddOffset = $mzOffset + 0xF8  # Data Directories

# Import RVA (Entry 1) at +8
$importRVAoffset = $ddOffset + 8
Write-Host "Import RVA offset: 0x$($importRVAoffset.ToString('X'))" -ForegroundColor Yellow

$currentRVA = [BitConverter]::ToUInt32($bytes, $importRVAoffset)
Write-Host "Current Import RVA: 0x$($currentRVA.ToString('X8'))" -ForegroundColor Red

# Patch with 0x11000
$newRVA = 0x11000
$rvaBytes = [BitConverter]::GetBytes([uint32]$newRVA)
$bytes[$importRVAoffset] = $rvaBytes[0]
$bytes[$importRVAoffset+1] = $rvaBytes[1]
$bytes[$importRVAoffset+2] = $rvaBytes[2]
$bytes[$importRVAoffset+3] = $rvaBytes[3]

# Patch Import Size with 0x100
$importSizeOffset = $importRVAoffset + 4
$newSize = 0x100
$sizeBytes = [BitConverter]::GetBytes([uint32]$newSize)
$bytes[$importSizeOffset] = $sizeBytes[0]
$bytes[$importSizeOffset+1] = $sizeBytes[1]
$bytes[$importSizeOffset+2] = $sizeBytes[2]
$bytes[$importSizeOffset+3] = $sizeBytes[3]

Write-Host "Patched Import RVA to: 0x$($newRVA.ToString('X8'))" -ForegroundColor Green
Write-Host "Patched Import Size to: 0x$($newSize.ToString('X'))" -ForegroundColor Green

# IAT (Entry 12) at +12*8
$iatRVAoffset = $ddOffset + (12 * 8)
$currentIATRVA = [BitConverter]::ToUInt32($bytes, $iatRVAoffset)
Write-Host "`nCurrent IAT RVA: 0x$($currentIATRVA.ToString('X8'))" -ForegroundColor Red

# Patch with 0x11028
$newIATRVA = 0x11028
$iatBytes = [BitConverter]::GetBytes([uint32]$newIATRVA)
$bytes[$iatRVAoffset] = $iatBytes[0]
$bytes[$iatRVAoffset+1] = $iatBytes[1]
$bytes[$iatRVAoffset+2] = $iatBytes[2]
$bytes[$iatRVAoffset+3] = $iatBytes[3]

# Patch IAT Size with 0x50
$iatSizeOffset = $iatRVAoffset + 4
$newIATSize = 0x50
$iatSizeBytes = [BitConverter]::GetBytes([uint32]$newIATSize)
$bytes[$iatSizeOffset] = $iatSizeBytes[0]
$bytes[$iatSizeOffset+1] = $iatSizeBytes[1]
$bytes[$iatSizeOffset+2] = $iatSizeBytes[2]
$bytes[$iatSizeOffset+3] = $iatSizeBytes[3]

Write-Host "Patched IAT RVA to: 0x$($newIATRVA.ToString('X8'))" -ForegroundColor Green
Write-Host "Patched IAT Size to: 0x$($newIATSize.ToString('X'))" -ForegroundColor Green

# Save
[System.IO.File]::WriteAllBytes("bin\synapse.exe", $bytes)
Write-Host "`nbin\synapse.exe template patched successfully!" -ForegroundColor Cyan
