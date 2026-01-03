with open('synapse_new.exe', 'rb') as f:
    data = f.read()

# Check PE Optional Header Data Directory for Import Table
pe_offset = int.from_bytes(data[0x3C:0x40], 'little')
print(f"PE Header at offset: 0x{pe_offset:X}")

# Optional Header starts at PE + 24
opt_header_offset = pe_offset + 24
print(f"Optional Header at: 0x{opt_header_offset:X}")

# Data Directory at Optional Header + 112 (for PE32+)
data_dir_offset = opt_header_offset + 112
import_dir_entry_offset = data_dir_offset + 8  # Second entry (index 1)

import_rva = int.from_bytes(data[import_dir_entry_offset:import_dir_entry_offset+4], 'little')
import_size = int.from_bytes(data[import_dir_entry_offset+4:import_dir_entry_offset+8], 'little')

print(f"\nPE Optional Header -> Import Directory Entry:")
print(f"  RVA:  0x{import_rva:08X}")
print(f"  Size: {import_size} bytes")

print(f"\nExpected RVA: 0x00002000")
print(f"Match: {import_rva == 0x2000}")

if import_rva != 0x2000:
    print(f"\n⚠️ MISMATCH! PE header points to 0x{import_rva:X}, but import data is at 0x2000")
