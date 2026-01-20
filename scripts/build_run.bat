@echo off
D:\fasmw17334\FASM.EXE D:\Projects\SYNAPSE\src\synapse.asm D:\Projects\SYNAPSE\bin\synapse.exe
if %errorlevel% equ 0 (
    echo Build successful!
    D:\Projects\SYNAPSE\bin\synapse.exe %1
) else (
    echo Build failed!
)
