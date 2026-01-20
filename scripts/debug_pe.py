import struct
import sys
import os

def align_up(val, align):
    return (val + align - 1) & ~(align - 1)

def dump_pe(filepath):
    print(f"Analyzing: {filepath}")
    with open(filepath, 'rb') as f:
        data = f.read()

    if len(data) < 0x40:
        print("Error: File too small for DOS header")
        return

    # DOS Header
    e_magic = data[0:2]
    if e_magic != b'MZ':
        print(f"Error: Invalid DOS magic: {e_magic}")
        return
    
    e_lfanew = struct.unpack_from('<I', data, 0x3C)[0]
    print(f"PE Header Offset (e_lfanew): {hex(e_lfanew)}")

    if len(data) < e_lfanew + 24:
        print("Error: File too small for PE header")
        return

    # PE Header
    pe_sig = data[e_lfanew:e_lfanew+4]
    if pe_sig != b'PE\0\0':
        print(f"Error: Invalid PE signature: {pe_sig}")
        return

    machine, num_sections, time_date, ptr_sym, num_sym, opt_hdr_size, characteristics = \
        struct.unpack_from('<HHIIIHH', data, e_lfanew + 4)

    print(f"Machine: {hex(machine)} (Expected 0x8664 for x64)")
    print(f"NumberOfSections: {num_sections}")
    print(f"SizeOfOptionalHeader: {opt_hdr_size}")
    print(f"Characteristics: {hex(characteristics)}")

    # Optional Header (PE32+)
    opt_offset = e_lfanew + 24
    magic = struct.unpack_from('<H', data, opt_offset)[0]
    print(f"Optional Magic: {hex(magic)} (Expected 0x20B for PE32+)")

    if magic == 0x20B:
        # PE32+ (64-bit) extraction
        # Standard fields
        size_code = struct.unpack_from('<I', data, opt_offset + 4)[0]
        size_init_data = struct.unpack_from('<I', data, opt_offset + 8)[0]
        size_uninit_data = struct.unpack_from('<I', data, opt_offset + 12)[0]
        entry_point = struct.unpack_from('<I', data, opt_offset + 16)[0]
        base_of_code = struct.unpack_from('<I', data, opt_offset + 20)[0]
        
        # Windows specific fields
        image_base = struct.unpack_from('<Q', data, opt_offset + 24)[0]
        section_alignment = struct.unpack_from('<I', data, opt_offset + 32)[0]
        file_alignment = struct.unpack_from('<I', data, opt_offset + 36)[0]
        
        major_os = struct.unpack_from('<H', data, opt_offset + 40)[0]
        minor_os = struct.unpack_from('<H', data, opt_offset + 42)[0]
        major_sub = struct.unpack_from('<H', data, opt_offset + 48)[0]
        minor_sub = struct.unpack_from('<H', data, opt_offset + 50)[0]
        
        size_of_image = struct.unpack_from('<I', data, opt_offset + 56)[0]
        size_of_headers = struct.unpack_from('<I', data, opt_offset + 60)[0]
        subsystem = struct.unpack_from('<H', data, opt_offset + 68)[0]
        dll_chars = struct.unpack_from('<H', data, opt_offset + 70)[0]
        
        print("\n--- OPTIONAL HEADER ---")
        print(f"AddressOfEntryPoint: {hex(entry_point)}")
        print(f"ImageBase: {hex(image_base)}")
        print(f"SectionAlignment: {hex(section_alignment)}")
        print(f"FileAlignment: {hex(file_alignment)}")
        print(f"SizeOfImage: {hex(size_of_image)}")
        print(f"SizeOfHeaders: {hex(size_of_headers)}")
        print(f"Subsystem: {subsystem} (Expected 3 for Console)")
        
        # Validation
        if section_alignment < 4096:
            if file_alignment != section_alignment:
                print(f"\n[ERROR] SectionAlignment ({section_alignment}) < PageSize, so it MUST equal FileAlignment ({file_alignment})!")
        
        # Sections
        sect_offset = opt_offset + opt_hdr_size
        print("\n--- SECTIONS ---")
        
        max_virt_addr = 0
        computed_size_of_image = 0
        
        for i in range(num_sections):
            name = data[sect_offset:sect_offset+8].rstrip(b'\0')
            virt_size, virt_addr, raw_size, raw_ptr, relocs, lines, num_relocs, num_lines, chars = \
                struct.unpack_from('<IIIIIIHHI', data, sect_offset + 8)
                
            print(f"[{i}] {name.decode('utf-8', errors='ignore')}")
            print(f"    VirtualAddress: {hex(virt_addr)}")
            print(f"    VirtualSize:    {hex(virt_size)}")
            print(f"    RawDataPtr:     {hex(raw_ptr)}")
            print(f"    RawDataSize:    {hex(raw_size)}")
            print(f"    Chars:          {hex(chars)}")

            end_addr = virt_addr + align_up(virt_size, section_alignment)
            if end_addr > computed_size_of_image:
                computed_size_of_image = end_addr
                
            sect_offset += 40
            
        print("\n--- VALIDATION ---")
        # Check SizeOfImage
        # Typically SizeOfImage = LastSectionVA + LastSectionAlignedVirtualSize
        # Note: Headers occupy the first 'Page' but RVA starts at 0x1000 usually.
        # So actually SizeOfImage should cover from 0 to top of last section.
        
        # Usually checking against computed
        expected_size = computed_size_of_image
        print(f"Computed SizeOfImage (Top of last section): {hex(expected_size)}")
        
        if size_of_image != expected_size:
            print(f"[WARNING] Header SizeOfImage ({hex(size_of_image)}) != Computed ({hex(expected_size)})")
            
        # Check invalid chars in section name
        
        # Check RawData vs File Size
        file_size = len(data)
        print(f"Actual File Size: {file_size}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        dump_pe(sys.argv[1])
    else:
        print("Usage: python debug_pe.py <exe>")
