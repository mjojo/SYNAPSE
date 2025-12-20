# SYNAPSE Language

<div align="center">

![Version](https://img.shields.io/badge/Version-0.4.0--alpha-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-Windows%20x64-green)
![Assembler](https://img.shields.io/badge/Built%20with-FASM-red)

**Современный системный язык с Python-синтаксисом и JIT-компиляцией на чистом Ассемблере**

[Особенности](#-особенности) • [Установка](#-быстрый-старт) • [Документация](#-документация) • [Roadmap](#-roadmap)

</div>

---

## 📋 Версия

| Компонент | Версия | Статус |
|-----------|--------|--------|
| **SYNAPSE Core** | `0.4.0-alpha` | 🔄 Active Development |
| Lexer | `2.0` | ✅ Stable |
| Parser | `2.0` | ✅ Stable |
| JIT Compiler | `2.0` | ✅ Stable |
| AVX2 Engine | `1.0` | ✅ Stable |
| Neural Engine | `1.0` | ✅ Stable |

**Стадия разработки:** `ALPHA` — базовый функционал работает, API может меняться.

---

## ⚡ Возможности

### ✅ Реализовано (v0.3.0-alpha)

| Возможность | Описание | Тест |
|-------------|----------|------|
| **Python-like синтаксис** | Отступы вместо скобок, INDENT/DEDENT токены | ✅ |
| **Типизация с дженериками** | `tensor<f32, [784, 128]>` | ✅ |
| **JIT-компиляция** | Генерация x64 кода в память, VirtualAlloc | ✅ |
| **Локальные переменные** | Stack frame, `[rbp-offset]` адресация | ✅ |
| **Арифметика** | `+`, `-`, `*` для int | ✅ |
| **CPU Detection** | CPUID/XGETBV для SSE/AVX2/AVX-512 | ✅ |
| **AVX2 Tensor Add** | `<+>` — 8 float за 1 такт | ✅ |
| **AVX2 Dot Product** | `<dot>` — VMULPS + VHADDPS | ✅ |
| **Aligned Allocator** | 32-byte выравнивание для SIMD | ✅ |

### 🔄 В разработке (v0.4.0)

- [ ] MATMUL (Matrix Multiplication)
- [ ] Full expression parser (operator precedence)
- [ ] Control flow codegen (`if`/`else` → jumps)
- [ ] MNIST inference demo

### 📋 Запланировано (v1.0.0)

- [ ] Полная система типов
- [ ] AVX-512 support (Tier 3)
- [ ] Blockchain memory contracts
- [ ] Linux support

---

## 🚀 Быстрый старт

### Требования
- Windows x64
- [FASM](https://flatassembler.net/) 1.73+

### Сборка и тест

```batch
cd src

# Основной JIT тест (return 42)
D:\fasmw17334\fasm.exe jit_test.asm jit_test.exe
jit_test.exe

# AVX2 тензорный тест
D:\fasmw17334\fasm.exe avx_test.asm avx_test.exe
avx_test.exe

# Dot Product тест
D:\fasmw17334\fasm.exe dot_test.asm dot_test.exe
dot_test.exe
```

### Пример кода SYNAPSE

```synapse
fn main():
    # Скалярные переменные
    let x: int = 40
    let y: int = 2
    
    # Тензорные операции (AVX2)
    let a: tensor<f32, [8]> = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    let b: tensor<f32, [8]> = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    
    let c = a <+> b      # Поэлементное сложение
    let d = a <dot> b    # Скалярное произведение → 4.0
    
    return x + y         # → 42
```

---

## 📁 Структура проекта

```
SYNAPSE/
├── src/                     # Исходный код компилятора
│   ├── jit_test.asm         # JIT v1: return 42
│   ├── jit_vars.asm         # JIT v2: переменные + арифметика
│   ├── cpu_test.asm         # CPU tier detection
│   ├── avx_test.asm         # AVX2 tensor add
│   ├── dot_test.asm         # AVX2 dot product
│   ├── lexer_v2.asm         # Indentation lexer
│   ├── parser_v2.asm        # Type parser with generics
│   └── build_*.bat          # Build scripts
├── include/
│   ├── synapse_tokens.inc   # Token constants
│   └── ast.inc              # AST structures
├── docs/
│   ├── SYNAPSE_SPEC.md      # Language specification
│   ├── SYNAPSE_GRAMMAR.md   # BNF grammar
│   └── archive/             # TITAN legacy code
├── TASKS.md                 # Development tracker
├── CHANGELOG.md             # Version history
└── README.md
```

---

## 📊 Размеры компонентов

| Компонент | Размер | Описание |
|-----------|--------|----------|
| `jit_test.exe` | 4,608 B | Базовый JIT |
| `jit_vars.exe` | 5,632 B | Переменные + стек |
| `cpu_test.exe` | 3,072 B | CPUID детектор |
| `avx_test.exe` | 3,584 B | AVX2 add |
| `dot_test.exe` | 4,096 B | Dot product |
| **TOTAL** | **~21 KB** | Весь компилятор! |

---

## 🔬 Технологии

- **Ассемблер:** FASM (Flat Assembler)
- **Архитектура:** x86-64 (Windows PE64)
- **JIT:** VirtualAlloc + PAGE_EXECUTE_READWRITE
- **SIMD:** AVX2 (256-bit YMM registers)
- **Парсинг:** Recursive Descent

---

## 📖 Документация

| Документ | Описание |
|----------|----------|
| [SYNAPSE_SPEC.md](docs/SYNAPSE_SPEC.md) | Спецификация языка |
| [SYNAPSE_GRAMMAR.md](docs/SYNAPSE_GRAMMAR.md) | BNF грамматика |
| [SYNAPSE_SYNTAX.md](docs/SYNAPSE_SYNTAX.md) | Примеры синтаксиса |
| [TASKS.md](TASKS.md) | Трекер разработки |
| [CHANGELOG.md](CHANGELOG.md) | История версий |

---

## 🗺️ Roadmap

```
v0.1.0 ✅ Lexer (INDENT/DEDENT)
v0.2.0 ✅ Parser (generics, blocks)
v0.3.0 ✅ JIT + AVX2 (current)
v0.4.0 🔄 MATMUL + MNIST
v0.5.0 📋 Full type system
v1.0.0 📋 Production release
```

---

## 📜 Лицензия

MIT License — свободное использование с указанием авторства.

## 👥 Авторы

- **mjojo (Vitaly.G)** — архитектура, ASM реализация
- **GLK-Dev** — AI-ассистент

---

<div align="center">

**SYNAPSE: Where Python meets Assembly**

*Built with ❤️ and pure x86-64 Assembly*

</div>
