import re

with open("bin/synapse.exe", "rb") as f:
    data = f.read()

strings = re.findall(b"[A-Za-z0-9_]{4,}", data)
for s in strings:
    try:
        print(s.decode())
    except:
        pass
