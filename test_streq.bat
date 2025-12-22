@echo off
echo.
echo ========================================
echo SYNAPSE SHELL TEST v1.0
echo ========================================
echo.

REM Компилируем
D:\fasmw17334\FASM.EXE D:\Projects\SYNAPSE\src\synapse.asm D:\Projects\SYNAPSE\bin\synapse.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Compilation failed!
    exit /b 1
)
echo [OK] Compilation successful

REM Создаем входной файл для теста
echo help> test_input.tmp
echo exit>> test_input.tmp

REM Запускаем с перенаправлением ввода
echo.
echo [TEST] Running shell with commands...
echo ----------------------------------------
bin\synapse.exe examples\shell.syn < test_input.tmp
echo ----------------------------------------
echo.

REM Очистка
del test_input.tmp >nul 2>&1

echo [OK] Test completed
