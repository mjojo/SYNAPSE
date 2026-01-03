REM Test synapse_new.exe exit code
@echo off
cd /d D:\Projects\SYNAPSE
echo Compiling test_return_42.syn...
bin\synapse.exe test_return_42.syn
echo.
echo Running synapse_new.exe...
synapse_new.exe
echo Exit code: %ERRORLEVEL%
if %ERRORLEVEL%==42 (
    echo [SUCCESS] Exit code is 42!
) else (
    echo [FAIL] Expected 42, got %ERRORLEVEL%
)
pause
