import struct

with open("bin/synapse.exe", "rb") as f:
    data = f.read()

offset = 0xEF0
val = struct.unpack("<I", data[offset:offset+4])[0]
print(f"Value at 0x{offset:X}: 0x{val:X}")

offset_iat = 0xF48
val_iat = struct.unpack("<I", data[offset_iat:offset_iat+4])[0]
print(f"Value at 0x{offset_iat:X}: 0x{val_iat:X}")
