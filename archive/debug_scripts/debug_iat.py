data = open('synapse_new.exe', 'rb').read()
print(f"File size: {len(data)}")

# Entry point bytes
print("\nEntry point (file offset 0x200):")
print(' '.join(f'{b:02X}' for b in data[0x200:0x220]))

# Find FF 15 patterns
print("\nFF 15 (call [rip+disp]) instructions:")
count = 0
for i in range(0x200, min(0x10200, len(data)-6)):
    if data[i] == 0xFF and data[i+1] == 0x15:
        disp = int.from_bytes(data[i+2:i+6], 'little', signed=True)
        rva = 0x1000 + (i - 0x200) + 6  # RVA of next instruction
        target = rva + disp
        iat_idx = (target - 0x41028) // 8 if target >= 0x41028 else -1
        print(f'  0x{i:04X}: call [rip+0x{disp:X}] -> RVA 0x{target:X} (IAT[{iat_idx}])')
        count += 1
        if count >= 20: break

# Check IAT location
print(f"\nIAT expected at RVA 0x41028 (file offset 0x10228)")
iat_off = 0x10200 + 0x28
print("IAT first 3 entries:")
for i in range(3):
    val = int.from_bytes(data[iat_off+i*8:iat_off+i*8+8], 'little')
    print(f"  [{i}]: 0x{val:X}")
