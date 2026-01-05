import struct
import sys
import os

def patch_host(filename):
    if not os.path.exists(filename):
        print(f"File {filename} not found.")
        return

    with open(filename, 'rb') as f:
        data = bytearray(f.read())

    pe_sig_offset = struct.unpack_from('<I', data, 0x3C)[0]
    opt_header_offset = pe_sig_offset + 24
    num_sections = struct.unpack_from('<H', data, pe_sig_offset + 6)[0]
    size_of_opt_header = struct.unpack_from('<H', data, pe_sig_offset + 20)[0]
    section_table_offset = opt_header_offset + size_of_opt_header
    
    for i in range(num_sections):
        sec_offset = section_table_offset + i * 40
        name = data[sec_offset:sec_offset+8].rstrip(b'\0').decode('utf-8', errors='ignore')
        v_addr = struct.unpack_from('<I', data, sec_offset + 12)[0]
        raw_size = struct.unpack_from('<I', data, sec_offset + 16)[0]
        raw_ptr = struct.unpack_from('<I', data, sec_offset + 20)[0]
        
        print(f"Section: {name}, VAddr: {hex(v_addr)}, RawSize: {hex(raw_size)}, RawPtr: {hex(raw_ptr)}")
        
        # if name == '.text':
            # ...
            
    with open(filename, 'wb') as f:
        f.write(data)
    print(f"Patched {filename}")

if __name__ == '__main__':
    patch_host(sys.argv[1])
