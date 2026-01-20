import struct

with open('synapse.exe', 'rb') as f:
    syn = f.read()

with open('out.exe', 'rb') as f:
    out = f.read()

print('=== Comparing PE headers ===')
print()

# DOS Header
syn_elf = struct.unpack('<I', syn[0x3C:0x40])[0]
out_elf = struct.unpack('<I', out[0x3C:0x40])[0]
print(f'e_lfanew: synapse=0x{syn_elf:X}, out=0x{out_elf:X}')

# Optional Header fields
syn_opt = syn_elf + 4 + 20
out_opt = out_elf + 4 + 20

print()
print('Optional Header:')

# Magic
syn_magic = struct.unpack('<H', syn[syn_opt:syn_opt+2])[0]
out_magic = struct.unpack('<H', out[out_opt:out_opt+2])[0]
print(f'  Magic: synapse=0x{syn_magic:X}, out=0x{out_magic:X}')

# Entry point
syn_entry = struct.unpack('<I', syn[syn_opt+16:syn_opt+20])[0]
out_entry = struct.unpack('<I', out[out_opt+16:out_opt+20])[0]
print(f'  EntryPoint: synapse=0x{syn_entry:X}, out=0x{out_entry:X}')

# ImageBase
syn_base = struct.unpack('<Q', syn[syn_opt+24:syn_opt+32])[0]
out_base = struct.unpack('<Q', out[out_opt+24:out_opt+32])[0]
print(f'  ImageBase: synapse=0x{syn_base:X}, out=0x{out_base:X}')

# SizeOfImage
syn_soi = struct.unpack('<I', syn[syn_opt+56:syn_opt+60])[0]
out_soi = struct.unpack('<I', out[out_opt+56:out_opt+60])[0]
print(f'  SizeOfImage: synapse=0x{syn_soi:X}, out=0x{out_soi:X}')

# SizeOfHeaders
syn_soh = struct.unpack('<I', syn[syn_opt+60:syn_opt+64])[0]
out_soh = struct.unpack('<I', out[out_opt+60:out_opt+64])[0]
print(f'  SizeOfHeaders: synapse=0x{syn_soh:X}, out=0x{out_soh:X}')

# Subsystem
syn_sub = struct.unpack('<H', syn[syn_opt+68:syn_opt+70])[0]
out_sub = struct.unpack('<H', out[out_opt+68:out_opt+70])[0]
print(f'  Subsystem: synapse={syn_sub}, out={out_sub}')

# DllCharacteristics
syn_dll = struct.unpack('<H', syn[syn_opt+70:syn_opt+72])[0]
out_dll = struct.unpack('<H', out[out_opt+70:out_opt+72])[0]
print(f'  DllChars: synapse=0x{syn_dll:X}, out=0x{out_dll:X}')

# Stack/Heap sizes
print()
print('Stack/Heap:')
syn_stack_reserve = struct.unpack('<Q', syn[syn_opt+72:syn_opt+80])[0]
out_stack_reserve = struct.unpack('<Q', out[out_opt+72:out_opt+80])[0]
print(f'  StackReserve: synapse=0x{syn_stack_reserve:X}, out=0x{out_stack_reserve:X}')

syn_stack_commit = struct.unpack('<Q', syn[syn_opt+80:syn_opt+88])[0]
out_stack_commit = struct.unpack('<Q', out[out_opt+80:out_opt+88])[0]
print(f'  StackCommit: synapse=0x{syn_stack_commit:X}, out=0x{out_stack_commit:X}')

syn_heap_reserve = struct.unpack('<Q', syn[syn_opt+88:syn_opt+96])[0]
out_heap_reserve = struct.unpack('<Q', out[out_opt+88:out_opt+96])[0]
print(f'  HeapReserve: synapse=0x{syn_heap_reserve:X}, out=0x{out_heap_reserve:X}')

syn_heap_commit = struct.unpack('<Q', syn[syn_opt+96:syn_opt+104])[0]
out_heap_commit = struct.unpack('<Q', out[out_opt+96:out_opt+104])[0]
print(f'  HeapCommit: synapse=0x{syn_heap_commit:X}, out=0x{out_heap_commit:X}')
