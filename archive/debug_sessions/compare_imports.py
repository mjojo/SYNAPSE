with open('test_fasm_iat.exe', 'rb') as f:
    fasm_data = f.read()
    
with open('synapse_new.exe', 'rb') as f:
    syn_data = f.read()

print("="*70)
print("COMPARING IMPORT SECTIONS")
print("="*70)

# Both should have import at offset 0x400
for offset in range(0x400, 0x500, 16):
    fasm_chunk = fasm_data[offset:offset+16]
    syn_chunk = syn_data[offset:offset+16]
    
    match = fasm_chunk == syn_chunk
    marker = " " if match else " <<<< DIFF"
    
    fasm_hex = ' '.join(f'{b:02X}' for b in fasm_chunk)
    syn_hex = ' '.join(f'{b:02X}' for b in syn_chunk)
    
    print(f"0x{offset:03X}: FASM: {fasm_hex}")
    print(f"0x{offset:03X}:  SYN: {syn_hex}{marker}")
    if not match:
        print()
