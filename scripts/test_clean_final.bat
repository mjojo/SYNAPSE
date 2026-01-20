@echo off
setlocal enabledelayedexpansion
echo Testing CLEAN Gen1 with Phoenix host...
synapse_new.exe test_42.syn > clean_compile.txt 2>&1
set EXIT=!ERRORLEVEL!
echo Clean Gen1 exit: !EXIT!

if !EXIT! EQU 0 (
    if exist out.exe (
        out.exe
        set RESULT=!ERRORLEVEL!
        echo out.exe exit: !RESULT!
        if !RESULT! EQU 42 (
            echo ✅ CLEAN VERSION WORKS!
        ) else (
            echo ❌ Wrong result
        )
    )
) else (
    echo ❌ Compiler crashed
)
