$bytes = [System.IO.File]::ReadAllBytes(".\synapse_new.exe")
$callOffset = $bytes[0x205] + ($bytes[0x206] * 256) + ($bytes[0x207] * 65536) + ($bytes[0x208] * 16777216)
$expected = 0xEA0B

Write-Host "Entry stub CALL offset: 0x$($callOffset.ToString('X4'))"
Write-Host "Expected offset      : 0x$($expected.ToString('X4'))"

if ($callOffset -eq $expected) {
    Write-Host "`n✓✓✓ PERFECT MATCH! Testing executable..." -ForegroundColor Green
    
    $proc = Start-Process ".\synapse_new.exe" -PassThru -Wait -NoNewWindow
    $exit = $proc.ExitCode
    
    Write-Host "Exit Code: $exit"
    
    if ($exit -eq 42) {
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "   🎉 PHASE 77 COMPLETE! 🎉" -ForegroundColor Green
        Write-Host "   Entry Point Works Perfectly!" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Green
    }
} else {
    $diff = $expected - $callOffset
    Write-Host "`nOffset mismatch: difference = $diff bytes" -ForegroundColor Yellow
}
