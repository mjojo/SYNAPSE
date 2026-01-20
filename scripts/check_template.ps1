# Find Import RVA in bin\synapse.exe template

$bytes = [System.IO.File]::ReadAllBytes("bin\synapse.exe")

# pe_header_stub starts at MZ
$mzOffset = 0xDF0
Write-Host "pe_header_stub starts at: 0x$($mzOffset.ToString('X'))" -ForegroundColor Cyan

# Data Directories at offset +0xF8
$ddOffset = $mzOffset + 0xF8
Write-Host "Data Directories at: 0x$($ddOffset.ToString('X'))" -ForegroundColor Cyan

# Import RVA (Entry 1) at offset +8 from Data Directories
$importRVAoffset = $ddOffset + 8
$importRVA = [BitConverter]::ToUInt32($bytes, $importRVAoffset)
$importSize = [BitConverter]::ToUInt32($bytes, $importRVAoffset + 4)

Write-Host "`nImport Table (Entry 1):" -ForegroundColor Yellow
Write-Host "  Offset: 0x$($importRVAoffset.ToString('X'))"
Write-Host "  RVA: 0x$($importRVA.ToString('X8'))" -ForegroundColor $(if ($importRVA -eq 0x11000) { "Green" } else { "Red" })
Write-Host "  Size: 0x$($importSize.ToString('X'))"

# IAT RVA (Entry 12) at offset +12*8 from Data Directories
$iatRVAoffset = $ddOffset + (12 * 8)
$iatRVA = [BitConverter]::ToUInt32($bytes, $iatRVAoffset)
$iatSize = [BitConverter]::ToUInt32($bytes, $iatRVAoffset + 4)

Write-Host "`nIAT (Entry 12):" -ForegroundColor Yellow
Write-Host "  Offset: 0x$($iatRVAoffset.ToString('X'))"
Write-Host "  RVA: 0x$($iatRVA.ToString('X8'))" -ForegroundColor $(if ($iatRVA -eq 0x11028) { "Green" } else { "Red" })
Write-Host "  Size: 0x$($iatSize.ToString('X'))"

# Section headers
$sectOffset = $mzOffset + 0x188
Write-Host "`nSection headers at: 0x$($sectOffset.ToString('X'))" -ForegroundColor Cyan

# .idata VirtualAddress
$idataVAoffset = $sectOffset + 40 + 12  # Skip .text (40 bytes) + name (8) + VirtualSize (4)
$idataVA = [BitConverter]::ToUInt32($bytes, $idataVAoffset)
Write-Host ".idata VirtualAddress: 0x$($idataVA.ToString('X8'))" -ForegroundColor $(if ($idataVA -eq 0x11000) { "Green" } else { "Red" })
