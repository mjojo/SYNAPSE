data=open('synapse_new.exe','rb').read()
# Find FF 15 in first 0x300 bytes
for i in range(0x200, 0x300):
    if data[i] == 0xFF and data[i+1] == 0x15:
        disp = int.from_bytes(data[i+2:i+6], 'little', signed=True)
        rva = 0x1000 + (i - 0x200)
        rip = rva + 6
        target = rip + disp
        print(f'FF 15 at file 0x{i:03X}, RVA 0x{rva:X}, target RVA 0x{target:X}')
        
        if target >= 0x41028 and target < 0x41080:
            idx = (target - 0x41028) // 8
            off = (target - 0x41028) % 8
            names = ['ExitProcess', 'VirtualAlloc', 'VirtualFree', 'WriteFile', 
                     'ReadFile', 'CreateFileA', 'CloseHandle', 'GetStdHandle']
            if off == 0:
                print(f'   -> IAT[{idx}] = {names[idx]}')
            else:
                print(f'   -> MISALIGNED! Off by {off}')
