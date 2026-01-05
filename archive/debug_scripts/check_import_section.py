with open("synapse_new.exe", "rb") as f:
    data = f.read()

import struct

print(f"File size: {len(data)} bytes")

# Import section at file offset 0x10200
import_offset = 0x10200
print(f"\nImport Directory at file offset 0x{import_offset:X}:")

# Import Directory Entry (20 bytes)
ilt_rva = struct.unpack("<I", data[import_offset:import_offset+4])[0]
timestamp = struct.unpack("<I", data[import_offset+4:import_offset+8])[0]
forwarder = struct.unpack("<I", data[import_offset+8:import_offset+12])[0]
name_rva = struct.unpack("<I", data[import_offset+12:import_offset+16])[0]
iat_rva = struct.unpack("<I", data[import_offset+16:import_offset+20])[0]

print(f"  ILT RVA: 0x{ilt_rva:X}")
print(f"  Timestamp: {timestamp}")
print(f"  Forwarder: {forwarder}")
print(f"  DLL Name RVA: 0x{name_rva:X}")
print(f"  IAT RVA: 0x{iat_rva:X}")

# Show raw bytes
print(f"\nRaw bytes at 0x{import_offset:X}:")
print(" ".join(f"{b:02X}" for b in data[import_offset:import_offset+32]))

# Check if all zeros
if ilt_rva == 0 and name_rva == 0 and iat_rva == 0:
    print("\nALL ZEROS - Import section not written!")
else:
    print("\nImport section looks valid!")
