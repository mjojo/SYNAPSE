# SYNAPSE Language

<div align="center">

![Version](https://img.shields.io/badge/Version-0.7.0--alpha-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-Windows%20x64-green)
![Assembler](https://img.shields.io/badge/Built%20with-FASM-red)

**Системный язык с Python-синтаксисом, JIT-компиляцией и TRUE Blockchain-памятью**

[Особенности](#-особенности) • [Быстрый старт](#-быстрый-старт) • [Blockchain Memory](#-blockchain-memory) • [Roadmap](#-roadmap)

</div>

---

## 📋 Версия

| Компонент | Версия | Статус |
|-----------|--------|--------|
| **SYNAPSE Core** | `0.7.0-alpha` | 🔄 Active Development |
| Lexer | `2.0` | ✅ Stable |
| Parser | `2.0` | ✅ Stable |
| JIT Compiler | `2.0` | ✅ Stable |
| AVX2 Engine | `1.0` | ✅ Stable |
| Neural Engine | `1.0` | ✅ Stable |
| Crypto Core | `1.0` | ✅ Stable |
| Ledger Memory | `1.0` | ✅ Stable |
| **Chain of Trust** | `2.0` | ✅ **NEW!** |

---

## ⚡ Особенности

### ✅ Реализовано (v0.7.0-alpha)

| Категория | Возможность | Описание |
|-----------|-------------|----------|
| **Синтаксис** | Python-like | Отступы, INDENT/DEDENT токены |
| **JIT** | x64 Codegen | VirtualAlloc, машинный код |
| **SIMD** | AVX2/FMA | VMOVAPS, VADDPS, VFMADD231PD |
| **Neural** | MATMUL+ReLU | MNIST inference 784→128→10 |
| **Crypto** | SHA-256 | Чистый ASM, FIPS 180-4 |
| **Blockchain** | XOR Linking | Global Root Hash, chain reaction |

### 🔐 Blockchain Memory

SYNAPSE — первый язык с **TRUE Blockchain Memory**:

```
Block A: "Hello" → SHA-256 → Hash_A
Block B: "World" → SHA-256 → Hash_B
Root Hash = Hash_A ⊕ Hash_B

[HACK] Block A: "Hello" → "Hxllo"
       Hash_A changes → Root Hash CHANGES!
       
*** CHAIN REACTION CONFIRMED! ***
```

- ✅ Каждый блок памяти защищён SHA-256
- ✅ Все хеши связаны через XOR
- ✅ Изменение ЛЮБОГО блока меняет глобальный Root Hash
- ✅ Это настоящий блокчейн в оперативной памяти!

---

## 🚀 Быстрый старт

### Требования
- Windows x64
- [FASM](https://flatassembler.net/) 1.73+

### Сборка и запуск

```batch
cd d:\Projects\SYNAPSE

# Chain of Trust (Blockchain Memory)
D:\fasmw17334\fasm.exe src\merkle_test.asm src\merkle_test.exe
.\src\merkle_test.exe

# Neural Network (MNIST)
D:\fasmw17334\fasm.exe src\mnist_infer.asm src\mnist_infer.exe
.\src\mnist_infer.exe

# SHA-256 Crypto
D:\fasmw17334\fasm.exe src\crypto_test.asm src\crypto_test.exe
.\src\crypto_test.exe
```

---

## 📁 Структура проекта

```
SYNAPSE/
├── src/
│   ├── merkle_test.asm     # Chain of Trust ⭐
│   ├── crypto_test.asm     # SHA-256
│   ├── mnist_infer.asm     # MNIST inference
│   ├── matmul_test.asm     # Neural layer
│   ├── dot_test.asm        # Dot product
│   ├── avx_test.asm        # AVX2 tensors
│   ├── cpu_test.asm        # CPU detection
│   ├── jit_test.asm        # Basic JIT
│   └── lexer/parser_*.asm
├── include/
├── neural/
├── docs/
├── TASKS.md
├── CHANGELOG.md
└── README.md
```

---

## 📊 Размеры

| Компонент | Размер |
|-----------|--------|
| merkle_test (blockchain) | 4,096 B |
| crypto_test (SHA-256) | ~4 KB |
| mnist_infer | 4,096 B |
| **TOTAL** | **~40 KB** |

---

## 🗺️ Roadmap

```
v0.1.0 ✅ Lexer (INDENT/DEDENT)
v0.2.0 ✅ Parser (generics, blocks)
v0.3.0 ✅ JIT + AVX2
v0.4.0 ✅ Neural Engine (MNIST)
v0.5.0 ✅ Crypto Core (SHA-256)
v0.6.0 ✅ Blockchain Memory
v0.7.0 ✅ Chain of Trust ← CURRENT
v0.8.0 🔄 Smart Contracts
v1.0.0 📋 Production Release
```

---

## 📜 Лицензия

MIT License

## 👥 Авторы

- **mjojo (Vitaly.G)** — архитектура, ASM
- **GLK-Dev** — AI-ассистент

---

<div align="center">

**SYNAPSE: TRUE Blockchain Memory in Pure Assembly**

</div>
