# TITAN Language

> JIT-компилируемый BASIC на чистом Ассемблере x64 с нейросетевым движком

## 🏆 Достижение

**Первый в мире нейросетевой движок на 21 КБ!**
- Полный MNIST inference (784→128→10 MLP)
- 96.37% точность распознавания цифр
- SIMD-ускорение (AVX2/FMA)

## 👤 Авторы

- **mjojo** — Vitaly.G
- **GLK-Dev** — [GitHub](https://github.com/GLK-Dev)

*© 2025 mjojo & GLK-Dev*

## Быстрый старт

### Требования
- Windows 10/11 x64
- [FASM (Flat Assembler)](https://flatassembler.net/download.php)

### Сборка

```cmd
build.bat
```

### Запуск

```cmd
titan.exe
```

### Пример: Нейросеть MNIST

```cmd
type neural_demo.ttn | titan.exe
```

### Пример: Фрактал Мандельброта

```cmd
type mandelbrot_fast.ttn | titan.exe
```

### Пример сессии REPL

```
TITAN Language v0.18.0
JIT-Compiled TITAN for x64
(c) 2025 mjojo & GLK-Dev

[SIMD: AVX2 enabled]
TITAN> DIM A(1000)
Array OK
TITAN> VRELU A, A
VRELU OK
TITAN> exit
Goodbye!
```

### Пример: Neural Inference

```basic
REM TITAN Neural Engine - MNIST
DIM A(100352)    ; W1: 784x128 weights
DIM H(128)       ; Hidden layer
DIM O(10)        ; Output (10 digits)

BLOAD "w1.bin", A
MATMUL H, I, A, 1, 784, 128
VRELU H, H
MATMUL O, H, C, 1, 128, 10

REM Result: O(9) = 9.299798 → Digit 9!
```

## Текущий статус: v0.18.0 (21 KB)

### Завершённые фазы
- [x] Phase 0-8 — REPL, Лексер, JIT, Переменные, Циклы, Строки, I/O
- [x] Phase 9 — SIMD (AVX2 векторизация)
- [x] Phase 10 — GOSUB/RETURN (подпрограммы)
- [x] Phase 11 — REM, многострочный IF
- [x] Phase 12 — FUNC/ENDFUNC/LOCAL (полная рекурсия)
- [x] Phase 13 — **FFI: MSGBOX, Windows API**
- [x] Phase 14 — **GDI Graphics: окна, пиксели, линии**
- [x] Phase 15 — **Floating-Point: полная поддержка double**
- [x] Phase 16 — **Heap Memory: динамические массивы до 1MB**
- [x] Phase 17 — **BLOAD/BSAVE: бинарные файлы**
- [x] Phase 18 — **MATMUL/VRELU: матричные операции**
- [x] Phase 19 — **MNIST Neural Inference** ✨

## 🧠 Neural Engine

TITAN включает полноценный нейросетевой движок:

| Команда | Описание |
|---------|----------|
| `DIM A(n)` | Массив на куче (до 1MB) |
| `BLOAD "file", A` | Загрузить бинарные веса |
| `BSAVE "file", A` | Сохранить массив |
| `MATMUL C, A, B, m, k, n` | Умножение матриц (AVX2+FMA) |
| `VRELU B, A` | ReLU активация (SIMD) |

## 📊 Размер

| Версия | Размер | Фичи |
|--------|--------|------|
| v0.13.0 | 14 KB | FFI, MSGBOX |
| v0.14.0 | 15 KB | +GDI Graphics |
| v0.15.0 | 17 KB | +Float64 |
| v0.16.0 | 18 KB | +Heap Arrays |
| v0.17.0 | 19 KB | +BLOAD/BSAVE |
| v0.18.0 | **21 KB** | +MATMUL/VRELU/Neural |

## Документация

- [ROADMAP.md](ROADMAP.md) — полный план разработки
- [docs/commands.md](docs/commands.md) — справочник команд
- [docs/grammar.md](docs/grammar.md) — BNF грамматика

---

*© 2025 mjojo & GLK-Dev. TITAN Language.*
