d=open('bin/synapse.exe','rb').read()
off=0x40+0xC8
print('Import Dir in synapse.exe:')
print(' '.join(f'{b:02X}' for b in d[off:off+8]))
