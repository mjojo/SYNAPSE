@echo off
del min_test_result.txt 2>nul

synapse_minimal.exe test_42.syn > min_compile.txt 2>&1
echo Compiler exit: %ERRORLEVEL% > min_test_result.txt

if exist out.exe (
    out.exe
    echo Out exit: %ERRORLEVEL% >> min_test_result.txt
    del out.exe
) else (
    echo No out.exe >> min_test_result.txt
)

type min_test_result.txt
