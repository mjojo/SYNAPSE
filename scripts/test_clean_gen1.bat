@echo off
synapse_new.exe test_42.syn > clean_test_output.txt 2>&1
echo Compiler exit: %ERRORLEVEL%
if exist out.exe (
    out.exe
    echo Program exit: %ERRORLEVEL%
) else (
    echo No out.exe
    type clean_test_output.txt
)
