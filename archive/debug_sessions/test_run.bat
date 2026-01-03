@echo off
echo Running synapse_new.exe...
synapse_new.exe
set CODE=%ERRORLEVEL%
echo Exit code: %CODE% > result.txt
type result.txt
