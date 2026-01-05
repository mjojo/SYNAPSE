with open("synapse_new.exe", "rb") as f:
    data = f.read()

# 9th function at RVA 0x110F6
rva = 0x110F6
file_off = 0x10200 + (rva - 0x11000)
print(f"9th function at file offset 0x{file_off:X} (RVA 0x{rva:X}):")
print("Bytes:", " ".join(f"{b:02X}" for b in data[file_off:file_off+24]))

# Try to read as hint+name
hint = data[file_off] | (data[file_off+1] << 8)
name_start = file_off + 2
name = b""
for j in range(30):
    if data[name_start + j] == 0:
        break
    name += bytes([data[name_start + j]])

print(f"Hint: {hint}")
print(f"Name: {name.decode('ascii', errors='replace')}")
