import struct

# Наш exe
with open(r'D:\Projects\SYNAPSE\synapse_new.exe', 'rb') as f:
    our = f.read()

# FASM exe
with open(r'D:\Projects\SYNAPSE\test_va.exe', 'rb') as f:
    fasm = f.read()

print('=== Our VirtualAlloc call sequence ===')
# FF 15 at file offset ~0x255 area
for i in range(0x240, 0x280):
    if our[i] == 0xFF and our[i+1] == 0x15:
        print(f'FF 15 at offset 0x{i:X}')
        pre = our[i-30:i]
        post = our[i:i+12]
        print(f'Before: {" ".join(f"{b:02X}" for b in pre)}')
        print(f'Call:   {" ".join(f"{b:02X}" for b in post)}')
        break

print()
print('=== FASM VirtualAlloc call sequence ===')
for i in range(0x200, 0x280):
    if fasm[i] == 0xFF and fasm[i+1] == 0x15:
        print(f'FF 15 at offset 0x{i:X}')
        pre = fasm[i-20:i]
        post = fasm[i:i+12]
        print(f'Before: {" ".join(f"{b:02X}" for b in pre)}')
        print(f'Call:   {" ".join(f"{b:02X}" for b in post)}')
        break
