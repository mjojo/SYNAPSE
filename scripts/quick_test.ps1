$bytes = [System.IO.File]::ReadAllBytes(".\synapse_new.exe")
$callOffset = $bytes[0x205] + ($bytes[0x206] * 256) + ($bytes[0x207] * 65536) + ($bytes[0x208] * 16777216)
$expected = 0xEA0B

Write-Host "Entry stub CALL offset:" $callOffset.ToString("X4")
Write-Host "Expected offset:" $expected.ToString("X4")

if ($callOffset -eq $expected) {
    Write-Host ""
    Write-Host "SUCCESS - CALL offset is PERFECT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Testing executable..." -ForegroundColor Yellow
    
    $proc = Start-Process ".\synapse_new.exe" -PassThru -Wait -NoNewWindow
    $exit = $proc.ExitCode
    
    Write-Host "Exit Code:" $exit
    
    if ($exit -eq 42) {
        Write-Host ""
        Write-Host "========================================"  -ForegroundColor Green
        Write-Host "   PHASE 77 COMPLETE - VICTORY!"  -ForegroundColor Green
        Write-Host "   Entry Point Works!" -ForegroundColor Green
        Write-Host "========================================"  -ForegroundColor Green
    }
} else {
    $diff = $expected - $callOffset
    Write-Host "Offset mismatch - difference:" $diff "bytes" -ForegroundColor Yellow
}
