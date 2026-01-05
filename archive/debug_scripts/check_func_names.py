with open("synapse_new.exe", "rb") as f:
    data = f.read()

# Check function names
hint_rvas = [0x11086, 0x11094, 0x110A4, 0x110B2, 0x110BE, 0x110CA, 0x110D8, 0x110E6, 0x110F6]

for i, rva in enumerate(hint_rvas):
    file_off = 0x10200 + (rva - 0x11000)
    # Hint is 2 bytes, then name (null-terminated)
    hint = data[file_off] | (data[file_off+1] << 8)
    name_start = file_off + 2
    name = b""
    j = 0
    while data[name_start + j] != 0:
        name += bytes([data[name_start + j]])
        j += 1
    print(f"[{i}] Hint {hint}: {name.decode('ascii')}")
