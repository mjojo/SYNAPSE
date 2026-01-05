with open('out.exe', 'rb') as f:
    data = f.read()
    print(f"Size: {len(data)}")
    print(f"Bytes at 0x200: {data[0x200:0x220].hex()}")
    
    pe_off = int.from_bytes(data[0x3C:0x40], 'little')
    print(f"PE Off: 0x{pe_off:X}")
    
    opt_off = pe_off + 24
    print(f"Opt Off: 0x{opt_off:X}")
    
    dd_off = opt_off + 112
    print(f"DD Off: 0x{dd_off:X}")
    
    rva = int.from_bytes(data[dd_off:dd_off+4], 'little')
    print(f"Import RVA: 0x{rva:X}")
