@echo off
if exist out.exe (
    out.exe
    echo Out.exe returned: %ERRORLEVEL%
) else (
    echo No out.exe
)
