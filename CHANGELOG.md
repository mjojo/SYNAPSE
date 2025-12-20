# SYNAPSE Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version Naming

- **MAJOR.MINOR.PATCH-STAGE**
- Stages: `alpha` → `beta` → `rc` → (release)

---

## [0.3.0-alpha] - 2025-12-20

### Added
- **AVX2 Dot Product** (`<dot>` operator)
  - VMULPS for vertical multiplication
  - VEXTRACTF128 + VHADDPS for horizontal sum (reduction)
  - Full test: `1.0 * 0.5 * 8 = 4.0`
- **AVX2 Tensor Addition** (`<+>` operator)
  - VMOVAPS for aligned load/store
  - VADDPS for 8-wide float addition
  - VZEROUPPER for clean state transition
- **CPU Tier Detection**
  - CPUID + XGETBV for SSE/AVX2/AVX-512
  - Automatic tier selection (1/2/3)
- **Aligned Memory Allocator**
  - 32-byte alignment for AVX2
  - Bump allocator with VirtualAlloc

### Files Added
- `src/cpu_test.asm` - CPU detection (3,072 bytes)
- `src/avx_test.asm` - Tensor add test (3,584 bytes)
- `src/dot_test.asm` - Dot product test (4,096 bytes)

---

## [0.2.0-alpha] - 2025-12-20

### Added
- **JIT Compiler v2** with local variables
  - Stack frame allocation (`sub rsp, N`)
  - Variable storage at `[rbp-offset]`
  - Symbol table for name lookup
- **Arithmetic Expressions**
  - Binary operators: `+`, `-`, `*`
  - Code generation for ADD, SUB, IMUL
- **Recursive Block Parser**
  - Nested `if` statements
  - INDENT/DEDENT depth tracking

### Files Added
- `src/jit_vars.asm` - Variables test (5,632 bytes)
- `src/block_test.asm` - Block recursion test (6,144 bytes)

---

## [0.1.0-alpha] - 2025-12-20

### Added
- **SYNAPSE Lexer v2.0**
  - Python-like indentation (INDENT/DEDENT tokens)
  - New keywords: `fn`, `let`, `mut`, `tensor`, `chain`, `contract`
  - New operators: `->`, `<dot>`, `<+>`, `..`
- **SYNAPSE Parser v2.0**
  - Generic type parsing: `tensor<f32, [784, 128]>`
  - Function declarations: `fn name():`
  - Variable declarations: `let x: int = 10`
- **JIT Compiler v1**
  - Basic code generation
  - VirtualAlloc with PAGE_EXECUTE_READWRITE
  - "The 42 Test" passed

### Files Added
- `include/synapse_tokens.inc` - Token constants
- `include/ast.inc` - AST structures
- `src/lexer_v2.asm` - Indentation lexer
- `src/parser_v2.asm` - Type parser
- `src/jit_test.asm` - Basic JIT test (4,608 bytes)

---

## [0.0.1] - 2025-12-19

### Added
- Initial project structure
- TITAN analysis documentation
- SYNAPSE specification draft
- BNF grammar definition

---

## Upcoming

### [0.4.0-alpha] - Planned
- MATMUL (Matrix Multiplication)
- Full expression parser with operator precedence
- Control flow code generation (if/else → jumps)
- MNIST inference demo

### [0.5.0-beta] - Planned
- Full type system with inference
- Error handling and diagnostics
- Linux support (mmap instead of VirtualAlloc)

### [1.0.0] - Planned
- Production-ready release
- AVX-512 support (Tier 3)
- Blockchain memory contracts
- Standard library
