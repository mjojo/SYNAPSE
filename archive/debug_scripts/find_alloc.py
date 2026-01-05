import struct

with open("synapse_new.exe", "rb") as f:
    data = f.read()

# Sequence:
# MOV RDX, RAX          48 89 C2
# XOR ECX, ECX          31 C9
# MOV R8D, 0x3000       41 B8 00 30 00 00
# MOV R9D, 4            41 B9 04 00 00 00
# CALL [REL]            FF 15 .. .. .. ..

pattern = b'\x48\x89\xC2\x31\xC9\x41\xB8\x00\x30\x00\x00\x41\xB9\x04\x00\x00\x00\xFF\x15'

offset = data.find(pattern)

if offset != -1:
    print(f"Found alloc sequence at file offset: 0x{offset:X}")
    
    # The CALL instruction starts at offset + 17 bytes
    call_instr_offset = offset + 17
    print(f"CALL instruction at file offset: 0x{call_instr_offset:X}")
    
    # The relative offset is the 4 bytes after FF 15
    rel_offset_loc = call_instr_offset + 2
    rel_offset = struct.unpack("<i", data[rel_offset_loc:rel_offset_loc+4])[0]
    print(f"Relative offset: 0x{rel_offset:X} ({rel_offset})")
    
    # Calculate RVA of the next instruction
    # .text section starts at file offset 0x200 and maps to RVA 0x1000
    # So RVA = FileOffset - 0x200 + 0x1000
    next_instr_file_offset = call_instr_offset + 6
    next_instr_rva = next_instr_file_offset - 0x200 + 0x1000
    print(f"Next instruction RVA: 0x{next_instr_rva:X}")
    
    # Target RVA = Next Instr RVA + Relative Offset
    target_rva = next_instr_rva + rel_offset
    print(f"Target RVA (IAT Entry): 0x{target_rva:X}")
    
    # Expected VirtualAlloc IAT entry
    # IAT Base RVA = 0x11028
    # VirtualAlloc is index 1 (2nd entry) -> 0x11028 + 8 = 0x11030
    expected_rva = 0x11030
    
    if target_rva == expected_rva:
        print("SUCCESS: Target RVA matches VirtualAlloc IAT entry!")
    else:
        print(f"FAILURE: Target RVA mismatch! Expected 0x{expected_rva:X}")

else:
    print("Alloc sequence not found!")
    
    # Try searching for parts of it
    part1 = b'\x41\xB8\x00\x30\x00\x00' # MOV R8D, 0x3000
    off1 = data.find(part1)
    if off1 != -1:
        print(f"Found partial sequence (MOV R8D, 0x3000) at 0x{off1:X}")
        # Check surrounding bytes
        start = max(0, off1 - 10)
        end = min(len(data), off1 + 20)
        print("Surrounding bytes:")
        print(" ".join(f"{b:02X}" for b in data[start:end]))
    else:
        print("Partial sequence (MOV R8D, 0x3000) NOT FOUND")
        
    part2 = b'\x41\xB9\x04\x00\x00\x00' # MOV R9D, 4
    off2 = data.find(part2)
    if off2 != -1:
        print(f"Found partial sequence (MOV R9D, 4) at 0x{off2:X}")
