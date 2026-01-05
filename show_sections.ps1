# Analyze section table in synapse_new.exe

$bytes = [System.IO.File]::ReadAllBytes('synapse_new.exe')

# Get PE offset
$peOffset = [BitConverter]::ToUInt32($bytes, 0x3C)
Write-Host "PE offset: 0x$($peOffset.ToString('X'))" -ForegroundColor Cyan

# Number of sections (at PE+6)
$numSections = [BitConverter]::ToUInt16($bytes, $peOffset + 6)
Write-Host "Number of sections: $numSections`n" -ForegroundColor Cyan

# Section table starts after Optional Header
# PE + 4 (signature) + 20 (COFF) + SizeOfOptionalHeader
$sizeOfOptHeader = [BitConverter]::ToUInt16($bytes, $peOffset + 20)
$sectionTableOffset = $peOffset + 4 + 20 + $sizeOfOptHeader

Write-Host "Section Table at offset: 0x$($sectionTableOffset.ToString('X'))`n" -ForegroundColor Yellow

# Each section header is 40 bytes
for ($i = 0; $i -lt $numSections; $i++) {
    $secOffset = $sectionTableOffset + ($i * 40)
    
    # Section name (8 bytes, null-terminated)
    $name = [System.Text.Encoding]::ASCII.GetString($bytes, $secOffset, 8).TrimEnd([char]0)
    
    # Virtual Size (offset +8)
    $virtualSize = [BitConverter]::ToUInt32($bytes, $secOffset + 8)
    
    # Virtual Address (offset +12)
    $virtualAddr = [BitConverter]::ToUInt32($bytes, $secOffset + 12)
    
    # Size of Raw Data (offset +16)
    $rawSize = [BitConverter]::ToUInt32($bytes, $secOffset + 16)
    
    # Pointer to Raw Data (offset +20)
    $rawPointer = [BitConverter]::ToUInt32($bytes, $secOffset + 20)
    
    Write-Host "Section $($i + 1): $name" -ForegroundColor Green
    Write-Host "  Virtual Address: 0x$($virtualAddr.ToString('X8'))" -ForegroundColor Yellow
    Write-Host "  Virtual Size:    0x$($virtualSize.ToString('X8'))"
    Write-Host "  Raw Size:        0x$($rawSize.ToString('X8'))"
    Write-Host "  Raw Pointer:     0x$($rawPointer.ToString('X8'))`n"
}
