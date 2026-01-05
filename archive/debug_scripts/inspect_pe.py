import struct
import sys

def read_pe(filename):
    with open(filename, 'rb') as f:
        data = f.read()

    pe_off = struct.unpack_from('<I', data, 0x3C)[0]
    print(f"PE Header at: 0x{pe_off:X}")
    
    num_sections = struct.unpack_from('<H', data, pe_off + 6)[0]
    opt_header_size = struct.unpack_from('<H', data, pe_off + 20)[0]
    print(f"Sections: {num_sections}")
    
    opt_header_off = pe_off + 24
    image_base = struct.unpack_from('<Q', data, opt_header_off + 24)[0]
    print(f"Image Base: 0x{image_base:X}")
    
    import_table_rva = struct.unpack_from('<I', data, opt_header_off + 112 + 8)[0] # Data Directory [1] (Import)
    print(f"Import Table RVA: 0x{import_table_rva:X}")
    
    sections_off = opt_header_off + opt_header_size
    
    import_file_off = 0
    
    for i in range(num_sections):
        sec_off = sections_off + i * 40
        name = data[sec_off:sec_off+8].rstrip(b'\x00').decode()
        v_size = struct.unpack_from('<I', data, sec_off + 8)[0]
        v_addr = struct.unpack_from('<I', data, sec_off + 12)[0]
        r_size = struct.unpack_from('<I', data, sec_off + 16)[0]
        r_addr = struct.unpack_from('<I', data, sec_off + 20)[0]
        
        print(f"Section {name}: RVA 0x{v_addr:X}, Size 0x{r_size:X}, FileOff 0x{r_addr:X}")
        
        if v_addr <= import_table_rva < v_addr + v_size:
            import_file_off = r_addr + (import_table_rva - v_addr)
            
    if import_file_off == 0:
        print("Import table not found in sections")
        return

    print(f"Import Table File Offset: 0x{import_file_off:X}")
    
    # Parse Import Directory Table
    off = import_file_off
    while True:
        ilt_rva = struct.unpack_from('<I', data, off)[0]
        if ilt_rva == 0: break
        
        name_rva = struct.unpack_from('<I', data, off + 12)[0]
        iat_rva = struct.unpack_from('<I', data, off + 16)[0]
        
        # Find file offset for name
        name_off = 0
        for i in range(num_sections):
            sec_off = sections_off + i * 40
            v_addr = struct.unpack_from('<I', data, sec_off + 12)[0]
            r_addr = struct.unpack_from('<I', data, sec_off + 20)[0]
            if v_addr <= name_rva < v_addr + 0x10000: # Assuming section size
                 name_off = r_addr + (name_rva - v_addr)
                 break
        
        dll_name = ""
        if name_off:
            i = 0
            while data[name_off+i] != 0:
                dll_name += chr(data[name_off+i])
                i += 1
        
        print(f"DLL: {dll_name} (IAT RVA: 0x{iat_rva:X})")
        
        # Parse IAT
        iat_off = 0
        for i in range(num_sections):
            sec_off = sections_off + i * 40
            v_addr = struct.unpack_from('<I', data, sec_off + 12)[0]
            r_addr = struct.unpack_from('<I', data, sec_off + 20)[0]
            if v_addr <= iat_rva < v_addr + 0x10000:
                 iat_off = r_addr + (iat_rva - v_addr)
                 break
        
        if iat_off:
            idx = 0
            while True:
                entry = struct.unpack_from('<Q', data, iat_off + idx * 8)[0]
                if entry == 0: break
                
                # Hint/Name RVA
                hint_rva = entry & 0x7FFFFFFF # Mask off high bit (ordinal)
                
                hint_off = 0
                for i in range(num_sections):
                    sec_off = sections_off + i * 40
                    v_addr = struct.unpack_from('<I', data, sec_off + 12)[0]
                    r_addr = struct.unpack_from('<I', data, sec_off + 20)[0]
                    if v_addr <= hint_rva < v_addr + 0x10000:
                        hint_off = r_addr + (hint_rva - v_addr)
                        break
                
                func_name = ""
                if hint_off:
                    hint = struct.unpack_from('<H', data, hint_off)[0]
                    i = 0
                    while data[hint_off+2+i] != 0:
                        func_name += chr(data[hint_off+2+i])
                        i += 1
                
                print(f"  [{idx}] 0x{entry:X} -> {func_name}")
                idx += 1
        
        off += 20

read_pe("out.exe")
