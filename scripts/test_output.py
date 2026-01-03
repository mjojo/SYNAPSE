import subprocess
r = subprocess.run(['output.exe'], capture_output=True, timeout=5)
print(f'Exit code: {r.returncode}')
