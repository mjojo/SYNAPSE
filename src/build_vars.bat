@echo off
echo ================================================
echo   SYNAPSE JIT v2 - Variables + Arithmetic
echo ================================================
echo.

cd /d %~dp0

set FASM=D:\fasmw17334\fasm.exe

echo [1/2] Compiling jit_vars.asm...
"%FASM%" jit_vars.asm jit_vars.exe
if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo [2/2] Running: let x=40; let y=2; return x+y
echo ------------------------------------------------
jit_vars.exe
echo ------------------------------------------------

echo.
pause
