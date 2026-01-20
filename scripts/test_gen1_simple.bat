@echo off
echo === Testing Gen1 ===
synapse_new.exe test_simple42.syn
echo Exit code: %ERRORLEVEL%
if exist out.exe (
    echo out.exe created: YES
    out.exe
    echo out.exe exit: %ERRORLEVEL%
) else (
    echo out.exe created: NO
)
