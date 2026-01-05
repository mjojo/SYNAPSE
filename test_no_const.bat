@echo off
echo === Test without const ===
synapse_new.exe test_simple42.syn
if exist out.exe (
    echo OK
    out.exe
    echo Exit: %ERRORLEVEL%
) else (
    echo FAIL
)
