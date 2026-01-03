with open('synapse_new.exe', 'rb') as f:
    data = f.read()

pe_offset = int.from_bytes(data[0x3C:0x40], 'little')
num_sections = int.from_bytes(data[pe_offset+6:pe_offset+8], 'little')

print(f"PE Signature at offset 0x{pe_offset:X}")
print(f"Number of sections: {num_sections}\n")

# Section headers start after Optional Header
opt_header_size = int.from_bytes(data[pe_offset+20:pe_offset+22], 'little')
section_table_offset = pe_offset + 24 + opt_header_size

for i in range(num_sections):
    sec_offset = section_table_offset + i * 40
    
    name = data[sec_offset:sec_offset+8].rstrip(b'\x00').decode('ascii')
    virt_size = int.from_bytes(data[sec_offset+8:sec_offset+12], 'little')
    virt_addr = int.from_bytes(data[sec_offset+12:sec_offset+16], 'little')
    raw_size = int.from_bytes(data[sec_offset+16:sec_offset+20], 'little')
    raw_ptr = int.from_bytes(data[sec_offset+20:sec_offset+24], 'little')
    characteristics = int.from_bytes(data[sec_offset+36:sec_offset+40], 'little')
    
    print(f"Section {i+1}: '{name}'")
    print(f"  VirtualSize:     0x{virt_size:08X} ({virt_size} bytes)")
    print(f"  VirtualAddress:  0x{virt_addr:08X} (RVA)")
    print(f"  RawSize:         0x{raw_size:08X} ({raw_size} bytes)")
    print(f"  RawPointer:      0x{raw_ptr:08X} (file offset)")
    print(f"  Characteristics: 0x{characteristics:08X}")
    
    # Decode characteristics
    flags = []
    if characteristics & 0x00000020: flags.append("CODE")
    if characteristics & 0x00000040: flags.append("INIT_DATA")
    if characteristics & 0x00000080: flags.append("UNINIT_DATA")
    if characteristics & 0x20000000: flags.append("EXEC")
    if characteristics & 0x40000000: flags.append("READ")
    if characteristics & 0x80000000: flags.append("WRITE")
    print(f"  Flags: {' | '.join(flags)}")
    print()

print("="*70)
print("CHECKING .idata section characteristics...")
print("="*70)
print("Expected for .idata:")
print("  - INIT_DATA (0x00000040)")
print("  - READ (0x40000000)")  
print("  - WRITE (0x80000000)")
print("  - Total: 0xC0000040")
print("\nNote: Some linkers use 0xC0000040, others use 0x40000040 (no WRITE)")
