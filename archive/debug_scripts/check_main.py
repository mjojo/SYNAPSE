import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

offset = 0x211
print(f"Code at main (0x{offset:X}):")
print(f"Bytes: {data[offset:offset+128].hex()}")
