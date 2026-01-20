@echo off
setlocal enabledelayedexpansion
echo Testing CLEAN synapse_full.syn (from git, no Phase 71)...
synapse_new.exe test_42.syn > clean_git_test.txt 2>&1
set EXIT=!ERRORLEVEL!
echo Compiler exit: !EXIT!

if !EXIT! EQU 0 (
    if exist out.exe (
        out.exe
        set RESULT=!ERRORLEVEL!
        echo out.exe exit: !RESULT!
        if !RESULT! EQU 42 (
            echo.
            echo ✅✅✅ CLEAN VERSION WORKS! ✅✅✅
            echo Problem WAS in Phase 71 code!
            exit /b 0
        ) else (
            echo ❌ Wrong exit code
        )
    ) else (
        echo ❌ No out.exe
    )
) else (
    echo ❌ Compiler crashed with: !EXIT!
    echo Phoenix itself works, but something in synapse_full.syn structure breaks.
)
