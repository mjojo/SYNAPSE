import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

offset = 0x10228
print(f"IAT at 0x{offset:X}:")
print(f"Bytes: {data[offset:offset+64].hex()}")
