# SYNAPSE Changelog

---

## [0.9.0-alpha] - 2025-12-20

### Added
- **SYNAPSE ↔ MOVA Bridge** (Phase 5.1)
  - Intrinsics Table: Jump table for kernel functions
  - `init_intrinsics()` — populates table with function pointers
  - JIT can now call: `merkle_alloc`, `merkle_commit`, `sha256_compute`
  - Generated code invokes MOVA Engine directly!
- JIT Compiler upgraded to v3.0

### Files Added
- `src/bridge_test.asm` - Bridge verification test (4,096 bytes)

---

## [0.8.0-alpha] - 2025-12-20

### Added
- **SYNAPSE CORE** - Grand Unification
  - Neural Network on Blockchain Memory
  - Integrity verification (hashes match!)
- AVX2 Aligned Headers (64 bytes)

---

## [0.7.0-alpha] - 2025-12-20

### Added
- **Chain of Trust** (XOR Crypto-Linking)
  - Global Root Hash

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
- AVX2 Operations
- CPU Detection

---

## [0.2.0-alpha] - 2025-12-20

### Added
- JIT Compiler with variables

---

## [0.1.0-alpha] - 2025-12-20

### Added
- SYNAPSE Lexer/Parser
- Basic JIT

---

## Upcoming

### [1.0.0] - Planned
- Full language integration
- Production release
