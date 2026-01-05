import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

offset = 0x200
print(f"Code at Entry Point (0x{offset:X}):")
print(f"Bytes: {data[offset:offset+32].hex()}")
print(list(data[offset:offset+32]))
