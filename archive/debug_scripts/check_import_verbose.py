import sys
try:
    with open('bin/synapse.exe', 'rb') as f:
        data = f.read()
    
    print(f'File size: {len(data)} bytes', file=sys.stderr)
    
    # Import DD offset: 256
    import_rva = int.from_bytes(data[256:260], 'little')
    import_size = int.from_bytes(data[260:264], 'little')
    
    print(f'Import RVA: 0x{import_rva:X}', file=sys.stderr)
    print(f'Import Size: 0x{import_size:X}', file=sys.stderr)
    
    # Check if it's correct
    if import_rva == 0x41000:
        print('SUCCESS: Import RVA is correct!', file=sys.stderr)
    else:
        print(f'ERROR: Import RVA is {import_rva}, expected 0x41000', file=sys.stderr)
        
except Exception as e:
    print(f'Exception: {e}', file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
