import sys

data = open(sys.argv[1] if len(sys.argv) > 1 else 'out.exe', 'rb').read()

# .idata at file offset 0x10200 (RVA 0x41000)
idata_off = 0x10200
idata_rva = 0x41000

# Import Directory Table (first 20 bytes)
print('Import Directory Entry:')
ilt_rva = int.from_bytes(data[idata_off:idata_off+4], 'little')
ts = int.from_bytes(data[idata_off+4:idata_off+8], 'little')
fwd = int.from_bytes(data[idata_off+8:idata_off+12], 'little')
name_rva = int.from_bytes(data[idata_off+12:idata_off+16], 'little')
iat_rva = int.from_bytes(data[idata_off+16:idata_off+20], 'little')

print(f'  ILT RVA: 0x{ilt_rva:X}')
print(f'  Timestamp: {ts}')
print(f'  Forwarder: {fwd}')
print(f'  DLL Name RVA: 0x{name_rva:X}')
print(f'  IAT RVA: 0x{iat_rva:X}')

def rva_to_file(rva):
    return idata_off + (rva - idata_rva)

# Check DLL name
name_file_off = rva_to_file(name_rva)
print(f'DLL Name at file offset 0x{name_file_off:X}:')
name = b''
for i in range(20):
    if name_file_off+i >= len(data): break
    b = data[name_file_off+i]
    if b == 0: break
    name += bytes([b])
print(f'  Name: {name.decode()}')

# Check IAT entries
print('IAT entries:')
iat_file_off = rva_to_file(iat_rva)
for i in range(12):
    off = iat_file_off + i*8
    if off+8 > len(data): break
    val = int.from_bytes(data[off:off+8], 'little')
    if val == 0:
        print(f'  [{i}]: NULL (end)')
        break
    # This should point to Hint/Name
    hint_off = rva_to_file(val)
    if hint_off < 0 or hint_off+32 > len(data):
        print(f'  [{i}]: RVA 0x{val:X} (out of bounds)')
        continue
    hint = int.from_bytes(data[hint_off:hint_off+2], 'little')
    fname = b''
    for j in range(30):
        b = data[hint_off+2+j]
        if b == 0: break
        fname += bytes([b])
    print(f'  [{i}]: RVA 0x{val:X} -> {fname.decode()}')

# Check IAT Data Directory
iat_dd_off = 200 + 12*8
iat_dd_rva = int.from_bytes(data[iat_dd_off:iat_dd_off+4], 'little')
iat_dd_size = int.from_bytes(data[iat_dd_off+4:iat_dd_off+8], 'little')
print(f'IAT Data Directory: RVA=0x{iat_dd_rva:X}, Size={iat_dd_size}')
