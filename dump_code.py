with open('synapse_new.exe', 'rb') as f:
    data = f.read()
    
# Code section starts at 0x200
code = data[0x200:0x200+120]

print("Full code sequence:")
for i in range(0, min(len(code), 120), 16):
    hex_str = ' '.join(f'{b:02X}' for b in code[i:i+16])
    ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in code[i:i+16])
    print(f"  {0x200+i:04X}: {hex_str:47}  {ascii_str}")
