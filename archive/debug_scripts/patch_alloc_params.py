import struct

with open("synapse_new_patched.exe", "rb") as f:
    data = bytearray(f.read())

# Pattern: MOV R8D, 0x3000; MOV R9D, 4
# 41 B8 00 30 00 00 41 B9 04 00 00 00
pattern = b'\x41\xB8\x00\x30\x00\x00\x41\xB9\x04\x00\x00\x00'
replacement = b'\x41\xB8\x00\x10\x00\x00\x41\xB9\x40\x00\x00\x00' # 0x1000, 0x40

count = 0
offset = 0
while True:
    idx = data.find(pattern, offset)
    if idx == -1:
        break
    
    print(f"Patching params at 0x{idx:X}")
    # Patch 0x30 -> 0x10
    data[idx+3] = 0x10
    # Patch 0x04 -> 0x40
    data[idx+8] = 0x40
    
    count += 1
    offset = idx + 1

print(f"Patched {count} occurrences.")

with open("synapse_new_patched_2.exe", "wb") as f:
    f.write(data)
