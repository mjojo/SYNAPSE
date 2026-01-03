import subprocess
import struct

result = subprocess.run(['bin/synapse.exe', 'test_param_return.syn', 'out.exe'], 
                       capture_output=True, text=True)
print(result.stdout)
print(result.stderr)

# Read out.exe and dump .text section  
with open('synapse_new.exe', 'rb') as f:
    data = f.read()
    
# PE starts at offset in e_lfanew
e_lfanew = struct.unpack('<I', data[0x3C:0x40])[0]
print(f"\nPE header at 0x{e_lfanew:X}")

# .text section starts at file offset 0x200
text_start = 0x200
text_size = 0x1000  # 4KB
text = data[text_start:text_start+text_size]

# Print first 256 bytes of .text as hex
print("\n.text section (first 256 bytes):")
for i in range(0, min(256, len(text)), 16):
    hex_str = ' '.join(f'{b:02X}' for b in text[i:i+16])
    print(f"  {i:04X}: {hex_str}")
