# SYNAPSE Development Tasks

## 🎉 Phase 6 - Control Flow: COMPLETE! ✅

**Status:** v1.1.0 Released - Turing-Complete!
**Achievement:** if/else/while + JIT backpatching (forward AND backward jumps)

### 📋 Phase 6 Summary
- ✅ Tokens: if, elif, else, while, loop, break, continue defined
- ✅ AST Nodes: NODE_IF, NODE_WHILE, NODE_BLOCK ready
- ✅ Operators: ==, !=, <, >, <=, >= supported
- ✅ Parser: Extended with parse_if/parse_while/parse_block (3/3 tests)
- ✅ JIT IF: TEST/JZ with forward backpatching (PASSED)
- ✅ JIT WHILE: TEST/JZ/JMP with backward jump (PASSED)

---

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

### 2.2 AVX2 Tensor Engine ✅ COMPLETE
- [x] Создать aligned memory allocator (32-byte alignment)
- [x] Создать JIT emit для AVX2 инструкций
- [x] VMOVAPS ymm0, [mem] — загрузка 8 float
- [x] VADDPS ymm0, ymm0, ymm1 — сложение векторов
- [x] VZEROUPPER — очистка состояния YMM
- [x] Скомпилировать и протестировать ✅ 3584 bytes
- [x] **Результат:** 1.0 + 2.0 = 3.0 (8 чисел за 1 такт!)

### 2.3 Dot Product (Scalar) ✅ COMPLETE
- [x] Создать `src/dot_test.asm` — тест dot product
- [x] VMULPS — вертикальное умножение
- [x] VEXTRACTF128 — разделение 256 → 128 бит
- [x] VHADDPS x2 — горизонтальная сумма (редукция)
- [x] Скомпилировать и протестировать ✅ 4096 bytes
- [x] **Результат:** 1.0 * 0.5 * 8 = 4.0 ✅

### 2.4 Neural Layer (MATMUL + ReLU) ✅ COMPLETE
- [x] Создать `src/matmul_test.asm` — тест нейронного слоя
- [x] Loop generator — JNZ цикл для множественных DOT
- [x] ReLU activation — VXORPS + VMAXSS
- [x] 4 нейрона × 8 входов = правильный результат
- [x] Скомпилировать и протестировать ✅ 4096 bytes
- [x] **Результат:** 4.0, 8.0, 0.0 (ReLU!), 16.0 ✅

### 2.5 MNIST Inference ✅ COMPLETE
- [x] Создать `src/mnist_infer.asm` — полный inference engine
- [x] File I/O — CreateFileA, ReadFile, CloseHandle
- [x] Double precision — VFMADD231PD для FMA
- [x] 784 → 128 (ReLU) → 10 network
- [x] Загрузка весов из .bin файлов
- [x] Скомпилировать и протестировать ✅ 3584 bytes
- [x] **Результат:** Сеть работает, даёт разные выходы для разных изображений

### 2.6 Biases Support ✅ COMPLETE
- [x] Загрузка b1.bin (128 doubles) и b2.bin (10 doubles)
- [x] VADDSD для сложения bias после dot product
- [x] Полное уравнение: output = ReLU(W*x + b)
- [x] Скомпилировать и протестировать ✅ 4096 bytes
- [x] **Результат:** Сеть даёт разные scores для разных изображений

### 2.7 Expression Evaluation
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

## 📋 Phase 3: Blockchain Memory (IN PROGRESS)

### 3.1 SHA-256 Crypto Core ✅ COMPLETE
- [x] Создать `src/crypto_test.asm` — полная реализация SHA-256
- [x] K константы (64 dwords) — кубические корни простых чисел
- [x] Message expansion W[0..63]
- [x] 64 раунда компрессии (Sigma, Ch, Maj)
- [x] Big-endian конвертация
- [x] Скомпилировать и протестировать
- [x] **Результат:** SHA256("abc") = ba7816bf...f20015ad ✅

### 3.2 Merkle Tree Allocator ✅ COMPLETE
- [x] Создать `src/merkle_test.asm` — blockchain memory test
- [x] Block Header: MAGIC + SIZE + PREV_PTR + HASH
- [x] `merkle_alloc()` — выделение блока с заголовком
- [x] `merkle_commit()` — пересчёт SHA-256 хешей
- [x] Tamper detection: изменение данных меняет хеш
- [x] **Результат:** "Hello" → "Hxllo" детектировано ✅

### 3.3 Chain of Trust ✅ COMPLETE
- [x] Two-pass algorithm в `merkle_commit()`
- [x] Pass 1: SHA-256 для каждого блока
- [x] Pass 2: XOR всех хешей в глобальный Root Hash
- [x] **Chain Reaction**: изменение ЛЮБОГО блока меняет глобальный хеш
- [x] **Результат:** "Hello" → "Hxllo" инвалидировало весь blockchain ✅

### 3.4 Memory Integrity
- [ ] Tensor operations → SIMD instructions
- [ ] <dot> → MATMUL
- [ ] <+>, <-> → Vectorized add/sub

---

## 📋 Phase 4: Grand Unification (COMPLETE)

### 4.1 AVX2 Aligned Ledger ✅ COMPLETE
- [x] Изменить BLOCK_HEADER_SIZE с 48 на 64 байта
- [x] Добавить 16-byte padding (48-63)
- [x] Гарантировать 32-byte alignment для AVX2
- [x] **Результат:** Данные теперь AVX2-safe ✅

### 4.2 SYNAPSE CORE ✅ COMPLETE
- [x] Создать `src/synapse_core.asm`
- [x] Нейросеть в blockchain памяти
- [x] Веса загружаются через `merkle_alloc()`
- [x] Integrity check до и после inference
- [x] **Результат:** INTEGRITY VERIFIED! Hashes match! ✅

---

## 📋 Phase 5: The Bridge (COMPLETE) ✅

### 5.1 Intrinsics Table ✅ COMPLETE
- [x] Создать `src/bridge_test.asm`
- [x] Intrinsics Table: Jump table для kernel функций
- [x] `init_intrinsics()` — заполняет таблицу указателями
- [x] JIT генерирует вызовы: `merkle_alloc`, `merkle_commit`
- [x] **Результат:** SYNAPSE -> MOVA Bridge Works! ✅

### 5.2 Auto-Ledger ✅ COMPLETE
- [x] Создать `src/auto_test.asm`
- [x] `codegen_run()` обрабатывает NODE_CALL
- [x] "alloc" → генерирует merkle_alloc()
- [x] "commit" → генерирует merkle_commit()
- [x] **Результат:** 3 AST nodes → 3 kernel calls → 1 root hash ✅

---

## 🚀 Phase 6: Control Flow - The Logic (IN PROGRESS)

**Vision:** Дать SYNAPSE способность принимать решения и повторять действия.
**Milestone:** Тьюринг-полнота языка

### 6.1 Parser Extension (Week 1-2)
- [ ] Реализовать `parse_condition()` - парсинг условий (x > 0, a == b)
- [ ] Реализовать `parse_if_statement()` - полный разбор if/elif/else
- [ ] Реализовать `parse_while_statement()` - разбор while циклов
- [ ] Реализовать `parse_block()` - рекурсивный разбор блоков кода
- [ ] Обновить `parse_statement()` для обработки новых конструкций
- [ ] Создать тесты парсера (без выполнения)

**Files to modify:**
- `src/parser_v2.asm`
- `tests/control_flow_test.asm`

### 6.2 Label Manager (Week 3)
- [ ] Создать `src/label_manager.asm`
- [ ] Реализовать структуру Label (name, address, fixup_list)
- [ ] Реализовать `label_create()` - создание меток
- [ ] Реализовать `label_define()` - установка адреса метки
- [ ] Реализовать `label_reference()` - ссылка на метку для JMP
- [ ] Реализовать `label_fixup()` - исправление неразрешённых адресов

### 6.3 JIT Conditional Codegen (Week 3-4)
- [ ] Создать `src/jit_control_flow.asm`
- [ ] Реализовать `jit_emit_cmp_rax_zero()` - генерация CMP
- [ ] Реализовать `jit_emit_je()` - условный переход (equal)
- [ ] Реализовать `jit_emit_jne()` - условный переход (not equal)
- [ ] Реализовать `jit_emit_jg()` - условный переход (greater)
- [ ] Реализовать `jit_emit_jl()` - условный переход (less)
- [ ] Реализовать `jit_emit_jmp()` - безусловный переход
- [ ] Реализовать `jit_emit_if()` - генерация полного if statement
- [ ] Создать тесты: abs(), max(), min()

**Test cases:**
```asm
; Test 1: Absolute value
if x < 0:
    return -x
else:
    return x
```

### 6.4 JIT Loop Codegen (Week 4-5)
- [ ] Реализовать `jit_emit_while()` - генерация while цикла
- [ ] Реализовать `jit_emit_loop()` - бесконечный цикл
- [ ] Реализовать обработку `break` - выход из цикла
- [ ] Реализовать обработку `continue` - следующая итерация
- [ ] Создать тесты: sum_array(), factorial_iterative(), countdown()

**Test cases:**
```asm
; Test 2: Factorial (iterative)
let result: int = 1
let i: int = n
while i > 1:
    result = result * i
    i = i - 1
return result
```

### 6.5 Symbol Table (Week 5-6)
- [ ] Создать `src/symbol_table.asm`
- [ ] Реализовать структуру Variable (name, type, address, scope)
- [ ] Реализовать `symtab_declare()` - объявление переменной
- [ ] Реализовать `symtab_lookup()` - поиск переменной
- [ ] Реализовать `symtab_enter_scope()` - вход в блок
- [ ] Реализовать `symtab_exit_scope()` - выход из блока
- [ ] Интегрировать с парсером и кодогенератором
- [ ] Создать тесты: nested scopes, shadowing

### 6.6 Integration & Testing (Week 7-8)
- [ ] Интеграция всех компонентов
- [ ] Комплексные тесты:
  - [ ] Факториал (рекурсивный и итеративный)
  - [ ] Числа Фибоначчи
  - [ ] Поиск в массиве
  - [ ] Сортировка пузырьком
  - [ ] Обучение нейросети (epochs loop)
- [ ] Тесты безопасности (MOVA Engine):
  - [ ] AI Flight Recorder с проверкой целостности
  - [ ] Anti-Cheat система
  - [ ] Защищённая цепочка транзакций
- [ ] Обновление документации
- [ ] Benchmarks производительности

**Created Files:**
- ✅ `examples/control_flow_simple.syn` - базовые примеры
- ✅ `examples/control_flow_secure.syn` - защищённые вычисления
- ✅ `tests/control_flow_test.asm` - тестовый драйвер
- ✅ `docs/PHASE_6_ROADMAP.md` - полная дорожная карта
- ✅ `docs/CONTROL_FLOW_GUIDE.md` - руководство по реализации

---

## 📋 Phase 7: Functions & Recursion (Future - v1.3)

### 7.1 Function Calls
- [ ] Реализовать стековые фреймы (PUSH/POP RBP)
- [ ] Передача аргументов через регистры (FastCall)
- [ ] Возврат значений (return)
- [ ] Локальные переменные

### 7.2 Recursion
- [ ] Поддержка рекурсивных вызовов
- [ ] Тесты: factorial, Fibonacci, tree traversal

---

## 📋 Phase 8-9: Types & Structures (Future - v1.4-1.5)

### 8.1 Type System
- [ ] int, f32, f64, bool, string
- [ ] Автоматическое приведение типов
- [ ] Проверка типов в парсере

### 8.2 Structures
- [ ] struct определения
- [ ] Доступ к полям (obj.field)
- [ ] Выравнивание памяти

---

## 🎯 Phase 10: Self-Hosting (Future - v2.0)

**The Ultimate Goal:** Написать компилятор SYNAPSE на языке SYNAPSE

### 10.1 Compiler Rewrite
- [ ] Переписать lexer на SYNAPSE
- [ ] Переписать parser на SYNAPSE
- [ ] Переписать codegen на SYNAPSE

### 10.2 Bootstrap
- [ ] Скомпилировать synapse.exe самим собой
- [ ] Удалить зависимость от FASM
- [ ] 🎉 **INDEPENDENCE ACHIEVED**

### 5.3 Final Script
- [ ] Написать `mnist.syn` на языке SYNAPSE
- [ ] Компилятор генерирует и исполняет защищённый код

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
