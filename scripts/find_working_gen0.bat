@echo off
echo Testing which Gen0 compiler works...
echo.

FOR %%G IN (bin\synapse.exe bin\synapse_host.exe bin\synapse_patched.exe) DO (
    echo Testing %%G...
    %%G test_42.syn > test_gen0.txt 2>&1
    if exist out.exe (
        out.exe
        if %ERRORLEVEL% EQU 42 (
            echo   SUCCESS: %%G works!
            del out.exe
            goto :found
        )
        del out.exe
    )
    echo   FAIL
)

echo.
echo No working Gen0 found!
exit /b 1

:found
echo.
echo Found working Gen0: Use this for compiling!
