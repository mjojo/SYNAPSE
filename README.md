# SYNAPSE Language

<div align="center">

![Version](https://img.shields.io/badge/Version-0.9.0--alpha-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-Windows%20x64-green)
![Assembler](https://img.shields.io/badge/Built%20with-FASM-red)

**The Bridge is Complete: SYNAPSE Language ↔ MOVA Engine**

[Features](#-features) • [Architecture](#-architecture) • [Quick Start](#-quick-start) • [Roadmap](#-roadmap)

</div>

---

## 📋 Version

| Component | Version | Status |
|-----------|---------|--------|
| **SYNAPSE Core** | `0.9.0-alpha` | 🔄 Active |
| Lexer/Parser | `2.0` | ✅ Stable |
| JIT Compiler | `3.0` | ✅ **Bridged!** |
| MOVA Engine | `1.0` | ✅ Stable |
| Neural Engine | `2.0` | ✅ Stable |
| Crypto Core | `1.0` | ✅ Stable |

---

## ⚡ Features

### 🌉 The Bridge (Phase 5.1)

SYNAPSE JIT compiler can now invoke MOVA Engine functions:

```
==================================================
  SYNAPSE -> MOVA Bridge Test (Phase 5.1)
  JIT Compiler Calling Kernel Functions
==================================================

[BRIDGE] Building intrinsics table...
[JIT] Generating bridge code...
[JIT] Executing generated code...
[MOVA] Checking kernel response...
  Root Hash: [SHA-256]

*** SUCCESS! SYNAPSE -> MOVA Bridge Works! ***
    JIT successfully called merkle_alloc() and merkle_commit()
    The language can now invoke kernel power.
```

### 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│              SYNAPSE LANGUAGE                   │
│         (Syntax, Parser, Semantics)             │
├─────────────────────────────────────────────────┤
│              JIT COMPILER v3.0                  │
│           (Code Generation + Bridge)            │
├─────────────────────────────────────────────────┤
│       ┌──────────────────────────────┐          │
│       │    INTRINSICS TABLE          │          │
│       │  ┌─────────┬────────────┐    │          │
│       │  │ ID 0    │ merkle_alloc│   │          │
│       │  │ ID 1    │ merkle_commit│  │          │
│       │  │ ID 2    │ sha256_compute│ │          │
│       │  └─────────┴─────────────┘   │          │
│       └──────────────────────────────┘          │
├─────────────────────────────────────────────────┤
│              MOVA ENGINE                        │
│    (Blockchain Memory, SHA-256, Neural)         │
└─────────────────────────────────────────────────┘
```

### ✅ Completed Phases

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Lexer + Parser | ✅ |
| 2 | JIT + AVX2 + Neural | ✅ |
| 3 | Blockchain Memory | ✅ |
| 4 | Grand Unification | ✅ |
| **5.1** | **SYNAPSE ↔ MOVA Bridge** | ✅ |

---

## 🚀 Quick Start

```batch
cd d:\Projects\SYNAPSE

# Bridge Test (JIT calling MOVA)
D:\fasmw17334\fasm.exe src\bridge_test.asm src\bridge_test.exe
.\src\bridge_test.exe

# Unhackable AI
D:\fasmw17334\fasm.exe src\synapse_core.asm src\synapse_core.exe
.\src\synapse_core.exe
```

---

## 📊 Binary Sizes

| Component | Size |
|-----------|------|
| bridge_test.exe | 4,096 bytes |
| synapse_core.exe | 5,632 bytes |
| **TOTAL PLATFORM** | **~10 KB** |

---

## 🗺️ Roadmap

```
v0.1.0 ✅ Lexer
v0.2.0 ✅ Parser
v0.3.0 ✅ JIT + AVX2
v0.4.0 ✅ Neural Engine
v0.5.0 ✅ SHA-256
v0.6.0 ✅ Blockchain Memory
v0.7.0 ✅ Chain of Trust
v0.8.0 ✅ Grand Unification
v0.9.0 ✅ Bridge ← CURRENT
v1.0.0 📋 Production Release
```

---

## 📜 License

MIT License

## 👥 Authors

- **mjojo (Vitaly.G)** — Architecture, ASM
- **GLK-Dev** — AI Assistant
