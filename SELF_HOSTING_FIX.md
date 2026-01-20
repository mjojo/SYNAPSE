# Self-Hosting Crash Fix
**Date:** 2026-01-05
**Status:** FIXED

## Problem
The self-hosted compiler (`synapse_new.exe`) was crashing with `Access Violation (0xC0000005)` when calling functions with parameters (e.g., `str_len(s)`).

## Root Cause
The `param_offset` variable in the compiler causing incorrect stack offset calculations for function parameters.
- Params were intended to be spilled to `[RBP-8]`, `[RBP-16]`, etc.
- `param_offset` was initialized to `16` in `src/synapse.asm`.
- This caused the compiler to think the first parameter was at index 4+ (Stack Param) instead of register spill.
- `sym_add_param` calculated offset based on `param_offset`.
- Result: Function tried to read parameter from `[RBP + 144]` (garbage) instead of `[RBP - 8]`.

## Fix
Modified `src/synapse.asm` to initialize `param_offset` to `0`.
```asm
; src/synapse.asm : Line ~1300 (inside parse_fn)
mov dword [param_offset], 0  ; Was 16
```

## Verification
1. Rebuilt host compiler `bin\synapse.exe`.
2. Recompiled `synapse_full.syn` to `synapse_new.exe`.
3. Verified `synapse_new.exe` runs `run_compiler` successfully (returns 120, prints "R").
4. Validated parameter passing (`my_len(s)`), string access (`str_len`), and intrinsic calls (`io_print`).

## Next Steps
- The `run_compiler` function in `examples/synapse_full.syn` is currently in debug mode (calculating factorial). Restore it to full compiler logic when ready to test full self-compilation pipeline.
