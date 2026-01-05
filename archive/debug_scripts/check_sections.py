import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

# Section Headers start after Optional Header + Data Directories
# Optional Header at 0x98. Size 240 (0xF0) for PE32+?
# No, SizeOfOptionalHeader is in File Header.
pe_offset = struct.unpack("<I", data[0x3C:0x40])[0]
size_opt = struct.unpack("<H", data[pe_offset+20:pe_offset+22])[0]
print(f"SizeOfOptionalHeader: {size_opt}")

sections_start = pe_offset + 24 + size_opt
print(f"Sections start at: 0x{sections_start:X}")

# Number of sections
num_sections = struct.unpack("<H", data[pe_offset+6:pe_offset+8])[0]
print(f"Number of sections: {num_sections}")

for i in range(num_sections):
    off = sections_start + i * 40
    name = data[off:off+8].rstrip(b'\x00').decode()
    vsize = struct.unpack("<I", data[off+8:off+12])[0]
    vaddr = struct.unpack("<I", data[off+12:off+16])[0]
    raw_size = struct.unpack("<I", data[off+16:off+20])[0]
    raw_off = struct.unpack("<I", data[off+20:off+24])[0]
    print(f"Section {i}: {name}")
    print(f"  VirtualSize: 0x{vsize:X}")
    print(f"  VirtualAddress: 0x{vaddr:X}")
    print(f"  RawSize: 0x{raw_size:X}")
    print(f"  RawOffset: 0x{raw_off:X}")
    
    chars = struct.unpack("<I", data[off+36:off+40])[0]
    print(f"  Characteristics: 0x{chars:X}")
