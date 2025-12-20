# SYNAPSE Changelog

---

## [0.8.0-alpha] - 2025-12-20

### Added
- **SYNAPSE CORE** - Grand Unification (Phase 4)
  - Neural Network running on Blockchain Memory!
  - All weights allocated via `merkle_alloc()`
  - Integrity verification before and after inference
  - **Hashes match = data was not tampered!**
- **AVX2 Aligned Headers**
  - BLOCK_HEADER_SIZE changed from 48 to 64 bytes
  - Guarantees 32-byte alignment for AVX2 operations
  - Added 16-byte padding (48-63)

### Files Added
- `src/synapse_core.asm` - The Unhackable AI (5,632 bytes)

### Changed
- `merkle_test.asm` - Updated to 64-byte aligned headers

---

## [0.7.0-alpha] - 2025-12-20

### Added
- **Chain of Trust** (XOR Crypto-Linking)
  - Two-pass algorithm: Hash then XOR
  - Global Root Hash = XOR of all block hashes
  - Chain Reaction: changing ANY block changes global hash

---

## [0.6.0-alpha] - 2025-12-20

### Added
- **Merkle Ledger Allocator**
  - Block headers: MAGIC + SIZE + PREV_PTR + HASH
  - Tamper detection via SHA-256

---

## [0.5.0-alpha] - 2025-12-20

### Added
- **SHA-256 Crypto Core**
  - Pure assembly implementation
  - Verified: SHA256("abc") = ba7816bf...

---

## [0.4.0-alpha] - 2025-12-20

### Added
- **Neural Engine** (MNIST Inference)
  - 784 → 128 → 10 architecture
  - AVX2 FMA operations

---

## [0.3.0-alpha] - 2025-12-20

### Added
- AVX2 Dot Product
- CPU Tier Detection
- Aligned Memory Allocator

---

## [0.2.0-alpha] - 2025-12-20

### Added
- JIT Compiler with variables
- Block Parser

---

## [0.1.0-alpha] - 2025-12-20

### Added
- SYNAPSE Lexer (INDENT/DEDENT)
- SYNAPSE Parser (generics)
- Basic JIT ("The 42 Test")

---

## Upcoming

### [0.9.0-alpha] - Planned
- Smart Contracts
- JIT optimization

### [1.0.0] - Planned
- Production release
- Linux support
