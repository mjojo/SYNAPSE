@echo off
echo ========================================
echo SYNAPSE Block Parser Test (Phase 1.4)
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
echo [2/3] Compiling block_test.asm...
"%FASM%" block_test.asm block_test.exe
if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Running block parser test...
echo ----------------------------------------
block_test.exe
echo ----------------------------------------

echo.
echo Build complete!
pause
