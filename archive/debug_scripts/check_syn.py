import struct

with open("bin/synapse.exe", "rb") as f:
    data = f.read()

# Find MZ
mz_offset = data.find(b'MZ', 1)  # Skip first MZ at offset 0
print(f"pe_header_stub starts at: 0x{mz_offset:X}")

# Data Directories at +0xF8
dd_offset = mz_offset + 0xF8
print(f"Data Directories at: 0x{dd_offset:X}")

# Import RVA (Entry 1)
import_rva_offset = dd_offset + 8
import_rva = struct.unpack("<I", data[import_rva_offset:import_rva_offset+4])[0]
print(f"\nImport RVA at 0x{import_rva_offset:X}: 0x{import_rva:08X}")

# Show bytes
print(f"\nBytes at 0x{import_rva_offset:X}:")
print(" ".join(f"{b:02X}" for b in data[import_rva_offset:import_rva_offset+16]))

# Search for 0x11000
print(f"\nSearching for 0x11000 in file...")
for i in range(len(data) - 3):
    val = struct.unpack("<I", data[i:i+4])[0]
    if val == 0x11000:
        print(f"  Found at 0x{i:X}")
        if i >= import_rva_offset - 16 and i <= import_rva_offset + 16:
            print(f"    ^ This is near Import RVA offset!")
