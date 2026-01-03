@echo off
echo SYNAPSE Phase 6.3 - JIT Logic Test
cd /d %~dp0
D:\fasmw17334\fasm.exe jit_logic_test.asm jit_logic_test.exe
if errorlevel 1 exit /b 1
jit_logic_test.exe
