@echo off
setlocal
echo =================================
echo  PHASE 80: THE GRAND LOOP
echo =================================

echo [1] Compiling Gen 1 (synapse_new.exe) using Host Compiler...
bin\synapse.exe examples\synapse_full.syn
:: Note: Host compiler might return 1 on "success" or just failing to return 0 explicitly.
:: We check for file existence.

if exist synapse_new.exe (
    echo [SUCCESS] synapse_new.exe created.
) else (
    echo [FAIL] synapse_new.exe NOT created!
    exit /b 1
)

echo.
echo [2] Running Gen 1 to create Gen 2 (synapse_gen2.exe)...
synapse_new.exe
:: Gen 1 returns 0 on success (from my run_compiler code: returns 0)
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Gen 1 execution failed. Exit Code: %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

if exist synapse_gen2.exe (
    echo [SUCCESS] Gen 2 Created!
    dir synapse_gen2.exe
) else (
    echo [FAIL] Gen 2 not found.
)

echo.
echo =================================
echo  GRAND LOOP COMPLETE
echo =================================
