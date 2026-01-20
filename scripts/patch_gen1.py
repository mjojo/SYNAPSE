import struct

# Read gen1_fixed.exe
with open('gen1_fixed.exe', 'rb') as f:
    data = bytearray(f.read())

IDATA_FILE_OFFSET = 0x10200
IDATA_RVA = 0x41000

print("=== PATCHING gen1_fixed.exe ===")
print()

# Current layout (offsets within .idata):
#   0-19: IDT entry
#   20-39: Null IDT  
#   40-135: ILT (96 bytes, 12 qwords)
#   136-148: DLL Name "KERNEL32.DLL\0" (13 bytes)
#   149: padding (1 byte) -> total 14 bytes
#   150-245: IAT (96 bytes, 12 qwords)
#   246+: Hint/Name entries

# New layout (shift everything after DLL name by 2 bytes):
#   0-19: IDT entry
#   20-39: Null IDT  
#   40-135: ILT (96 bytes, 12 qwords)
#   136-148: DLL Name "KERNEL32.DLL\0" (13 bytes)
#   149-151: padding (3 bytes) -> 16 bytes total, ends at 152
#   152-247: IAT (96 bytes, 12 qwords)
#   248+: Hint/Name entries

# Step 1: Read current Hint/Name entries (they start at offset 246)
print("Step 1: Read Hint/Name entries...")
# Find end of Hint/Name data
last_nonzero = 0
for i in range(511, 245, -1):
    if data[IDATA_FILE_OFFSET + i] != 0:
        last_nonzero = i
        break
hint_name_len = last_nonzero - 246 + 1
print(f"  Hint/Name data length: {hint_name_len} bytes")
hint_name_data = bytes(data[IDATA_FILE_OFFSET + 246:IDATA_FILE_OFFSET + 246 + hint_name_len])

# Step 2: Read current IAT content
print("Step 2: Read IAT content...")
iat_content = []
for i in range(12):
    val = struct.unpack('<Q', data[IDATA_FILE_OFFSET + 150 + i*8:IDATA_FILE_OFFSET + 150 + i*8 + 8])[0]
    iat_content.append(val)
    if val == 0:
        break

# Step 3: Update IDT entry (FirstThunk/IAT pointer)
print("Step 3: Update IDT IAT pointer from 0x41096 to 0x41098...")
new_iat_rva = IDATA_RVA + 152  # 0x41098
data[IDATA_FILE_OFFSET + 16:IDATA_FILE_OFFSET + 20] = struct.pack('<I', new_iat_rva)

# Step 4: Update ILT entries (they point to Hint/Name entries, add 2 to each)
print("Step 4: Update ILT entries (add 2 to each RVA)...")
for i in range(12):
    offset = IDATA_FILE_OFFSET + 40 + i * 8
    old_val = struct.unpack('<Q', data[offset:offset+8])[0]
    if old_val == 0:
        break
    new_val = old_val + 2
    data[offset:offset+8] = struct.pack('<Q', new_val)
    print(f"  ILT[{i}]: 0x{old_val:X} -> 0x{new_val:X}")

# Step 5: Clear old IAT and Hint/Name area
print("Step 5: Clear old data...")
for i in range(150, 512):
    data[IDATA_FILE_OFFSET + i] = 0

# Step 6: Add padding bytes (offset 149, 150, 151)
data[IDATA_FILE_OFFSET + 149] = 0
data[IDATA_FILE_OFFSET + 150] = 0
data[IDATA_FILE_OFFSET + 151] = 0

# Step 7: Write IAT at new position (offset 152) with updated entries
print("Step 6: Write IAT at offset 152 with updated entries...")
for i, val in enumerate(iat_content):
    new_offset = 152 + i * 8
    if val == 0:
        data[IDATA_FILE_OFFSET + new_offset:IDATA_FILE_OFFSET + new_offset + 8] = struct.pack('<Q', 0)
        break
    new_val = val + 2  # Hint/Name entries also shifted by 2
    data[IDATA_FILE_OFFSET + new_offset:IDATA_FILE_OFFSET + new_offset + 8] = struct.pack('<Q', new_val)
    print(f"  IAT[{i}]: 0x{val:X} -> 0x{new_val:X}")

# Step 8: Write Hint/Name entries at new position (offset 248)
print("Step 7: Write Hint/Name entries at offset 248...")
for i, b in enumerate(hint_name_data):
    data[IDATA_FILE_OFFSET + 248 + i] = b

# Step 9: Update entry stub displacement
print("Step 8: Update entry stub displacement...")
ENTRY_STUB_OFFSET = 0x200
old_disp = struct.unpack('<I', data[ENTRY_STUB_OFFSET + 15:ENTRY_STUB_OFFSET + 19])[0]
new_disp = 0x40085
data[ENTRY_STUB_OFFSET + 15:ENTRY_STUB_OFFSET + 19] = struct.pack('<I', new_disp)
print(f"  Displacement: 0x{old_disp:X} -> 0x{new_disp:X}")

# Step 10: Update IAT Data Directory in Optional Header
print("Step 9: Update IAT Data Directory RVA...")
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
print("=== PATCH COMPLETE ===")
print("Saved to gen1_patched.exe")
