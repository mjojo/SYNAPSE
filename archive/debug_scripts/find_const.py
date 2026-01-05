import struct

def search_instruction(filename):
    with open(filename, 'rb') as f:
        data = f.read()
    
    # mov rax, 0x400000
    pattern = b'\x00\xF8\x40\x00'
    
    offset = 0
    while True:
        offset = data.find(pattern, offset)
        if offset == -1:
            break
        print(f"Found mov rax, 0x400000 at offset {offset}")
        offset += 1

search_instruction('bin/synapse_patched.exe')
