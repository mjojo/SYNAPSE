# SYNAPSE Development Tasks

## Phase 1: Рефакторинг и Новое Лицо

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
- [x] Создать `examples/test_syntax.syn` — тестовый файл
- [x] Скомпилировать и протестировать лексер ✅ 5120 bytes

### 1.3 Парсер Типов ✅ COMPLETE
- [x] Создать `src/parser_v2.asm` — парсер
- [x] Создать `src/parser_test.asm` — интегрированный тест
- [x] Реализовать парсинг `let x: type = value`
- [x] Реализовать парсинг `tensor<T, [shape]>` — дженерики!
- [x] Реализовать парсинг `fn name():` — функции
- [x] Скомпилировать и протестировать ✅ 5632 bytes

### 1.4 Синтаксис v0.1
- [ ] Парсинг `fn name():` → вызов парсера блока
- [ ] Парсинг `if/elif/else:`
- [ ] Парсинг `for x in range:`
- [ ] Парсинг `return value`

### 1.5 JIT-адаптация
- [ ] Модифицировать `jit_emit.asm` для нового AST
- [ ] Генерация кода для функций
- [ ] Генерация кода для блоков

---

## Документация (Готово)

- [x] `docs/SYNAPSE_SPEC.md` — Спецификация языка
- [x] `docs/SYNAPSE_ROADMAP.md` — Дорожная карта
- [x] `docs/SYNAPSE_SYNTAX.md` — Спецификация синтаксиса
- [x] `docs/SYNAPSE_GRAMMAR.md` — Формальная BNF грамматика
- [x] `docs/TITAN_ANALYSIS.md` — Анализ базы TITAN

---

## Файлы Phase 1.2

| Файл | Статус | Описание |
|------|--------|----------|
| `include/synapse_tokens.inc` | ✅ | Константы токенов SYNAPSE |
| `src/lexer_v2.asm` | ✅ | Основной лексер с INDENT/DEDENT |
| `src/lexer_test.asm` | ✅ | Тестовый драйвер |
| `examples/test_syntax.syn` | ✅ | Пример SYNAPSE кода |

---

## Следующие шаги

1. **Сборка лексера:**
   ```cmd
   cd src
   fasm lexer_test.asm lexer_test.exe
   ```

2. **Тестирование:**
   ```cmd
   lexer_test.exe
   ```

3. **Ожидаемый вывод:**
   ```
   [KEYWORD=fn L1:C0]
   [IDENT=main L1:C3]
   [OPERATOR=40 L1:C7]    ; (
   [OPERATOR=41 L1:C8]    ; )
   [OPERATOR=52 L1:C9]    ; :
   [NEWLINE L1:C10]
   [INDENT L2:C0]
   [KEYWORD=let L2:C4]
   ...
   ```

---

*Last updated: 2025-12-20*
