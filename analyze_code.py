import struct

with open('synapse_new.exe', 'rb') as f:
    data = f.read()

print("=== Code Section (offset 512) ===")
code = data[512:600]
print("First 88 bytes:")
for i in range(0, 88, 16):
    offset = 512 + i
    chunk = code[i:i+16]
    hex_str = ' '.join(f'{b:02X}' for b in chunk)
    ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
    print(f"  {offset:04X}: {hex_str:48s} {ascii_str}")

# Find CALL [RIP+disp] instruction (FF 15)
for i in range(len(code) - 6):
    if code[i] == 0xFF and code[i+1] == 0x15:
        disp = struct.unpack('<i', code[i+2:i+6])[0]
        print(f"\nFound CALL [RIP+disp32] at offset {512+i} (0x{512+i:X})")
        print(f"  Displacement: {disp} (0x{disp:X})")
        print(f"  RVA after instruction: 0x{0x1000 + i + 6:X}")
        print(f"  Target RVA: 0x{0x1000 + i + 6 + disp:X}")
        print(f"  Expected IAT RVA: 0x2070 (VirtualAlloc)")
