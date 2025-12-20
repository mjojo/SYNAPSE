@echo off
echo ============================================
echo TITAN Language - Build Script (Windows)
echo ============================================
echo.

:: Путь к FASM (измените при необходимости)
set FASM=D:\fasmw17334\FASM.EXE

:: Проверяем наличие FASM
if not exist "%FASM%" (
    where fasm >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] FASM not found!
        echo Please set FASM path in build.bat or add to PATH
        pause
        exit /b 1
    )
    set FASM=fasm
)

:: Создаём папку для бинарников
if not exist "bin" mkdir bin

echo [1/2] Compiling src\main.asm...
"%FASM%" src\main.asm bin\titan.exe

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed!
    pause
    exit /b 1
)

echo [2/2] Build successful!
echo.
echo Output: bin\titan.exe
echo Size:   
for %%A in (bin\titan.exe) do echo         %%~zA bytes
echo.
echo Run with: bin\titan.exe
echo ============================================
