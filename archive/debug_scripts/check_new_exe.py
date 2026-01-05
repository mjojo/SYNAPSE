with open('synapse_new.exe', 'rb') as f:
    data = f.read()

print(f'synapse_new.exe size: {len(data)} bytes')

# Check DOS header
dos_magic = data[0:2]
print(f'DOS Magic: {dos_magic}')

elfanew = int.from_bytes(data[0x3C:0x40], 'little')
print(f'e_lfanew: 0x{elfanew:X}')

# PE signature
pe_offset = elfanew
pe_sig = data[pe_offset:pe_offset+4]
print(f'PE signature at 0x{pe_offset:X}: {pe_sig}')

# COFF
coff_offset = pe_offset + 4
machine = int.from_bytes(data[coff_offset:coff_offset+2], 'little')
print(f'Machine: 0x{machine:X}')

size_opt_hdr = int.from_bytes(data[coff_offset+16:coff_offset+18], 'little')
print(f'Size of Optional Header: 0x{size_opt_hdr:X}')

# Optional header
opt_offset = coff_offset + 20
opt_magic = int.from_bytes(data[opt_offset:opt_offset+2], 'little')
print(f'Optional Header Magic: 0x{opt_magic:X}')

# Data Directories at opt_offset + 112
data_dir_offset = opt_offset + 112
print(f'\nData Directories at: 0x{data_dir_offset:X}')

# Import (DD[1])
import_offset = data_dir_offset + 8
import_rva = int.from_bytes(data[import_offset:import_offset+4], 'little')
import_size = int.from_bytes(data[import_offset+4:import_offset+8], 'little')
print(f'DD[1] Import: RVA=0x{import_rva:X}, Size=0x{import_size:X}')

if import_rva == 0x41000:
    print('\n*** SUCCESS! Import RVA is correct! ***')
elif import_rva == 0:
    print('\n*** FAIL: Import RVA is NULL ***')
else:
    print(f'\n*** UNEXPECTED: Import RVA = 0x{import_rva:X} ***')
