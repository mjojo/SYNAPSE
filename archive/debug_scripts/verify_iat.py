data=open('synapse_new.exe','rb').read()
# IAT at file offset 0x10200 + 0x28 = 0x10228
iat_off = 0x10200 + 0x28
print('IAT entries:')
names = ['ExitProcess', 'VirtualAlloc', 'VirtualFree', 'WriteFile', 
         'ReadFile', 'CreateFileA', 'CloseHandle', 'GetStdHandle', 'GetCommandLineA']
for i in range(9):
    val = int.from_bytes(data[iat_off+i*8:iat_off+i*8+8], 'little')
    print(f'  [{i}] {names[i]}: RVA 0x{val:X}')
    # Check hint/name
    if val:
        name_off = 0x10200 + (val - 0x41000)
        if 0 <= name_off < len(data) - 30:
            hint = int.from_bytes(data[name_off:name_off+2], 'little')
            name = data[name_off+2:name_off+30].split(b'\x00')[0].decode()
            print(f'      -> Hint={hint}, Name="{name}"')
