# SYNAPSE Development Tasks

## 🏆 Current Status: v2.9.0 (Phase 29 Complete)

**Achievement:** Self-Hosting Foundation + File I/O + GUI + Byte Memory!

---

## ✅ COMPLETED PHASES

### Phase 1: Foundation ✅
- [x] Лексер с отступами (`lexer_v2.asm`)
- [x] Парсер типов (`parser_v2.asm`)
- [x] AST структуры (`ast.inc`)
- [x] JIT компилятор базовый

### Phase 2: Adaptive AI Engine ✅
- [x] CPU Detection (SSE/AVX2/AVX-512)
- [x] AVX2 Tensor Engine (VMOVAPS, VADDPS)
- [x] Dot Product (VMULPS, VHADDPS)
- [x] Neural Layer (MATMUL + ReLU float)
- [x] MNIST Inference (784→128→10)
- [x] Biases Support (W*x + b)

### Phase 3: Blockchain Memory ✅
- [x] SHA-256 Crypto Core
- [x] Merkle Tree Allocator
- [x] Chain of Trust (tamper detection)

### Phase 4: Grand Unification ✅
- [x] AVX2 Aligned Ledger (64-byte headers)
- [x] SYNAPSE CORE (neural + blockchain)

### Phase 5: The Bridge ✅
- [x] Intrinsics Table (jump table)
- [x] Auto-Ledger (alloc/commit from AST)

### Phase 6: Control Flow ✅
- [x] Tokens: if, elif, else, while, loop
- [x] AST: NODE_IF=5, NODE_WHILE=9, NODE_BLOCK=16
- [x] Operators: ==, !=, <, >, <=, >=
- [x] Parser: parse_if, parse_while, parse_block
- [x] JIT IF: TEST/JZ + backpatching
- [x] JIT WHILE: JMP backward loop
- [x] Tests: `control_flow_test.asm`, `jit_if_test.asm`, `jit_while_test.asm`

### Phase 7: Variables ✅
- [x] Symbol Table (`symbols.asm`)
- [x] sym_init, sym_add, sym_find
- [x] NODE_LET (stack write)
- [x] NODE_VAR (stack read)
- [x] NODE_OP_ADD, NODE_OP_LT
- [x] Real loop: `while (i < 5) { i = i + 1 }`
- [x] Tests: `sym_test.asm`, `jit_let_test.asm`, `jit_read_test.asm`, `loop_real_test.asm`
- [x] **TURING-COMPLETE!**

### Phase 8: Functions ✅
- [x] Function Table (`functions.asm`)
- [x] func_init, func_add, func_find
- [x] NODE_FUNC_DEF, NODE_FUNC_RET, NODE_CALL_USER
- [x] JIT: CALL rel32, RET
- [x] Tests: `func_table_test.asm`, `jit_func_test.asm`

### Phase 9: Arrays ✅
- [x] Tokens: SOP_LBRACKET, SOP_RBRACKET
- [x] NODE_ARRAY_GET, NODE_ARRAY_SET
- [x] JIT: ptr[index] read/write
- [x] Tests: `array_lex_test.asm`, `jit_array_test.asm`

### Phase 10: Perceptron ✅
- [x] NODE_OP_MUL (IMUL instruction)
- [x] JIT: 5 * 10 = 50
- [x] Tests: `perceptron_test.asm`

### Phase 11: Neural Network ✅
- [x] Dynamic array access arr[i]
- [x] JIT `.gen_array_get`: SHL + ADD + MOV [RAX]
- [x] Dot Product loop: sum += inputs[i] * weights[i]
- [x] **[2,3,4] * [10,20,30] = 200**
- [x] Tests: `full_neural_test.asm`
- [x] **THE NEURON IS ALIVE!**

### Phase 12: ReLU Activation ✅
- [x] NODE_OP_SUB (SUB instruction)
- [x] JIT: 0 - 50 = -50
- [x] ReLU: if (x < 0) x = 0
- [x] Tests: `relu_test.asm`
- [x] **relu(-50)=0, relu(50)=50**

### Phase 13: Matrix Layer ✅
- [x] Nested loops (while inside while)
- [x] Array Store (out[n] = sum)
- [x] Complex index (w[n*2 + k])
- [x] Tests: `layer_test.asm`
- [x] **2 neurons x 2 inputs = [50, 110]**

### Phase 19: Memory Manager (Alloc & Pointers) ✅
- [x] Intrinsic `alloc(size)`
- [x] Pointer passing between functions
- [x] Argument order fix (L-to-R stack)
- [x] Tests: `arrays.syn`
- [x] **100 + 101 + 102 = 303**

### Phase 20: Vector Operations ✅
- [x] `vec_add(a, b, out, len)` - full vector addition
- [x] Array read in while: `let val = arr[i]`
- [x] Array write in while: `out[i] = sum`
- [x] Fixed MOV RCX, RAX opcode bug (0xC88948 → 0xC18948)
- [x] Tests: `vectors_debug.syn`
- [x] **[10,20,30] + [1,2,3] = [11,22,33]**

### Phase 27: File I/O ✅
- [x] `fopen(filename, mode)` - open files (read=0, write=1)
- [x] `fclose(handle)` - close file handle
- [x] `fread(handle, buffer, len)` - read bytes from file
- [x] `fwrite(handle, buffer, len)` - write bytes to file
- [x] Tests: `test_fread.syn`
- [x] **Read source files from disk!**

### Phase 28: GUI Foundation ✅
- [x] Multi-DLL Import (KERNEL32 + USER32)
- [x] `msgbox(text, title)` - Windows MessageBox
- [x] Tests: `msgbox_test.ttn`
- [x] **Windows GUI dialogs!**

### Phase 29: Self-Hosting Lexer ✅
- [x] `alloc_bytes(size)` - byte-addressable allocation
- [x] `get_byte(ptr, idx)` - read single byte
- [x] `set_byte(ptr, idx, val)` - write single byte
- [x] `self_lexer_final.syn` - lexer written in SYNAPSE!
- [x] Tokenizes: IDENT, DIGIT, LPAREN, RPAREN
- [x] "Full Hoist Pattern" discovered
- [x] **SELF-HOSTING FOUNDATION COMPLETE!**

### Phase 35: JIT Stabilization (Operation Spinal Cord) ✅
- [x] **Win64 ABI Compliance** (Shadow Space, Stack Alignment)
- [x] **Recursive Functions** (Stabilized Frame Pointers)
- [x] **Register Argument Passing** (RCX, RDX, R8, R9)
- [x] **Expression & Statement Calls** Fixed
- [x] **Forward Parameter Registration** Fixed
- [x] Updated Intrinsics (`print`, `alloc`, `fopen`, etc.)
- [x] Tests: `fib_crash_test.syn` (Recursive Fibonacci)
- [x] **JIT IS NOW STABLE ON WINDOWS x64!**

### Phase 36: The Cortex (Scope Isolation) ✅
- [x] **Variable Shadowing** (Inner `let x` doesn't overwrite outer `x`)
- [x] **Scope Push/Pop** in `compile_if`
- [x] **Backwards Symbol Search** (Finds newest definition first)
- [x] **Always-Add Semantics** in `sym_add`
- [x] Tests: `scope_shadow.syn`
- [x] **LOCAL VARIABLE SCOPING COMPLETE!**

### Phase 37: The Scribe (Strings & Text) ✅
- [x] **String Literals** (`"Hello World"` → pointer in RAX)
- [x] **String Pooling** (lexer stores in `string_table`)
- [x] **`puts(str)`** intrinsic (outputs null-terminated strings)
- [x] Tests: `hello_world.syn`
- [x] **SYNAPSE CAN SPEAK!**

### Phase 38: The Elegant Ouroboros (Clean Self-Hosting) ✅
- [x] **String Literals in Compiler** (`let src = "fn main { return 123 }"`)
- [x] **Pointer-Based Lexing** (`get_byte(src, i)` with `strlen()`)
- [x] **Guarded-If Pattern** (simulates else-if chains)
- [x] **Local Array Workaround** (functions receive arrays as params)
- [x] Tests: `self_compile_v3.syn`
- [x] **Output**: `85 72 137 229 72 184 123 0 0 0 0 0 0 0 93 195` (Valid x64!)
- [x] **ELEGANT SELF-HOSTING COMPLETE!**

### Phase 39: The Keystone (JIT Opcode Fixes) ✅
- [x] **Fixed 6 x64 opcode byte order issues** (dword writes inverted bytes)
  - `.arr_gen_global`: MOV RDX, [RDX]
  - `.arr_gen_store`: MOV [RDX+RCX*8], RAX
  - `.arr_get_global`: MOV RDX, [RDX]
  - `.arr_get_load`: MOV RAX, [RDX+RCX*8]
  - `.try_global`: MOV RAX, [RCX]
  - `.var_not_found`: MOV RAX, [RCX]
- [x] **LOCAL ARRAYS NOW WORK PERFECTLY!**
- [ ] Global arrays (file scope) still broken (different symbol table issue)
- [x] Tests: `test_local_arr.syn` ✅

### Phase 40: The Recursive Mind ✅
- [x] **Context Passing Pattern** verified working
- [x] **10 functions** all compile and run correctly
- [x] Tests: `self_parser_v4.syn` ✅
- [x] AST Output: `NODE_ADD(NODE_NUM 10, NODE_NUM 5)`

### Phase 41: Infrastructure Scaling ✅
- [x] **Symbol tables**: 64 → 256 entries (8192 bytes each)
- [x] **Function table**: 64 → 256 entries (8192 bytes)
- [x] **JIT buffer**: 64KB → 256KB
- [x] Build size: 21KB → 35KB

### Phase 41.5: Debug Traceback ✅
- [x] Added `[JIT] Compiling fn: <name>` debug output
- [x] Identified root cause: `!=` operator not implemented
- [x] Workaround: Use `==` with inverted logic

### Phase 42: Recursive CodeGen (Stack Machine) ✅
- [x] **15 functions** compiled successfully
- [x] Recursive descent parser with operator precedence
- [x] Stack machine code generator
- [x] Expression `10 + 2 * 5` → correct x64 opcodes:
  - `48 B8 0A...` MOV RAX, 10
  - `50` PUSH RAX
  - `48 B8 02...` MOV RAX, 2 → multiply → `48 0F AF C1` IMUL
  - `48 01 C8` ADD RAX, RCX
- [x] Tests: `self_compile_v4.syn` ✅

---

## 🔮 FUTURE PHASES

### Pending Features
- [x] **Implement OP_NE (!=) in compile_expr** ✅ (Phase 42.5)
- [x] **Implement matmul with correct 6-arg stack handling** ✅

### Phase 43: The Power Unlock (AI/Crypto Intrinsics) ✅
- [x] Added `str_matmul`, `str_relu`, `str_sha256` string names
- [x] Registered intrinsics in `init_intrinsics`
- [x] **intrinsic_relu WORKS!** (RCX=ptr, RDX=size)
- [x] **intrinsic_matmul WORKS!** (Corrected 6-arg calling convention)
- [x] **intrinsic_sha256** (placeholder ready)
- [x] Verified with `power_test.syn`:
  - MatMul: `[10, 20, 30, 40]` (Identity * Values)
  - ReLU: `-55` -> `0`

---


---

## 🔮 FUTURE PHASES

### Phase 30: Self-Hosting Parser (v3.0)
- [ ] Parse tokens into AST
- [ ] Handle expressions
- [ ] Build syntax tree

### Phase 31: Self-Hosting Codegen (v3.1)
- [ ] Generate x64 from AST
- [ ] JIT compilation in SYNAPSE
- [ ] **Bootstrap: compile synapse.exe with itself!**

### Phase 32: Dot Product (v3.2)
- [ ] `dot_product(a, b, len)` returning scalar
- [ ] Neural Network forward pass

### Phase 33: Training (v4.0)
- [ ] Gradient calculation
- [ ] Backpropagation
- [ ] Weight updates

### Phase 34: Expression Parser
- [ ] Arithmetic expressions (a + b * c)
- [ ] Operator precedence (Pratt parsing)
- [ ] Unary operators (-x, not x)
- [ ] Parentheses

### Phase 35: Type System
- [ ] int, f32, f64, bool, string
- [ ] Type checking in parser
- [ ] Implicit conversions

### Phase 36: Structures
- [ ] struct definitions
- [ ] Field access (obj.field)
- [ ] Memory alignment

### Phase 37: Platform Abstraction
- [ ] sys_interface.asm for Linux
- [ ] Abstract VirtualAlloc/mmap
- [ ] Cross-platform file I/O

---

## 📊 Test Summary

| Test File | Phase | Result |
|-----------|-------|--------|
| `lexer_test.asm` | 1 | ✅ |
| `parser_test.asm` | 1 | ✅ |
| `jit_test.asm` | 1 | ✅ 42! |
| `cpu_test.asm` | 2 | ✅ AVX2 |
| `avx2_test.asm` | 2 | ✅ 3.0 |
| `dot_test.asm` | 2 | ✅ 4.0 |
| `matmul_test.asm` | 2 | ✅ ReLU |
| `crypto_test.asm` | 3 | ✅ SHA256 |
| `merkle_test.asm` | 3 | ✅ Tamper |
| `synapse_core.asm` | 4 | ✅ Integrity |
| `bridge_test.asm` | 5 | ✅ Intrinsics |
| `auto_test.asm` | 5 | ✅ 3 nodes |
| `control_flow_test.asm` | 6 | ✅ 3/3 |
| `jit_if_test.asm` | 6 | ✅ |
| `jit_while_test.asm` | 6 | ✅ |
| `sym_test.asm` | 7 | ✅ 6/6 |
| `jit_let_test.asm` | 7 | ✅ 777 |
| `jit_read_test.asm` | 7 | ✅ x→y |
| `loop_real_test.asm` | 7 | ✅ 5 iters |
| `func_table_test.asm` | 8 | ✅ 3 funcs |
| `jit_func_test.asm` | 8 | ✅ get_five=5 |
| `array_lex_test.asm` | 9 | ✅ [] |
| `jit_array_test.asm` | 9 | ✅ ptr[0]=42 |
| `perceptron_test.asm` | 10 | ✅ 5*10=50 |
| `full_neural_test.asm` | 11 | ✅ **200** |
| `relu_test.asm` | 12 | ✅ ReLU |
| `layer_test.asm` | 13 | ✅ **[50, 110]** |
| `arrays.syn` | 19 | ✅ **303** |
| `test_fread.syn` | 27 | ✅ File I/O |
| `msgbox_test.ttn` | 28 | ✅ GUI |
| `self_lexer_final.syn` | 29 | ✅ **Self-Lexer!** |
| `fib_crash_test.syn` | 35 | ✅ **Recursion!** |

**Total: 32 tests PASSED**

---

## 📂 Key Files

```
include/
├── synapse_tokens.inc   # Token constants
├── ast.inc              # AST node types (37 nodes)
└── version.inc          # v2.9.0-selfhost

src/
├── lexer_v2.asm         # Indentation lexer
├── parser_v2.asm        # Type/control flow parser
├── codegen.asm          # JIT code generator
├── symbols.asm          # Symbol table
├── functions.asm        # Function table
├── memory.asm           # MOVA allocator
├── io.asm               # Console I/O + File I/O
├── intrinsics.asm       # Intrinsics table
├── cpu.asm              # CPU detection
├── crypto.asm           # SHA-256
└── merkle.asm           # Blockchain memory

examples/
├── self_lexer_final.syn # Self-hosted lexer (Phase 29)
├── test_fread.syn       # File I/O test
└── ...                  # Various test files
```

---

*Last updated: 2025-12-24 v2.9.0*
