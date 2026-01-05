import subprocess
import sys

# Pass simple test file
result = subprocess.run(['synapse_new.exe', 'in.syn'], capture_output=True, text=True, timeout=30)
print(f"stdout: '{result.stdout[:500] if len(result.stdout) > 500 else result.stdout}'")
print(f"stderr: '{result.stderr[:500] if len(result.stderr) > 500 else result.stderr}'")
print(f"return code: {result.returncode}")
