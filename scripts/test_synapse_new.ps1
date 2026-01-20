# Test synapse_new.exe compilation
Write-Host "=== Testing synapse_new.exe ===" -ForegroundColor Cyan

# Test 1: Compile test_exit_99.syn
Write-Host "`nTest 1: Compiling test_exit_99.syn..." -ForegroundColor Yellow
.\synapse_new.exe test_exit_99.syn 2>&1 | Out-Null

if (Test-Path out.exe) {
    Write-Host "  out.exe created: YES" -ForegroundColor Green
    
    # Run out.exe and check exit code
    .\out.exe 2>&1 | Out-Null
    $exitCode = $LASTEXITCODE
    
    Write-Host "  out.exe exit code: $exitCode" -ForegroundColor $(if ($exitCode -eq 99) { "Green" } else { "Red" })
    
    if ($exitCode -eq 99) {
        Write-Host "  Result: SUCCESS!" -ForegroundColor Green
    } else {
        Write-Host "  Result: FAIL - Expected exit code 99" -ForegroundColor Red
    }
} else {
    Write-Host "  out.exe created: NO" -ForegroundColor Red
    Write-Host "  Result: FAIL" -ForegroundColor Red
}

# Test 2: Check synapse_new.exe PE structure
Write-Host "`nTest 2: Checking PE structure..." -ForegroundColor Yellow
$hex = Format-Hex synapse_new.exe -Count 512 | Select-Object -Skip 17 -First 1
Write-Host "  Data Directory (Import Table RVA at offset 0x110):"
Write-Host "  $($hex.Bytes -join ' ')"

# Test 3: Check if JIT array operations work
Write-Host "`nTest 3: Testing JIT array operations..." -ForegroundColor Yellow
.\bin\synapse.exe test_jit_array_minimal.syn 2>&1 | Out-Null
$jitExit = $LASTEXITCODE

Write-Host "  JIT test exit code: $jitExit" -ForegroundColor $(if ($jitExit -eq 0) { "Green" } else { "Red" })

if ($jitExit -eq 0) {
    Write-Host "  Result: JIT array operations WORK!" -ForegroundColor Green
} else {
    Write-Host "  Result: JIT array operations BROKEN!" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
