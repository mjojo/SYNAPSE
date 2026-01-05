with open("synapse_new.exe", "rb") as f:
    data = f.read()

import struct

# IAT at RVA 0x11028 → file offset 0x10228
iat_offset = 0x10228

print("IAT at file offset 0x{:X}:".format(iat_offset))
for i in range(10):  # 10 entries (9 functions + null terminator)
    entry_off = iat_offset + (i * 8)
    entry = struct.unpack("<Q", data[entry_off:entry_off+8])[0]
    print(f"  [{i}]: 0x{entry:016X}")
    
    if entry == 0:
        print(f"    ^ Null terminator")
        break
    elif entry & 0x8000000000000000:  # Ordinal import
        ordinal = entry & 0xFFFF
        print(f"    ^ Ordinal {ordinal}")
    else:  # Name import
        hint_rva = entry
        print(f"    ^ Hint/Name RVA: 0x{hint_rva:X}")
