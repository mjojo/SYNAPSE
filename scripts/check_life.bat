@echo off
echo.
echo ========================================
echo   PHASE 78: THE FIRST BREATH
echo   Testing synapse_new.exe...
echo ========================================
echo.

REM Запускаем компилятор
.\synapse_new.exe

REM Сохраняем код возврата
SET RET=%ERRORLEVEL%

echo.
echo Exit Code: %RET%
echo.

REM Проверяем
IF %RET% EQU 42 (
    echo ====================================
    echo   *** SUCCESS! LIFE DETECTED! ***
    echo   Exit Code is 42
    echo   The compiler is ALIVE!
    echo ====================================
) ELSE (
    IF %RET% EQU 0 (
        echo Exit 0 - Process completed but wrong return
    ) ELSE (
        echo FAILURE - Exit Code is %RET%
    )
)

echo.
pause
