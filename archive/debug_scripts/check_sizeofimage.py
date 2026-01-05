import struct

with open("bin/synapse.exe", "rb") as f:
    data = f.read()

offset = 0xE40
val = struct.unpack("<I", data[offset:offset+4])[0]
print(f"SizeOfImage at 0x{offset:X}: 0x{val:X} ({val})")
