import struct

with open("bin/synapse.exe", "rb") as f:
    data = f.read()

pe_offset = struct.unpack("<I", data[0x3C:0x40])[0]
size_opt = struct.unpack("<H", data[pe_offset+20:pe_offset+22])[0]
sections_start = pe_offset + 24 + size_opt
num_sections = struct.unpack("<H", data[pe_offset+6:pe_offset+8])[0]

for i in range(num_sections):
    off = sections_start + i * 40
    name = data[off:off+8].rstrip(b'\x00').decode()
    chars = struct.unpack("<I", data[off+36:off+40])[0]
    print(f"Section {i}: {name} Chars: 0x{chars:X}")
