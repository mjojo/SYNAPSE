import struct

with open("synapse_new_patched.exe", "rb") as f:
    data = bytearray(f.read())

# Pattern: MOV R8D, 0x3000
# 41 B8 00 30 00 00
pattern = b'\x41\xB8\x00\x30\x00\x00'
# Replace with 0x103000 (MEM_COMMIT|MEM_RESERVE|MEM_TOP_DOWN)
replacement = b'\x41\xB8\x00\x30\x10\x00'

count = 0
offset = 0
while True:
    idx = data.find(pattern, offset)
    if idx == -1:
        break
    
    print(f"Patching params at 0x{idx:X}")
    data[idx:idx+6] = replacement
    
    count += 1
    offset = idx + 1

print(f"Patched {count} occurrences.")

with open("synapse_new_patched_topdown.exe", "wb") as f:
    f.write(data)
