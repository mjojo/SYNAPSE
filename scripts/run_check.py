import subprocess
result = subprocess.run(['synapse_new.exe'], capture_output=True)
print(f"Exit code: {result.returncode}")
print(f"Stdout: {result.stdout}")
print(f"Stderr: {result.stderr}")
