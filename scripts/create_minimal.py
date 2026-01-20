import struct
import subprocess

def create_minimal_exe():
    """Create a minimal PE that just calls ExitProcess(42)"""
    
    # Layout:
    # 0x0000-0x007F: DOS Header + DOS Stub
    # 0x0080-0x01FF: PE Header + Section Headers
    # 0x0200-0x03FF: .text section (code)
    # 0x0400-0x05FF: .idata section (imports)
    
    data = bytearray(0x600)
    
    # DOS Header
    data[0:2] = b'MZ'
    data[0x3C:0x40] = struct.pack('<I', 0x80)  # e_lfanew
    
    # PE Signature
    data[0x80:0x84] = b'PE\x00\x00'
    
    # COFF Header
    struct.pack_into('<H', data, 0x84, 0x8664)   # Machine: AMD64
    struct.pack_into('<H', data, 0x86, 2)        # NumberOfSections
    struct.pack_into('<H', data, 0x94, 0xF0)     # SizeOfOptionalHeader (240)
    struct.pack_into('<H', data, 0x96, 0x22)     # Characteristics
    
    # Optional Header (PE32+)
    opt_start = 0x98
    struct.pack_into('<H', data, opt_start, 0x20B)       # Magic: PE32+
    struct.pack_into('<I', data, opt_start + 16, 0x1000) # AddressOfEntryPoint
    struct.pack_into('<Q', data, opt_start + 24, 0x400000) # ImageBase
    struct.pack_into('<I', data, opt_start + 32, 0x1000) # SectionAlignment
    struct.pack_into('<I', data, opt_start + 36, 0x200)  # FileAlignment
    struct.pack_into('<H', data, opt_start + 40, 6)      # MajorOperatingSystemVersion
    struct.pack_into('<I', data, opt_start + 56, 0x4000) # SizeOfImage
    struct.pack_into('<I', data, opt_start + 60, 0x200)  # SizeOfHeaders
    struct.pack_into('<H', data, opt_start + 68, 3)      # Subsystem: CONSOLE
    struct.pack_into('<I', data, opt_start + 108, 16)    # NumberOfRvaAndSizes
    
    # Data Directory: Import (index 1)
    struct.pack_into('<I', data, opt_start + 120 + 8, 0x2000)  # Import RVA
    struct.pack_into('<I', data, opt_start + 120 + 12, 40)     # Import Size
    
    # Data Directory: IAT (index 12)
    struct.pack_into('<I', data, opt_start + 120 + 96, 0x2040) # IAT RVA
    struct.pack_into('<I', data, opt_start + 120 + 100, 16)    # IAT Size
    
    # Section Headers (start at 0x188)
    sect_start = 0x188
    
    # .text section
    data[sect_start:sect_start+8] = b'.text\x00\x00\x00'
    struct.pack_into('<I', data, sect_start + 8, 0x200)   # VirtualSize
    struct.pack_into('<I', data, sect_start + 12, 0x1000) # VirtualAddress
    struct.pack_into('<I', data, sect_start + 16, 0x200)  # SizeOfRawData
    struct.pack_into('<I', data, sect_start + 20, 0x200)  # PointerToRawData
    struct.pack_into('<I', data, sect_start + 36, 0x60000020) # Characteristics: RX
    
    # .idata section
    sect_start += 40
    data[sect_start:sect_start+8] = b'.idata\x00\x00'
    struct.pack_into('<I', data, sect_start + 8, 0x200)   # VirtualSize
    struct.pack_into('<I', data, sect_start + 12, 0x2000) # VirtualAddress
    struct.pack_into('<I', data, sect_start + 16, 0x200)  # SizeOfRawData
    struct.pack_into('<I', data, sect_start + 20, 0x400)  # PointerToRawData
    struct.pack_into('<I', data, sect_start + 36, 0xC0000040) # Characteristics: RW
    
    # .text section code at 0x200 (entry point at 0x1000)
    code_start = 0x200
    code = bytearray([
        # sub rsp, 40
        0x48, 0x83, 0xEC, 0x28,
        # mov ecx, 42 (exit code)
        0xB9, 0x2A, 0x00, 0x00, 0x00,
        # mov rax, [rip + offset]  ; load ExitProcess from IAT
        # IAT is at 0x2040, this instruction ends at 0x1010
        # offset = 0x2040 - 0x1010 = 0x1030
        0x48, 0x8B, 0x05, 0x30, 0x10, 0x00, 0x00,
        # call rax
        0xFF, 0xD0,
    ])
    data[code_start:code_start+len(code)] = code
    
    # .idata section at 0x400 (VA 0x2000)
    idata_start = 0x400
    
    # Import Directory Table (20 bytes per entry, need null terminator)
    # Entry: ILT, TimeDateStamp, ForwarderChain, Name, IAT
    struct.pack_into('<I', data, idata_start + 0, 0x2028)   # ILT RVA
    struct.pack_into('<I', data, idata_start + 4, 0)        # TimeDateStamp
    struct.pack_into('<I', data, idata_start + 8, 0)        # ForwarderChain
    struct.pack_into('<I', data, idata_start + 12, 0x2060)  # Name RVA
    struct.pack_into('<I', data, idata_start + 16, 0x2040)  # IAT RVA (DIFFERENT!)
    # Null terminator (20 bytes of zeros already there)
    
    # ILT at 0x2028 (file offset 0x428)
    ilt_off = 0x428
    struct.pack_into('<Q', data, ilt_off, 0x2070)  # Hint/Name RVA
    struct.pack_into('<Q', data, ilt_off + 8, 0)   # Null terminator
    
    # IAT at 0x2040 (file offset 0x440) - SEPARATE from ILT!
    iat_off = 0x440
    struct.pack_into('<Q', data, iat_off, 0x2070)  # Same Hint/Name RVA (will be patched)
    struct.pack_into('<Q', data, iat_off + 8, 0)   # Null terminator
    
    # DLL Name at 0x2060 (file offset 0x460)
    dll_name = b'KERNEL32.DLL\x00'
    data[0x460:0x460+len(dll_name)] = dll_name
    
    # Hint/Name at 0x2070 (file offset 0x470)
    data[0x470:0x472] = struct.pack('<H', 0)  # Hint
    func_name = b'ExitProcess\x00'
    data[0x472:0x472+len(func_name)] = func_name
    
    with open('minimal_test.exe', 'wb') as f:
        f.write(data)
    
    print("Created minimal_test.exe")
    return 'minimal_test.exe'

create_minimal_exe()

# Test it
result = subprocess.run(['minimal_test.exe'], capture_output=True)
print(f"Exit code: {result.returncode}")
if result.returncode == 42:
    print("SUCCESS! ExitProcess(42) worked!")
elif result.returncode == -1073741819:  # 0xC0000005
    print("CRASH: ACCESS_VIOLATION")
else:
    print(f"Unexpected: 0x{result.returncode & 0xFFFFFFFF:08X}")
