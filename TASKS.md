# SYNAPSE Development Tasks

## ✅ Phase 1: Foundation (COMPLETE)

### 1.1 Platform Abstraction Layer (PAL)
- [ ] Создать `src/sys_interface.asm`
- [ ] Вынести все вызовы kernel32.dll
- [ ] Абстрагировать VirtualAlloc/mmap
- [ ] Абстрагировать file I/O

### 1.2 Новый Лексер (Indentation) ✅ COMPLETE
- [x] Создать `include/synapse_tokens.inc` — константы токенов
- [x] Создать `src/lexer_v2.asm` — лексер с отступами
- [x] Реализовать INDENT/DEDENT стек
- [x] Добавить новые ключевые слова (fn, let, mut, tensor, chain, contract)
- [x] Добавить новые операторы (->, <dot>, <+>, ..)
- [x] Создать `src/lexer_test.asm` — тестовый драйвер
- [x] Скомпилировать и протестировать ✅ 5,120 bytes

### 1.3 Парсер Типов ✅ COMPLETE
- [x] Создать `src/parser_v2.asm` — парсер
- [x] Создать `src/parser_test.asm` — интегрированный тест
- [x] Реализовать парсинг `let x: type = value`
- [x] Реализовать парсинг `tensor<T, [shape]>` — дженерики!
- [x] Реализовать парсинг `fn name():` — функции
- [x] Скомпилировать и протестировать ✅ 5,632 bytes

### 1.4 Синтаксис v0.1 ✅ COMPLETE
- [x] Создать `include/ast.inc` — структуры AST
- [x] Парсинг `fn name():` → вызов парсера блока
- [x] Парсинг `if/elif/else:`
- [x] Парсинг `for x in range:` / `while:`
- [x] Парсинг `return value` / `pass` / `break`
- [x] **Рекурсивный разбор вложенных блоков** — РАБОТАЕТ!
- [x] Скомпилировать и протестировать ✅ 6,144 bytes

### 1.5 JIT-адаптация ✅ COMPLETE
- [x] Создать `src/jit_test.asm` — полный pipeline
- [x] Lexer → Parser → CodeGen → Execute
- [x] VirtualAlloc с PAGE_EXECUTE_READWRITE
- [x] Генерация x64 машинного кода
- [x] **"The 42 Test" — PASSED!** ✅ 4,608 bytes

---

## 🔄 Phase 2: Adaptive AI Engine (IN PROGRESS)

### 2.1 Hardware Awareness ✅ COMPLETE
- [x] Создать `src/cpu_test.asm` — детектор CPU
- [x] CPUID + XGETBV для определения SSE/AVX2/AVX-512
- [x] Автоматическое определение Tier: 1 (SSE), 2 (AVX2), 3 (AVX-512)
- [x] Скомпилировать и протестировать ✅ 3072 bytes
- [x] **Результат:** AuthenticAMD, TIER 2 (AVX2)

### 2.2 Expression Evaluation
- [ ] Парсинг арифметических выражений (a + b * c)
- [ ] Приоритет операторов (Shunting-yard или Pratt parsing)
- [ ] Унарные операторы (-x, not x)
- [ ] Скобки и вложенные выражения

### 2.2 Variable Management
- [ ] Таблица символов (Symbol Table)
- [ ] Область видимости (Scope)
- [ ] Локальные переменные (стек)
- [ ] Глобальные переменные

### 2.3 Control Flow Codegen
- [ ] if/else → JIT conditional jumps
- [ ] for/while → JIT loops
- [ ] break/continue
- [ ] Function calls

### 2.4 Type System
- [ ] Type checking
- [ ] Implicit conversions
- [ ] Tensor shape validation

---

## 📋 Phase 3: Advanced Features (PLANNED)

### 3.1 SIMD/AVX Operations
- [ ] Tensor operations → SIMD instructions
- [ ] <dot> → MATMUL
- [ ] <+>, <-> → Vectorized add/sub

### 3.2 Memory Management
- [ ] Arena allocator
- [ ] Stack-based locals
- [ ] Heap for dynamic data

### 3.3 Standard Library
- [ ] print() function
- [ ] File I/O
- [ ] String operations

---

## 📂 Project Structure

```
src/
├── jit_test.asm       # Main JIT compiler test ⭐
├── lexer_v2.asm       # Indentation lexer
├── lexer_test.asm     # Lexer standalone test
├── parser_v2.asm      # Type/generics parser
├── parser_test.asm    # Parser standalone test
├── block_test.asm     # Recursive block test
└── build_*.bat        # Build scripts

include/
├── synapse_tokens.inc # Token constants
└── ast.inc            # AST structures

docs/archive/          # TITAN legacy code (reference)
```

---

*Last updated: 2025-12-20*
