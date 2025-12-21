@echo off
echo SYNAPSE Phase 6 - Control Flow Test
cd /d %~dp0
D:\fasmw17334\fasm.exe control_flow_test.asm control_flow_test.exe
if errorlevel 1 exit /b 1
control_flow_test.exe
