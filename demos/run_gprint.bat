@echo off
cd /d D:\Projects\Titan\demos
echo Loading GPRINT test...
(
echo LIST
echo RUN
echo.
) | D:\Projects\Titan\bin\titan.exe gprint_debug.ttn
pause
