import struct

# Read the PE
with open('d:/Projects/SYNAPSE/synapse_new.exe', 'rb') as f:
    data = f.read()

# Find code section and dump hex
pe_offset = struct.unpack('<H', data[0x3C:0x3E])[0]
optional_hdr_offset = pe_offset + 24
image_base = struct.unpack('<Q', data[optional_hdr_offset + 24:optional_hdr_offset + 32])[0]
text_rva = 0x1000  # First section RVA
text_offset = 0x200  # First section file offset

code_data = data[text_offset:text_offset+0x100]

print("=== Machine code dump ===")
print(' '.join(f'{b:02X}' for b in code_data[:95]))

# Find the CALL [RIP+disp]
for i in range(len(code_data) - 6):
    if code_data[i:i+2] == b'\xFF\x15':
        disp = struct.unpack('<i', code_data[i+2:i+6])[0]
        call_addr_rva = text_rva + i + 6 + disp
        print(f"\nCALL [RIP+0x{disp:X}] at offset 0x{i:X}")
        print(f"  Next instruction RVA: 0x{text_rva + i + 6:X}")
        print(f"  Target IAT entry RVA: 0x{call_addr_rva:X}")
        
        # Read from IAT
        iat_file_offset = 0x200 + (call_addr_rva - text_rva)
        if iat_file_offset < len(data):
            iat_value = struct.unpack('<Q', data[iat_file_offset:iat_file_offset+8])[0]
            print(f"  IAT entry value at file offset 0x{iat_file_offset:X}: 0x{iat_value:X}")

# Check IAT section
print("\n=== IAT Section (RVA 0x2000+) ===")
iat_offset = 0x400  # .rdata section
print("IAT[0] (0x2028):", data[iat_offset+0x28:iat_offset+0x30].hex())
print("IAT[1] (0x2030):", data[iat_offset+0x30:iat_offset+0x38].hex())

# Import Directory
print("\n=== Import Directory ===")
import_dir_offset = iat_offset  # IDT starts at 0x2000
idt = data[import_dir_offset:import_dir_offset+0x20]
print("IDT bytes:", idt.hex())

# First IDT entry (20 bytes)
ilt_rva = struct.unpack('<I', idt[0:4])[0]
name_rva = struct.unpack('<I', idt[12:16])[0]
first_thunk_rva = struct.unpack('<I', idt[16:20])[0]
print(f"OriginalFirstThunk (ILT RVA): 0x{ilt_rva:X}")
print(f"Name RVA: 0x{name_rva:X}")
print(f"FirstThunk (IAT RVA): 0x{first_thunk_rva:X}")
