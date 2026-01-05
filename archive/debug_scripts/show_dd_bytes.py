with open('bin/synapse_test.exe', 'rb') as f:
    data = f.read()

print('Bytes at offset 248 (Export DD):')
print(' '.join(f'{b:02X}' for b in data[248:256]))

print('\nBytes at offset 256 (Import DD):')
print(' '.join(f'{b:02X}' for b in data[256:264]))

print('\nBytes at offset 264:')
print(' '.join(f'{b:02X}' for b in data[264:272]))
