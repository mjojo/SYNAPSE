@echo off
echo === Testing const keyword ===
synapse_new.exe test_const_simple_return.syn
if exist out.exe (
    echo Compilation succeeded
    out.exe
    echo Exit code: %ERRORLEVEL%
) else (
    echo Compilation FAILED
)
pause
