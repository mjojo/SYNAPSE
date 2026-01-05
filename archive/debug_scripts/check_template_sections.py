import struct

with open("bin/synapse.exe", "rb") as f:
    data = f.read()

# Template starts at 0xDF0
base = 0xDF0
# Read e_lfanew from base + 0x3C
e_lfanew = struct.unpack("<I", data[base+0x3C:base+0x40])[0]
pe_offset = base + e_lfanew
print(f"PE Header at: 0x{pe_offset:X}")

sig = data[pe_offset:pe_offset+4]
print(f"Signature: {sig}")

if sig != b'PE\x00\x00':
    print("Not a PE header!")
    exit()

# File Header starts at pe_offset + 4
num_sections = struct.unpack("<H", data[pe_offset+4+2:pe_offset+4+4])[0]
size_opt = struct.unpack("<H", data[pe_offset+4+16:pe_offset+4+18])[0]
print(f"Num Sections: {num_sections}")
print(f"Size Optional: {size_opt}")

sections_start = pe_offset + 4 + 20 + size_opt
print(f"Sections start at: 0x{sections_start:X}")

for i in range(num_sections):
    off = sections_start + i * 40
    name = data[off:off+8].rstrip(b'\x00').decode(errors='ignore')
    chars = struct.unpack("<I", data[off+36:off+40])[0]
    print(f"Section {i}: {name} Chars: 0x{chars:X}")
