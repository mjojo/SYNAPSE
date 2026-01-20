import subprocess
import os

if os.path.exists('synapse_new.exe'):
     try:
        result = subprocess.run(['synapse_new.exe'], capture_output=True, timeout=5)
        print(f"Return Code: {result.returncode}")
        print(f"Stdout: {result.stdout}")
        print(f"Stderr: {result.stderr}")
     except Exception as e:
        print(f"Error: {e}")
else:
    print("synapse_new.exe not found")
