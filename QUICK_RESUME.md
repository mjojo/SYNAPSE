# 🚨 QUICK RESUME - Phase 71 Debug

## THE BUG
Gen1 compiler (synapse_new.exe) crashes silently on ANY input file.

## ROOT CAUSE (95% Confidence)
**Direct array indexing incompatibility:**
- Code uses `state[29-32]` for const tables  
- Original compiler only used direct indexing for `state[0-28]`
- In COMPILED code, `state[29]` may return WRONG VALUE or GARBAGE POINTER
- This causes crash in `get_arr(garbage_pointer, i)`

## IMMEDIATE FIX (Try First)
Replace ALL direct indexing with get_arr/set_arr:

```synapse
// BAD (current):
let const_names = state[29]
state[31] = 0

// GOOD (fix):
let const_names = get_arr(state, 29)
set_arr(state, 31, 0)
```

**Locations to fix:**
1. `find_const_index()` - lines ~1471-1472
2. `parse_const_decl()` - lines ~2275-2277  
3. `parse_ident()` - line ~1550
4. `add_var()` - lines ~1488-1490
5. `parse_function()` - line ~2197
6. `init_compiler()` - lines ~549-554

## ALTERNATIVE FIX (If Above Fails)
Add debug output to pinpoint exact crash line:
```synapse
fn run_compiler() {
    io_print("A")
    let cmd = get_cmd_line()
    io_print("B")
    let state = my_alloc(512)
    io_print("C")
    init_compiler(state)
    io_print("D")
    // ...
}
```

## TEST COMMAND
```powershell
bin\synapse.exe examples/synapse_full.syn
cmd /c test_no_const.bat  # Should see "OK" if fixed
```

## FILES TO CHECK
- examples/synapse_full.syn (main compiler)
- DEBUGGING_SESSION_JAN5.md (full analysis)
- test_no_const.bat, test_const.bat (test scripts)

**Status:** Ready to fix (know the issue, have the solution)
