import struct

data = open('synapse_new.exe', 'rb').read()

# Section 2 (.bss) starts at offset 0x188 + 80 (2 * 40 bytes)
sec2_off = 0x188 + 80
chars = struct.unpack('<I', data[sec2_off+36:sec2_off+40])[0]
print(f'.bss Characteristics: {hex(chars)}')

# Decode characteristics
if chars & 0x80000000:
    print("  IMAGE_SCN_MEM_WRITE")
if chars & 0x40000000:
    print("  IMAGE_SCN_MEM_READ")
if chars & 0x20000000:
    print("  IMAGE_SCN_MEM_EXECUTE")
if chars & 0x00000080:
    print("  IMAGE_SCN_CNT_UNINITIALIZED_DATA")
if chars & 0x00000040:
    print("  IMAGE_SCN_CNT_INITIALIZED_DATA")
if chars & 0x00000020:
    print("  IMAGE_SCN_CNT_CODE")
