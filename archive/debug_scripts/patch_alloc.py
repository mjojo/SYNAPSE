import struct

with open("synapse_new.exe", "rb") as f:
    data = bytearray(f.read())

# Pattern: POP RAX; SHL RAX, 3; MOV RDX, RAX
# 58 48 C1 E0 03 48 89 C2
pattern = b'\x58\x48\xC1\xE0\x03\x48\x89\xC2'
replacement = b'\x90\x48\xC1\xE0\x03\x48\x89\xC2'

count = 0
offset = 0
print(f"Searching for pattern: {pattern.hex()}")
while True:
    idx = data.find(pattern, offset)
    if idx == -1:
        break
    
    print(f"Patching at 0x{idx:X}")
    data[idx] = 0x90 # NOP
    count += 1
    offset = idx + 1

print(f"Patched {count} occurrences.")

with open("synapse_new_patched.exe", "wb") as f:
    f.write(data)
