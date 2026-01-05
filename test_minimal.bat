@echo off
echo === Test minimal_file ===
synapse_new.exe examples\minimal_file.syn
if exist out.exe (
    echo OK
) else (
    echo FAIL
)
