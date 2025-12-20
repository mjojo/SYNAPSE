@echo off
cd /d D:\Projects\Titan\demos
(
echo RUN
ping localhost -n 10 >nul
) | D:\Projects\Titan\bin\titan.exe test_gprint.ttn
