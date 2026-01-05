import struct

with open("synapse_new_patched.exe", "rb") as f:
    data = bytearray(f.read())

# Pattern: CALL [REL]
# FF 15 DD CF 00 00
pattern = b'\xFF\x15\xDD\xCF\x00\x00'
# Replace with MOV EAX, 12345 (0x3039); NOP
replacement = b'\xB8\x39\x30\x00\x00\x90'

count = 0
offset = 0
while True:
    idx = data.find(pattern, offset)
    if idx == -1:
        break
    
    print(f"Patching call at 0x{idx:X}")
    data[idx:idx+6] = replacement
    
    count += 1
    offset = idx + 1

print(f"Patched {count} occurrences.")

with open("synapse_new_patched_ret.exe", "wb") as f:
    f.write(data)
