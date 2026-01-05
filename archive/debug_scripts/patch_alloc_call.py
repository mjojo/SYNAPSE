import struct

with open("synapse_new_patched_2.exe", "rb") as f:
    data = bytearray(f.read())

# Pattern: CALL [REL]
# FF 15 DD CF 00 00
pattern = b'\xFF\x15\xDD\xCF\x00\x00'
replacement = b'\xFF\x15\xD5\xCF\x00\x00' # -8 bytes

count = 0
offset = 0
while True:
    idx = data.find(pattern, offset)
    if idx == -1:
        break
    
    print(f"Patching call at 0x{idx:X}")
    data[idx+2] = 0xD5
    
    count += 1
    offset = idx + 1

print(f"Patched {count} occurrences.")

with open("synapse_new_patched_3.exe", "wb") as f:
    f.write(data)
