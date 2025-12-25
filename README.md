# SYNAPSE Language & MOVA Engine

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0--singularity-gold)
![Size](https://img.shields.io/badge/binary-18kb-blue)
![Arch](https://img.shields.io/badge/arch-x64_AVX2-red)
![License](https://img.shields.io/badge/license-MIT-yellow)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)

# 🎆 SYNAPSE v1.0
**The Singularity Release**

*"The Language where `malloc` is a Transaction"*

**🏆 Self-Hosting • Blockchain Memory • Bare Metal AI • Stack JIT 🏆**

</div>

---

## 💡 What is SYNAPSE?

**SYNAPSE** is an experimental compiled programming language built from scratch in pure x86-64 Assembly (FASM).

At its core lies the **MOVA Engine** (Memory Of Verifiable Authorization) — a kernel that unifies neural network computation with cryptographic memory protection.

> *"Memory is not a scratchpad. It's a Blockchain."*

In a world where "Hello World" in Electron weighs 100 MB, we created an **AI-Blockchain Language in ~6 KB**.

---

## 🌌 The Singularity Example

Before you read the features, look at the code. This script proves that memory allocation impacts the cryptographic state of the machine.

```rust
// singularity.syn
fn main() {
    print(888888) // == START SINGULARITY ==

    // 1. Snapshot State (Genesis)
    let hash = alloc(4)
    chain_hash(hash)
    print_hex(hash, 32)
    
    // 2. Initialize AI (Allocates memory -> Changes Hash)
    let inputs = alloc(4)
    let weights = alloc(16)
    
    // 3. Verify Memory State Changed
    chain_hash(hash)
    print_hex(hash, 32) // Hash CHANGED! 
    
    // 4. Run AI (Metal + Neural)
    matmul(inputs, weights, inputs, 1, 4, 4)
    relu(inputs, 4)
}
```

**Output:**
```
> 888888
3F C9 BC 92 ... (Genesis Hash)
C0 36 43 6D ... (Post-Alloc Hash - CHANGED!)
> 111111        (AI Result)
```

---

## 🚀 Key Features

### 1. The Tri-Core Engine

| Core | Function |
|---|---|
| **Metal Core** | Recursive Descent Parser + Stack Machine JIT (x64) |
| **Neural Core** | AVX2-accelerated MatMul + ReLU Intrinsics |
| **Ledger Core** | Merkle Heap Allocator (Memory as Blockchain) |

### 2. Unhackable Memory (MOVA)

| Feature | Description |
|---|---|
| **Merkle Heap** | All memory is a cryptographic ledger |
| **Chain of Trust** | Changing ANY byte instantly changes the global `Root Hash` |
| **Tamper-Evident** | Neural weights tampering is impossible without detection |

### 3. Bare Metal AI

| Feature | Description |
|---|---|
| **AVX2 Native** | Matrix ops and ReLU compiled to optimal machine code |
| **No Dependencies** | No Python, TensorFlow, or CUDA. Just CPU |
| **Tiny Footprint** | Entire compiler + runtime = **~18 KB** |

### 4. Stack Machine JIT

| Feature | Description |
|---|---|
| **Text → x64** | Full compilation pipeline: Lexer -> Parser -> AST -> CodeGen |
| **Recursive** | Handles nested blocks, expressions, and logic (`10+2*5`) |
| **Intrinsics** | Direct mapping to Assembly: `matmul`, `relu`, `sha256` |
| **Self-Hosting** | The compiler is written in SYNAPSE itself (`self_parser_v4.syn`) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│              SYNAPSE LANGUAGE                   │
│          source.syn → Lexer → Parser            │
├─────────────────────────────────────────────────┤
│              JIT COMPILER v3.0                  │
│            AST → x64 Machine Code               │
├─────────────────────────────────────────────────┤
│             INTRINSICS BRIDGE                   │
│     alloc() → merkle_alloc()                    │
│     commit() → merkle_commit()                  │
│     sha256() → sha256_compute()                 │
├─────────────────────────────────────────────────┤
│               MOVA ENGINE                       │
│   Blockchain Memory │ SHA-256 │ Neural AVX2    │
└─────────────────────────────────────────────────┘
```

**Pipeline:**

```
Source Code → Lexer → Tokens → Parser → AST → JIT → x64 → MOVA → Blockchain
```

---

## ⚡ Syntax Example

### Genesis Script (`scripts/genesis.syn`)

```synapse
// SYNAPSE GENESIS BLOCK
// The first script executed on MOVA Engine

// 1. Allocate Neural Weights (Input Layer)
// Creates Block #1 in the Merkle Tree
alloc(784)

// 2. Allocate Hidden Layer  
// Creates Block #2, cryptographically linked to #1
alloc(128)

// 3. Seal the Chain
// Computes Global Root Hash ensuring integrity
commit()
```

### Output

```
==================================================
  SYNAPSE v1.0 - The Script Engine
  Phase 5.3: From Text to Blockchain
==================================================

[SRC] Source Code:
--------------------------------------------------
alloc(784)
alloc(128)
commit()
--------------------------------------------------
[LEX] Tokenizing...
  Token: IDENT alloc
  Token: OP (
  Token: NUMBER 784
  ...
[PRS] Parsing to AST...
  Node: CALL alloc(784)
  Node: CALL alloc(128)
  Node: CALL commit()
[JIT] Compiling to x64...
[RUN] Executing...
--------------------------------------------------
[DONE] Execution complete!
  Root Hash: a7f3b2c1...8e4d9f0a

*** SUCCESS! From Text to Blockchain! ***
```

---

## 🛠️ Build Instructions

### Requirements

- **FASM** (Flat Assembler) for Windows
- Windows x64

### Build

```batch
# Build the script engine
fasm src/script_test.asm bin/synapse.exe

# Run
bin/synapse.exe
```

### Binary Sizes

| Component | Size |
|-----------|------|
| synapse.exe (script engine) | 5,632 bytes |
| synapse_core.exe (full AI) | 5,632 bytes |
| auto_test.exe | 4,608 bytes |
| **Total Runtime** | **~18 KB** |

---

## 📁 Project Structure

```
SYNAPSE/
├── bin/                    # Compiled executables
├── include/                # Header files
│   ├── ast.inc            # AST node definitions
│   ├── synapse_tokens.inc # Token constants
│   └── constants.inc      # System constants
├── src/                    # Source code
│   ├── script_test.asm    # Main entry (Text→Blockchain)
│   ├── synapse_core.asm   # Full AI + Blockchain
│   ├── auto_test.asm      # Auto-Ledger test
│   ├── lexer_v2.asm       # Tokenizer
│   ├── parser_v2.asm      # Parser
│   ├── mnist_infer.asm    # MNIST neural network
│   ├── crypto_test.asm    # SHA-256 implementation
│   └── merkle_test.asm    # Blockchain memory
├── scripts/                # Example scripts
│   └── genesis.syn        # First SYNAPSE program
├── neural/                 # Neural network weights
│   ├── w1.bin, w2.bin     # Layer weights
│   └── b1.bin, b2.bin     # Layer biases
├── docs/                   # Documentation
│   ├── SYNAPSE_SPEC.md    # Language specification
│   └── grammar.md         # Formal grammar
├── README.md
├── CHANGELOG.md
└── TASKS.md
```

---

## 🏆 Development History

| Phase | Name | Achievement |
|-------|------|-------------|
| **1** | The Tongue | Lexer + Parser (Text Analysis) |
| **2** | The Brain | Neural Engine (AVX2 MNIST) |
| **3** | The Memory | Blockchain Memory (SHA-256 Merkle) |
| **4** | Unification | Neural Network on Blockchain |
| **5** | The Bridge | Self-Compiling Script Engine |
| **6** | Control Flow | if/else/while + JIT Backpatching |
| **7** | Variables | let/read + real loops (i < 5) |
| **8** | Functions | fn/return + CALL/RET |
| **9** | Arrays | ptr[0] = 42 + pointer access |
| **10** | Perceptron | IMUL: 5 * 10 = 50 |
| **11** | Neural Network | Dot Product = 200 |
| **12** | ReLU Activation | relu(-50)=0, relu(50)=50 |
| **13** | Matrix Layer | 2 neurons x 2 inputs = [50, 110] |
| **19** | Memory Manager | alloc(size) + Pointers |
| **20** | Vector Operations | C = A + B array math! |
| **27** | File I/O | fopen/fread/fwrite/fclose |
| **28** | GUI Foundation | msgbox() Windows dialogs |
| **29** | **Self-Hosting** | **Lexer written in SYNAPSE!** |

**29 major phases. Self-Hosting Bootstrap begun!**

---

## 🔮 Roadmap: v3.0

- [ ] GPU Support (CUDA/OpenCL)
- [ ] P2P Networking (Distributed Ledger)
- [ ] Smart Contracts
- [ ] WASM Compilation Target
- [ ] Linux Support

---

## 📊 Technical Specifications

| Specification | Value |
|---------------|-------|
| **Language** | SYNAPSE v2.9 |
| **Engine** | MOVA v1.0 |
| **Architecture** | x64 JIT Compiler |
| **Control Flow** | if/else/while (Backpatching) |
| **Variables** | let/var + ADD/LT operations |
| **Functions** | fn/return + CALL/RET |
| **Arrays** | ptr[index] read/write |
| **Memory** | Dynamic Alloc + Pointers |
| **Bytes** | alloc_bytes/get_byte/set_byte |
| **Vectors** | C = A + B array operations |
| **File I/O** | fopen/fread/fwrite/fclose |
| **GUI** | msgbox() Windows dialogs |
| **Math** | IMUL for neural calculations |
| **Neural** | Dot Product = 200 |
| **Activation** | ReLU (max(0,x)) |
| **Matrix** | Dense Layer (2x2) |
| **SIMD** | AVX2/FMA |
| **Crypto** | SHA-256 (native) |
| **Self-Hosting** | Lexer in SYNAPSE! |
| **Dependencies** | 0 (only kernel32.dll, user32.dll) |
| **Binary Size** | ~8 KB |
| **Memory Model** | Merkle Heap + Stack Frame |

---

## 📜 License

MIT License

---

## 👥 Authors

- **mjojo (Vitaly.G)** — Architecture, Assembly
- **Claude (Anthropic)** — AI Assistant, Documentation

---

<div align="center">

# 🧠 SYNAPSE v2.9

**🏆 Self-Hosting + File I/O + GUI + Deep Learning! 🏆**

*~8 KB of Pure x86-64 Assembly*

---

*"From Text to Blockchain. From Compiler to Self-Compiler."*

</div>
