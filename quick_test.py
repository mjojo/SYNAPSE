import subprocess
result = subprocess.run(['synapse_new.exe'], capture_output=True)
code = result.returncode
print(f"Exit code: {code}")
if code == 42:
    print("✅ SUCCESS! Phase 51 COMPLETE!")
else:
    print(f"❌ FAIL: Expected 42, got {code}")
