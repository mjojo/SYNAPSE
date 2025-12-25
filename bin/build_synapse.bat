@echo off
echo ============================================
echo SYNAPSE JIT Compiler - Build Script
echo ============================================
echo.

:: FASM path from functioning build.bat
set FASM=D:\fasmw17334\FASM.EXE

if not exist "%FASM%" (
    echo [ERROR] FASM not found at %FASM%
    exit /b 1
)

echo [1/2] Compiling src\synapse.asm...
"%FASM%" src\synapse.asm bin\synapse.exe

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed!
    exit /b 1
)

echo [2/2] Build successful!
echo Output: bin\synapse.exe
echo.
echo Run with: bin\synapse.exe
echo ============================================
