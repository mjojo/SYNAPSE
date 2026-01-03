import sys
f = open('synapse_new.exe', 'rb')
data = f.read()
f.close()

print(f"File size: {len(data)}")

# Look for 'ab\x00'
idx = data.find(b'ab\x00')
if idx >= 0:
    print(f"'ab' found at file offset: 0x{idx:x}")
else:
    print("'ab' not found")
    # Look for any 'a' followed by 'b'
    for i, b in enumerate(data):
        if b == ord('a') and i+1 < len(data) and data[i+1] == ord('b'):
            print(f"ab at: 0x{i:x}")
            break

# Check if address 0x41AE44 makes sense
# .rdata typically at 0x400000 + section offset
# Let's check what's at typical locations
print("\nChecking PE structure:")
e_lfanew = int.from_bytes(data[0x3C:0x40], 'little')
print(f"e_lfanew: 0x{e_lfanew:x}")

pe_sig = data[e_lfanew:e_lfanew+4]
print(f"PE signature: {pe_sig}")

# Section headers are at e_lfanew + 24 (COFF header) + size of optional header
# For PE32+, optional header is 240 bytes
optional_header_offset = e_lfanew + 4 + 20  # After PE sig and COFF header
size_of_optional = int.from_bytes(data[e_lfanew + 4 + 16:e_lfanew + 4 + 18], 'little')
num_sections = int.from_bytes(data[e_lfanew + 4 + 2:e_lfanew + 4 + 4], 'little')
print(f"Num sections: {num_sections}")
print(f"Size of optional header: {size_of_optional}")

section_headers_offset = optional_header_offset + size_of_optional
print(f"Section headers at: 0x{section_headers_offset:x}")

for i in range(num_sections):
    sec_start = section_headers_offset + i * 40
    sec_name = data[sec_start:sec_start+8].rstrip(b'\x00').decode('ascii', errors='ignore')
    virtual_size = int.from_bytes(data[sec_start+8:sec_start+12], 'little')
    virtual_addr = int.from_bytes(data[sec_start+12:sec_start+16], 'little')
    raw_size = int.from_bytes(data[sec_start+16:sec_start+20], 'little')
    raw_ptr = int.from_bytes(data[sec_start+20:sec_start+24], 'little')
    print(f"  {sec_name}: VirtAddr=0x{virtual_addr:x}, VirtSize=0x{virtual_size:x}, RawPtr=0x{raw_ptr:x}, RawSize=0x{raw_size:x}")

# The address 0x41AE44 would be at virtual address 0x1AE44 relative to image base 0x400000
relative_addr = 0x41AE44 - 0x400000
print(f"\nRelative address for 0x41AE44: 0x{relative_addr:x}")
