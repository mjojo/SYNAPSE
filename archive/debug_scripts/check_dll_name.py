with open("synapse_new.exe", "rb") as f:
    data = f.read()

# DLL Name at RVA 0x11078
dll_name_rva = 0x11078
dll_name_off = 0x10200 + (dll_name_rva - 0x11000)

print(f"DLL Name at file offset 0x{dll_name_off:X} (RVA 0x{dll_name_rva:X}):")
name = b""
for i in range(50):
    b = data[dll_name_off + i]
    if b == 0:
        break
    name += bytes([b])
print(f"  {name.decode('ascii')}")
