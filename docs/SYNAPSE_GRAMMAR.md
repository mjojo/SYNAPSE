# SYNAPSE Language — Формальная Грамматика (BNF)

**Версия:** 0.1 (Draft)  
**Статус:** В разработке  
**Основа:** SYNAPSE Syntax Specification v0.1

---

## 📖 Нотация

```
<rule>          ::= определение правила
|                   альтернатива (ИЛИ)
[ ... ]             необязательный элемент (0 или 1)
{ ... }             повторение (0 или более)
{ ... }+            повторение (1 или более)
( ... )             группировка
'...'               терминал (литерал)
"..."               строковый литерал
KEYWORD             ключевое слово (uppercase)
<rule>              нетерминал (в угловых скобках)
```

---

## 1. Лексические Элементы (Tokens)

### 1.1 Базовые Символы

```bnf
<letter>            ::= 'A'..'Z' | 'a'..'z'
<digit>             ::= '0'..'9'
<hex-digit>         ::= <digit> | 'A'..'F' | 'a'..'f'
<underscore>        ::= '_'
<whitespace>        ::= ' ' | '\t'
<newline>           ::= '\n' | '\r\n'
```

### 1.2 Числовые Литералы

```bnf
<integer>           ::= <digit> { <digit> }
                      | '0x' <hex-digit> { <hex-digit> }
                      | '0b' ('0' | '1') { '0' | '1' }

<float>             ::= <integer> '.' <integer> [ <exponent> ]
                      | <integer> <exponent>

<exponent>          ::= ('e' | 'E') ['+' | '-'] <integer>

<number>            ::= <integer> | <float>
```

**Примеры:**
- `42`, `0xFF`, `0b1010` — целые
- `3.14`, `2.5e-3`, `1E10` — float

### 1.3 Строковые Литералы

```bnf
<string>            ::= '"' { <string-char> } '"'
<string-char>       ::= <any-char-except-quote-or-backslash>
                      | <escape-sequence>

<escape-sequence>   ::= '\\' ('n' | 'r' | 't' | '\\' | '"' | '0' | 'x' <hex-digit> <hex-digit>)
```

**Примеры:**
- `"Hello World"`
- `"Line1\nLine2"`
- `"Tab:\tValue"`

### 1.4 Идентификаторы

```bnf
<identifier>        ::= <letter> { <letter> | <digit> | <underscore> }
```

**Примеры:**
- `x`, `counter`, `my_variable`, `Layer1`

### 1.5 Отступы (Indentation)

```bnf
<indent>            ::= <INDENT-TOKEN>     ; Увеличение отступа
<dedent>            ::= <DEDENT-TOKEN>     ; Уменьшение отступа
<indent-unit>       ::= 4 × ' '            ; 4 пробела на уровень
```

> **Примечание:** Лексер генерирует токены `INDENT` и `DEDENT` при изменении уровня отступа.

---

## 2. Типы Данных

### 2.1 Базовые Типы

```bnf
<base-type>         ::= 'int' | 'int8' | 'int16' | 'int32' | 'int64'
                      | 'uint8' | 'uint16' | 'uint32' | 'uint64'
                      | 'f32' | 'f64'
                      | 'bool'
                      | 'byte'
                      | 'string'
                      | 'ptr'
```

### 2.2 Составные Типы

```bnf
<type>              ::= <base-type>
                      | <tensor-type>
                      | <array-type>
                      | <hash-type>
                      | <generic-type>
                      | <identifier>          ; Пользовательский тип

<tensor-type>       ::= 'tensor' '<' <base-type> ',' '[' <shape-list> ']' '>'
<shape-list>        ::= <expression> { ',' <expression> }

<array-type>        ::= '[' <type> ';' <expression> ']'
                      | 'Vec' '<' <type> '>'

<hash-type>         ::= 'hash256' | 'sign' | 'block' | 'transaction'

<generic-type>      ::= <identifier> '<' <type> { ',' <type> } '>'
```

**Примеры:**
```synapse
tensor<f32, [784, 128]>
[int; 10]
Vec<string>
hash256
```

---

## 3. Выражения (Expressions)

### 3.1 Приоритет Операций

От низшего к высшему:

1. `or` (логическое ИЛИ)
2. `and` (логическое И)
3. `not` (логическое НЕ)
4. `==`, `!=`, `<`, `>`, `<=`, `>=` (сравнение)
5. `|` (побитовое ИЛИ)
6. `^` (побитовое XOR)
7. `&` (побитовое И)
8. `<<`, `>>` (сдвиги)
9. `+`, `-` (сложение, вычитание)
10. `*`, `/`, `%`, `//` (умножение, деление)
11. `**` (возведение в степень)
12. Унарные: `-`, `~`, `not`
13. Вызов функции, индексация, доступ к полю
14. Атомы: литералы, идентификаторы, скобки

### 3.2 Грамматика Выражений

```bnf
<expression>        ::= <or-expr>

<or-expr>           ::= <and-expr> { 'or' <and-expr> }

<and-expr>          ::= <not-expr> { 'and' <not-expr> }

<not-expr>          ::= [ 'not' ] <comparison-expr>

<comparison-expr>   ::= <bitor-expr> [ <comparison-op> <bitor-expr> ]

<comparison-op>     ::= '==' | '!=' | '<' | '>' | '<=' | '>='

<bitor-expr>        ::= <xor-expr> { '|' <xor-expr> }

<xor-expr>          ::= <bitand-expr> { '^' <bitand-expr> }

<bitand-expr>       ::= <shift-expr> { '&' <shift-expr> }

<shift-expr>        ::= <add-expr> { ('<<' | '>>') <add-expr> }

<add-expr>          ::= <mul-expr> { ('+' | '-') <mul-expr> }

<mul-expr>          ::= <power-expr> { ('*' | '/' | '%' | '//') <power-expr> }

<power-expr>        ::= <unary-expr> [ '**' <power-expr> ]   ; Правоассоциативный

<unary-expr>        ::= ('-' | '~' | 'not') <unary-expr>
                      | <postfix-expr>

<postfix-expr>      ::= <primary> { <postfix-op> }

<postfix-op>        ::= '(' [ <arg-list> ] ')'              ; Вызов функции
                      | '[' <expression> ']'                 ; Индексация
                      | '.' <identifier>                     ; Доступ к полю
                      | '.' <identifier> '(' [ <arg-list> ] ')' ; Вызов метода

<primary>           ::= <number>
                      | <string>
                      | <identifier>
                      | 'true' | 'false'
                      | '(' <expression> ')'
                      | <tensor-literal>
                      | <array-literal>
                      | <struct-literal>

<arg-list>          ::= <expression> { ',' <expression> }
```

### 3.3 Тензорные Операторы

```bnf
<tensor-op>         ::= '<dot>'         ; Скалярное произведение / MATMUL
                      | '<+>'           ; Поэлементное сложение
                      | '<->'           ; Поэлементное вычитание
                      | '<*>'           ; Поэлементное умножение
                      | '</>'           ; Поэлементное деление

; Тензорные операции имеют тот же приоритет, что и соответствующие скалярные
<tensor-expr>       ::= <expression> <tensor-op> <expression>
```

### 3.4 Литералы Коллекций

```bnf
<array-literal>     ::= '[' [ <expression> { ',' <expression> } ] ']'

<tensor-literal>    ::= 'tensor' '(' <array-literal> ')'
                      | 'tensor' '.' <tensor-init> '(' <arg-list> ')'

<tensor-init>       ::= 'zeros' | 'ones' | 'rand' | 'eye'

<struct-literal>    ::= <identifier> '{' [ <field-init> { ',' <field-init> } ] '}'

<field-init>        ::= <identifier> ':' <expression>
```

**Примеры:**
```synapse
[1, 2, 3, 4]
tensor.zeros([784, 128])
Point { x: 10.0, y: 20.0 }
```

---

## 4. Объявления (Declarations)

### 4.1 Переменные

```bnf
<var-decl>          ::= <var-modifier> <identifier> [ ':' <type> ] [ '=' <expression> ]

<var-modifier>      ::= 'let'           ; Неизменяемая
                      | 'mut'           ; Изменяемая
                      | 'const'         ; Константа времени компиляции
                      | 'chain'         ; В Ledger Zone
                      | 'global'        ; Глобальная
                      | 'chain' 'let'   ; Блокчейн неизменяемая
                      | 'global' 'chain' 'let'  ; Глобальная блокчейн
```

**Примеры:**
```synapse
let x = 42
let y: int = 100
mut counter = 0
const PI: f64 = 3.14159
chain let balance: int = 1000
```

### 4.2 Функции

```bnf
<func-decl>         ::= [ <func-modifier> ] 'fn' <identifier> '(' [ <param-list> ] ')' [ '->' <type> ] ':' <newline> <indent> <block> <dedent>

<func-modifier>     ::= 'contract'      ; Смарт-контракт
                      | 'neuron'        ; Функция активации
                      | 'unsafe'        ; Небезопасная
                      | 'contract' <sign-clause>

<sign-clause>       ::= 'signed_by' '(' <identifier> ')'

<param-list>        ::= <param> { ',' <param> }

<param>             ::= <identifier> ':' <type>
```

**Примеры:**
```synapse
fn add(a: int, b: int) -> int:
    return a + b

contract fn transfer(amount: int) signed_by(Admin):
    balance -= amount
    chain.commit()

neuron fn relu(x: f32) -> f32:
    return max(0.0, x)
```

### 4.3 Структуры

```bnf
<struct-decl>       ::= 'struct' <identifier> ':' <newline> <indent> { <field-decl> <newline> } <dedent>

<field-decl>        ::= <identifier> ':' <type>
```

**Пример:**
```synapse
struct Point:
    x: f32
    y: f32
```

### 4.4 Перечисления (Enums)

```bnf
<enum-decl>         ::= 'enum' <identifier> [ '<' <type-param-list> '>' ] ':' <newline> <indent> { <variant> <newline> } <dedent>

<type-param-list>   ::= <identifier> { ',' <identifier> }

<variant>           ::= <identifier> [ '(' <type> ')' ]
```

**Пример:**
```synapse
enum Result<T>:
    Ok(T)
    Error(string)
```

### 4.5 Модули

```bnf
<module-decl>       ::= 'module' <identifier> ':' <newline> <indent> { <declaration> } <dedent>

<import-stmt>       ::= 'import' <module-path>
                      | 'from' <module-path> 'import' <import-list>

<module-path>       ::= <identifier> { '.' <identifier> }

<import-list>       ::= <identifier> { ',' <identifier> }
                      | '*'
```

---

## 5. Операторы (Statements)

### 5.1 Блок Кода

```bnf
<block>             ::= { <statement> <newline> }+

<statement>         ::= <var-decl>
                      | <assignment>
                      | <if-stmt>
                      | <for-stmt>
                      | <while-stmt>
                      | <loop-stmt>
                      | <match-stmt>
                      | <return-stmt>
                      | <break-stmt>
                      | <continue-stmt>
                      | <expression-stmt>
                      | <unsafe-block>
                      | <asm-block>
                      | <chain-stmt>
```

### 5.2 Присваивание

```bnf
<assignment>        ::= <lvalue> '=' <expression>
                      | <lvalue> <compound-op> <expression>

<lvalue>            ::= <identifier>
                      | <postfix-expr>

<compound-op>       ::= '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>>='
```

### 5.3 Условия (if/elif/else)

```bnf
<if-stmt>           ::= 'if' <expression> ':' <newline> <indent> <block> <dedent>
                        { 'elif' <expression> ':' <newline> <indent> <block> <dedent> }
                        [ 'else' ':' <newline> <indent> <block> <dedent> ]
```

**Пример:**
```synapse
if x > 0:
    print("Positive")
elif x < 0:
    print("Negative")
else:
    print("Zero")
```

### 5.4 Циклы

```bnf
<for-stmt>          ::= 'for' <identifier> 'in' <iterable> ':' <newline> <indent> <block> <dedent>

<iterable>          ::= <range-expr>
                      | <expression>

<range-expr>        ::= <expression> '..' <expression> [ '..' <expression> ]   ; start..end или start..end..step

<while-stmt>        ::= 'while' <expression> ':' <newline> <indent> <block> <dedent>

<loop-stmt>         ::= 'loop' ':' <newline> <indent> <block> <dedent>
```

**Примеры:**
```synapse
for i in 0..10:
    print(i)

for i in 0..100..2:     ; С шагом 2
    print(i)

while running:
    process()

loop:
    if done:
        break
```

### 5.5 Pattern Matching

```bnf
<match-stmt>        ::= 'match' <expression> ':' <newline> <indent> { <match-arm> } <dedent>

<match-arm>         ::= <pattern> ':' <newline> <indent> <block> <dedent>

<pattern>           ::= <literal>
                      | <identifier>
                      | '_'                 ; Wildcard
                      | <range-pattern>
                      | <enum-pattern>

<range-pattern>     ::= <literal> '..' <literal>

<enum-pattern>      ::= <identifier> '(' <identifier> ')'
```

**Пример:**
```synapse
match value:
    0:
        print("Zero")
    1..10:
        print("Small")
    _:
        print("Other")
```

### 5.6 Управление Потоком

```bnf
<return-stmt>       ::= 'return' [ <expression> ]

<break-stmt>        ::= 'break'

<continue-stmt>     ::= 'continue'

<pass-stmt>         ::= 'pass'
```

---

## 6. Unsafe и Inline ASM

### 6.1 Unsafe Блоки

```bnf
<unsafe-block>      ::= 'unsafe' ':' <newline> <indent> <block> <dedent>
```

### 6.2 Inline Assembler

```bnf
<asm-block>         ::= 'unsafe' 'asm' [ '(' <asm-bindings> ')' ] ':' <newline> <indent> { <asm-line> <newline> } <dedent>

<asm-bindings>      ::= <asm-binding> { ',' <asm-binding> }

<asm-binding>       ::= <identifier> '=' <register>

<register>          ::= 'RAX' | 'RBX' | 'RCX' | 'RDX' | 'RSI' | 'RDI' | 'R8'..'R15'
                      | 'XMM0'..'XMM15' | 'YMM0'..'YMM15' | 'ZMM0'..'ZMM31'

<asm-line>          ::= <asm-instruction>

<asm-instruction>   ::= <mnemonic> [ <asm-operand> { ',' <asm-operand> } ]
```

**Пример:**
```synapse
unsafe asm(result=RAX):
    MOV RAX, 1
    CPUID
    MOV [result], RBX
```

---

## 7. Блокчейн Конструкции

### 7.1 Chain Операции

```bnf
<chain-stmt>        ::= 'chain' '.' <chain-method> '(' [ <arg-list> ] ')'

<chain-method>      ::= 'begin'         ; Начать транзакцию
                      | 'commit'        ; Зафиксировать
                      | 'rollback'      ; Откатить
                      | 'verify'        ; Проверить целостность
```

---

## 8. Программа (Top-Level)

```bnf
<program>           ::= { <top-level-item> }

<top-level-item>    ::= <import-stmt> <newline>
                      | <func-decl>
                      | <struct-decl>
                      | <enum-decl>
                      | <module-decl>
                      | <var-decl> <newline>
```

---

## 9. Комментарии

```bnf
<comment>           ::= '//' { <any-char-except-newline> }    ; Однострочный
                      | '/*' { <any-char> } '*/'              ; Многострочный
                      | '///' { <any-char-except-newline> }   ; Документационный
```

---

## 10. Зарезервированные Слова

```
; Объявления
let, mut, const, fn, struct, enum, module, import, from

; Модификаторы функций
contract, neuron, unsafe, signed_by

; Управление потоком
if, elif, else, for, while, loop, match, break, continue, return, pass

; Базовые типы
int, int8, int16, int32, int64
uint8, uint16, uint32, uint64
f32, f64, bool, byte, string, ptr

; Составные типы
tensor, Vec, hash256, sign, block, transaction

; Логические
and, or, not, true, false

; Блокчейн
chain, global

; Специальные
asm, in
```

---

## 11. Полные Примеры

### 11.1 Hello World

```synapse
fn main():
    print("Hello, SYNAPSE!")
```

**AST:**
```
Program
└── FuncDecl "main"
    └── Block
        └── ExprStmt
            └── Call "print"
                └── String "Hello, SYNAPSE!"
```

### 11.2 Нейросеть

```synapse
import core.ai

fn forward(input: tensor<f32, [784]>, weights: tensor<f32, [784, 128]>) -> tensor<f32, [128]>:
    let hidden = input <dot> weights
    return hidden.relu()
```

**AST:**
```
Program
├── Import "core.ai"
└── FuncDecl "forward"
    ├── Params
    │   ├── Param "input" : tensor<f32, [784]>
    │   └── Param "weights" : tensor<f32, [784, 128]>
    ├── ReturnType: tensor<f32, [128]>
    └── Block
        ├── VarDecl "hidden"
        │   └── TensorOp <dot>
        │       ├── Ident "input"
        │       └── Ident "weights"
        └── Return
            └── MethodCall "relu"
                └── Ident "hidden"
```

### 11.3 Смарт-контракт

```synapse
chain let balance: int = 1000

contract fn transfer(to: hash256, amount: int) signed_by(Owner):
    if amount > balance:
        return Error("Insufficient funds")
    
    balance -= amount
    chain.commit()
    return Ok(amount)
```

---

## 12. Отличия от TITAN BASIC

| Элемент | TITAN (BASIC) | SYNAPSE |
|---------|---------------|---------|
| Переменные | `DIM A(100)`, `LET X = 5` | `let a: tensor<100>`, `let x = 5` |
| Блоки | `THEN`/`ENDIF`, `FOR`/`NEXT` | Отступы (`:` + indent) |
| Функции | `FUNC NAME` / `ENDFUNC` | `fn name():` |
| Типы | Неявные | Явные (`int`, `f32`, `tensor`) |
| Строки | `A$` | `string` тип |
| Комментарии | `REM` | `//`, `/* */`, `///` |
| Переход | `GOTO 100` | Структурное программирование |
| Массивы | `DIM A(100)` | `[int; 100]`, `Vec<int>` |

---

*© 2025 mjojo & GLK-Dev. SYNAPSE Language Grammar.*
