import struct

with open('synapse_new.exe', 'rb') as f:
    data = f.read()

print(f"File size: {len(data)} bytes\n")

# PE offset
e_lfanew = struct.unpack('<I', data[0x3C:0x40])[0]
print(f"PE Header at offset: 0x{e_lfanew:X}")

# Entry point RVA
entry_rva = struct.unpack('<I', data[e_lfanew+0x28:e_lfanew+0x2C])[0]
print(f"Entry Point RVA: 0x{entry_rva:X}")

# Import Directory RVA
import_rva = struct.unpack('<I', data[e_lfanew+0xC8:e_lfanew+0xCC])[0]
print(f"Import Directory RVA: 0x{import_rva:X}\n")

# Find Import Section (should be at file offset 1024 = 0x400)
# Import RVA = 0x2000, Section starts at RVA 0x2000, file offset 0x400
import_offset = 0x400

print("=== Import Directory Table ===")
idt = data[import_offset:import_offset+20]
print(" ".join(f"{b:02X}" for b in idt))

# Parse IDT
ilt_rva = struct.unpack('<I', idt[0:4])[0]
name_rva = struct.unpack('<I', idt[12:16])[0]
iat_rva = struct.unpack('<I', idt[16:20])[0]

print(f"\nILT RVA: 0x{ilt_rva:X}")
print(f"Name RVA: 0x{name_rva:X}")
print(f"IAT RVA: 0x{iat_rva:X}")

# IAT should be at RVA 0x2028 = offset 0x400 + 0x28 = 0x428
iat_offset = import_offset + (iat_rva - import_rva)
print(f"\nIAT file offset: 0x{iat_offset:X}")

print("\n=== IAT Entries ===")
for i in range(8):
    entry_offset = iat_offset + i*8
    entry = struct.unpack('<Q', data[entry_offset:entry_offset+8])[0]
    if entry == 0:
        print(f"[{i}] NULL (end of table)")
        break
    print(f"[{i}] 0x{entry:016X}", end="")
    # If < 0x100000000, it's an RVA to hint/name
    if entry < 0x100000000:
        hint_offset = import_offset + (entry - import_rva)
        hint = struct.unpack('<H', data[hint_offset:hint_offset+2])[0]
        name = data[hint_offset+2:hint_offset+20].split(b'\x00')[0].decode()
        print(f" -> Hint {hint}, Name: {name}")
    else:
        print(f" -> LOADED ADDRESS (after Windows Loader)")

print("\n=== Code Section (entry stub) ===")
code_offset = 0x200
code = data[code_offset:code_offset+32]
print(" ".join(f"{b:02X}" for b in code))
