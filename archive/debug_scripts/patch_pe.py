import struct
import sys
import os

def patch_pe(filename='synapse_new.exe'):
    if not os.path.exists(filename):
        print(f"File {filename} not found.")
        return

    with open(filename, 'rb') as f:
        data = bytearray(f.read())

    # 1. Find PE Header
    pe_sig_offset = struct.unpack_from('<I', data, 0x3C)[0]
    if data[pe_sig_offset:pe_sig_offset+4] != b'PE\0\0':
        print("Invalid PE signature")
        return
        
    opt_header_offset = pe_sig_offset + 24
    num_sections = struct.unpack_from('<H', data, pe_sig_offset + 6)[0]
    size_of_opt_header = struct.unpack_from('<H', data, pe_sig_offset + 20)[0]
    section_table_offset = opt_header_offset + size_of_opt_header
    
    # 2. Find .text and .idata sections
    text_section = None
    idata_section = None
    
    for i in range(num_sections):
        sec_offset = section_table_offset + i * 40
        name = data[sec_offset:sec_offset+8].rstrip(b'\0').decode('utf-8', errors='ignore')
        v_addr = struct.unpack_from('<I', data, sec_offset + 12)[0]
        raw_size = struct.unpack_from('<I', data, sec_offset + 16)[0]
        raw_ptr = struct.unpack_from('<I', data, sec_offset + 20)[0]
        
        sec_info = {
            'name': name,
            'v_addr': v_addr,
            'raw_size': raw_size,
            'raw_ptr': raw_ptr
        }
        
        if name == '.text':
            text_section = sec_info
            # Patch .text size to 256KB (0x40000)
            print(f"Patching .text size to 256KB at offset {sec_offset}")
            struct.pack_into('<I', data, sec_offset + 8, 0x40000)  # VirtualSize
            # struct.pack_into('<I', data, sec_offset + 16, 0x40000) # SizeOfRawData - DO NOT CHANGE! File is truncated.
            # Update local info
            # text_section['raw_size'] = 0x40000
            
            # Relocate Data (Strings)
            # Strings found at 46218 ("Source: ").
            # "R" and "M" are before it (4 bytes). So start at 46214.
            # Main is at 48660.
            # We copy 2KB from 46214 to 58112.
            # src_off = 46214
            # dst_off = 58112
            # copy_size = 2048
            # print(f"Relocating data from {src_off} to {dst_off} (size {copy_size})...")
            # chunk = data[src_off : src_off + copy_size]
            # data[dst_off : dst_off + copy_size] = chunk
            print("Skipping data relocation (already present in synapse_new.exe)")
            
        elif name == '.idata':
            idata_section = sec_info
            # Patch .idata VirtualAddress to 0x41000
            print(f"Patching .idata VirtualAddress to 0x41000 at offset {sec_offset}")
            struct.pack_into('<I', data, sec_offset + 12, 0x41000)
            idata_section['v_addr'] = 0x41000
            
    if not text_section:
        print(".text section not found")
        return
        
    # 3. Patch Entry Point Stub
    # Limit search to first 49000 bytes to avoid finding relocated copies
    search_limit = 49000
    text_data = data[text_section['raw_ptr'] : text_section['raw_ptr'] + search_limit]
    prologue = b'\x55\x48\x89\xE5'
    main_offset_in_section = text_data.rfind(prologue)
    
    if main_offset_in_section != -1:
        main_file_offset = text_section['raw_ptr'] + main_offset_in_section
        print(f"Found main() at file offset: {main_file_offset}")
        
        stub_offset = text_section['raw_ptr']
        if data[stub_offset] == 0x48 and data[stub_offset+1] == 0x83 and data[stub_offset+2] == 0xEC:
            print("Found Entry Stub signature")
            stub_rva = text_section['v_addr']
            call_next_ip_rva = stub_rva + 9
            main_rva = text_section['v_addr'] + main_offset_in_section
            disp = main_rva - call_next_ip_rva
            print(f"Calculated displacement: {disp} ({hex(disp)})")
            struct.pack_into('<i', data, stub_offset + 5, disp)
            print("Patched Entry Stub CALL instruction")
            
            # Patch ExitProcess call in Stub
            # Stub: 48 83 EC 30 E8 .. .. .. .. 48 89 C1 48 8B 05 .. .. .. .. FF D0
            # Offset of 48 8B 05 is 4+5+3 = 12
            exit_mov_offset = stub_offset + 12
            if data[exit_mov_offset] == 0x48 and data[exit_mov_offset+1] == 0x8B and data[exit_mov_offset+2] == 0x05:
                print("Found ExitProcess MOV signature in Stub")
                # Target IAT RVA = 0x41028
                # NextIP = stub_rva + 12 + 7 = stub_rva + 19
                # Disp = Target - NextIP
                
                target_iat = 0x41028
                next_ip = stub_rva + 19
                exit_disp = target_iat - next_ip
                
                print(f"Calculated ExitProcess displacement: {exit_disp} ({hex(exit_disp)})")
                struct.pack_into('<i', data, exit_mov_offset + 3, exit_disp)
                print("Patched Stub ExitProcess call")
            else:
                print("Could not find ExitProcess MOV in Stub")

            entry_point_offset = opt_header_offset + 16
            struct.pack_into('<I', data, entry_point_offset, text_section['v_addr'])
            print(f"Reset EntryPoint to {hex(text_section['v_addr'])}")
            
            # Stack Reserve/Commit
            stack_reserve_offset = opt_header_offset + 72
            stack_commit_offset = opt_header_offset + 80
            
            stack_reserve = struct.unpack_from('<Q', data, stack_reserve_offset)[0]
            stack_commit = struct.unpack_from('<Q', data, stack_commit_offset)[0]
            
            if stack_reserve < 0x200000: # 2MB
                struct.pack_into('<Q', data, stack_reserve_offset, 0x200000)
                print("Patched StackReserve to 2MB")
                
            struct.pack_into('<Q', data, stack_commit_offset, 0x100000) # 1MB
            print("Patched StackCommit to 1MB")

            # Patch Data Directories (Import Table and IAT)
            # Data Directories start at opt_header_offset + 112
            data_dirs_offset = opt_header_offset + 112
            
            # Import Table (Index 1)
            import_rva_offset = data_dirs_offset + 1 * 8
            import_rva = struct.unpack_from('<I', data, import_rva_offset)[0]
            if 0x11000 <= import_rva <= 0x11FFF:
                new_import_rva = import_rva + 0x30000
                struct.pack_into('<I', data, import_rva_offset, new_import_rva)
                print(f"Patched Import Table RVA to {hex(new_import_rva)}")
                
            # IAT (Index 12)
            iat_rva_offset = data_dirs_offset + 12 * 8
            iat_rva = struct.unpack_from('<I', data, iat_rva_offset)[0]
            if 0x11000 <= iat_rva <= 0x11FFF:
                new_iat_rva = iat_rva + 0x30000
                struct.pack_into('<I', data, iat_rva_offset, new_iat_rva)
                print(f"Patched IAT RVA to {hex(new_iat_rva)}")

    else:
        print("Could not find main prologue")

    # 4. Patch .idata RVAs (Relocation)
    if idata_section:
        print("Patching .idata RVAs...")
        idata_start = idata_section['raw_ptr']
        idata_end = idata_start + idata_section['raw_size']
        count = 0
        for offset in range(idata_start, idata_end, 4):
            val = struct.unpack_from('<I', data, offset)[0]
            if 0x11000 <= val <= 0x11FFF:
                new_val = val + 0x30000
                struct.pack_into('<I', data, offset, new_val)
                count += 1
        print(f"Patched {count} RVAs in .idata section")

    # 5. Patch SizeOfImage
    size_of_image_offset = opt_header_offset + 56
    size_of_image = struct.unpack_from('<I', data, size_of_image_offset)[0]
    print(f"SizeOfImage: {hex(size_of_image)}")
    
    if size_of_image < 0x60000:
        print("SizeOfImage is too small! Patching to 0x150000 (1.3MB)")
        struct.pack_into('<I', data, size_of_image_offset, 0x150000)

    with open(filename, 'wb') as f:
        f.write(data)
    print(f"Patched {filename}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        patch_pe(sys.argv[1])
    else:
        patch_pe()
