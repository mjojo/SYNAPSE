@echo off
synapse_new.exe test_42.syn > test_output.txt 2>&1
echo Exit code: %ERRORLEVEL%
type test_output.txt
if exist out.exe (
    echo.
    echo Running out.exe...
    out.exe
    echo out.exe returned: %ERRORLEVEL%
) else (
    echo No out.exe created
)
