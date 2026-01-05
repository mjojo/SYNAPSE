@echo off
cd /d D:\Projects\SYNAPSE
bin\synapse.exe examples\synapse_full.syn synapse_new.exe
echo Exit code: %ERRORLEVEL%
pause
