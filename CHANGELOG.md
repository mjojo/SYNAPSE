# SYNAPSE Changelog

All notable changes to this project will be documented in this file.

---

## [0.7.0-alpha] - 2025-12-20

### Added
- **Chain of Trust** (XOR Crypto-Linking)
  - Two-pass algorithm in `merkle_commit()`
  - Pass 1: Compute SHA-256 for each block's data
  - Pass 2: XOR all block hashes into global Root Hash
  - **Chain Reaction**: Changing ANY block changes the global hash!
  - Test: "Hello" → "Hxllo" invalidated ENTIRE blockchain state

### Changed
- `merkle_commit()` now returns global Root Hash instead of last block hash
- Banner updated to "Chain of Trust - Phase 3.3"

---

## [0.6.0-alpha] - 2025-12-20

### Added
- **Merkle Ledger Allocator** (Blockchain Memory)
  - Block headers: MAGIC + SIZE + PREV_PTR + HASH (48 bytes)
  - `merkle_alloc()` — allocates blocks with headers
  - `merkle_commit()` — computes SHA-256 for all blocks
  - Tamper detection: modifying data changes the hash

### Files Added
- `src/merkle_test.asm` - Blockchain memory test (4,096 bytes)

---

## [0.5.0-alpha] - 2025-12-20

### Added
- **SHA-256 Crypto Core** (pure assembly)
  - K constants (64 dwords)
  - Message schedule W[0..63]
  - 64 compression rounds
  - Verified: SHA256("abc") = ba7816bf...f20015ad

### Files Added
- `src/crypto_test.asm` - SHA-256 test

---

## [0.4.0-alpha] - 2025-12-20

### Added
- **Neural Engine** (MATMUL + ReLU)
  - Loop generator for neurons
  - ReLU activation
- **MNIST Inference**
  - 784 → 128 → 10 network
  - File I/O for weights
  - Biases support

### Files Added
- `src/matmul_test.asm`
- `src/mnist_infer.asm`

---

## [0.3.0-alpha] - 2025-12-20

### Added
- **AVX2 Operations**
  - Dot product with VMULPS + VHADDPS
  - Tensor addition with VADDPS
- **CPU Tier Detection**
  - CPUID + XGETBV
- **Aligned Memory Allocator**

### Files Added
- `src/cpu_test.asm`
- `src/avx_test.asm`
- `src/dot_test.asm`

---

## [0.2.0-alpha] - 2025-12-20

### Added
- **JIT Compiler v2** with local variables
- **Arithmetic Expressions**
- **Block Parser**

---

## [0.1.0-alpha] - 2025-12-20

### Added
- **SYNAPSE Lexer v2.0** (INDENT/DEDENT)
- **SYNAPSE Parser v2.0** (generics)
- **JIT Compiler v1** ("The 42 Test")

---

## Upcoming

### [0.8.0-alpha] - Planned
- Smart contract primitives
- World state management

### [1.0.0] - Planned
- Production-ready release
- AVX-512 support
- Linux support
