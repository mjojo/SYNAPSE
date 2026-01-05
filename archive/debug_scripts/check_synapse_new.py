import sys

data = open('synapse_new.exe', 'rb').read()
print(f'File size: {len(data)} bytes')

# Parse PE header to find .idata section
e_lfanew = int.from_bytes(data[0x3C:0x40], 'little')
print(f'e_lfanew: 0x{e_lfanew:X}')

# Optional header starts at e_lfanew + 4 + 20
opt_offset = e_lfanew + 4 + 20
print(f'Optional header at: 0x{opt_offset:X}')

# Data Directories start at opt_offset + 112 (for PE32+)
dd_offset = opt_offset + 112

# Read Import Directory (DD[1])
import_rva = int.from_bytes(data[dd_offset+8:dd_offset+12], 'little')
import_size = int.from_bytes(data[dd_offset+12:dd_offset+16], 'little')
print(f'Import Directory: RVA=0x{import_rva:X}, Size=0x{import_size:X}')

# Section headers start at opt_offset + SizeOfOptionalHeader
size_opt_hdr = int.from_bytes(data[e_lfanew+4+16:e_lfanew+4+18], 'little')
sections_offset = e_lfanew + 4 + 20 + size_opt_hdr
num_sections = int.from_bytes(data[e_lfanew+4+2:e_lfanew+4+4], 'little')
print(f'Number of sections: {num_sections}')

# Find section containing Import Directory RVA
idata_file_offset = None
for i in range(num_sections):
    sec_off = sections_offset + i * 40
    sec_name = data[sec_off:sec_off+8].rstrip(b'\x00').decode()
    sec_vsize = int.from_bytes(data[sec_off+8:sec_off+12], 'little')
    sec_rva = int.from_bytes(data[sec_off+12:sec_off+16], 'little')
    sec_raw_size = int.from_bytes(data[sec_off+16:sec_off+20], 'little')
    sec_raw_ptr = int.from_bytes(data[sec_off+20:sec_off+24], 'little')
    print(f'  Section {i}: {sec_name}, RVA=0x{sec_rva:X}, VSize=0x{sec_vsize:X}, RawPtr=0x{sec_raw_ptr:X}, RawSize=0x{sec_raw_size:X}')
    
    if sec_rva <= import_rva < sec_rva + sec_raw_size:
        # Import Directory is in this section
        idata_file_offset = sec_raw_ptr + (import_rva - sec_rva)
        print(f'    -> Import Directory at file offset 0x{idata_file_offset:X}')

if idata_file_offset is None:
    # Calculate manually if Import RVA = 0x41000
    # For .idata at RVA 0x41000, it should be after .text (0x40000 bytes)
    # File layout: DOS+PE headers (512) + .text (65536) = 66048
    idata_file_offset = 512 + 65536  # = 66048 = 0x10200
    print(f'Calculated .idata file offset: 0x{idata_file_offset:X} ({idata_file_offset})')

if idata_file_offset is not None and idata_file_offset < len(data):
    print(f'\n--- Import Directory Table at file offset 0x{idata_file_offset:X} ---')
    
    # Hex dump first 64 bytes at that location
    print('First 64 bytes (hex):')
    for row in range(4):
        off = idata_file_offset + row * 16
        hex_str = ' '.join(f'{data[off+i]:02X}' for i in range(16))
        print(f'  0x{off:05X}: {hex_str}')
    
    # Parse IDT entry
    print('\nIDT Entry 0:')
    ilt_rva = int.from_bytes(data[idata_file_offset:idata_file_offset+4], 'little')
    ts = int.from_bytes(data[idata_file_offset+4:idata_file_offset+8], 'little')
    fwd = int.from_bytes(data[idata_file_offset+8:idata_file_offset+12], 'little')
    name_rva = int.from_bytes(data[idata_file_offset+12:idata_file_offset+16], 'little')
    iat_rva = int.from_bytes(data[idata_file_offset+16:idata_file_offset+20], 'little')
    
    print(f'  ILT RVA: 0x{ilt_rva:X}')
    print(f'  Timestamp: {ts}')
    print(f'  Forwarder Chain: {fwd}')
    print(f'  DLL Name RVA: 0x{name_rva:X}')
    print(f'  IAT RVA: 0x{iat_rva:X}')
    
    # IDT Entry 1 (null terminator?)
    print('\nIDT Entry 1 (should be null terminator):')
    entry1_off = idata_file_offset + 20
    e1 = data[entry1_off:entry1_off+20]
    if all(b == 0 for b in e1):
        print('  [NULL - terminator OK]')
    else:
        print('  ', ' '.join(f'{b:02X}' for b in e1))
else:
    print(f'ERROR: Cannot read .idata (offset 0x{idata_file_offset:X} out of range)')
