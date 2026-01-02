d=open('bin/synapse.exe','rb').read()
import_off=0x80+0xC8
print(f'Import Dir at 0x{import_off:X}:')
print(' '.join(f'{b:02X}' for b in d[import_off:import_off+8]))
