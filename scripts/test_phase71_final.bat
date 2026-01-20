@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Phase 71: CONST Keyword Test
echo ============================================
echo.

echo [Test 1] Compiling test_const.syn...
synapse_new.exe test_const.syn > const_compile.txt 2>&1
set COMPILE_EXIT=!ERRORLEVEL!
echo Compiler exit: !COMPILE_EXIT!

if !COMPILE_EXIT! NEQ 0 (
    echo ❌ COMPILATION FAILED
    type const_compile.txt
    exit /b 1
)

if not exist out.exe (
    echo ❌ No out.exe created
    type const_compile.txt
    exit /b 1
)

echo [Test 2] Running out.exe...
out.exe
set OUT_EXIT=!ERRORLEVEL!
echo Program exit code: !OUT_EXIT!

if !OUT_EXIT! EQU 42 (
    echo.
    echo ✅✅✅ SUCCESS! CONST KEYWORD WORKS! ✅✅✅
    echo Expected: 42
    echo Got: !OUT_EXIT!
    exit /b 0
) else (
    echo.
    echo ❌ WRONG EXIT CODE
    echo Expected: 42
    echo Got: !OUT_EXIT!
    exit /b 1
)
