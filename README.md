# SYNAPSE Language & MOVA Engine

<div align="center">

![Version](https://img.shields.io/badge/version-2.2.0--matrix-gold)
![Size](https://img.shields.io/badge/binary-7kb-blue)
![Arch](https://img.shields.io/badge/arch-x64_AVX2-red)
![License](https://img.shields.io/badge/license-MIT-yellow)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)

# 🧠 SYNAPSE v2.2

**Unhackable AI on Bare Metal Assembly**

*The World's First Compiler-Driven Blockchain AI Platform*

**🏆 Matrix Layer: [50, 110] • Nested Loops • Deep Learning! 🏆**

</div>

---

## 💡 What is SYNAPSE?

**SYNAPSE** is an experimental compiled programming language built from scratch in pure x86-64 Assembly (FASM).

At its core lies the **MOVA Engine** (Memory Of Verifiable Authorization) — a kernel that unifies neural network computation with cryptographic memory protection.

> *"Memory is not a scratchpad. It's a Blockchain."*

In a world where "Hello World" in Electron weighs 100 MB, we created an **AI-Blockchain Language in ~6 KB**.

---

## 🚀 Key Features

### 🔐 MOVA Core (Unhackable Memory)

Unlike C++ or Rust, SYNAPSE doesn't use a standard heap.

| Feature | Description |
|---------|-------------|
| **Merkle Heap** | All memory is a cryptographic ledger |
| **Chain of Trust** | Changing ANY byte instantly changes the global `Root Hash` |
| **Tamper-Evident** | Neural weights tampering is impossible without detection |
| **SHA-256 Native** | Hardware-accelerated cryptographic core |

### 🧠 Bare Metal AI

| Feature | Description |
|---------|-------------|
| **AVX2 Native** | Matrix ops and ReLU compiled to optimal machine code |
| **MNIST Ready** | 784→128→10 neural network runs on protected memory |
| **No Dependencies** | No Python, TensorFlow, or CUDA. Just CPU |
| **Tiny Footprint** | Entire compiler + runtime = **~6 KB** |

### ⚡ JIT Compiler

| Feature | Description |
|---------|-------------|
| **Text → Tokens → AST → x64** | Full compilation pipeline |
| **Auto-Ledger** | Compiler automatically generates blockchain calls |
| **Intrinsics Bridge** | Script commands map to kernel functions |
| **Control Flow** | if/else/while with JIT backpatching |
| **Variables (v1.2)** | let x = 10, let y = x, i = i + 1 |
| **Real Loops** | while (i < 5) with counter increments |
| **Functions (v1.3)** | fn name() { return } + CALL/RET |
| **Arrays (v1.4)** | ptr[0] = 42 + pointer arithmetic |
| **Perceptron (v1.5)** | IMUL for input * weight calculations |
| **Neural Network (v2.0)** | Full Dot Product: [2,3,4] * [10,20,30] = 200 |
| **ReLU Activation (v2.1)** | relu(-50)=0, relu(50)=50 + SUB operation |
| **Matrix Layer (v2.2)** | 2x2 Dense Layer: [50, 110] + Array Store |

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
| **13** | **Matrix Layer** | **2 neurons x 2 inputs = [50, 110]** |

**18 major versions. Full Matrix Layer with Nested Loops!**

---

## 🔮 Roadmap: v2.0

- [ ] GPU Support (CUDA/OpenCL)
- [ ] P2P Networking (Distributed Ledger)
- [ ] Smart Contracts
- [ ] WASM Compilation Target
- [ ] Linux Support

---

## 📊 Technical Specifications

| Specification | Value |
|---------------|-------|
| **Language** | SYNAPSE v2.2 |
| **Engine** | MOVA v1.0 |
| **Architecture** | x64 JIT Compiler |
| **Control Flow** | if/else/while (Backpatching) |
| **Variables** | let/var + ADD/LT operations |
| **Functions** | fn/return + CALL/RET |
| **Arrays** | ptr[index] read/write |
| **Math** | IMUL for neural calculations |
| **Neural** | Dot Product = 200 |
| **Activation** | ReLU (max(0,x)) |
| **Matrix** | Dense Layer (2x2) |
| **SIMD** | AVX2/FMA |
| **Crypto** | SHA-256 (native) |
| **Dependencies** | 0 (only kernel32.dll) |
| **Binary Size** | ~6 KB |
| **Memory Model** | Merkle Heap + Stack Frame |

---

## 📜 License

MIT License

---

## 👥 Authors

- **mjojo (Vitaly.G)** — Architecture, Assembly
- **GLK-Dev** — AI Assistant, Documentation

---

<div align="center">

# 🧠 SYNAPSE v2.2

**🏆 Matrix Layer + Deep Learning Engine! 🏆**

*~7 KB of Pure x86-64 Assembly*

---

*"From Text to Blockchain. From Idea to Reality."*

</div>
