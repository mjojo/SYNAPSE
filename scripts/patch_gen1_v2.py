import struct

# Read gen1_fixed.exe
with open('gen1_fixed.exe', 'rb') as f:
    data = bytearray(f.read())

IDATA_FILE_OFFSET = 0x10200
IDATA_RVA = 0x41000

print("=== PATCHING gen1_fixed.exe (v2) ===")
print()

# Current layout:
#   0-19: IDT entry (FirstThunk at offset 16 = 0x41096)
#   20-39: Null IDT  
#   40-135: ILT (96 bytes)
#   136-148: DLL Name (13 bytes)  
#   149: padding (1 byte)
#   150-245: IAT (96 bytes)
#   246-402: Hint/Name entries
#
# We need to INSERT 2 bytes at position 150, shifting everything after by 2

# Step 1: Read everything after DLL name (from offset 150 to end)
print("Step 1: Read data from offset 150...")
tail_data = bytes(data[IDATA_FILE_OFFSET + 150:IDATA_FILE_OFFSET + 512 - 2])  # Leave room for 2 new bytes
print(f"  Read {len(tail_data)} bytes")

# Step 2: Insert 2 padding bytes at offset 150
print("Step 2: Insert 2 padding bytes at offset 150...")
data[IDATA_FILE_OFFSET + 150] = 0
data[IDATA_FILE_OFFSET + 151] = 0

# Step 3: Write tail data starting at offset 152
print("Step 3: Write tail data starting at offset 152...")
for i, b in enumerate(tail_data):
    data[IDATA_FILE_OFFSET + 152 + i] = b

# Step 4: Update IDT FirstThunk (IAT pointer) at offset 16
print("Step 4: Update IDT IAT pointer...")
old_iat_rva = struct.unpack('<I', data[IDATA_FILE_OFFSET + 16:IDATA_FILE_OFFSET + 20])[0]
new_iat_rva = old_iat_rva + 2  # 0x41096 -> 0x41098
data[IDATA_FILE_OFFSET + 16:IDATA_FILE_OFFSET + 20] = struct.pack('<I', new_iat_rva)
print(f"  IDT FirstThunk: 0x{old_iat_rva:X} -> 0x{new_iat_rva:X}")

# Step 5: Update all ILT entries (add 2 to each)
print("Step 5: Update ILT entries...")
for i in range(12):
    offset = IDATA_FILE_OFFSET + 40 + i * 8
    val = struct.unpack('<Q', data[offset:offset+8])[0]
    if val == 0:
        break
    new_val = val + 2
    data[offset:offset+8] = struct.pack('<Q', new_val)
    print(f"  ILT[{i}]: 0x{val:X} -> 0x{new_val:X}")

# Step 6: Update all IAT entries (add 2 to each) - IAT now at offset 152
print("Step 6: Update IAT entries...")
for i in range(12):
    offset = IDATA_FILE_OFFSET + 152 + i * 8
    val = struct.unpack('<Q', data[offset:offset+8])[0]
    if val == 0:
        break
    new_val = val + 2
    data[offset:offset+8] = struct.pack('<Q', new_val)
    print(f"  IAT[{i}]: 0x{val:X} -> 0x{new_val:X}")

# Step 7: Update entry stub displacement
print("Step 7: Update entry stub displacement...")
ENTRY_STUB_OFFSET = 0x200
old_disp = struct.unpack('<I', data[ENTRY_STUB_OFFSET + 15:ENTRY_STUB_OFFSET + 19])[0]
new_disp = old_disp + 2  # 0x40083 -> 0x40085
data[ENTRY_STUB_OFFSET + 15:ENTRY_STUB_OFFSET + 19] = struct.pack('<I', new_disp)
print(f"  Displacement: 0x{old_disp:X} -> 0x{new_disp:X}")

# Step 8: Update IAT Data Directory RVA in PE header
print("Step 8: Update IAT Data Directory...")
PE_OFFSET = struct.unpack('<I', data[0x3C:0x40])[0]
OPT_START = PE_OFFSET + 4 + 20
IAT_DIR_OFFSET = OPT_START + 112 + 12 * 8
old_iat_dir_rva = struct.unpack('<I', data[IAT_DIR_OFFSET:IAT_DIR_OFFSET+4])[0]
data[IAT_DIR_OFFSET:IAT_DIR_OFFSET+4] = struct.pack('<I', new_iat_rva)
print(f"  IAT Dir RVA: 0x{old_iat_dir_rva:X} -> 0x{new_iat_rva:X}")

# Save patched file
with open('gen1_patched.exe', 'wb') as f:
    f.write(data)

print()
print("=== PATCH COMPLETE (v2) ===")
print("Saved to gen1_patched.exe")
