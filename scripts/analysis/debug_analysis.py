# Debug disasm for test_fn
# test_fn JIT bytes from output...

# Look at test_fn code directly by checking its address
# From output: test_fn at 5505000 (approx, it's 66 bytes before main at 5505066)

# Let's see what the function prologue looks like
# Expected test_fn code:
# 55              PUSH RBP
# 48 89 E5        MOV RBP, RSP
# 48 81 EC 20 01  SUB RSP, 0x120
# 48 89 4D 10     MOV [RBP+0x10], RCX  <- homing
# 48 89 55 18     MOV [RBP+0x18], RDX
# 4C 89 45 20     MOV [RBP+0x20], R8
# 4C 89 4D 28     MOV [RBP+0x28], R9
# ...
# 48 8B 45 10     MOV RAX, [RBP+0x10]  <- return x (should read from +0x10)
# C9              LEAVE
# C3              RET

# The problem: when caller pushes arg, then pops to RCX, then does CALL,
# the CALLEE's prologue creates NEW RBP!
# So [RBP+0x10] in callee is DIFFERENT from [RBP+0x10] in caller!

print("The issue is: callee's RBP+0x10 should point to caller's shadow space")
print("Let's trace what happens:")
print("1. Caller: PUSH 55 -> stack has 55")
print("2. Caller: POP RCX -> RCX = 55, stack empty")  
print("3. Caller: SUB RSP, 32 -> shadow space created")
print("4. Caller: CALL test_fn -> pushes return addr")
print("5. Callee: PUSH RBP -> saves old RBP")
print("6. Callee: MOV RBP, RSP -> new RBP = RSP")
print("7. Callee: SUB RSP, 0x120 -> local space")
print("8. Callee: MOV [RBP+0x10], RCX -> HOMING into CALLER's shadow!")
print("9. Callee: MOV RAX, [RBP+0x10] -> reads back")
print()
print("RBP layout in callee:")
print("  RBP+0x00 = saved RBP (pushed in step 5)")
print("  RBP+0x08 = return address (from CALL)")
print("  RBP+0x10 = shadow[0] - this is where we home RCX")
print("  RBP+0x18 = shadow[1]")
print("  etc...")
print()
print("This SHOULD work! Let me check if sym_find is returning wrong offset...")
