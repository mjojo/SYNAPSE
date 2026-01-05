# Show template in bin\synapse.exe

$bytes = [System.IO.File]::ReadAllBytes("bin\synapse.exe")

Write-Host "=== PE Header Template in bin\synapse.exe ===" -ForegroundColor Cyan

# Show Data Directories area (Entry 1 at offset 8 from start of Dir)
# Template starts around offset 0xE78 based on synapse.asm
# But we found 0x11000 at 0xF00, so Data Directories at 0xF00-8 = 0xEF8

$ddOffset = 0xEF8
Write-Host "`nData Directories at offset 0x$($ddOffset.ToString('X')):" -ForegroundColor Yellow

for ($i = 0; $i -lt 16; $i++) {
    $entryOffset = $ddOffset + ($i * 8)
    $rva = [BitConverter]::ToUInt32($bytes, $entryOffset)
    $size = [BitConverter]::ToUInt32($bytes, $entryOffset + 4)
    
    $name = switch ($i) {
        0 { "Export" }
        1 { "Import" }
        2 { "Resource" }
        12 { "IAT" }
        default { "Entry$i" }
    }
    
    if ($rva -ne 0 -or $size -ne 0) {
        Write-Host "  $name`: RVA=0x$($rva.ToString('X8')), Size=0x$($size.ToString('X'))" -ForegroundColor $(if ($i -eq 1 -or $i -eq 12) { "Green" } else { "Gray" })
    }
}
