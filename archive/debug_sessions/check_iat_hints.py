with open('synapse_new.exe', 'rb') as f:
    data = f.read()

print("Checking IAT entries and their hint/name structures:\n")

import_offset = 0x400
iat_offset = 0x428  # IAT starts at 0x28 from import_data_start

for i in range(8):
    entry_offset = iat_offset + i * 8
    entry_rva = int.from_bytes(data[entry_offset:entry_offset+8], 'little')
    
    if entry_rva == 0:
        print(f"IAT[{i}]: NULL (terminator)")
        break
        
    # Convert RVA to file offset
    hint_file_offset = import_offset + (entry_rva - 0x2000)
    
    # Read hint word
    hint = int.from_bytes(data[hint_file_offset:hint_file_offset+2], 'little')
    
    # Read function name (null-terminated)
    name_start = hint_file_offset + 2
    name_bytes = []
    for j in range(50):
        b = data[name_start + j]
        if b == 0:
            break
        name_bytes.append(b)
    
    func_name = bytes(name_bytes).decode('ascii', errors='replace')
    
    print(f"IAT[{i}] at RVA 0x{0x2028 + i*8:04X}:")
    print(f"  Points to RVA: 0x{entry_rva:04X}")
    print(f"  Hint: {hint}")
    print(f"  Name: '{func_name}'")
    print()
