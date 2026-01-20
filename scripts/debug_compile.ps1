# Debug script - trace JIT execution of synapse_full.syn
Write-Host "=== Recompiling synapse_new.exe with JIT ===" -ForegroundColor Cyan

# Delete old file
if (Test-Path synapse_new.exe) {
    Remove-Item synapse_new.exe -Force
    Write-Host "Deleted old synapse_new.exe" -ForegroundColor Yellow
}

# Compile with JIT
Write-Host "`nCompiling with bin\synapse.exe..." -ForegroundColor Yellow
$output = .\bin\synapse.exe examples\synapse_full.syn 2>&1
$output | Select-Object -Last 10

# Check if created
if (Test-Path synapse_new.exe) {
    Write-Host "`nsynapse_new.exe created!" -ForegroundColor Green
    
    # Check file size
    $size = (Get-Item synapse_new.exe).Length
    Write-Host "File size: $size bytes" -ForegroundColor Cyan
    
    # Check Import RVA
    Write-Host "`nChecking Import Table RVA (should be 0x2028 = 8232)..." -ForegroundColor Yellow
    
    $bytes = [System.IO.File]::ReadAllBytes("synapse_new.exe")
    $offset = 0x110
    $rva = [BitConverter]::ToUInt32($bytes, $offset)
    
    Write-Host "Import RVA at offset 0x110: 0x$($rva.ToString('X8')) ($rva decimal)" -ForegroundColor $(if ($rva -eq 8232) { "Green" } else { "Red" })
    
    if ($rva -ne 8232) {
        Write-Host "PROBLEM: Expected 0x2028 (8232) but got 0x$($rva.ToString('X8'))" -ForegroundColor Red
        
        # Try to find where 8232 was written
        Write-Host "`nSearching for 8232 (0x2028) in file..." -ForegroundColor Yellow
        for ($i = 0; $i -lt $bytes.Length - 3; $i++) {
            $val = [BitConverter]::ToUInt32($bytes, $i)
            if ($val -eq 8232) {
                Write-Host "  Found 8232 at file offset 0x$($i.ToString('X'))" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "SUCCESS: Import RVA is correct!" -ForegroundColor Green
    }
    
    # Test if synapse_new.exe works
    Write-Host "`nTesting synapse_new.exe with test_exit_99.syn..." -ForegroundColor Yellow
    .\synapse_new.exe test_exit_99.syn 2>&1 | Out-Null
    
    if (Test-Path out.exe) {
        .\out.exe 2>&1 | Out-Null
        $code = $LASTEXITCODE
        Write-Host "out.exe exit code: $code" -ForegroundColor $(if ($code -eq 99) { "Green" } else { "Red" })
    }
    
} else {
    Write-Host "`nERROR: synapse_new.exe not created!" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Cyan
