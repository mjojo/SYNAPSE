@echo off
echo ========================================
echo PHOENIX RESURRECTION TEST
echo ========================================
echo.

echo [1] Testing Phoenix with test_seven.syn...
bin\synapse_phoenix.exe test_seven.syn > phoenix_test.txt 2>&1
if exist synapse_new.exe (
    synapse_new.exe
    if %ERRORLEVEL% EQU 7 (
        echo ✅ PHOENIX WORKS! Basic test passed!
    ) else (
        echo ❌ Wrong exit code: %ERRORLEVEL%
        exit /b 1
    )
    del synapse_new.exe
) else (
    echo ❌ No synapse_new.exe
    type phoenix_test.txt
    exit /b 1
)

echo.
echo [2] Testing Phoenix with synapse_full.syn (Phase 71)...
bin\synapse_phoenix.exe examples\synapse_full.syn > phoenix_full.txt 2>&1
set RESULT=%ERRORLEVEL%
echo Phoenix compilation exit: %RESULT%

if %RESULT% NEQ 0 (
    echo ❌ Compilation failed!
    type phoenix_full.txt | findstr /I "error"
    exit /b 1
)

if not exist synapse_new.exe (
    echo ❌ No synapse_new.exe created
    exit /b 1
)

echo ✅ PHASE 71 COMPILED!
echo.
echo [3] Testing Phase 71 with test_const.syn...
synapse_new.exe test_const.syn > const_test.txt 2>&1
set COMPILE=%ERRORLEVEL%

if %COMPILE% NEQ 0 (
    echo ❌ Gen1 crashed: %COMPILE%
    type const_test.txt
    exit /b 1
)

if exist out.exe (
    out.exe
    if %ERRORLEVEL% EQU 42 (
        echo.
        echo ╔══════════════════════════════════════╗
        echo ║  🎉 SUCCESS! CONST KEYWORD WORKS! 🎉  ║
        echo ╚══════════════════════════════════════╝
        exit /b 0
    ) else (
        echo ❌ Wrong exit: %ERRORLEVEL% (expected 42)
        exit /b 1
    )
) else (
    echo ❌ No out.exe
    exit /b 1
)
