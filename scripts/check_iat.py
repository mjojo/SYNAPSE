import sys

def check_iat(filename):
    with open(filename, 'rb') as f:
        f.seek(0x10200)  # .idata section
        d = f.read(32)
        
        ilt = int.from_bytes(d[0:4], 'little')
        name_rva = int.from_bytes(d[12:16], 'little')
        iat = int.from_bytes(d[16:20], 'little')
        
        print(f"{filename}:")
        print(f"  ILT RVA:  0x{ilt:08X}")
        print(f"  Name RVA: 0x{name_rva:08X}")
        print(f"  IAT RVA:  0x{iat:08X}")
        
        if ilt == iat:
            print("  WARNING: ILT == IAT (old format, may crash on modern Windows!)")
        else:
            print("  OK: ILT != IAT (proper separate tables)")
        print()

check_iat("gen1.exe")
check_iat("synapse_new.exe")
check_iat("out.exe")
