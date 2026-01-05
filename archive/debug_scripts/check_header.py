import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

# Find PE header
pe_offset = struct.unpack("<I", data[0x3C:0x40])[0]
print(f"PE Header at: 0x{pe_offset:X}")

# Optional Header
opt_header = pe_offset + 24
print(f"Optional Header at: 0x{opt_header:X}")

# SizeOfImage is at offset 56 in Optional Header
soi_offset = opt_header + 56
soi = struct.unpack("<I", data[soi_offset:soi_offset+4])[0]
print(f"SizeOfImage: 0x{soi:X} ({soi})")

# Data Directories (offset 96 in Optional Header for PE32+)
# Wait, is it PE32 or PE32+?
magic = struct.unpack("<H", data[opt_header:opt_header+2])[0]
print(f"Magic: 0x{magic:X}")

if magic == 0x20B: # PE32+
    dd_offset = opt_header + 112
else: # PE32
    dd_offset = opt_header + 96

print(f"Data Directories at: 0x{dd_offset:X}")

# Import RVA is entry 1 (index 1) -> +8 bytes
import_rva_offset = dd_offset + 8
print(f"Reading Import RVA from 0x{import_rva_offset:X}")
bytes_val = data[import_rva_offset:import_rva_offset+4]
print(f"Bytes: {bytes_val.hex()}")
import_rva = struct.unpack("<I", bytes_val)[0]
print(f"Import RVA at 0x{import_rva_offset:X}: 0x{import_rva:X}")
