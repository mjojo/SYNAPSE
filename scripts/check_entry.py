import sys

with open('synapse_new.exe', 'rb') as f:
    f.seek(512)
    data = f.read(16)
    print(f"Bytes at 512: {data.hex()}")

    f.seek(0)
    all_data = f.read()
    print(f"Total size: {len(all_data)}")
