@echo off
echo [DEBUG] Compiling test_args.syn with Host...
bin\synapse.exe test_args.syn -o args_test.exe
if %ERRORLEVEL% NEQ 0 exit /b 1

echo [DEBUG] Running args_test.exe...
args_test.exe hello world
echo Exit Code: %ERRORLEVEL%
