import re

def process(path):
    with open(path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        # Strip DEBUG lines
        if 'DEBUG' in line and ('io_print' in line or 'io_println' in line):
            continue
        # Strip my beacons
        if '[1] Entered Main' in line: continue
        if '[2] Calling run_compiler' in line: continue
        if '[3] Exit Main' in line: continue
        if '[A] Inside run_compiler' in line: continue
        if 'SYNAPSE v3.6 - FULL COMPILER' in line: continue
        if '=================================' in line: continue
        
        # Replace constants
        l = line
        if 'io_print("' in l:
            l = re.sub(r'io_print\("[^"]*"\)', 'io_print("")', l)
        if 'io_println("' in l:
            l = re.sub(r'io_println\("[^"]*"\)', 'io_println("")', l)
            
        l = l.replace('65536', '131072') 
        l = l.replace('69632', '135168')
        l = l.replace('69672', '135208')
        
        new_lines.append(l)

    with open(path, 'w') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    process("d:/Projects/SYNAPSE/examples/synapse_stripped.syn")
