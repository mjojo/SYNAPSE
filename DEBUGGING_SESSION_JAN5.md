# 🐞 DEBUGGING SESSION - January 5, 2026

## Phase 71: Const Keyword Implementation - BLOCKED

**Status:** ⚠️ CRITICAL BUG - Gen1 compiler crashes on all inputs

---

## 🔍 PROBLEM SUMMARY

The self-hosted compiler (`synapse_new.exe`) compiled from `synapse_full.syn` with Phase 71 changes crashes immediately when trying to compile ANY file, even simple programs without `const` keyword.

### Symptoms
- ✅ Gen0 (bin/synapse.exe) compiles synapse_full.syn successfully → 58KB code, 86 functions
- ❌ Gen1 (synapse_new.exe) crashes on launch, no error message
- ❌ No `out.exe` created (compilation never starts)
- ❌ PowerShell shows no console output (Win32 stdout not captured)

---

## 🧪 WHAT WE TESTED

### Working Configurations
```
✓ Gen0 + synapse_full.syn (OLD, Phase 69) → Gen1 works perfectly
✓ Gen0 + hello.syn → compiles and runs (exit code varies)
✓ Gen0 + synapse_full.syn (Phase 71) → compiles without errors
```

### Broken Configurations  
```
✗ Gen1 (Phase 71) + hello.syn → CRASH (silent)
✗ Gen1 (Phase 71) + test_simple42.syn → CRASH (no output)
✗ Gen1 (Phase 71) + test_const_simple_return.syn → CRASH
✗ Gen1 (Phase 71) + (no args) → CRASH (should show usage error)
```

**Conclusion:** The problem is in the COMPILED CODE (Gen1), not the source logic.

---

## 🔧 CHANGES MADE (Phase 71)

### 1. State Array Extension
**Original:** `let state = my_alloc(256)` (32 qwords, indices 0-31)  
**Current:** `let state = my_alloc(512)` (64 qwords, indices 0-63)

**New Indices:**
- `state[29]` = const_names (pointer to 2048-byte buffer)
- `state[30]` = const_values (pointer to 2048-byte buffer)  
- `state[31]` = const_count (integer 0-256)
- `state[32]` = stack_depth (MOVED from index 29)

### 2. New Functions
- `find_const_index(state, name)` - Lookup constant by name
- `parse_const_decl(state)` - Parse `const NAME = VALUE`

### 3. Modified Functions
- `init_compiler()` - Allocate const tables, initialize state[29-32]
- `parse_ident()` - Check constants before variables
- `parse_program()` - Handle `const` keyword
- `add_var()` - Use state[32] instead of state[29] for stack_depth
- `parse_function()` - Reset state[32] instead of state[29]

---

## 🐛 BUGS FOUND & FIXED

### Bug 1: Double Increment in find_const_index ✅
**Problem:** Loop counter `i` incremented twice per iteration  
```synapse
if existing == 0 {
    i = i + 1  // First increment
}
if existing > 0 {
    // ...
    i = i + 1  // Second increment (always executed!)
}
```
**Fix:** Removed nested if, use simple loop with single increment  
**Status:** ✅ FIXED (but crash persists)

### Bug 2: Insufficient State Buffer (Suspected) ✅
**Problem:** `state[32]` accessed with only 256-byte buffer (32 qwords)  
**Fix:** Increased to 512 bytes (64 qwords)  
**Status:** ✅ FIXED (but crash persists)

### Bug 3: ??? (Active Investigation)
**Hypothesis:** Memory corruption or pointer issue in compiled code  
**Evidence:**
- Crash happens BEFORE parsing (even with empty input)
- `find_const_index` is called for EVERY identifier (including "main", "fn")
- If `state[29]` contains garbage, `get_arr(const_names, i)` will crash

---

## 🎯 LEADING HYPOTHESIS

### Theory: Direct Indexing vs get_arr Mismatch

**Observation:** Original compiler only uses direct indexing for `state[0-28]`.  
For higher indices, it ALWAYS uses `get_arr(state, index)`.

**Current Code Uses:**
```synapse
// In find_const_index:
let const_names = state[29]  // Direct indexing ← SUSPECT!
let const_count = state[31]  // Direct indexing ← SUSPECT!

// In parse_ident:
let const_values = state[30]  // Direct indexing ← SUSPECT!
```

**Hypothesis:** In COMPILED code (Gen1), direct indexing `state[29]` may:
1. Not work correctly for indices > 28 (bootstrap limitation)
2. Read from wrong memory location
3. Return garbage pointer → crash in `get_arr(garbage, i)`

**Test:** Replace ALL `state[29-32]` with `get_arr(state, 29-32)` and `set_arr(state, 29-32, value)`

---

## 📋 NEXT SESSION ACTION PLAN

### Step 1: Pinpoint Crash Location (5 min)
Add debug output to narrow down crash point:
```synapse
fn run_compiler() {
    io_print("A")  // Start
    let cmd = get_cmd_line()
    io_print("B")  // After cmd
    let state = my_alloc(512)
    io_print("C")  // After alloc
    init_compiler(state)
    io_print("D")  // After init
    // ... rest of function
}
```
Run: `synapse_new.exe test_simple42.syn`  
Expected: See which letter appears → find exact crash line

### Step 2: Test Array Access Pattern (10 min)
Replace direct indexing with get_arr/set_arr:
```synapse
// OLD:
let const_names = state[29]
state[31] = 0

// NEW:
let const_names = get_arr(state, 29)
set_arr(state, 31, 0)
```
Test: Does Gen1 work after this change?

### Step 3: Isolate find_const_index (5 min)
Temporarily disable const lookup:
```synapse
// In parse_ident:
let const_idx = 0 - 1  // Always return -1 (not found)
// Comment out: let const_idx = find_const_index(state, name)
```
Test: Does Gen1 work without const lookups?

### Step 4: If Still Broken...
Check these areas:
- ✓ Verify all `my_alloc()` calls succeed (not returning 0)
- ✓ Check if `state[32]` usage in `add_var()` is correct
- ✓ Verify `parse_function()` resets state[32] properly
- ✓ Look for off-by-one errors in array bounds

---

## 🔬 DEBUG TOOLS AVAILABLE

### Command Line Testing
```batch
# test_const.bat - Test const syntax
synapse_new.exe test_const_simple_return.syn
if exist out.exe (echo OK) else (echo FAIL)

# test_no_const.bat - Test without const
synapse_new.exe test_simple42.syn  
if exist out.exe (echo OK) else (echo FAIL)
```

### Test Files Created
- `test_simple42.syn` - Simple return 42 (no const)
- `test_const_simple_return.syn` - const ANSWER=42; return ANSWER
- `test_const_run.syn` - Arithmetic with multiple consts

### Compiler Versions
- **Gen0:** `bin\synapse.exe` (v3.5.0 JIT, always works)
- **Gen1:** `synapse_new.exe` (self-hosted Phase 71, currently broken)

---

## 📊 SESSION STATISTICS

**Duration:** ~3 hours  
**Token Usage:** 68K / 1M  
**Bugs Fixed:** 2  
**Bugs Remaining:** 1 (critical)  
**Lines Changed:** ~150  
**Functions Added:** 2 (find_const_index, parse_const_decl)  
**Compiler Size:** 58KB code (86 functions)

---

## 💡 KEY INSIGHTS

1. **The Bug is Subtle:** Code compiles without errors, crashes at runtime
2. **Platform-Specific:** Self-hosted compiler behavior differs from JIT
3. **Memory Layout Matters:** Direct indexing may have hidden assumptions
4. **Bootstrap Constraints:** Gen0 and Gen1 may handle arrays differently

**Most Likely Cause:** Incompatibility between direct indexing `state[29-32]` in source code and how compiled code accesses arrays.

**Next Focus:** Convert all state[29-32] access to get_arr/set_arr pattern.

---

**Session End:** January 5, 2026, 21:35 UTC+3  
**Status:** Ready to resume debugging  
**Confidence Level:** High (we've narrowed down the issue significantly)
