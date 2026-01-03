fasm_data = open('test_fasm_iat.exe', 'rb').read()
syn_data = open('synapse_new.exe', 'rb').read()

print("="*70)
print("COMPARING ENTRY STUBS")
print("="*70)

print("\nFASM entry_stub (21 bytes):")
fasm_stub = fasm_data[0x200:0x215]
print(' '.join(f'{b:02X}' for b in fasm_stub))

print("\nSYN entry_stub (21 bytes):")
syn_stub = syn_data[0x200:0x215]
print(' '.join(f'{b:02X}' for b in syn_stub))

print("\n" + "="*70)
print("COMPARING CODE - FF 15 INSTRUCTIONS")
print("="*70)

print("\nFASM:")
for i in range(len(fasm_data[0x200:0x300])-5):
    if fasm_data[0x200+i:0x200+i+2] == b'\xFF\x15':
        chunk = fasm_data[0x200+i:0x200+i+6]
        disp = int.from_bytes(chunk[2:6], 'little', signed=True)
        print(f"  0x{0x200+i:03X}: {' '.join(f'{x:02X}' for x in chunk)} (disp: 0x{disp:04X})")

print("\nSYN:")
for i in range(len(syn_data[0x200:0x300])-5):
    if syn_data[0x200+i:0x200+i+2] == b'\xFF\x15':
        chunk = syn_data[0x200+i:0x200+i+6]
        disp = int.from_bytes(chunk[2:6], 'little', signed=True)
        print(f"  0x{0x200+i:03X}: {' '.join(f'{x:02X}' for x in chunk)} (disp: 0x{disp:04X})")
