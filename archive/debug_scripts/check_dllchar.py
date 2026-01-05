import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

offset = 0xDE
print("Reading...")
print(f"Bytes: {data[offset:offset+2].hex()}")
val = struct.unpack("<H", data[offset:offset+2])[0]
print(f"DllCharacteristics at 0x{offset:X}: 0x{val:X}")
