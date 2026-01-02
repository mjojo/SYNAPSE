import struct

with open('bin/synapse.exe', 'rb') as f:
    data = f.read()

# Find Import Directory entry in Data Directories
pe_offset = struct.unpack("<I", data[0x3C:0x40])[0]
dd_offset = pe_offset + 0xC8  # Import Directory entry offset

rva = struct.unpack("<I", data[dd_offset:dd_offset+4])[0]
size = struct.unpack("<I", data[dd_offset+4:dd_offset+8])[0]

print(f"PE offset: {pe_offset} (0x{pe_offset:X})")
print(f"Data Dir Import offset: {dd_offset} (0x{dd_offset:X})")
print(f"Import RVA: 0x{rva:X}")
print(f"Import Size: {size}")

# Show raw bytes around this area
print("\nRaw bytes at Data Directories:")
start = dd_offset - 8
for i in range(0, 64, 16):
    offset = start + i
    chunk = data[offset:offset+16]
    hex_str = ' '.join(f'{b:02X}' for b in chunk)
    print(f"  {offset:04X}: {hex_str}")
