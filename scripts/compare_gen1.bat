@echo off
setlocal enabledelayedexpansion

del test_result.txt 2>nul

echo Testing CLEAN Gen1 (no Phase 71)...
synapse_clean.exe test_42.syn > clean_output.txt 2>&1
set COMPILE=!ERRORLEVEL!

if exist out.exe (
    out.exe
    set RESULT=!ERRORLEVEL!
    echo Clean Gen1: Compile=!COMPILE! Run=!RESULT! > test_result.txt
    del out.exe
) else (
    echo Clean Gen1: Compile=!COMPILE! NoOutput >> test_result.txt
)

echo.
echo Testing PHASE71 Gen1...
synapse_new.exe test_42.syn > ph71_output.txt 2>&1
set COMPILE2=!ERRORLEVEL!

if exist out.exe (
    out.exe
    set RESULT2=!ERRORLEVEL!
    echo Phase71 Gen1: Compile=!COMPILE2! Run=!RESULT2! >> test_result.txt
    del out.exe
) else (
    echo Phase71 Gen1: Compile=!COMPILE2! NoOutput >> test_result.txt
)

type test_result.txt
