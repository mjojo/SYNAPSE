import sys

def analyze(path):
    with open(path, 'rb') as f:
        data = f.read()

    print(f'File size: {len(data)}')

    # Search for 57344 (0xE000)
    val_data = b'\x00\xE0\x00\x00'
    offsets_data = []
    pos = 0
    while True:
        pos = data.find(val_data, pos)
        if pos == -1:
            break
        offsets_data.append(pos)
        pos += 1
    
    print(f'Found 57344 (0xE000) count: {len(offsets_data)}')
    if len(offsets_data) < 20:
        print(offsets_data)

if __name__ == '__main__':
    analyze('d:/Projects/SYNAPSE/bin/synapse.exe')
