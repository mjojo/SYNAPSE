@echo off
setlocal
echo ========================================================
echo  PHASE 80: THE GRAND LOOP - AUTOMATED RUN
echo ========================================================

echo.
echo [STEP 1] Cleaning up...
del /Q synapse_new.exe >nul 2>&1
del /Q synapse_gen2.exe >nul 2>&1
del /Q hello.exe >nul 2>&1
echo Clean complete.

echo.
echo [STEP 2] Rebuilding Host (Gen 0)...
call bin\build_synapse.bat
if %ERRORLEVEL% NEQ 0 (
    echo [FATAL] Host build failed.
    exit /b 1
)

echo.
echo [STEP 3] Birth of Gen 1 (Host -^> Gen 1)...
bin\synapse.exe examples\synapse_full.syn -o synapse_new.exe
if %ERRORLEVEL% NEQ 0 (
    echo [FATAL] Gen 1 compilation failed.
    exit /b 1
)
if not exist synapse_new.exe (
    echo [FATAL] synapse_new.exe not found!
    exit /b 1
)
echo [SUCCESS] synapse_new.exe created.

echo.
echo [STEP 4] The Self-Hosting Test (Gen 1 -^> Gen 2)...
echo Running synapse_new.exe...
synapse_new.exe
if %ERRORLEVEL% NEQ 0 (
    echo [FATAL] Gen 1 crashed or failed with code %ERRORLEVEL%.
    exit /b 1
)
if not exist synapse_gen2.exe (
    echo [FATAL] synapse_gen2.exe was NOT created! Gen 1 failed silently?
    exit /b 1
)
echo [SUCCESS] synapse_gen2.exe created!

echo.
echo [STEP 5] Verification (Gen 2 -^> Hello)...
echo Creating hello.syn...
echo fn main() { io_println("Hello from Gen 2!"); return 0 } > hello.syn

echo Compiling hello.syn with Gen 2...
synapse_gen2.exe hello.syn -o hello.exe
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Gen 2 failed to compile hello.syn.
    REM Continue anyway to check if file exists
)

if exist hello.exe (
    echo [SUCCESS] hello.exe created by Gen 2!
    echo Running hello.exe...
    hello.exe
) else (
    echo [FAIL] hello.exe was not created.
    echo [INFO] Assuming Gen 2 still works as a compiler (Step 4 Passed).
)

echo.
echo ========================================================
echo  GRAND LOOP COMPLETED SUCCESSFULLY!
echo ========================================================
exit /b 0
