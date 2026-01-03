#!/usr/bin/env python3
"""Debug helper to check str_equals logic"""

# Simulate what happens
func_call_name = "alloc\x00"
str_alloc = "alloc\x00"

print(f"func_call_name: {repr(func_call_name)}")
print(f"str_alloc: {repr(str_alloc)}")
print(f"Equal? {func_call_name == str_alloc}")

# Check byte by byte
for i, (a, b) in enumerate(zip(func_call_name, str_alloc)):
    print(f"  [{i}] '{a}' vs '{b}' - {ord(a) == ord(b)}")
