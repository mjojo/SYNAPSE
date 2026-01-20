@echo off
echo === Testing Gen1 (Phase 71) ===
synapse_new.exe test_const.syn > gen1_output.txt 2>&1
echo Gen1 exit code: %ERRORLEVEL%
if exist gen1_output.txt type gen1_output.txt

if exist out.exe (
    echo.
    echo === Running out.exe ===
    out.exe
    echo Exit code from out.exe: %ERRORLEVEL%
) else (
    echo No out.exe created
)
