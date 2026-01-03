with open('synapse_new.exe', 'rb') as f:
    data = f.read()

print(f"File size: {len(data)} bytes\n")

# Check Import section at offset 0x400 (file offset)
import_offset = 0x400
if len(data) < import_offset + 100:
    print(f"ERROR: File too small ({len(data)} bytes), Import section missing!")
else:
    import_data = data[import_offset:import_offset+200]
    
    print("Import Directory Table (first 40 bytes at offset 0x400):")
    for i in range(0, 40, 4):
        chunk = import_data[i:i+4]
        value = int.from_bytes(chunk, 'little')
        print(f"  +{i:02X}: 0x{value:08X}")
    
    print("\nImport Lookup Table (ILT at offset ~0x428):")
    ilt_offset = 40
    for i in range(8):
        chunk = import_data[ilt_offset + i*8:ilt_offset + i*8 + 8]
        if len(chunk) == 8:
            value = int.from_bytes(chunk, 'little')
            print(f"  ILT[{i}]: 0x{value:016X}")
    
    print("\nImport Address Table (IAT at offset ~0x470 = 0x2070 RVA):")
    iat_offset = 40 + 9*8  # After Directory + ILT
    for i in range(8):
        chunk = import_data[iat_offset + i*8:iat_offset + i*8 + 8]
        if len(chunk) == 8:
            value = int.from_bytes(chunk, 'little')
            func_name = ["ExitProcess", "VirtualAlloc", "VirtualFree", "WriteFile", 
                        "ReadFile", "CreateFileA", "CloseHandle", "GetStdHandle"][i]
            print(f"  IAT[{i}] ({func_name}): 0x{value:016X}")
            if i == 1:
                print(f"         ^ VirtualAlloc RVA should be at file:0x{import_offset+iat_offset+i*8:X} = mem:0x{0x2070+i*8:X}")
    
    # Check for KERNEL32.DLL string
    kernel_str_offset = 40 + 18*8
    if kernel_str_offset < len(import_data):
        kernel_name = import_data[kernel_str_offset:kernel_str_offset+20]
        try:
            kernel_decoded = kernel_name.split(b'\x00')[0].decode('ascii')
            print(f"\nDLL Name at offset 0x{import_offset+kernel_str_offset:X}: '{kernel_decoded}'")
        except:
            print(f"\nDLL Name data: {kernel_name.hex()}")

print("\n" + "="*60)
print("Checking code section for FF 15 instruction...")
code_offset = 0x200
if len(data) > code_offset:
    code_data = data[code_offset:code_offset+200]
    for i in range(len(code_data)-2):
        if code_data[i] == 0xFF and code_data[i+1] == 0x15:
            disp_bytes = code_data[i+2:i+6]
            disp = int.from_bytes(disp_bytes, 'little', signed=True)
            print(f"Found FF 15 at code offset 0x{code_offset+i:X}")
            print(f"  Displacement: 0x{disp:X} ({disp})")
            print(f"  Target RVA: 0x{0x1000 + 21 + i + 6 + disp:X}")
