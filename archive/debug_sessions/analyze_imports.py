with open('synapse_new.exe', 'rb') as f:
    data = f.read()

print("="*70)
print("IMPORT DIRECTORY TABLE ANALYSIS")
print("="*70)

import_offset = 0x400  # File offset where import section starts
base_rva = 0x2000      # RVA where import section is mapped

# Import Directory Entry (20 bytes)
ilt_rva = int.from_bytes(data[import_offset:import_offset+4], 'little')
timestamp = int.from_bytes(data[import_offset+4:import_offset+8], 'little')
forwarder = int.from_bytes(data[import_offset+8:import_offset+12], 'little')
name_rva = int.from_bytes(data[import_offset+12:import_offset+16], 'little')
iat_rva = int.from_bytes(data[import_offset+16:import_offset+20], 'little')

print("\nImport Directory Entry #1:")
print(f"  OriginalFirstThunk (ILT) RVA: 0x{ilt_rva:08X}")
print(f"  TimeDateStamp:                 0x{timestamp:08X}")
print(f"  ForwarderChain:                0x{forwarder:08X}")
print(f"  Name RVA:                      0x{name_rva:08X}")
print(f"  FirstThunk (IAT) RVA:          0x{iat_rva:08X}")

# Verify DLL name
name_file_offset = import_offset + (name_rva - base_rva)
dll_name = data[name_file_offset:name_file_offset+20].split(b'\x00')[0].decode('ascii')
print(f"\nDLL Name at RVA 0x{name_rva:X}: '{dll_name}'")

# Check ILT
print("\nImport Lookup Table (ILT):")
ilt_file_offset = import_offset + (ilt_rva - base_rva)
for i in range(8):
    entry_offset = ilt_file_offset + i * 8
    entry = int.from_bytes(data[entry_offset:entry_offset+8], 'little')
    if entry == 0:
        print(f"  ILT[{i}]: 0x0000000000000000 (terminator)")
        break
    # Check if it's ordinal (bit 63 set) or name RVA
    if entry & (1 << 63):
        ordinal = entry & 0xFFFF
        print(f"  ILT[{i}]: Ordinal {ordinal}")
    else:
        hint_rva = entry
        hint_file_offset = import_offset + (hint_rva - base_rva)
        hint_word = int.from_bytes(data[hint_file_offset:hint_file_offset+2], 'little')
        func_name = data[hint_file_offset+2:hint_file_offset+50].split(b'\x00')[0].decode('ascii')
        print(f"  ILT[{i}]: RVA 0x{hint_rva:08X} -> Hint:{hint_word} '{func_name}'")

# Check IAT
print("\nImport Address Table (IAT) - BEFORE LoaderFill:")
iat_file_offset = import_offset + (iat_rva - base_rva)
for i in range(8):
    entry_offset = iat_file_offset + i * 8
    entry = int.from_bytes(data[entry_offset:entry_offset+8], 'little')
    if entry == 0:
        print(f"  IAT[{i}]: 0x0000000000000000 (terminator)")
        break
    print(f"  IAT[{i}] at file:0x{entry_offset:X} (RVA:0x{base_rva + (iat_rva - base_rva) + i*8:X}): 0x{entry:016X}")

print("\n" + "="*70)
print("EXPECTED BEHAVIOR:")
print("="*70)
print("Windows Loader should:")
print("  1. Read ILT entries to find function names")
print("  2. Resolve each name in KERNEL32.DLL")
print("  3. OVERWRITE IAT entries with real function addresses")
print("  4. After load, IAT should contain addresses like 0x00007FF8XXXXX")
print("\nIf IAT still contains RVAs (0x20XX) after load, it means:")
print("  - Loader didn't process the import table")
print("  - Something is wrong with Import Directory structure")
