# PHASE 71: CONST KEYWORD IMPLEMENTATION PLAN

**Goal:** Add compile-time constant support to SYNAPSE language  
**Status:** Ready to implement  
**Complexity:** Medium (simpler than global variables!)  
**Expected Duration:** 2-3 days  

---

## 🎯 WHY CONST INSTEAD OF GLOBAL VARIABLES?

**Const (Compile-Time Substitution):**
- ✅ No memory allocation needed
- ✅ No runtime initialization
- ✅ No Global Scope required
- ✅ Just a symbol table lookup during parsing
- ✅ Zero performance overhead

**Global Variables (Runtime Storage):**
- ❌ Requires `.data` section management
- ❌ Needs initialization code in entry point
- ❌ Requires memory addressing (RIP-relative or absolute)
- ❌ Complex scope resolution

**Decision:** Start with `const` — it's 10x simpler and solves 90% of our refactoring needs.

---

## 📋 IMPLEMENTATION STEPS

### Step 1: Lexer — Add TOKEN_CONST

**File:** `examples/synapse_full.syn` → `tokenize()` function

**Changes:**
1. Add keyword recognition for `"const"`
2. Create new token type `TOKEN_CONST = 13` (next available)

**Code location:**
```synapse
fn tokenize(state, source) {
    // ... existing code ...
    
    // After checking for "fn", "let", "if", "while", "return"
    if str_eq(word_buf, "const") {
        add_token(state, 13, word_buf)  // TOKEN_CONST
        continue
    }
}
```

**Test:**
```synapse
const PI = 314
```
Should tokenize as: `[TOKEN_CONST, "const"], [TOKEN_IDENT, "PI"], [TOKEN_ASSIGN, "="], [TOKEN_NUMBER, "314"]`

---

### Step 2: Parser — Create Constants Table

**Data Structure:**
We need a simple key-value store: `name → value`

**Implementation approach:**
Since we don't have hash tables yet, use parallel arrays:
- `const_names[100]` — array of name pointers
- `const_values[100]` — array of integer values
- `const_count` — number of constants defined

**Where to store:**
Add to compiler state (array index 16-18):
```synapse
state[16] = my_alloc(800)   // const_names (100 * 8 bytes)
state[17] = my_alloc(800)   // const_values (100 * 8 bytes)
state[18] = 0               // const_count
```

---

### Step 3: Parser — Parse Const Definitions

**Syntax:**
```synapse
const IDENTIFIER = NUMBER
```

**Function:** `parse_const_definition(state)`

**Pseudocode:**
```synapse
fn parse_const_definition(state) {
    advance(state)  // Skip "const" token
    
    // Expect identifier
    if current_token_type(state) != TOKEN_IDENT {
        io_println("Error: Expected identifier after const")
        return 0
    }
    let name = current_token_text(state)
    advance(state)
    
    // Expect "="
    if current_token_type(state) != TOKEN_ASSIGN {
        io_println("Error: Expected = after const name")
        return 0
    }
    advance(state)
    
    // Expect number
    if current_token_type(state) != TOKEN_NUMBER {
        io_println("Error: Expected number after =")
        return 0
    }
    let value = str_to_int(current_token_text(state))
    advance(state)
    
    // Store in constants table
    add_const(state, name, value)
    
    return 0
}
```

**Helper function:**
```synapse
fn add_const(state, name, value) {
    let const_names = state[16]
    let const_values = state[17]
    let const_count = state[18]
    
    // Store name pointer
    set_arr(const_names, const_count, name)
    
    // Store value
    set_arr(const_values, const_count, value)
    
    // Increment count
    state[18] = const_count + 1
    
    return 0
}
```

---

### Step 4: Parser — Lookup Constants in Expressions

**Function:** `lookup_const(state, name) → value or -1`

**Pseudocode:**
```synapse
fn lookup_const(state, name) {
    let const_names = state[16]
    let const_values = state[17]
    let const_count = state[18]
    
    let i = 0
    while i < const_count {
        let stored_name = get_arr(const_names, i)
        if str_eq(stored_name, name) {
            return get_arr(const_values, i)
        }
        i = i + 1
    }
    
    return -1  // Not found
}
```

---

### Step 5: Parser — Substitute in parse_expr

**Current flow:**
```synapse
fn parse_ident(state) {
    let name = current_token_text(state)
    
    // Check if it's a variable
    let var_offset = lookup_var(state, name)
    if var_offset >= 0 {
        // Generate: MOV RAX, [RBP + offset]
        emit(state, 0x48)  // REX.W
        emit(state, 0x8B)  // MOV
        emit(state, 0x85)  // ModRM
        emit_dword(state, var_offset)
        return 0
    }
    
    // Otherwise error
    io_print("Error: Undefined variable: ")
    io_println(name)
    return 0
}
```

**NEW flow:**
```synapse
fn parse_ident(state) {
    let name = current_token_text(state)
    
    // 1. Check if it's a constant (NEW!)
    let const_value = lookup_const(state, name)
    if const_value >= 0 {
        // Generate: MOV RAX, immediate
        emit_mov_rax_imm64(state, const_value)
        return 0
    }
    
    // 2. Check if it's a variable
    let var_offset = lookup_var(state, name)
    if var_offset >= 0 {
        // Generate: MOV RAX, [RBP + offset]
        emit(state, 0x48)
        emit(state, 0x8B)
        emit(state, 0x85)
        emit_dword(state, var_offset)
        return 0
    }
    
    // 3. Otherwise error
    io_print("Error: Undefined variable/constant: ")
    io_println(name)
    return 0
}
```

**Note:** Lookup constants BEFORE variables (constants have priority).

---

### Step 6: Parser — Update parse_program

**Current:**
```synapse
fn parse_program(state) {
    while current_token_type(state) > 0 {
        if current_token_type(state) == TOKEN_FN {
            parse_function(state)
        }
    }
}
```

**NEW:**
```synapse
fn parse_program(state) {
    while current_token_type(state) > 0 {
        let tok = current_token_type(state)
        
        if tok == TOKEN_CONST {
            parse_const_definition(state)
        }
        
        if tok == TOKEN_FN {
            parse_function(state)
        }
    }
}
```

---

### Step 7: Test — Simple Constant

**Test file:** `examples/test_const.syn`
```synapse
const ANSWER = 42

fn main() {
    return ANSWER
}
```

**Expected behavior:**
```bash
synapse_new.exe examples/test_const.syn
.\out.exe
echo %ERRORLEVEL%  # Should print 42
```

**Generated code should be:**
```asm
main:
    push rbp
    mov rbp, rsp
    mov rax, 42        ; Constant substituted!
    pop rbp
    ret
```

---

### Step 8: Test — Const in Expressions

**Test file:** `examples/test_const_expr.syn`
```synapse
const BASE = 100
const OFFSET = 23

fn main() {
    let result = BASE + OFFSET
    return result
}
```

**Expected:**
```bash
.\out.exe
echo %ERRORLEVEL%  # Should print 123
```

---

### Step 9: Test — Multiple Constants

**Test file:** `examples/test_many_consts.syn`
```synapse
const PE_IMAGE_BASE = 4194304
const PE_SECT_ALIGN = 4096
const PE_FILE_ALIGN = 512

fn main() {
    let x = PE_IMAGE_BASE
    let y = PE_SECT_ALIGN
    let z = PE_FILE_ALIGN
    return z  // Returns 512
}
```

---

### Step 10: Bootstrap Test — Self-Hosting with Const

**Critical test:**
1. Add const support to `synapse_full.syn`
2. Compile with Gen 0 (assembly host): `bin\synapse.exe examples\synapse_full.syn`
3. Result: `synapse_new.exe` (Gen 1 with const support)
4. Compile itself: `.\synapse_new.exe examples\synapse_full.syn`
5. Result: `out.exe` (Gen 2)
6. Compare: `fc /b synapse_new.exe out.exe` → **Should be identical!**

**If identical:** ✅ Const feature works and is stable  
**If different:** ❌ Bug in const substitution logic

---

## 🧪 DEBUGGING TIPS

### If constants aren't substituted:
1. Check `add_const()` is called during parsing
2. Print `const_count` after parsing — should be > 0
3. Add debug print in `lookup_const()` to see if it's being called

### If wrong values:
1. Check `str_to_int()` is parsing numbers correctly
2. Verify `set_arr()` / `get_arr()` work for const tables
3. Print value immediately after `lookup_const()`

### If compilation crashes:
1. Const table arrays might be too small (increase from 100 to 200)
2. Memory allocation might overlap with other buffers
3. Check `state[16-18]` aren't used by other code

---

## 📊 SUCCESS CRITERIA

**Phase 71 is complete when:**
1. ✅ Lexer recognizes `const` keyword
2. ✅ Parser stores const definitions in symbol table
3. ✅ Parser substitutes const names with values in expressions
4. ✅ Test: `const X = 42; return X` works
5. ✅ Test: `const A = 10; const B = 20; return A + B` works
6. ✅ Bootstrap test: Gen 1 → Gen 2 → identical binaries
7. ✅ No performance regression (constants are compile-time only)

---

## 🚀 NEXT STEPS (Phase 72)

Once const works, we can:
1. Add const block to `synapse_full.syn`:
```synapse
const PE_IMAGE_BASE = 4194304
const PE_SECT_ALIGN = 4096
const PE_FILE_ALIGN = 512
const RVA_IAT = 266280
// ... 50+ more constants from CONSTANTS.md
```

2. Replace all magic numbers:
```synapse
// Before:
put_qword(state, 4194304)

// After:
put_qword(state, PE_IMAGE_BASE)
```

3. Verify bootstrap still works
4. Commit with message: "Phase 72: Exorcise magic numbers" ✅

---

**Estimated Effort:**
- Step 1-6 (Implementation): 4-6 hours
- Step 7-9 (Testing): 2 hours
- Step 10 (Bootstrap verification): 1 hour
- **Total: 7-9 hours (~1 full day of focused work)**

---

**Ready to begin Phase 71?** 🛠️🚀
