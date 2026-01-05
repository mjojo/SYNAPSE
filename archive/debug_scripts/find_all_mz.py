with open('bin/synapse.exe', 'rb') as f:
    data = f.read()

# Find ALL occurrences of MZ with e_lfanew=0x80
for offset in range(len(data) - 0x40):
    if data[offset:offset+2] == b'MZ' and data[offset+0x3C:offset+0x40] == b'\x80\x00\x00\x00':
        print(f'Found MZ header with e_lfanew=0x80 at offset: 0x{offset:X}')
        # Check Import DD
        import_offset = offset + 256
        import_rva = int.from_bytes(data[import_offset:import_offset+4], 'little')
        import_size = int.from_bytes(data[import_offset+4:import_offset+8], 'little')
        print(f'  Import DD: RVA=0x{import_rva:X}, Size=0x{import_size:X}')
