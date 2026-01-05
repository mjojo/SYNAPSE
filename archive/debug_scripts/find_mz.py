with open("bin/synapse.exe", "rb") as f:
    data = f.read()

print(f"Total file size: {len(data)} bytes (0x{len(data):X})")
print("\nMZ locations:")
for i in range(len(data) - 1):
    if data[i:i+2] == b'MZ':
        print(f"  0x{i:X}")

# Check if synapse.exe itself is valid PE
pe_offset = int.from_bytes(data[0x3C:0x40], 'little')
print(f"\nsynapse.exe's own PE offset (e_lfanew): 0x{pe_offset:X}")
print(f"PE signature at that location: {data[pe_offset:pe_offset+4]}")

# Now check template
mz2 = data.find(b'MZ', 1)
print(f"\nSecond MZ (pe_header_stub template) at: 0x{mz2:X}")

#  Check e_lfanew in template
if mz2 != -1:
    template_lfanew_off = mz2 + 0x3C
    template_lfanew = int.from_bytes(data[template_lfanew_off:template_lfanew_off+4], 'little')
    print(f"Template e_lfanew value: 0x{template_lfanew:X}")
    template_pe_off = mz2 + template_lfanew
    print(f"Template PE signature at 0x{template_pe_off:X}: {data[template_pe_off:template_pe_off+4]}")
