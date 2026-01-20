import subprocess
import sys

# Run gen1.exe and capture everything
print("Running gen1.exe test_simple.syn...")
result = subprocess.run(['gen1.exe', 'test_simple.syn'], 
                        capture_output=True, text=True)
print(f"stdout: {result.stdout[:200] if result.stdout else '(empty)'}")
print(f"stderr: {result.stderr[:200] if result.stderr else '(empty)'}")
print(f"exit code: {result.returncode}")
print(f"hex exit: 0x{result.returncode & 0xFFFFFFFF:08X}")

print()
print("Running out.exe...")
result2 = subprocess.run(['out.exe'], capture_output=True, text=True)
print(f"stdout: {result2.stdout[:100] if result2.stdout else '(empty)'}")
print(f"stderr: {result2.stderr[:100] if result2.stderr else '(empty)'}")
print(f"exit code: {result2.returncode}")
print(f"hex exit: 0x{result2.returncode & 0xFFFFFFFF:08X}")
