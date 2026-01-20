@echo off
.\synapse_new.exe
if %ERRORLEVEL%==42 (
    echo.
    echo ========================================
    echo   SUCCESS! Exit Code 42!
    echo   PHASE 77 COMPLETE!
    echo ========================================
    echo.
) else (
    echo Exit Code: %ERRORLEVEL%
)
