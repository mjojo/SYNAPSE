.\synapse_new.exe
Write-Host "Exit Code: $LASTEXITCODE"
if ($LASTEXITCODE -eq 42) {
    Write-Host "SUCCESS - Entry point works!" -ForegroundColor Green
} else {
    Write-Host "FAILED - Exit: $LASTEXITCODE" -ForegroundColor Red
}
