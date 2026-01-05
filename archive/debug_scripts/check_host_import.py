with open('bin/synapse.exe', 'rb') as f:
    data = f.read()

# Import DD offset: 128 + 4 + 20 + 96 + 8 = 256
import_rva = int.from_bytes(data[256:260], 'little')
import_size = int.from_bytes(data[260:264], 'little')
print(f'Import DD in HOST: RVA=0x{import_rva:X}, Size=0x{import_size:X}')
