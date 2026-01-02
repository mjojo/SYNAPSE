import struct
d=open('bin/synapse.exe','rb').read()
e_lf=struct.unpack('<I', d[0x3C:0x40])[0]
print(f'e_lfanew in synapse.exe = {e_lf} (0x{e_lf:X})')

# Compare with our header stub
print("\nChecking pe_header_stub in source...")
print("Expected e_lfanew: 0x40")
print(f"Actual e_lfanew: 0x{e_lf:X}")

# Check what's at 0x40
print(f"\nBytes at 0x40: {' '.join(f'{b:02X}' for b in d[0x40:0x48])}")
print(f"Bytes at 0x80: {' '.join(f'{b:02X}' for b in d[0x80:0x88])}")
