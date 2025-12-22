# SYNAPSE Changelog

---

## [2.8.0] - 2025-12-22

### 🚀 GUI RELEASE - WINDOWS INTEGRATION!

**SYNAPSE v2.8** breaks free from the console into the world of Windows GUI!

### Added - Phase 28: Graphics & GUI Foundation
- **Multi-DLL Import**: Extended `.idata` section to support multiple DLLs
  - `KERNEL32.DLL` - System calls, file I/O
  - `USER32.DLL` - Windows GUI (NEW!)
- **`msgbox(text, title)`**: Display Windows MessageBox dialog
  - Returns: Button clicked (1 = OK)
  - Uses: MessageBoxA from USER32.DLL

### Technical Achievements
- Proper Import Directory Table structure for multiple DLLs ✅
- Lookup tables and address tables for each DLL ✅
- USER32.DLL successfully loaded and called ✅
- MessageBoxA shows dialog and returns IDOK (1) ✅

### Milestone
**SYNAPSE can now display GUI dialogs!** This is the foundation for creating Windows applications with graphical interfaces. Future phases will add window creation, graphics, and more GUI controls.

---

## [2.7.0] - 2025-12-22

### 🚀 FILE I/O RELEASE - SELF-HOSTING FOUNDATION!

**SYNAPSE v2.7** introduces complete File I/O support, the critical foundation for self-hosting!

### Added - Phase 27: File I/O Intrinsics
- **`fopen(filename, mode)`**: Open files for reading (mode=0) or writing (mode=1)
  - Returns: Valid file handle, or 0 on failure
  - Uses: CreateFileA WinAPI with proper flags
- **`fclose(handle)`**: Close an open file handle
  - Uses: CloseHandle WinAPI
- **`fread(handle, buffer, len)`**: Read bytes from file into buffer
  - Returns: Number of bytes actually read
  - Uses: ReadFile WinAPI
- **`fwrite(handle, buffer, len)`**: Write bytes from buffer to file
  - Returns: Number of bytes actually written
  - Uses: WriteFile WinAPI

### Fixed
- **if-block function calls**: Changed `compile_expr` to `compile_term` in `.if_try_ident`
  - `compile_expr` called `next_token` first, skipping the current identifier
  - `compile_term` processes the current token directly
- **puts stack offset**: Fixed from 56 to 64 bytes
- **puts length bug**: Saved string length in RBX before overwriting RCX

### Technical Achievements  
- Full write/read cycle: Write "hello" to file, read it back ✅
- Proper x64 calling convention for 5-argument WinAPI calls ✅
- Stack alignment maintained through push/sub sequences ✅

### Milestone
**SYNAPSE can now read source files!** This is the first step toward self-hosting - the compiler can read `.syn` files from disk, enabling future phases to implement a complete self-compiling bootstrap.

---

## [2.6.0] - 2025-12-22

### 🚀 VECTOR OPERATIONS RELEASE!

**SYNAPSE v2.6** introduces full Vector Operations support!

### Added - Phase 20: Vector Operations
- **Vector Addition**: `C = A + B` works with arrays in loops
- **Array Read in While**: `let val = arr[i]` inside loops
- **Array Write in While**: `out[i] = value` inside loops  
- **Multi-parameter Functions**: Up to 4+ array parameters
- **Complex Expressions**: `a[i] + b[i]` evaluated correctly

### Fixed
- **Critical Bug**: Fixed `MOV RCX, RAX` opcode in `.while_array_assign`
  - Was: `0xC88948` (MOV RAX, RCX) - WRONG!
  - Now: `0xC18948` (MOV RCX, RAX) - CORRECT!

### Technical Achievements
- Vector sum: `[10,20,30] + [1,2,3] = [11,22,33]` ✅
- Full while loop with array read/write ✅
- 4-parameter function calls with pointers ✅

---

## [2.5.0] - 2025-12-21

### 🧠 MEMORY MANAGER RELEASE!

**SYNAPSE v2.5** introduces Dynamic Memory Allocation and Pointer Arithmetic!

### Added - Phase 19: Memory Manager
- **Intrinsic**: `alloc(size)` — allocates memory on the heap
- **Pointers**: Pass arrays/memory blocks between functions
- **Argument Fix**: Corrected L-to-R stack argument passing order
- **Tests**: `arrays.syn` — verified alloc, write, read, and pass-by-pointer

---

## [2.3.0] - 2025-12-21

### 🧠 EVOLUTION RELEASE!

**SYNAPSE v2.3** features **Deep Neural Networks** and **Darwinian JIT** optimization!

### Added - Phase 6: Control Flow (The Logic)
- **Parser Extension** (Phase 6.1-6.2)
  - `parse_condition()` — comparison operators (==, !=, <, >, <=, >=)
  - `parse_if_statement()` — full if/elif/else chains
  - `parse_while_statement()` — while loops
  - `parse_block()` — recursive block parsing
  - `src/control_flow_test.asm` — 3/3 tests PASSED!

- **JIT Codegen** (Phase 6.3-6.4)
  - `.gen_number` — `MOV RAX, imm64`
  - `.gen_binop` — `CMP`/`SETE`/`MOVZX` for comparisons
  - `.gen_if` — `TEST`/`JZ` with **backpatching**
  - `.gen_while` — **backward JMP** for loops
  - `src/jit_logic_test.asm` — SUCCESS! (IF test)
  - `src/jit_loop_test.asm` — SUCCESS! (WHILE test)

### Technical Achievements
- **Backpatching**: Forward AND backward jumps work correctly
- **Turing-Complete**: Full control flow (if/else/while)
- **Symbol Table**: Mutable variable support (reuse existing offset)
- **Stack Variables**: let/read with ADD and LT operations
- **Real Loops**: `while (i < 5) { alloc(64); i = i + 1 }` — 5 iterations!
- **Function Table**: Register and lookup function JIT addresses
- **CALL/RET**: `fn get_five() { return 5 }` → CALL rel32 + RET
- **Arrays**: `ptr[0] = 42` read/write with pointer arithmetic
- **Perceptron**: `5 * 10 = 50` IMUL instruction for neural math
- **Neural Network**: `[2,3,4] * [10,20,30] = 200` Full Dot Product!
- **Subtraction**: `0 - 50 = -50` SUB instruction
- **ReLU Activation**: `relu(-50)=0, relu(50)=50` Deep Learning ready!
- **Matrix Layer**: `2x2 Dense = [50, 110]` Nested loops + Array Store!
- **All Tests**: Parser + JIT + Neural + ReLU + Matrix (27 total)

---

## [1.0.0-stable] - 2025-12-20

### 🏆 STABLE RELEASE!

**SYNAPSE v1.0** is complete. The world's first compiler-driven blockchain AI platform.

### Added
- **Script Engine** (Phase 5.3) - The Final Pipeline
  - Full compilation: Text → Lexer → Parser → AST → JIT → MOVA
  - `src/script_test.asm` - Complete standalone compiler
  - `src/main.asm` - Official entry point
  - `scripts/genesis.syn` - First SYNAPSE program
- **README.md** - Professional documentation for release
- Integrated Lexer + Parser + JIT + MOVA in single binary

### Technical Achievements
- **Pipeline**: Source code compiles to x64 machine code
- **Size**: ~5.6 KB for complete compiler + runtime
- **Dependencies**: Zero (only kernel32.dll)

---

## [1.0.0-rc] - 2025-12-20

### 🏆 RELEASE CANDIDATE!

All major features are complete. SYNAPSE is ready for production testing.

### Added
- **Auto-Ledger Compiler** (Phase 5.2)
  - `codegen_run()` reads AST nodes
  - NODE_CALL with "alloc" → generates `merkle_alloc()` call
  - NODE_CALL with "commit" → generates `merkle_commit()` call
  - **Result: 3 AST nodes → 3 kernel calls → 1 root hash**
- AST Node Types: NODE_CALL (6), NODE_NUMBER (7)
- JIT Compiler upgraded to v3.0 with codegen

### Files Added
- `src/auto_test.asm` - Auto-Ledger test (4,608 bytes)

---

## [0.9.0-alpha] - 2025-12-20

### Added
- **SYNAPSE ↔ MOVA Bridge** (Phase 5.1)
  - Intrinsics Table for kernel functions
  - JIT calling `merkle_alloc`, `merkle_commit`

---

## [0.8.0-alpha] - 2025-12-20

### Added
- **SYNAPSE CORE** - Grand Unification
  - Neural Network on Blockchain Memory
  - Integrity verification

---

## [0.7.0-alpha] - 2025-12-20

### Added
- **Chain of Trust** (XOR linking)

---

## [0.6.0-alpha] - 2025-12-20

### Added
- **Merkle Ledger Allocator**

---

## [0.5.0-alpha] - 2025-12-20

### Added
- **SHA-256 Crypto Core**

---

## [0.4.0-alpha] - 2025-12-20

### Added
- **Neural Engine** (MNIST)

---

## [0.3.0-alpha] - 2025-12-20

### Added
- AVX2 + CPU Detection

---

## [0.2.0-alpha] - 2025-12-20

### Added
- JIT Compiler with variables

---

## [0.1.0-alpha] - 2025-12-20

### Added
- SYNAPSE Lexer/Parser
- Basic JIT ("The 42 Test")

---

## Achievement Unlocked 🏆

**SYNAPSE v1.0.0-rc** represents:
- 10 major versions in one day
- ~18 KB total binary size
- World's first compiler-driven blockchain AI platform
