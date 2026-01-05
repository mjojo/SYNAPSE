import struct

with open("synapse_new_patched.exe", "rb") as f:
    data = bytearray(f.read())

# Pattern: POP RAX; SHL RAX, 3; MOV RDX, RAX
# 58 48 C1 E0 03 48 89 C2
# Note: We already patched 58 to 90 in synapse_new_patched.exe!
# So pattern is 90 48 C1 E0 03 48 89 C2
pattern = b'\x90\x48\xC1\xE0\x03\x48\x89\xC2'

# CALL is at offset 26
call_offset = 26

# Replace CALL with MOV EAX, 12345; NOP
replacement = b'\xB8\x39\x30\x00\x00\x90'

count = 0
offset = 0
while True:
    idx = data.find(pattern, offset)
    if idx == -1:
        break
    
    call_idx = idx + call_offset
    print(f"Patching call at 0x{call_idx:X}")
    data[call_idx:call_idx+6] = replacement
    
    count += 1
    offset = idx + 1

print(f"Patched {count} occurrences.")

with open("synapse_new_patched_ret_all.exe", "wb") as f:
    f.write(data)
