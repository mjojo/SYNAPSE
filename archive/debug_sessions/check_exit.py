import subprocess
import sys
import os

os.chdir("D:\\Projects\\SYNAPSE")
result = subprocess.run(["D:\\Projects\\SYNAPSE\\synapse_new.exe"], 
                        capture_output=True, 
                        shell=True)
exit_code = result.returncode

print(f"\n{'='*50}")
print(f"Exit Code: {exit_code}")
if exit_code == 99:
    print("✓ SUCCESS! VirtualAlloc call worked!")
    print("✓ Phase 52 Infrastructure: COMPLETE")
else:
    print(f"✗ FAILED: Expected 99, got {exit_code}")
    if exit_code < 0:
        print(f"  (Negative = crash, hex: {hex(exit_code & 0xFFFFFFFF)})")
print(f"{'='*50}\n")

sys.exit(0)
