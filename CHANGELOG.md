# SYNAPSE Changelog

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
