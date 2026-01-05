import sys

def find_string(filename, search_str):
    with open(filename, 'rb') as f:
        data = f.read()
    
    search_bytes = search_str.encode('utf-8')
    start = 0
    while True:
        offset = data.find(search_bytes, start)
        if offset == -1:
            break
        
        print(f"Found '{search_str}' at offset {offset} (0x{offset:X})")
        if offset >= 512:
            rva = 0x1000 + (offset - 512)
            print(f"Estimated RVA: 0x{rva:X}")
            print(f"Estimated VA: 0x{0x400000 + rva:X}")
        
        start = offset + 1

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python find_string.py <file> <string>")
    else:
        find_string(sys.argv[1], sys.argv[2])
