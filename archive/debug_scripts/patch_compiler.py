import sys

def patch(path, out_path):
    with open(path, 'rb') as f:
        data = f.read()

    # Replace 65536 (0x00010000 -> 00 00 01 00) with 262144 (0x00040000 -> 00 00 04 00)
    old_val = b'\x00\x00\x01\x00'
    new_val = b'\x00\x00\x04\x00'
    
    count = data.count(old_val)
    print(f"Found {count} occurrences of 65536")
    
    data = data.replace(old_val, new_val)
    
    # Replace 69632 (0x11000) with 266240 (0x41000)
    old_val_idata = b'\x00\x10\x01\x00'
    new_val_idata = b'\x00\x10\x04\x00'
    count = data.count(old_val_idata)
    print(f"Found {count} occurrences of 69632")
    data = data.replace(old_val_idata, new_val_idata)
    
    # Replace 69672 (0x11028) with 266280 (0x41028)
    old_val_iat = b'\x28\x10\x01\x00'
    new_val_iat = b'\x28\x10\x04\x00'
    count = data.count(old_val_iat)
    print(f"Found {count} occurrences of 69672")
    data = data.replace(old_val_iat, new_val_iat)
    
    # Replace 66048 (0x10200) with 264192 (0x40800)
    old_val_rawptr = b'\x00\x02\x01\x00'
    new_val_rawptr = b'\x00\x08\x04\x00'
    count = data.count(old_val_rawptr)
    print(f"Found {count} occurrences of 66048")
    data = data.replace(old_val_rawptr, new_val_rawptr)
    
    # Replace 131072 (0x00020000) with 524288 (0x00080000)
    old_val_128k = b'\x00\x00\x02\x00'
    new_val_512k = b'\x00\x00\x08\x00'
    count = data.count(old_val_128k)
    print(f"Found {count} occurrences of 131072")
    data = data.replace(old_val_128k, new_val_512k)
    
    # Replace 512 (0x200) with 2048 (0x800)
    old_val_512 = b'\x00\x02\x00\x00'
    new_val_2048 = b'\x00\x08\x00\x00'
    count = data.count(old_val_512)
    print(f"Found {count} occurrences of 512")
    data = data.replace(old_val_512, new_val_2048)
    
    # Replace 4253696 (0x40E100) with 4257792 (0x40F100)
    old_val_data = b'\x00\xE1\x40\x00'
    new_val_data = b'\x00\xF1\x40\x00'
    count = data.count(old_val_data)
    print(f"Found {count} occurrences of 4253696")
    data = data.replace(old_val_data, new_val_data)
    
    with open(out_path, 'wb') as f:
        f.write(data)
    
    print(f"Patched {path} -> {out_path}")

if __name__ == "__main__":
    patch("d:/Projects/SYNAPSE/bin/synapse.exe", "d:/Projects/SYNAPSE/bin/synapse_patched.exe")
