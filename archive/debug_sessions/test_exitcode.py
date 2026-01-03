import subprocess
import sys

print("Testing synapse_new.exe...")
result = subprocess.run(['synapse_new.exe'], cwd=r'd:\Projects\SYNAPSE')
print(f"Exit code: {result.returncode}")
sys.exit(0)
