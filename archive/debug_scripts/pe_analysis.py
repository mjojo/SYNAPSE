data=open('synapse_new.exe','rb').read()
print('PE Header Analysis:')
print()

# Basic PE info
e_lfanew = int.from_bytes(data[0x3C:0x40], 'little')
print(f'e_lfanew: 0x{e_lfanew:X}')

# COFF header
num_sections = int.from_bytes(data[e_lfanew+4+2:e_lfanew+4+4], 'little')
print(f'NumberOfSections: {num_sections}')

# Optional header
opt_offset = e_lfanew + 4 + 20
magic = int.from_bytes(data[opt_offset:opt_offset+2], 'little')
pe_type = "PE32+" if magic == 0x20B else "PE32"
print(f'Magic: 0x{magic:X} ({pe_type})')

entry_rva = int.from_bytes(data[opt_offset+16:opt_offset+20], 'little')
print(f'AddressOfEntryPoint: 0x{entry_rva:X}')

image_base = int.from_bytes(data[opt_offset+24:opt_offset+32], 'little')
print(f'ImageBase: 0x{image_base:X}')

size_of_image = int.from_bytes(data[opt_offset+56:opt_offset+60], 'little')
print(f'SizeOfImage: 0x{size_of_image:X}')

size_of_headers = int.from_bytes(data[opt_offset+60:opt_offset+64], 'little')
print(f'SizeOfHeaders: 0x{size_of_headers:X}')

# Section headers
size_opt_hdr = int.from_bytes(data[e_lfanew+4+16:e_lfanew+4+18], 'little')
sections_offset = e_lfanew + 4 + 20 + size_opt_hdr
print()
print('Sections:')
for i in range(num_sections):
    sec_off = sections_offset + i * 40
    name = data[sec_off:sec_off+8].rstrip(b'\x00').decode()
    vsize = int.from_bytes(data[sec_off+8:sec_off+12], 'little')
    rva = int.from_bytes(data[sec_off+12:sec_off+16], 'little')
    raw_size = int.from_bytes(data[sec_off+16:sec_off+20], 'little')
    raw_ptr = int.from_bytes(data[sec_off+20:sec_off+24], 'little')
    chars = int.from_bytes(data[sec_off+36:sec_off+40], 'little')
    print(f'  {name}: RVA=0x{rva:X}, VSize=0x{vsize:X}, RawPtr=0x{raw_ptr:X}, RawSize=0x{raw_size:X}, Chars=0x{chars:X}')
