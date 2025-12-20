# TITAN Language — Дорожная карта разработки

> JIT-компилируемый язык на чистом Ассемблере x64

---

## 🎯 Цели проекта

- **Автономный .exe** — без зависимостей, работает везде
- **JIT-компиляция** — мгновенное выполнение кода
- **SIMD по умолчанию** — векторные вычисления (AVX2/AVX-512)
- **Arena Memory** — сверхбыстрое управление памятью
- **Минимальный размер** — килобайты, не мегабайты

---

## 🏛️ Архитектура TITAN

```
┌─────────────────────────────────────────────────────────────────┐
│                         TITAN REPL                              │
│                      "TITAN v1.0> _"                            │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LEXER (lexer.asm)                          │
│         "SET A = 10 + 5" → [SET][A][=][10][+][5]               │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PARSER (parser.asm)                         │
│                   Построение AST / IR                           │
│              Проверка синтаксиса по грамматике                  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  JIT GENERATOR (jit.asm)                        │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐    │
│  │ Opcode Gen  │  │ Reg Allocator│  │ SIMD Gen (AVX2)     │    │
│  │ MOV,ADD,JMP │  │ R8-R15,Spill │  │ VADDPS,VMULPS       │    │
│  └─────────────┘  └──────────────┘  └─────────────────────┘    │
│                           │                                     │
│                           ▼                                     │
│              ┌────────────────────────┐                        │
│              │   HEX DUMP (debug)     │                        │
│              │ "48 B8 0A 00 00 00..." │                        │
│              └────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  EXECUTABLE MEMORY (mmap/VirtualAlloc)          │
│                    PROT_READ | PROT_WRITE | PROT_EXEC           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  [JIT CODE BUFFER]  ← call rax  ← Процессор исполняет!  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  ARENA MEMORY    │  │  VARIABLES       │  │  FFI BRIDGE      │
│  (memory.asm)    │  │  (variables.asm) │  │  (ffi.asm)       │
│                  │  │                  │  │                  │
│  Fast alloc:     │  │  vars[A-Z]:      │  │  dlopen/dlsym    │
│  ptr += size     │  │  8 bytes each    │  │  LoadLibrary     │
│  Free: reset ptr │  │  Memory Baking   │  │  GetProcAddress  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PLATFORM LAYER                               │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐  │
│  │   linux.asm             │  │   windows.asm               │  │
│  │   syscall (rax,rdi...)  │  │   call [kernel32.dll]       │  │
│  │   sys_write, sys_mmap   │  │   WriteConsole, VirtualAlloc│  │
│  └─────────────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                        ┌─────────────┐
                        │   OUTPUT    │
                        │  "Result: 15"│
                        └─────────────┘
```

### Поток данных (Data Flow)
```
Исходный код → Токены → AST → Машинный код → Исполнение → Результат
     ↑                                              │
     └──────────── REPL Loop ───────────────────────┘
```

---

## 📋 Фазы разработки

### Phase 0: Инфраструктура
| # | Задача | Описание |
|---|--------|----------|
| 0.1 | Настройка окружения | Установка FASM/NASM, тестовая сборка |
| 0.2 | Структура проекта | Организация файлов, Makefile |
| 0.3 | Базовый REPL | Цикл ввода-вывода (prompt → input → echo) |
| 0.4 | Системные вызовы | Обёртки для read/write/mmap/exit |
| 0.5 | **Crash Handler** | sigaction (Linux) / SetUnhandledExceptionFilter (Windows) — перехват SIGSEGV/SIGFPE |

### Phase 1: Лексер (Tokenizer)
| # | Задача | Описание |
|---|--------|----------|
| 1.1 | Пропуск пробелов | skip_whitespace |
| 1.2 | Парсинг чисел | ASCII → Integer (atoi) |
| 1.3 | Парсинг идентификаторов | Имена переменных, ключевые слова |
| 1.4 | Парсинг операторов | =, +, -, *, /, <, >, == |
| 1.5 | Таблица токенов | Структура Token { type, value, pos } |

### Phase 2: JIT-ядро
| # | Задача | Описание |
|---|--------|----------|
| 2.1 | Исполняемая память | mmap с PROT_EXEC (Linux) / VirtualAlloc (Windows) |
| 2.2 | Генератор MOV | mov rax, imm64 |
| 2.3 | Генератор RET | Возврат из JIT-функции |
| 2.4 | Вызов JIT-кода | call [jit_buffer] |
| 2.5 | Вывод результата | print_number (integer → ASCII) |
| 2.6 | **Hex Dump (DUMP)** | Вывод сгенерированного байт-кода для отладки (критично!) |

### Phase 3: Переменные
| # | Задача | Описание |
|---|--------|----------|
| 3.1 | Арена переменных | Массив vars[26] для A-Z |
| 3.2 | Команда SET | SET A 100 → mov [addr], value |
| 3.3 | Команда GET | GET A → mov rax, [addr] |
| 3.4 | Memory Baking | Впаивание адресов в машинный код |

### Phase 4: Арифметика
| # | Задача | Описание |
|---|--------|----------|
| 4.1 | ADD | ADD A B → A = A + B |
| 4.2 | SUB | SUB A B → A = A - B |
| 4.3 | MUL | MUL A B → A = A * B |
| 4.4 | DIV | DIV A B → A = A / B |
| 4.5 | Выражения | A = B + C * D (приоритеты операций) |
| 4.6 | **Simple Allocator** | MVP: всегда spill в память (как v0.2) — работает, но медленно |
| 4.7 | **Register Allocator** | ⚠️ ПОСЛЕ MVP! Linear Scan или Graph Coloring — оптимизация |

> ⚠️ **Предупреждение**: Пункт 4.7 — это "кроличья нора". Задача раскраски графа регистров
> может занять месяц. Для MVP достаточно 4.6 (простой spill). Оптимизируй ПОСЛЕ того,
> как всё заработает!

### Phase 5: Управление потоком
| # | Задача | Описание |
|---|--------|----------|
| 5.1 | Нумерация строк | 10 PRINT "HI" — хранение в памяти |
| 5.2 | GOTO | GOTO 100 — безусловный переход |
| 5.3 | IF/THEN | IF A > 10 THEN GOTO 50 |
| 5.4 | Операторы сравнения | JIT: cmp + jcc инструкции |

### Phase 6: Циклы
| # | Задача | Описание |
|---|--------|----------|
| 6.1 | FOR/NEXT | FOR I = 1 TO 10 ... NEXT I |
| 6.2 | WHILE/WEND | WHILE A < 100 ... WEND |
| 6.3 | Стек циклов | Вложенные циклы |

### Phase 7: Строки
| # | Задача | Описание |
|---|--------|----------|
| 7.1 | Строковые литералы | "Hello World" |
| 7.2 | PRINT | PRINT "text" / PRINT A |
| 7.3 | INPUT | INPUT A (ввод от пользователя) |
| 7.4 | Конкатенация | A$ = "Hello" + " World" |

### Phase 8: Файловая система
| # | Задача | Описание |
|---|--------|----------|
| 8.1 | SAVE | SAVE "program.ttn" |
| 8.2 | LOAD | LOAD "program.ttn" |
| 8.3 | RUN | Выполнение загруженной программы |
| 8.4 | NEW | Очистка памяти программы |
| 8.5 | LIST | Вывод листинга |
| 8.6 | **.ttn формат** | Magic Header "TITAN\0" для защиты файлов |

### Phase 9: SIMD (Инновация)
| # | Задача | Описание |
|---|--------|----------|
| 9.1 | Детекция CPU | CPUID — проверка AVX2/AVX-512 |
| 9.2 | Векторные переменные | DIM V[8] — 8 чисел в одном регистре |
| 9.3 | VADD | VADD A B → vaddps ymm0, ymm1 |
| 9.4 | VMUL | VMUL A B → vmulps |
| 9.5 | Авто-векторизация | Простые циклы → SIMD |

### Phase 10: Продвинутые фичи
| # | Задача | Описание |
|---|--------|----------|
| 10.1 | Функции (GOSUB/RETURN) | Подпрограммы |
| 10.2 | Локальные переменные | Стек кадров |
| 10.3 | Массивы | DIM A(100) |
| 10.4 | DATA/READ | Встроенные данные |
| 10.5 | Графика (опционально) | Framebuffer / SDL |

---

### Phase X: Безопасность и Инструменты (The Safety Net)
> **Критично для отладки JIT-кода!**

| # | Задача | Описание |
|---|--------|----------|
| X.1 | Hex Dump | Команда `DUMP` — вывод байт-кода: `48 B8 0A 00...` |
| X.2 | Crash Handler | Перехват SIGSEGV/SIGFPE → "Ошибка в строке 10" вместо вылета |
| X.3 | Stack Trace | Сопоставление адреса ошибки с номером строки TITAN |
| X.4 | Sandbox | Защита памяти компилятора от JIT-кода |
| X.5 | Debug Mode | Флаг `-d` — пошаговое выполнение с выводом состояния |

### Phase Y: FFI — Foreign Function Interface (Связь с миром)
> **Киллер-фича: вызов любых DLL/SO из TITAN**

| # | Задача | Описание |
|---|--------|----------|
| Y.1 | DLOPEN | `dlopen` (Linux) / `LoadLibrary` (Windows) |
| Y.2 | DLSYM | `dlsym` / `GetProcAddress` — поиск функции по имени |
| Y.3 | DECLARE | `DECLARE FUNCTION MsgBox LIB "user32.dll"` |
| Y.4 | C-Call Convention | Правильная передача аргументов (System V / MS x64) |
| Y.5 | Callback | Передача TITAN-функции в C-код (для событий)

---

### Phase Z: Качество и Инфраструктура (Production Ready)
> **Без этого проект останется игрушкой**

| # | Задача | Описание |
|---|--------|----------|
| Z.1 | **Test Framework** | Автотесты: `tests/001_set_get.bas` → ожидаемый вывод |
| Z.2 | **Бенчмарки** | Сравнение с LuaJIT, Python, QB64 — докажи скорость |
| Z.3 | **Грамматика (BNF)** | Формальная спецификация синтаксиса TITAN |
| Z.4 | **История REPL** | Стрелки ↑↓, редактирование строки (как readline) |
| Z.5 | **Compile Mode** | `titan -c game.bas -o game.exe` — AOT-компиляция |
| Z.6 | **Cross-platform** | Windows и Linux параллельно с Phase 0 |
| Z.7 | **HELP команда** | Встроенная справка: `HELP PRINT`, `HELP FOR` |
| Z.8 | **Цветной вывод** | ANSI-коды для ошибок (красный), успеха (зелёный) |

### Phase ∞: Будущее (После MVP)
> **Идеи для версии 2.0**

| # | Задача | Описание |
|---|--------|----------|
| ∞.1 | Отладчик (Debugger) | Breakpoints, step-by-step, watch variables |
| ∞.2 | Профайлер | Измерение времени выполнения каждой строки |
| ∞.3 | LSP Server | Подсветка синтаксиса и автодополнение в VS Code |
| ∞.4 | Пакетный менеджер | `titan install graphics` — установка библиотек |
| ∞.5 | Self-hosting | Компилятор TITAN, написанный на TITAN |

---

## 🏗️ Структура проекта

```
Titan/
├── src/
│   ├── main.asm          # Точка входа, REPL
│   ├── lexer.asm         # Токенизатор
│   ├── parser.asm        # Парсер команд
│   ├── jit.asm           # Генератор машинного кода
│   ├── memory.asm        # Управление памятью (арены)
│   ├── variables.asm     # Хранилище переменных
│   ├── math.asm          # Арифметические операции
│   ├── strings.asm       # Работа со строками
│   ├── simd.asm          # Векторные операции
│   ├── syscalls.asm      # Обёртки системных вызовов
│   ├── debug.asm         # Hex Dump, отладочные инструменты
│   ├── crash.asm         # Crash Handler (SIGSEGV/SIGFPE)
│   ├── ffi.asm           # Foreign Function Interface
│   └── platform/
│       ├── linux.asm     # Linux-специфичный код
│       └── windows.asm   # Windows-специфичный код
├── include/
│   ├── constants.inc     # Константы и макросы
│   ├── structs.inc       # Структуры данных
│   └── opcodes.inc       # Справочник опкодов x64 для JIT
├── tests/
│   ├── run_tests.sh      # Скрипт запуска всех тестов
│   ├── 001_repl.bas      # Тест: базовый REPL
│   ├── 002_variables.bas # Тест: SET/GET
│   ├── 003_math.bas      # Тест: арифметика
│   └── expected/         # Ожидаемые результаты
│       ├── 001_repl.txt
│       └── ...
├── bench/
│   ├── fib.bas           # Бенчмарк: Фибоначчи
│   ├── prime.bas         # Бенчмарк: Простые числа
│   └── compare.py        # Сравнение с другими языками
├── docs/
│   ├── grammar.md        # BNF-грамматика TITAN
│   ├── opcodes.md        # Справочник опкодов x64
│   ├── abi.md            # Соглашения о вызовах
│   └── commands.md       # Справочник команд TITAN
├── Makefile
├── ROADMAP.md
└── CHANGELOG.md
```

---

## 🔧 Технические решения

### Платформа
- **Основная**: Linux x64 (syscall напрямую)
- **Вторичная**: Windows x64 (kernel32.dll)

### Ассемблер
- **FASM** (Flat Assembler) — рекомендуется
- Альтернатива: NASM

### Соглашение о вызовах
- Linux: System V AMD64 ABI (rdi, rsi, rdx, rcx, r8, r9)
- Windows: Microsoft x64 (rcx, rdx, r8, r9)

### Регистры (распределение)
| Регистр | Назначение |
|---------|------------|
| RAX | Возвращаемое значение, временные вычисления |
| RBX | Указатель на арену переменных |
| RCX | Счётчик циклов |
| RDX | Временные данные |
| RSI | Указатель на исходный код (source) |
| RDI | Указатель на JIT-буфер (destination) |
| RBP | База стека |
| RSP | Указатель стека |
| R12-R15 | Сохраняемые регистры (callee-saved) |

---

## 📅 Оценка сроков

| Фаза | Сложность | Оценка времени |
|------|-----------|----------------|
| Phase 0 | ⭐ | 1-2 дня |
| Phase 1 | ⭐⭐ | 3-5 дней |
| Phase 2 | ⭐⭐⭐ | 5-7 дней |
| Phase 3 | ⭐⭐ | 2-3 дня |
| Phase 4 | ⭐⭐⭐ | 5-7 дней |
| Phase 5 | ⭐⭐⭐ | 5-7 дней |
| Phase 6 | ⭐⭐⭐ | 4-5 дней |
| Phase 7 | ⭐⭐ | 3-4 дня |
| Phase 8 | ⭐⭐ | 2-3 дня |
| Phase 9 | ⭐⭐⭐⭐⭐ | 2-3 недели |
| Phase 10 | ⭐⭐⭐⭐ | 1-2 недели |
| **Phase X** | ⭐⭐⭐ | 3-5 дней |
| **Phase Y** | ⭐⭐⭐⭐ | 1 неделя |
| **Phase Z** | ⭐⭐ | Параллельно с разработкой |
| **Phase ∞** | ⭐⭐⭐⭐⭐ | После релиза v1.0 |

**Итого MVP (Phase 0-5 + X)**: ~4-5 недель
**Полная версия**: ~2-3 месяца

---

## 🎯 Порядок разработки (Рекомендуемый)

> ⚠️ **Важно**: Phase X.1 (Hex Dump) нужно делать ДО арифметики!
> ⚠️ **Важно**: Cross-platform (Z.6) делать ПАРАЛЛЕЛЬНО с Phase 0!

```
Phase 0 (Инфраструктура) + Z.6 (Cross-platform) ← ПАРАЛЛЕЛЬНО!
    ↓
Phase Z.3 (Грамматика BNF) ← Зафиксировать синтаксис ДО кодирования
    ↓
Phase 1 (Лексер)
    ↓
Phase 2 (JIT-ядро) ──→ Phase X.1 (Hex Dump) ← КРИТИЧНО!
    ↓
Phase Z.1 (Test Framework) ← Начать писать тесты СЕЙЧАС
    ↓
Phase 3 (Переменные)
    ↓
Phase X.2 (Crash Handler) ← Защита перед сложной логикой
    ↓
Phase 4 (Арифметика + Register Allocator)
    ↓
Phase 5-8 (Управление, циклы, строки, файлы)
    ↓
Phase Z.2 (Бенчмарки) ← Докажи скорость
    ↓
Phase Y (FFI) ← Открываем мир
    ↓
Phase 9 (SIMD) ← Инновация
    ↓
Phase Z.5 (Compile Mode) ← titan -c game.bas -o game.exe
    ↓
Phase 10 (Продвинутые фичи)
    ↓
Phase ∞ (Будущее)
```

---

## ✅ Критерии готовности MVP

- [x] REPL работает (ввод команд, вывод результатов)
- [x] **Hex Dump работает** (видим каждый байт JIT-кода)
- [ ] **Crash Handler** (ошибки не убивают REPL)
- [x] Переменные A-Z сохраняют значения
- [x] Арифметика +, -, *, /
- [x] PRINT выводит числа и строки
- [x] GOTO работает
- [x] IF/THEN работает
- [x] Программы можно сохранять/загружать
- [ ] **Тесты проходят** (минимум 10 автотестов)
- [ ] **Работает на Linux И Windows**

---

## 📝 Версионирование

```
v0.1.0 — REPL + JIT (Phase 0-2)        ✓ DONE
v0.2.0 — Переменные + Арифметика       ✓ DONE (Phase 3-4)
v0.3.0 — Управление потоком            ✓ DONE (Phase 5)
v0.4.0 — Циклы                         ✓ DONE (Phase 6: FOR/NEXT)
v0.5.0 — Строки                        ✓ DONE (Phase 7: String Arena)
v0.6.0 — FOR/NEXT with loop_stack      ✓ DONE (Phase 6 complete)
v0.7.0 — Strings: A$, PRINT, concat    ✓ DONE (Phase 7 complete, 9216 bytes)
v0.8.0 — Persistence: INPUT/SAVE/LOAD  ✓ DONE (Phase 8 complete, 10752 bytes)
v0.9.0 — SIMD: AVX2 vector operations  ✓ DONE (Phase 9 complete, 11776 bytes)
v0.10.0 — GOSUB/RETURN                 ✓ DONE (Phase 10: Subroutines, 12288 bytes)
v0.11.0 — REM, multiline IF            ✓ DONE (Phase 11: Comments & Control)
v0.12.0 — FUNC/ENDFUNC/LOCAL           ✓ DONE (Phase 12.1-12.2: Functions)
v0.12.1 — Context stack for recursion  ✓ DONE (Phase 12.3)
v0.12.2 — Bug fixes for LOCAL          ✓ DONE (Phase 12.4)
v0.12.3 — Full recursion support       ✓ DONE (Phase 12 COMPLETE, 13824 bytes)
v0.13.0 — FFI: MSGBOX, Windows API     ✓ DONE (Phase 13 COMPLETE, 14336 bytes)
v0.14.0 — GDI Graphics                 ✓ DONE (Phase 14: Windows, Pixels, Lines, 15360 bytes)
v0.15.0 — Floating-Point               ✓ DONE (Phase 15: Full double support, 17408 bytes)
v0.16.0 — Heap Memory                  ✓ DONE (Phase 16: Dynamic arrays up to 1MB, 18432 bytes)
v0.17.0 — BLOAD/BSAVE                  ✓ DONE (Phase 17: Binary file I/O, 19456 bytes)
v0.18.0 — MATMUL/VRELU/Neural          ✓ DONE (Phase 18-19: Neural Engine, 20992 bytes) ← ТЕКУЩАЯ!
v1.0.0 — Production Ready
```

---

## 🚀 Начало работы

```bash
# 1. Установить FASM
# Linux: sudo apt install fasm
# Windows: скачать с flatassembler.net

# 2. Создать первый файл
# src/main.asm

# 3. Собрать
fasm src/main.asm titan
# или
fasm src/main.asm titan.exe  (Windows)

# 4. Запустить
./titan
```

---

## ⚠️ Известные ловушки (Lessons Learned)

> Эти пункты могут съесть недели времени. Будь осторожен!

| Ловушка | Описание | Решение |
|---------|----------|---------|
| **Register Allocator** | Graph Coloring — NP-полная задача | Для MVP: всегда spill в память |
| **x64 Encoding** | REX префиксы, ModR/M — ад | Hex Dump обязателен для отладки |
| **Windows vs Linux** | Разные ABI, разные syscall | Изоляция в `platform/*.asm` |
| **Строки** | Нет null-terminator | Хранить длину явно (Pascal-style) |
| **Вложенные циклы** | FOR внутри FOR | Стек состояний циклов |
| **Рекурсия** | GOSUB внутри GOSUB | Правильное сохранение RBP/RSP |

---

*Дата создания: 2025-12-17*
*Последнее обновление: 2025-12-18*
*Проект: TITAN Language*
*Статус: Phase 19 COMPLETE — Neural Engine (MATMUL/VRELU/MNIST) — v0.18.0, 20992 bytes (21 KB)*
*Достижения: MNIST Inference 96.37% ✓, Mandelbrot GDI ✓, Factorial/Fibonacci ✓, FFI MSGBOX ✓*

---

## 👤 Авторы

- **mjojo** — Vitaly.G
- **GLK-Dev** — [GitHub](https://github.com/GLK-Dev)

*© 2025 mjojo & GLK-Dev. All rights reserved.*
