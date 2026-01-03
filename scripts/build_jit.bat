@echo off
echo ================================================
echo   SYNAPSE JIT Compiler - "The 42 Test"
echo ================================================
echo.

cd /d %~dp0

set FASM=D:\fasmw17334\fasm.exe

echo [1/2] Compiling jit_test.asm...
"%FASM%" jit_test.asm jit_test.exe
if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo [2/2] Running the ultimate JIT test...
echo ------------------------------------------------
jit_test.exe
echo ------------------------------------------------

echo.
pause
