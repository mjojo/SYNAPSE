with open('bin/synapse.exe', 'rb') as f:
    data = f.read()

# pe_header_stub at 0xE00
stub_offset = 0xE00

print(f'pe_header_stub starts at: 0x{stub_offset:X}')
print()

# Check DOS header
dos_magic = data[stub_offset:stub_offset+2]
print(f'DOS Magic: {dos_magic}')

# e_lfanew at offset 0x3C from stub start
elfanew_offset = stub_offset + 0x3C
elfanew = int.from_bytes(data[elfanew_offset:elfanew_offset+4], 'little')
print(f'e_lfanew: 0x{elfanew:X} (expected 0x80)')

# PE signature at stub_offset + elfanew
pe_offset = stub_offset + elfanew
pe_sig = data[pe_offset:pe_offset+4]
print(f'PE signature at 0x{pe_offset:X}: {pe_sig}')

# COFF header starts after PE signature
coff_offset = pe_offset + 4
machine = int.from_bytes(data[coff_offset:coff_offset+2], 'little')
print(f'Machine: 0x{machine:X} (expected 0x8664 for AMD64)')

num_sections = int.from_bytes(data[coff_offset+2:coff_offset+4], 'little')
print(f'Number of sections: {num_sections}')

size_opt_hdr = int.from_bytes(data[coff_offset+16:coff_offset+18], 'little')
print(f'Size of Optional Header: 0x{size_opt_hdr:X}')

# Optional header starts after COFF (20 bytes)
opt_offset = coff_offset + 20
opt_magic = int.from_bytes(data[opt_offset:opt_offset+2], 'little')
print(f'Optional Header Magic: 0x{opt_magic:X} (0x20B = PE32+)')

# Data Directories offset:
# For PE32+: Optional Header base is 24 bytes, Windows-specific is 88 bytes
# Data Directories start at opt_offset + 24 + 88 = opt_offset + 112
data_dir_offset = opt_offset + 112
print(f'\nData Directories at: 0x{data_dir_offset:X}')

# Export (DD[0])
export_rva = int.from_bytes(data[data_dir_offset:data_dir_offset+4], 'little')
export_size = int.from_bytes(data[data_dir_offset+4:data_dir_offset+8], 'little')
print(f'DD[0] Export: RVA=0x{export_rva:X}, Size=0x{export_size:X}')

# Import (DD[1])
import_offset = data_dir_offset + 8
import_rva = int.from_bytes(data[import_offset:import_offset+4], 'little')
import_size = int.from_bytes(data[import_offset+4:import_offset+8], 'little')
print(f'DD[1] Import: RVA=0x{import_rva:X}, Size=0x{import_size:X}')

# Show raw bytes around Import DD
print(f'\nRaw bytes at Import DD (0x{import_offset:X}):')
print(' '.join(f'{b:02X}' for b in data[import_offset:import_offset+16]))

# Also check what's at offset 0x100 from stub (256 bytes)
check_offset = stub_offset + 256
print(f'\nRaw bytes at stub+256 (0x{check_offset:X}):')
print(' '.join(f'{b:02X}' for b in data[check_offset:check_offset+16]))
