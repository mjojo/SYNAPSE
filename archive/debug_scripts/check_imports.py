import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

def read_string(offset):
    s = b""
    # Hint is 2 bytes before string
    # But RVA points to Hint/Name structure (2 bytes hint + string)
    # So string starts at offset + 2
    for i in range(32):
        b = data[offset+2+i]
        if b == 0: break
        s += bytes([b])
    return s.decode()

print(f"Index 0 (0x10286): {read_string(0x10286)}")
print(f"Index 1 (0x10294): {read_string(0x10294)}")
