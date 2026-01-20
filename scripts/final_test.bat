@echo off
setlocal enabledelayedexpansion

echo ========================================
echo FINAL PHASE 71 TEST
echo ========================================
echo.

echo [Step 1] Using archived compiler...
start /wait /b archive\old_builds\synapse_old.exe examples\synapse_phase71_backup.syn > archive_compile.txt 2>&1
set ARCHIVE_EXIT=!ERRORLEVEL!
echo Archive compiler exit: !ARCHIVE_EXIT! > final_test_log.txt

if exist synapse_new.exe (
    echo Gen1 created by archive compiler >> final_test_log.txt
    
    echo [Step 2] Testing with test_const.syn...
    start /wait /b synapse_new.exe test_const.syn > const_compile_result.txt 2>&1
    set CONST_EXIT=!ERRORLEVEL!
    echo Const compile exit: !CONST_EXIT! >> final_test_log.txt
    
    if exist out.exe (
        echo out.exe created >> final_test_log.txt
        start /wait /b out.exe
        set OUT_EXIT=!ERRORLEVEL!
        echo out.exe exit: !OUT_EXIT! >> final_test_log.txt
        
        if !OUT_EXIT! EQU 42 (
            echo ========================================== >> final_test_log.txt
            echo SUCCESS! CONST KEYWORD WORKS! >> final_test_log.txt
            echo ========================================== >> final_test_log.txt
        )
    ) else (
        echo No out.exe created >> final_test_log.txt
    )
) else (
    echo No Gen1 created >> final_test_log.txt
)

type final_test_log.txt
echo.
echo Check files: archive_compile.txt, const_compile_result.txt, final_test_log.txt
