import struct

# Read HOST binary
with open('bin/synapse_test.exe', 'rb') as f:
    host_bytes = f.read()

# Check Import DD in HOST (offset 256)
import_rva = struct.unpack('<I', host_bytes[256:260])[0]
import_size = struct.unpack('<I', host_bytes[260:264])[0]
print(f"Import DD in HOST_TEST (offset 256): RVA=0x{import_rva:X}, Size=0x{import_size:X}")
