@echo off
echo ========================================
echo SYNAPSE Lexer v2.0 - Build Script
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
echo [2/3] Compiling lexer_test.asm...
"%FASM%" lexer_test.asm lexer_test.exe
if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Running lexer test...
echo ----------------------------------------
lexer_test.exe
echo ----------------------------------------

echo.
echo Build and test complete!
pause
