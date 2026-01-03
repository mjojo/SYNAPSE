import sys

with open('synapse_new.exe', 'rb') as f:
    data = f.read()
    
print(f"File size: {len(data)}")    

# IAT starts at file offset 0x400 (after 512 headers + 512 code section)
iat_offset = 0x400
iat_data = data[iat_offset:iat_offset+64]

print(f"IAT data length: {len(iat_data)}")

output = []
output.append("IAT Section (first 64 bytes from offset 0x600):")
for i in range(0, min(len(iat_data), 64), 8):
    chunk = iat_data[i:i+8]
    if len(chunk) < 8:
        break
    hex_str = ' '.join(f'{b:02X}' for b in chunk)
    addr = int.from_bytes(chunk, 'little')
    output.append(f"{i:04X}: {hex_str}  (address: 0x{addr:016X})")
        
for line in output:
    print(line)
    
with open('iat_dump.txt', 'w') as f:
    f.write('\n'.join(output))
