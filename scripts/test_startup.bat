@echo off
synapse_new.exe > startup_test.txt 2>&1
echo Exit: %ERRORLEVEL%
if exist startup_test.txt type startup_test.txt
