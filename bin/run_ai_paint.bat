@echo off
title TITAN AI Paint
echo ========================================
echo    TITAN AI Paint - Neural Recognizer  
echo    24KB Full-Stack AI Engine
echo ========================================
echo.
echo Controls:
echo   - Draw digit in TOP-LEFT corner (28x28)
echo   - Press SPACE to recognize  
echo   - Press ESC to quit
echo.

cd /d "%~dp0"

echo Type: LOAD "ai_demo.ttn" then RUN
echo.
titan.exe
