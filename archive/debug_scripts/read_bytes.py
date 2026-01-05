import sys

def read_bytes(filename, offset, count):
    with open(filename, 'rb') as f:
        f.seek(offset)
        data = f.read(count)
        print(f"Read {len(data)} bytes at offset {offset}:")
        print(data.hex())

if __name__ == '__main__':
    read_bytes(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
