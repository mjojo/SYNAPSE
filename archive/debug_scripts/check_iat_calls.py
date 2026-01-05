data = open('synapse_new.exe', 'rb').read()

# Check all FF 15 calls
print("All FF 15 calls and their targets:\n")

iat_base = 0x41028
iat_names = ["ExitProcess", "VirtualAlloc", "VirtualFree", "WriteFile", 
             "ReadFile", "CreateFileA", "CloseHandle", "GetStdHandle", "GetCommandLineA"]

for i in range(0x200, min(0x10200, len(data)-6)):
    if data[i] == 0xFF and data[i+1] == 0x15:
        disp = int.from_bytes(data[i+2:i+6], 'little', signed=True)
        file_off = i
        rva = 0x1000 + (file_off - 0x200)
        rip_after = rva + 6
        target_rva = rip_after + disp
        
        # Check if target is in IAT
        iat_idx = (target_rva - iat_base) // 8
        if 0 <= iat_idx < len(iat_names):
            name = iat_names[iat_idx]
            offset_in_entry = (target_rva - iat_base) % 8
            if offset_in_entry != 0:
                print(f"0x{file_off:04X}: call [rip+0x{disp:X}] -> RVA 0x{target_rva:X} = IAT[{iat_idx}] + {offset_in_entry} (MISALIGNED!) {name}")
            else:
                print(f"0x{file_off:04X}: call [rip+0x{disp:X}] -> RVA 0x{target_rva:X} = IAT[{iat_idx}] ({name})")
        else:
            print(f"0x{file_off:04X}: call [rip+0x{disp:X}] -> RVA 0x{target_rva:X} (NOT IN IAT?)")
