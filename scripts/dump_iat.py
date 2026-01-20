import struct

def dump_iat(filename):
    print(f"\n=== {filename} IAT ===")
    with open(filename, 'rb') as f:
        # .idata at file offset 0x10200, VA 0x41000
        f.seek(0x10200)
        d = f.read(512)
        
        # Import Directory Table
        ilt_rva = struct.unpack('<I', d[0:4])[0]
        name_rva = struct.unpack('<I', d[12:16])[0]
        iat_rva = struct.unpack('<I', d[16:20])[0]
        
        print(f"ILT: 0x{ilt_rva:X}, IAT: 0x{iat_rva:X}")
        
        # Get DLL name
        name_off = name_rva - 0x41000
        dll_name = d[name_off:].split(b'\x00')[0].decode('ascii')
        print(f"DLL: {dll_name}")
        
        # Dump IAT entries
        iat_off = iat_rva - 0x41000
        print("IAT entries:")
        for i in range(15):
            val = struct.unpack('<Q', d[iat_off + i*8:iat_off + i*8 + 8])[0]
            if val == 0:
                print(f"  [{i}] NULL (end)")
                break
            
            # Get function name
            hn_off = val - 0x41000
            if 0 <= hn_off < len(d) - 2:
                hint = struct.unpack('<H', d[hn_off:hn_off+2])[0]
                name = d[hn_off+2:].split(b'\x00')[0].decode('ascii')
                print(f"  [{i}] {name}")

dump_iat('out.exe')
dump_iat('gen1.exe')
