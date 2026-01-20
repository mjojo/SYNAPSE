@echo off
setlocal enabledelayedexpansion
synapse_new.exe test_42.syn > v1_test.txt 2>&1
set EXIT=!ERRORLEVEL!
if !EXIT! EQU 0 (
    if exist out.exe (
        out.exe
        if !ERRORLEVEL! EQU 42 (
            echo ✅ V1 WORKS! Exit: !ERRORLEVEL!
            exit /b 0
        )
    )
)
echo ❌ V1 FAILED. Exit: !EXIT!
type v1_test.txt
