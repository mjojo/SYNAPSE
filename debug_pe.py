import struct
import sys

def check_pe(filename):
    print(f"🔍 Analyzing {filename}...")
    try:
        with open(filename, "rb") as f:
            data = f.read()
    except FileNotFoundError:
        print("❌ File not found.")
        return

    # 1. DOS Header
    if data[0:2] != b'MZ':
        print("❌ Not an EXE file (Missing MZ)")
        return
    pe_offset = struct.unpack("<I", data[0x3C:0x40])[0]
    print(f"✅ PE Header Offset: 0x{pe_offset:X}")

    # 2. PE Header
    pe = data[pe_offset:]
    if pe[0:4] != b'PE\x00\x00':
        print("❌ Invalid PE Signature")
        return

    num_sections = struct.unpack("<H", pe[6:8])[0]
    opt_header_size = struct.unpack("<H", pe[20:22])[0]
    print(f"📊 Number of Sections: {num_sections}")

    # Optional Header
    opt_header = pe[24:24+opt_header_size]
    magic = struct.unpack("<H", opt_header[0:2])[0]
    if magic != 0x20B:
        print("❌ Not PE32+ (64-bit)")
        return

    entry_point = struct.unpack("<I", opt_header[16:20])[0]
    image_base = struct.unpack("<Q", opt_header[24:32])[0]
    sect_align = struct.unpack("<I", opt_header[32:36])[0]
    file_align = struct.unpack("<I", opt_header[36:40])[0]
    size_image = struct.unpack("<I", opt_header[56:60])[0]
    
    print(f"📍 Entry Point: 0x{entry_point:X}")
    print(f"📏 Alignment: Sect=0x{sect_align:X}, File=0x{file_align:X}")
    print(f"📦 SizeOfImage: 0x{size_image:X}")

    # Data Directories (Offset 112 in Optional Header for PE32+)
    # Import Directory is Index 1
    import_rva = struct.unpack("<I", opt_header[112+8:112+12])[0]
    import_size = struct.unpack("<I", opt_header[112+12:112+16])[0]
    print(f"⚓ Import Directory: RVA=0x{import_rva:X}, Size=0x{import_size:X}")

    # 3. Section Headers
    sect_offset = pe_offset + 24 + opt_header_size
    print("\n📂 SECTIONS:")
    
    import_in_section = False
    
    for i in range(num_sections):
        s_data = data[sect_offset + i*40 : sect_offset + (i+1)*40]
        name = s_data[0:8].decode('utf-8', 'ignore').strip('\x00')
        v_size = struct.unpack("<I", s_data[8:12])[0]
        v_addr = struct.unpack("<I", s_data[12:16])[0]
        raw_size = struct.unpack("<I", s_data[16:20])[0]
        raw_ptr = struct.unpack("<I", s_data[20:24])[0]
        chars = struct.unpack("<I", s_data[36:40])[0]

        print(f"  [{i}] {name}: RVA=0x{v_addr:X}, RawPtr=0x{raw_ptr:X}, RawSize=0x{raw_size:X}, Flags=0x{chars:X}")

        # Check if Import Directory is inside this section
        if import_rva >= v_addr and import_rva < v_addr + v_size:
            print(f"      ✅ Import Directory is inside this section!")
            import_in_section = True
            
            # Check Write Permissions (REQUIRED for IAT to be filled)
            if not (chars & 0x80000000): # IMAGE_SCN_MEM_WRITE
                print(f"      ❌ CRITICAL: Section is NOT WRITABLE! Loader cannot fill IAT!")
            else:
                 print(f"      ✅ Section is Writable.")

            # Calculate File Offset of Import Directory
            delta = import_rva - v_addr
            file_offset_import = raw_ptr + delta
            print(f"      📍 File Offset of Imports: 0x{file_offset_import:X}")
            
            # Read Import Directory Table
            try:
                idt = data[file_offset_import : file_offset_import + 20]
                orig_thunk = struct.unpack("<I", idt[0:4])[0]
                name_rva = struct.unpack("<I", idt[12:16])[0]
                first_thunk = struct.unpack("<I", idt[16:20])[0]
                print(f"      📑 IDT Entry 0: ILT=0x{orig_thunk:X}, NameRVA=0x{name_rva:X}, IAT(FirstThunk)=0x{first_thunk:X}")
                
                if first_thunk == 0:
                     print("      ❌ CRITICAL: FirstThunk (IAT) is 0!")
            except:
                print("      ❌ Could not read IDT data")

    if not import_in_section:
        print("\n❌ CRITICAL: Import Directory RVA is NOT covered by any section!")

print("=" * 60)
print("   SYNAPSE PE32+ Structure Diagnostic Tool")
print("   Phase 52 - IAT Resolution Blocker Analysis")
print("=" * 60)
print()

check_pe("synapse_new.exe")

print("\n" + "=" * 60)
print("Looking for:")
print("  1. Section containing imports must be WRITABLE (0x80000000 flag)")
print("  2. Import Directory RVA must be within section bounds")
print("  3. FirstThunk (IAT RVA) must be non-zero")
print("=" * 60)
