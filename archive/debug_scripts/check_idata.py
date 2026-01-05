import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

offset = 0x10200
if offset >= len(data):
    print(f"Offset 0x{offset:X} is beyond EOF (0x{len(data):X})")
else:
    print(f"Data at 0x{offset:X}:")
    print(f"Length: {len(data[offset:offset+64])}")
    print(f"Hex: {data[offset:offset+64].hex()}")
    print(list(data[offset:offset+64]))
