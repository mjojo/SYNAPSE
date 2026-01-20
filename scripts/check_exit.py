import subprocess
import sys

# Test out.exe (created by gen1.exe)
result = subprocess.run(['out.exe'], capture_output=True)
print(f"out.exe exit code: {result.returncode}")

# Test gen1.exe with test_simple.syn (no output, just create out.exe)
result2 = subprocess.run(['gen1.exe', 'test_simple.syn'], capture_output=True)
print(f"gen1.exe compilation exit code: {result2.returncode}")
