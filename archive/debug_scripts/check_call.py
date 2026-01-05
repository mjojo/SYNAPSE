import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

# Found partial sequence (MOV R8D, 0x3000) at 0x323D
# The sequence is:
# 0x323D: 41 B8 00 30 00 00 (MOV R8D, 0x3000)
# 0x3243: 41 B9 04 00 00 00 (MOV R9D, 4)
# 0x3249: 48 83 EC 30       (SUB RSP, 0x30)
# 0x324D: FF 15 DD CF 00 00 (CALL [REL])  <-- Assuming DD CF 00 00 is the displacement

call_offset = 0x324D
disp_offset = call_offset + 2
disp_bytes = data[disp_offset:disp_offset+4]
disp = struct.unpack("<i", disp_bytes)[0]

print(f"Displacement bytes: {disp_bytes.hex()}")
print(f"Displacement value: 0x{disp:X} ({disp})")

# Read bytes after the CALL instruction (6 bytes)
after_call = call_offset + 6
print(f"Bytes after CALL: {data[after_call:after_call+16].hex()}")
# Call Offset 0x324D -> RVA 0x1000 + (0x324D - 0x200) = 0x404D
call_rva = 0x1000 + (call_offset - 0x200)
next_rip = call_rva + 6

target_rva = next_rip + disp
print(f"Call RVA: 0x{call_rva:X}")
print(f"Next RIP: 0x{next_rip:X}")
print(f"Target RVA: 0x{target_rva:X}")

expected_rva = 0x11030
print(f"Expected RVA: 0x{expected_rva:X}")

if target_rva == expected_rva:
    print("MATCH!")
else:
    print("MISMATCH!")
