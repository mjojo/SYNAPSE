import struct

data = open('synapse_new.exe', 'rb').read()

# main() starts at RVA 0xD18F (calculated earlier)
# Entry at 0x200, call +0xC186 -> target RVA 0x1009 + 0xC186 = 0xD18F
main_file = 0x200 + (0xD18F - 0x1000)
print(f"main() at file offset 0x{main_file:X}")

# Check what main() does
print("\nmain() first 64 bytes:")
for row in range(4):
    off = main_file + row*16
    hex_str = ' '.join(f'{data[off+i]:02X}' for i in range(16))
    print(f"  0x{off:05X}: {hex_str}")

# Decode the first call in main() (to io_print)
# At main+31: E8 A3 6D FF FF
call_off = main_file + 35  # After jmp +2 and "M\0" and mov rax, imm64
print(f"\nLooking for call instruction around 0x{call_off:X}")

# Find E8 pattern
for i in range(main_file, main_file+50):
    if data[i] == 0xE8:
        rel = struct.unpack('<i', data[i+1:i+5])[0]
        rva = 0x1000 + (i - 0x200) + 5
        target_rva = rva + rel
        print(f"  E8 at 0x{i:X}: call to RVA 0x{target_rva:X}")
        if target_rva > 0 and target_rva < 0x10000:
            target_file = 0x200 + (target_rva - 0x1000)
            print(f"    -> file offset 0x{target_file:X}")
            print(f"    -> first bytes: {' '.join(f'{data[target_file+j]:02X}' for j in range(8))}")
