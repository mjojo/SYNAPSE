# Analyze synapse_new.exe PE structure in detail
Write-Host "=== Analyzing synapse_new.exe PE Structure ===" -ForegroundColor Cyan

if (-not (Test-Path synapse_new.exe)) {
    Write-Host "ERROR: synapse_new.exe not found!" -ForegroundColor Red
    exit
}

$bytes = [System.IO.File]::ReadAllBytes("synapse_new.exe")

# Show Optional Header location (after PE signature + COFF header)
$peOffset = [BitConverter]::ToUInt32($bytes, 0x3C)
Write-Host "`nPE Signature offset (e_lfanew): 0x$($peOffset.ToString('X'))" -ForegroundColor Yellow

# Data Directories start at: PE_offset + 4 (PE sig) + 20 (COFF) + 96 (Opt Header standard+windows) = offset + 120
$dataDirOffset = $peOffset + 4 + 20 + 96
Write-Host "Data Directories should start at: 0x$($dataDirOffset.ToString('X'))" -ForegroundColor Yellow

# Read Data Directory 1 (Import Table)
$importRVA = [BitConverter]::ToUInt32($bytes, $dataDirOffset + 8)  # Entry 1 is after Entry 0 (8 bytes)
$importSize = [BitConverter]::ToUInt32($bytes, $dataDirOffset + 12)

Write-Host "`nData Directory Entry 1 (Import Table):" -ForegroundColor Cyan
Write-Host "  Offset in file: 0x$($dataDirOffset + 8).ToString('X'))" 
Write-Host "  Import RVA: 0x$($importRVA.ToString('X8')) ($importRVA decimal)" -ForegroundColor $(if ($importRVA -eq 8232) { "Green" } else { "Red" })
Write-Host "  Import Size: $importSize"

# Expected vs Actual
Write-Host "`nExpected: 0x2028 (8232)" -ForegroundColor Yellow
Write-Host "Actual:   0x$($importRVA.ToString('X')) ($importRVA)" -ForegroundColor $(if ($importRVA -eq 8232) { "Green" } else { "Red" })

if ($importRVA -ne 8232) {
    Write-Host "`nPROBLEM: Import RVA is WRONG!" -ForegroundColor Red
    Write-Host "This means put_dword() did NOT write to offset 0x$($dataDirOffset + 8).ToString('X'))" -ForegroundColor Red
}

Write-Host "`n=== Analysis Complete ===" -ForegroundColor Cyan
