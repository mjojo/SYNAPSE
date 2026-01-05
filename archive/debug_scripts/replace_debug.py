
with open('examples/synapse_full.syn', 'r') as f:
    content = f.read()

old_str = '    init_compiler(state)'
new_str = '    io_println("DEBUG: Calling init_compiler")\n    init_compiler(state)'

new_content = content.replace(old_str, new_str)

with open('examples/synapse_full.syn', 'w') as f:
    f.write(new_content)
