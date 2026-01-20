import subprocess
r = subprocess.run(['out.exe'], capture_output=True)
print(r.returncode)
