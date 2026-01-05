with open('bin/synapse_test.exe', 'rb') as f:
    data = f.read()

# Find MZ header
mz_offset = data.find(b'MZ')
print(f'MZ found at: {mz_offset} (0x{mz_offset:X})')

# Read e_lfanew
e_lfanew = int.from_bytes(data[mz_offset + 0x3C:mz_offset + 0x40], 'little')
print(f'e_lfanew: {e_lfanew} (0x{e_lfanew:X})')

# PE header
pe_offset = mz_offset + e_lfanew
print(f'PE header at: {pe_offset} (0x{pe_offset:X})')

# Data Directories offset
dd_offset = pe_offset + 4 + 20 + 96
print(f'Data Directories at: {dd_offset} (0x{dd_offset:X})')

# Import DD
import_dd_offset = dd_offset + 8
import_rva = int.from_bytes(data[import_dd_offset:import_dd_offset+4], 'little')
import_size = int.from_bytes(data[import_dd_offset+4:import_dd_offset+8], 'little')
print(f'\nImport DD: RVA=0x{import_rva:X}, Size=0x{import_size:X}')

# Show raw bytes around Import DD
print(f'\nBytes {import_dd_offset}-{import_dd_offset+15}:')
print(' '.join(f'{b:02X}' for b in data[import_dd_offset:import_dd_offset+16]))
