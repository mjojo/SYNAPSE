with open('bin/synapse.exe', 'rb') as f:
    data = f.read()

# pe_header_stub at 0xE00
stub_offset = 0xE00
import_offset = stub_offset + 256

import_rva = int.from_bytes(data[import_offset:import_offset+4], 'little')
import_size = int.from_bytes(data[import_offset+4:import_offset+8], 'little')

print(f'pe_header_stub at offset: 0x{stub_offset:X}')
print(f'Import DD at offset: 0x{import_offset:X}')
print(f'Import RVA: 0x{import_rva:X}')
print(f'Import Size: 0x{import_size:X}')

if import_rva == 0x41000:
    print('SUCCESS!')
else:
    print(f'FAIL: Expected 0x41000, got 0x{import_rva:X}')
    
# Show raw bytes
print(f'\nRaw bytes at 0x{import_offset:X}:')
print(' '.join(f'{b:02X}' for b in data[import_offset:import_offset+16]))
