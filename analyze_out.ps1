# Analyze out.exe PE Structure
Write-Host "=== Analyzing out.exe PE Structure ===" -ForegroundColor Cyan

if (-not (Test-Path out.exe)) {
    Write-Host "ERROR: out.exe not found!" -ForegroundColor Red
    exit
}

$bytes = [System.IO.File]::ReadAllBytes("out.exe")

# Show Optional Header location
$peOffset = [BitConverter]::ToUInt32($bytes, 0x3C)
Write-Host "`nPE Signature offset (e_lfanew): 0x$($peOffset.ToString('X'))" -ForegroundColor Yellow

# Data Directories
$dataDirOffset = $peOffset + 4 + 20 + 96
Write-Host "Data Directories should start at: 0x$($dataDirOffset.ToString('X'))" -ForegroundColor Yellow

# Read Data Directory 1 (Import Table)
$importRVA = [BitConverter]::ToUInt32($bytes, $dataDirOffset + 8)
$importSize = [BitConverter]::ToUInt32($bytes, $dataDirOffset + 12)

Write-Host "`nData Directory Entry 1 (Import Table):" -ForegroundColor Cyan
Write-Host "  Offset in file: 0x$($dataDirOffset + 8).ToString('X'))" 
Write-Host "  Import RVA: 0x$($importRVA.ToString('X8'))" -ForegroundColor $(if ($importRVA -eq 0x11000) { "Green" } else { "Red" })
Write-Host "  Import Size: $importSize"

# Read Data Directory 12 (IAT)
$iatRVA = [BitConverter]::ToUInt32($bytes, $dataDirOffset + (12 * 8))
$iatSize = [BitConverter]::ToUInt32($bytes, $dataDirOffset + (12 * 8) + 4)

Write-Host "`nData Directory Entry 12 (IAT):" -ForegroundColor Cyan
Write-Host "  Offset in file: 0x$($dataDirOffset + (12 * 8)).ToString('X'))"
Write-Host "  IAT RVA: 0x$($iatRVA.ToString('X8'))" -ForegroundColor $(if ($iatRVA -eq 0x11028) { "Green" } else { "Red" })
Write-Host "  IAT Size: $iatSize"

# Check Section Headers
$sectOffset = $dataDirOffset + 128
Write-Host "`nSection Headers at: 0x$($sectOffset.ToString('X'))" -ForegroundColor Cyan

# .text
$textVA = [BitConverter]::ToUInt32($bytes, $sectOffset + 12)
Write-Host ".text VirtualAddress: 0x$($textVA.ToString('X8'))"

# .idata
$idataVA = [BitConverter]::ToUInt32($bytes, $sectOffset + 40 + 12)
Write-Host ".idata VirtualAddress: 0x$($idataVA.ToString('X8'))" -ForegroundColor $(if ($idataVA -eq 0x11000) { "Green" } else { "Red" })
