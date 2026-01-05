import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

offset = 0x10278
print(f"String at 0x{offset:X}:")
print(f"Bytes: {data[offset:offset+32].hex()}")
s = b""
for i in range(32):
    b = data[offset+i]
    if b == 0: break
    s += bytes([b])
print(s.decode())
