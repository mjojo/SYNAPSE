@echo off
echo Testing Gen0 with simple file...
bin\synapse.exe test_seven.syn > gen0_test.txt 2>&1
echo Gen0 exit code: %ERRORLEVEL%

if exist synapse_new.exe (
    echo Running synapse_new.exe...
    synapse_new.exe
    set RESULT=%ERRORLEVEL%
    echo Program exit code: !RESULT!
    if !RESULT! EQU 7 (
        echo ✅ SUCCESS! Gen0 works!
    ) else (
        echo ❌ FAIL! Expected 7, got !RESULT!
    )
) else (
    echo ❌ No synapse_new.exe created
    type gen0_test.txt
)
