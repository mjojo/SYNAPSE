@echo off
REM ============================================
REM SYNAPSE Shell - Automated Integration Test
REM ============================================

echo.
echo ========================================
echo   SYNAPSE SHELL - Integration Test
echo ========================================
echo.

REM Compile synapse.asm
echo [1/3] Compiling SYNAPSE...
D:\fasmw17334\FASM.EXE D:\Projects\SYNAPSE\src\synapse.asm D:\Projects\SYNAPSE\bin\synapse.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Compilation failed!
    exit /b 1
)
echo [OK] Build successful
echo.

REM Create test input (commands to test)
echo ver> test_shell_input.tmp
echo help>> test_shell_input.tmp
echo calc>> test_shell_input.tmp
echo exit>> test_shell_input.tmp

REM Run shell with input redirection
echo [2/3] Running Shell with test commands...
echo ========================================
D:\Projects\SYNAPSE\bin\synapse.exe < test_shell_input.tmp
echo ========================================
echo.

REM Cleanup
del test_shell_input.tmp >nul 2>&1

echo [3/3] Test completed!
echo.
echo Expected output:
echo  - Boot messages (1111, 2222)
echo  - Version info for 'ver'
echo  - Command list for 'help'
echo  - Unknown command for 'calc'
echo  - Shutdown for 'exit'
echo.
