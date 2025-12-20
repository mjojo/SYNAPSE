@echo off
echo ========================================
echo SYNAPSE Parser v0.1 - Build Script
echo ========================================
echo.

cd /d %~dp0

set FASM=D:\fasmw17334\fasm.exe

echo [1/3] Checking FASM...
if not exist "%FASM%" (
    echo ERROR: FASM not found at %FASM%
    pause
    exit /b 1
)
echo Found: %FASM%

echo.
echo [2/3] Compiling parser_test.asm...
"%FASM%" parser_test.asm parser_test.exe
if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Running parser test...
echo ----------------------------------------
parser_test.exe
echo ----------------------------------------

echo.
echo Build and test complete!
pause
