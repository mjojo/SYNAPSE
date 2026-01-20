@echo off
echo ============================================
echo Phase 71 Comprehensive Test
echo ============================================

echo.
echo [1] Testing Gen1 compiler startup...
synapse_new.exe > nul 2>&1
if %ERRORLEVEL% EQU -1073741819 (
    echo FAIL: Gen1 crashes on startup
    exit /b 1
) else (
    echo OK: Gen1 starts without crash
)

echo.
echo [2] Compiling test_42.syn...
del out.exe 2>nul
synapse_new.exe test_42.syn > test42_out.txt 2>&1
set GEN1_EXIT=%ERRORLEVEL%
echo Gen1 exit code: %GEN1_EXIT%

if %GEN1_EXIT% EQU -1073741819 (
    echo FAIL: Gen1 crashes during compilation
    exit /b 1
)

if exist out.exe (
    echo OK: out.exe created
    out.exe
    set OUT_EXIT=%ERRORLEVEL%
    echo out.exe returned: %OUT_EXIT%
    if %OUT_EXIT% EQU 42 (
        echo SUCCESS: Test passed!
    ) else (
        echo FAIL: Expected 42, got %OUT_EXIT%
    )
) else (
    echo FAIL: No out.exe created
    echo Gen1 output:
    type test42_out.txt
    exit /b 1
)

echo.
echo [3] Testing const keyword...
del out.exe 2>nul
synapse_new.exe test_const.syn > testconst_out.txt 2>&1
set CONST_EXIT=%ERRORLEVEL%
echo Gen1 exit code: %CONST_EXIT%

if %CONST_EXIT% EQU -1073741819 (
    echo FAIL: Gen1 crashes with const
    exit /b 1
)

if exist out.exe (
    echo OK: out.exe created
    out.exe
    set OUT_EXIT=%ERRORLEVEL%
    echo out.exe returned: %OUT_EXIT%
    if %OUT_EXIT% EQU 42 (
        echo SUCCESS: Const test passed!
    ) else (
        echo FAIL: Expected 42, got %OUT_EXIT%
    )
) else (
    echo FAIL: No out.exe created
    echo Gen1 output:
    type testconst_out.txt
)

echo.
echo ============================================
echo Test Complete
echo ============================================
