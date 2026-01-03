@echo off
echo ========================================
echo   TITAN Paint AI - Multi-Digit Demo
echo ========================================
echo.
cd neural

echo Testing digit 9 (expected: 9)
echo --------------------------------
type ..\examples\test_digit.ttn | ..\titan.exe
echo.

echo Testing digit 4 (expected: 4)
echo --------------------------------
copy digit_4_33.bin img.bin >nul
type ..\examples\neural_demo.ttn | ..\titan.exe
echo.

echo Testing digit 7 (expected: 7)
echo --------------------------------
copy digit_7_0.bin img.bin >nul
type ..\examples\neural_demo.ttn | ..\titan.exe
echo.

echo Testing digit 1 (expected: 1)
echo --------------------------------
copy digit_1_2.bin img.bin >nul
type ..\examples\neural_demo.ttn | ..\titan.exe
echo.

echo Testing digit 0 (expected: 0)
echo --------------------------------
copy digit_0_3.bin img.bin >nul
type ..\examples\neural_demo.ttn | ..\titan.exe
echo.

echo ========================================
echo   All tests complete!
echo ========================================
cd ..
pause
