import struct
import sys

def dump_imports(filename):
    with open(filename, 'rb') as f:
        data = bytearray(f.read())

    pe_sig_offset = struct.unpack_from('<I', data, 0x3C)[0]
    opt_header_offset = pe_sig_offset + 24
    
    # Import Table RVA is at offset 120 in Optional Header (PE32+)
    # Wait, PE32+ (64-bit) Optional Header is 112 bytes + Data Dirs.
    # Data Dir 1 is Import Table.
    # Offset 112 + 8 = 120.
    
    import_dir_offset = opt_header_offset + 120
    import_rva = struct.unpack_from('<I', data, import_dir_offset)[0]
    import_size = struct.unpack_from('<I', data, import_dir_offset + 4)[0]
    
    print(f"Import Table RVA: {hex(import_rva)}")
    print(f"Import Table Size: {hex(import_size)}")
    
    if import_rva == 0:
        print("No Import Table")
        return

    # Find file offset for Import RVA
    # We need section headers.
    num_sections = struct.unpack_from('<H', data, pe_sig_offset + 6)[0]
    size_of_opt_header = struct.unpack_from('<H', data, pe_sig_offset + 20)[0]
    section_table_offset = opt_header_offset + size_of_opt_header
    
    def rva_to_offset(rva):
        for i in range(num_sections):
            sec_offset = section_table_offset + i * 40
            v_addr = struct.unpack_from('<I', data, sec_offset + 12)[0]
            v_size = struct.unpack_from('<I', data, sec_offset + 8)[0]
            raw_ptr = struct.unpack_from('<I', data, sec_offset + 20)[0]
            raw_size = struct.unpack_from('<I', data, sec_offset + 16)[0]
            
            # Use RawSize for mapping
            if v_addr <= rva < v_addr + raw_size:
                return rva - v_addr + raw_ptr
        return None

    import_offset = rva_to_offset(import_rva)
    print(f"Import Table File Offset: {import_offset}")
    
    if import_offset is None:
        print("Could not map Import RVA to file offset")
        return

    # Dump Import Directory Table
    # 20 bytes per entry
    # OriginalFirstThunk (RVA), TimeDateStamp, ForwarderChain, Name (RVA), FirstThunk (RVA)
    
    offset = import_offset
    while True:
        original_first_thunk = struct.unpack_from('<I', data, offset)[0]
        time_date_stamp = struct.unpack_from('<I', data, offset + 4)[0]
        forwarder_chain = struct.unpack_from('<I', data, offset + 8)[0]
        name_rva = struct.unpack_from('<I', data, offset + 12)[0]
        first_thunk = struct.unpack_from('<I', data, offset + 16)[0]
        
        if original_first_thunk == 0 and name_rva == 0:
            break
            
        print(f"DLL Entry:")
        print(f"  OriginalFirstThunk: {hex(original_first_thunk)}")
        print(f"  Name RVA: {hex(name_rva)}")
        print(f"  FirstThunk: {hex(first_thunk)}")
        
        name_offset = rva_to_offset(name_rva)
        if name_offset:
            name = ""
            i = 0
            while data[name_offset + i] != 0:
                name += chr(data[name_offset + i])
                i += 1
            print(f"  Name: {name}")
        
        # Dump Thunks (Functions)
        thunk_rva = original_first_thunk if original_first_thunk != 0 else first_thunk
        thunk_offset = rva_to_offset(thunk_rva)
        
        if thunk_offset:
            print("  Functions:")
            i = 0
            while True:
                func_rva = struct.unpack_from('<Q', data, thunk_offset + i * 8)[0]
                if func_rva == 0:
                    break
                
                # If high bit set, it's ordinal. Otherwise RVA to Hint/Name
                if func_rva & 0x8000000000000000:
                    print(f"    Ordinal: {func_rva & 0xFFFF}")
                else:
                    hint_name_offset = rva_to_offset(func_rva)
                    if hint_name_offset:
                        hint = struct.unpack_from('<H', data, hint_name_offset)[0]
                        fname = ""
                        j = 2
                        while data[hint_name_offset + j] != 0:
                            fname += chr(data[hint_name_offset + j])
                            j += 1
                        print(f"    {fname} (Hint: {hint})")
                    else:
                        print(f"    RVA: {hex(func_rva)} (Invalid Offset)")
                i += 1
        
        offset += 20

if __name__ == '__main__':
    dump_imports(sys.argv[1])
