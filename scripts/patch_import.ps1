# Manually patch synapse_new.exe to fix Import RVA

Write-Host "=== Patching synapse_new.exe Import RVA ===" -ForegroundColor Cyan

if (-not (Test-Path synapse_new.exe)) {
    Write-Host "ERROR: synapse_new.exe not found!" -ForegroundColor Red
    exit
}

$bytes = [System.IO.File]::ReadAllBytes("synapse_new.exe")

# Find PE offset
$peOffset = [BitConverter]::ToUInt32($bytes, 0x3C)
Write-Host "PE offset: 0x$($peOffset.ToString('X'))" -ForegroundColor Yellow

# Data Directories offset
$dataDirOffset = $peOffset + 4 + 20 + 96
Write-Host "Data Directories offset: 0x$($dataDirOffset.ToString('X'))" -ForegroundColor Yellow

# Import RVA offset (Entry 1, after Export entry)
$importRVAoffset = $dataDirOffset + 8
Write-Host "Import RVA offset: 0x$($importRVAoffset.ToString('X'))" -ForegroundColor Yellow

# Read current value
$currentImportRVA = [BitConverter]::ToUInt32($bytes, $importRVAoffset)
Write-Host "Current Import RVA: 0x$($currentImportRVA.ToString('X8'))" -ForegroundColor Red

# Patch with 0x2028 (8232)
$newRVA = 8232
$rvaBytes = [BitConverter]::GetBytes([uint32]$newRVA)
$bytes[$importRVAoffset] = $rvaBytes[0]
$bytes[$importRVAoffset+1] = $rvaBytes[1]
$bytes[$importRVAoffset+2] = $rvaBytes[2]
$bytes[$importRVAoffset+3] = $rvaBytes[3]

Write-Host "Patched Import RVA to: 0x$($newRVA.ToString('X8')) ($newRVA)" -ForegroundColor Green

# Also patch IAT (Entry 12)
$iatRVAoffset = $dataDirOffset + (12 * 8)
$currentIATRVA = [BitConverter]::ToUInt32($bytes, $iatRVAoffset)
Write-Host "Current IAT RVA: 0x$($currentIATRVA.ToString('X8'))" -ForegroundColor Red

$bytes[$iatRVAoffset] = $rvaBytes[0]
$bytes[$iatRVAoffset+1] = $rvaBytes[1]
$bytes[$iatRVAoffset+2] = $rvaBytes[2]
$bytes[$iatRVAoffset+3] = $rvaBytes[3]

Write-Host "Patched IAT RVA to: 0x$($newRVA.ToString('X8')) ($newRVA)" -ForegroundColor Green

# Save patched file
[System.IO.File]::WriteAllBytes("synapse_patched.exe", $bytes)
Write-Host "`nPatched file saved as synapse_patched.exe" -ForegroundColor Cyan

# Test it
Write-Host "`n=== Testing patched synapse_patched.exe ===" -ForegroundColor Cyan
if (Test-Path test_exit_99.syn) {
    .\synapse_patched.exe test_exit_99.syn
    .\out.exe
    $exitCode = $LASTEXITCODE
    Write-Host "out.exe exit code: $exitCode" -ForegroundColor $(if ($exitCode -eq 99) { "Green" } else { "Red" })
} else {
    Write-Host "test_exit_99.syn not found, skipping test" -ForegroundColor Yellow
}

Write-Host "`n=== Patch Complete ===" -ForegroundColor Cyan
