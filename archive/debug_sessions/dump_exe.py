import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

print(f"File size: {len(data)} bytes\n")

# PE signature offset
e_lfanew = struct.unpack("<I", data[0x3C:0x40])[0]
print(f"PE Header at: 0x{e_lfanew:X}")

# Number of sections
num_sections = struct.unpack("<H", data[e_lfanew+6:e_lfanew+8])[0]
print(f"Number of sections: {num_sections}")

# Entry point
entry_rva = struct.unpack("<I", data[e_lfanew+0x28:e_lfanew+0x2C])[0]
print(f"Entry Point RVA: 0x{entry_rva:X}")

# Import Directory
import_rva = struct.unpack("<I", data[e_lfanew+0xC8:e_lfanew+0xCC])[0]
import_size = struct.unpack("<I", data[e_lfanew+0xCC:e_lfanew+0xD0])[0]
print(f"Import Directory: RVA=0x{import_rva:X}, Size={import_size}")

print("\n=== Code Section (offset 512) ===")
print("First 32 bytes (entry stub):")
code = data[512:544]
print(" ".join(f"{b:02X}" for b in code))

print("\n=== Import Section (offset 1024) ===")
print("Import Directory Table:")
idt = data[1024:1044]
print(" ".join(f"{b:02X}" for b in idt))

print("\nIAT (offset 1024+96):")
iat_offset = 1024 + 96  # Approximate
iat = data[iat_offset:iat_offset+64]
print(" ".join(f"{b:02X}" for b in iat))
