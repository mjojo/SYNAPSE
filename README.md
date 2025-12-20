# SYNAPSE Language

<div align="center">

![Version](https://img.shields.io/badge/Version-0.5.0--alpha-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-Windows%20x64-green)
![Assembler](https://img.shields.io/badge/Built%20with-FASM-red)

**Современный системный язык с Python-синтаксисом, JIT-компиляцией и Blockchain-памятью**

[Особенности](#-особенности) • [Установка](#-быстрый-старт) • [Документация](#-документация) • [Roadmap](#-roadmap)

</div>

---

## 📋 Версия

| Компонент | Версия | Статус |
|-----------|--------|--------|
| **SYNAPSE Core** | `0.5.0-alpha` | 🔄 Active Development |
| Lexer | `2.0` | ✅ Stable |
| Parser | `2.0` | ✅ Stable |
| JIT Compiler | `2.0` | ✅ Stable |
| AVX2 Engine | `1.0` | ✅ Stable |
| Neural Engine | `1.0` | ✅ Stable |
| **Crypto Core** | `1.0` | ✅ **NEW!** |

**Стадия:** `ALPHA` — базовый функционал работает, API может меняться.

---

## ⚡ Возможности

### ✅ Реализовано (v0.5.0-alpha)

| Категория | Возможность | Описание |
|-----------|-------------|----------|
| **Синтаксис** | Python-like | Отступы, INDENT/DEDENT токены |
| **Типы** | Generics | `tensor<f32, [784, 128]>` |
| **JIT** | x64 Codegen | VirtualAlloc, машинный код |
| **Переменные** | Stack Frame | `[rbp-offset]`, символьная таблица |
| **SIMD** | AVX2 | VMOVAPS, VADDPS, VMULPS, VFMADD |
| **CPU** | Detection | CPUID/XGETBV для Tier 1/2/3 |
| **Tensors** | `<+>`, `<dot>` | Сложение и скалярное произведение |
| **Neural** | MATMUL+ReLU | Полносвязные слои с активацией |
| **MNIST** | Inference | 784→128→10, загрузка весов |
| **Crypto** | SHA-256 | Чистый ASM, без зависимостей |

### 🔄 В разработке (v0.6.0)

- [ ] Merkle Tree Allocator
- [ ] Memory integrity verification
- [ ] Full expression parser

### 📋 Запланировано (v1.0.0)

- [ ] Blockchain memory contracts
- [ ] AVX-512 support
- [ ] Linux support

---

## 🚀 Быстрый старт

### Требования
- Windows x64
- [FASM](https://flatassembler.net/) 1.73+

### Сборка и запуск

```batch
cd d:\Projects\SYNAPSE

# JIT тест (return 42)
D:\fasmw17334\fasm.exe src\jit_test.asm src\jit_test.exe
.\src\jit_test.exe

# AVX2 тензоры
D:\fasmw17334\fasm.exe src\avx_test.asm src\avx_test.exe
.\src\avx_test.exe

# MNIST inference
D:\fasmw17334\fasm.exe src\mnist_infer.asm src\mnist_infer.exe
.\src\mnist_infer.exe

# SHA-256 crypto
D:\fasmw17334\fasm.exe src\crypto_test.asm src\crypto_test.exe
.\src\crypto_test.exe
```

---

## 📁 Структура проекта

```
SYNAPSE/
├── src/
│   ├── jit_test.asm        # JIT: return 42
│   ├── jit_vars.asm        # JIT: переменные + арифметика
│   ├── cpu_test.asm        # CPU tier detection
│   ├── avx_test.asm        # AVX2 tensor add
│   ├── dot_test.asm        # AVX2 dot product
│   ├── matmul_test.asm     # MATMUL + ReLU
│   ├── mnist_infer.asm     # MNIST inference
│   ├── crypto_test.asm     # SHA-256 ⭐ NEW
│   └── lexer/parser_*.asm  # Frontend
├── include/
│   ├── synapse_tokens.inc
│   ├── ast.inc
│   └── version.inc
├── neural/                  # MNIST weights (.bin)
├── docs/                    # Documentation
├── TASKS.md
├── CHANGELOG.md
└── README.md
```

---

## 📊 Размеры компонентов

| Компонент | Размер | Описание |
|-----------|--------|----------|
| jit_test | 4,608 B | Базовый JIT |
| jit_vars | 5,632 B | Переменные |
| cpu_test | 3,072 B | CPUID |
| avx_test | 3,584 B | AVX2 add |
| dot_test | 4,096 B | Dot product |
| matmul_test | 4,096 B | Neural layer |
| mnist_infer | 4,096 B | MNIST |
| crypto_test | ~4 KB | SHA-256 |
| **TOTAL** | **~33 KB** | Весь компилятор! |

---

## 🔬 Технологии

- **Ассемблер:** FASM (Flat Assembler)
- **Архитектура:** x86-64 (Windows PE64)
- **JIT:** VirtualAlloc + PAGE_EXECUTE_READWRITE
- **SIMD:** AVX2/FMA (256-bit YMM)
- **Crypto:** SHA-256 (pure ASM)
- **Neural:** MATMUL, ReLU, File I/O

---

## 📖 Документация

| Документ | Описание |
|----------|----------|
| [SYNAPSE_SPEC.md](docs/SYNAPSE_SPEC.md) | Спецификация языка |
| [SYNAPSE_GRAMMAR.md](docs/SYNAPSE_GRAMMAR.md) | BNF грамматика |
| [TASKS.md](TASKS.md) | Трекер разработки |
| [CHANGELOG.md](CHANGELOG.md) | История версий |

---

## 🗺️ Roadmap

```
v0.1.0 ✅ Lexer (INDENT/DEDENT)
v0.2.0 ✅ Parser (generics, blocks)
v0.3.0 ✅ JIT + AVX2
v0.4.0 ✅ Neural Engine (MATMUL, MNIST)
v0.5.0 ✅ Crypto Core (SHA-256) ← CURRENT
v0.6.0 🔄 Blockchain Memory
v1.0.0 📋 Production Release
```

---

## 📜 Лицензия

MIT License — свободное использование с указанием авторства.

## 👥 Авторы

- **mjojo (Vitaly.G)** — архитектура, ASM
- **GLK-Dev** — AI-ассистент

---

<div align="center">

**SYNAPSE: Where Python meets Assembly meets Blockchain**

*Built with ❤️ and pure x86-64 Assembly*

</div>
