import struct

def analyze_pe(filename, label):
    print(f"\n=== {label} ===")
    with open(filename, 'rb') as f:
        data = f.read()
    
    # PE header
    pe_offset = struct.unpack('<I', data[0x3C:0x40])[0]
    print(f"PE header at: 0x{pe_offset:X}")
    
    # Optional header
    opt_hdr = pe_offset + 24
    num_rva_sizes = struct.unpack('<I', data[opt_hdr + 108:opt_hdr + 112])[0]
    print(f"Number of RVA and sizes: {num_rva_sizes}")
    
    # Data directories start at opt_hdr + 112
    data_dir_offset = opt_hdr + 112
    
    # Import directory is at index 1 (each entry is 8 bytes)
    import_dir_rva = struct.unpack('<I', data[data_dir_offset + 8:data_dir_offset + 12])[0]
    import_dir_size = struct.unpack('<I', data[data_dir_offset + 12:data_dir_offset + 16])[0]
    print(f"Import Dir RVA: 0x{import_dir_rva:X}, Size: 0x{import_dir_size:X}")
    
    # Section headers
    num_sections = struct.unpack('<H', data[pe_offset + 6:pe_offset + 8])[0]
    opt_hdr_size = struct.unpack('<H', data[pe_offset + 20:pe_offset + 22])[0]
    sec_hdr_offset = pe_offset + 24 + opt_hdr_size
    
    print(f"\nSections ({num_sections}):")
    sections = []
    for i in range(num_sections):
        off = sec_hdr_offset + i * 40
        name = data[off:off+8].decode('ascii', errors='ignore').rstrip('\x00')
        vsize = struct.unpack('<I', data[off+8:off+12])[0]
        rva = struct.unpack('<I', data[off+12:off+16])[0]
        raw_size = struct.unpack('<I', data[off+16:off+20])[0]
        raw_ptr = struct.unpack('<I', data[off+20:off+24])[0]
        print(f"  {name}: RVA=0x{rva:X}, VSize=0x{vsize:X}, RawPtr=0x{raw_ptr:X}, RawSize=0x{raw_size:X}")
        sections.append({'name': name, 'rva': rva, 'raw_ptr': raw_ptr})
    
    # Find section containing import_dir_rva
    for sec in sections:
        if sec['rva'] <= import_dir_rva < sec['rva'] + 0x1000:
            file_offset = sec['raw_ptr'] + (import_dir_rva - sec['rva'])
            print(f"\nImport Directory at file offset: 0x{file_offset:X}")
            
            # Read IDT entries
            idt_off = file_offset
            entry_idx = 0
            while True:
                ilt_rva = struct.unpack('<I', data[idt_off:idt_off+4])[0]
                timestamp = struct.unpack('<I', data[idt_off+4:idt_off+8])[0]
                forwarder = struct.unpack('<I', data[idt_off+8:idt_off+12])[0]
                name_rva = struct.unpack('<I', data[idt_off+12:idt_off+16])[0]
                iat_rva = struct.unpack('<I', data[idt_off+16:idt_off+20])[0]
                
                if ilt_rva == 0 and name_rva == 0 and iat_rva == 0:
                    break
                
                # Get DLL name
                for s in sections:
                    if s['rva'] <= name_rva < s['rva'] + 0x1000:
                        name_off = s['raw_ptr'] + (name_rva - s['rva'])
                        end = data.find(b'\x00', name_off)
                        dll_name = data[name_off:end].decode('ascii', errors='ignore')
                        break
                else:
                    dll_name = '?'
                
                print(f"\nIDT Entry {entry_idx}: {dll_name}")
                print(f"  OriginalFirstThunk (ILT): 0x{ilt_rva:X}")
                print(f"  Name RVA: 0x{name_rva:X}")
                print(f"  FirstThunk (IAT): 0x{iat_rva:X}")
                
                # Show IAT entries
                if iat_rva != 0:
                    for s in sections:
                        if s['rva'] <= iat_rva < s['rva'] + 0x1000:
                            iat_off = s['raw_ptr'] + (iat_rva - s['rva'])
                            for j in range(4):  # Show first 4 entries
                                entry = struct.unpack('<Q', data[iat_off + j*8:iat_off + j*8 + 8])[0]
                                if entry == 0:
                                    print(f"  IAT[{j}]: 0 (end)")
                                    break
                                # Check if hint/name or ordinal
                                if entry & 0x8000000000000000:
                                    print(f"  IAT[{j}]: Ordinal 0x{entry & 0xFFFF:X}")
                                else:
                                    # Hint/Name
                                    hint_rva = entry & 0x7FFFFFFF
                                    for ss in sections:
                                        if ss['rva'] <= hint_rva < ss['rva'] + 0x1000:
                                            hint_off = ss['raw_ptr'] + (hint_rva - ss['rva'])
                                            hint = struct.unpack('<H', data[hint_off:hint_off+2])[0]
                                            end = data.find(b'\x00', hint_off+2)
                                            func_name = data[hint_off+2:end].decode('ascii', errors='ignore')
                                            print(f"  IAT[{j}]: 0x{entry:X} -> Hint {hint}: {func_name}")
                                            break
                            break
                
                idt_off += 20
                entry_idx += 1
            break

analyze_pe('d:/Projects/SYNAPSE/test_va.exe', 'FASM test_va.exe (WORKS)')
analyze_pe('d:/Projects/SYNAPSE/synapse_new.exe', 'Synapse generated (CRASHES)')
