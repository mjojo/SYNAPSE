f = open('gen1.exe', 'rb')
f.seek(0x102F6)
d = f.read(20)
print("Bytes:", ' '.join(f'{b:02X}' for b in d))
hint = int.from_bytes(d[0:2], 'little')
print(f"Hint: {hint}")
name = d[2:].split(b'\x00')[0]
print(f"Name: {name.decode('ascii')}")
