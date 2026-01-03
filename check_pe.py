import struct

with open(r'D:\Projects\SYNAPSE\synapse_new.exe', 'rb') as f:
    data = f.read()

print(f'File size: {len(data)} bytes')

# .idata section starts at file offset 0x400 (1024)
# and has RVA 0x2000
idata_file_off = 0x400
idata_rva = 0x2000

print('=== Import Directory Table ===')
idt = data[idata_file_off:idata_file_off+20]
ilt_rva = struct.unpack('<I', idt[0:4])[0]
name_rva = struct.unpack('<I', idt[12:16])[0]
iat_rva = struct.unpack('<I', idt[16:20])[0]
print(f'ILT RVA: 0x{ilt_rva:X}')
print(f'Name RVA: 0x{name_rva:X}')
print(f'IAT RVA: 0x{iat_rva:X}')

# DLL name
name_off = idata_file_off + (name_rva - idata_rva)
dll_name = data[name_off:name_off+20].split(b'\x00')[0].decode()
print(f'DLL: {dll_name}')

# IAT entries
iat_off = idata_file_off + (iat_rva - idata_rva)
print(f'\n=== IAT at file offset 0x{iat_off:X} ===')
for i in range(4):
    entry = struct.unpack('<Q', data[iat_off + i*8:iat_off + i*8 + 8])[0]
    if entry == 0:
        print(f'IAT[{i}] = 0 (end)')
        break
    print(f'IAT[{i}] = 0x{entry:X}')
    # Hint/Name
    hint_off = idata_file_off + (entry - idata_rva)
    hint = struct.unpack('<H', data[hint_off:hint_off+2])[0]
    func_name = data[hint_off+2:hint_off+50].split(b'\x00')[0].decode()
    print(f'       Hint={hint}, Name="{func_name}"')
