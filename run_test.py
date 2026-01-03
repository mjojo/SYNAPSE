import subprocess
p = subprocess.run([r'synapse_new.exe'], capture_output=True, text=True)
print(f'Exit code: {p.returncode}')
print(f'Output: [{p.stdout}]')
print(f'Stderr: [{p.stderr}]')
