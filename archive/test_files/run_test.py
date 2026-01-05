import subprocess
import sys

exe = sys.argv[1] if len(sys.argv) > 1 else 'synapse_new.exe'
try:
    result = subprocess.run([exe], capture_output=True, text=True, timeout=5)
    print(f"stdout: '{result.stdout}'")
    print(f"stderr: '{result.stderr}'")
    print(f"exit code: {result.returncode}")
except Exception as e:
    print(f"Error: {e}")
