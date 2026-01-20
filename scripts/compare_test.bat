@echo off
echo Testing OLD compiler (no Phase 71)...
synapse_old.exe test_42.syn > old_output.txt 2>&1
echo Old compiler exit: %ERRORLEVEL%
type old_output.txt
if exist out.exe (
    echo.
    echo Running out.exe from OLD compiler...
    out.exe
    echo out.exe returned: %ERRORLEVEL%
    del out.exe
) else (
    echo No out.exe from old compiler
)

echo.
echo Testing NEW compiler (with Phase 71)...
synapse_new.exe test_42.syn > new_output.txt 2>&1
echo New compiler exit: %ERRORLEVEL%
type new_output.txt
if exist out.exe (
    echo.
    echo Running out.exe from NEW compiler...
    out.exe
    echo out.exe returned: %ERRORLEVEL%
) else (
    echo No out.exe from new compiler
)
