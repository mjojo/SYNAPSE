# SYNAPSE v2 SYNTAX SPECIFICATION

**Версия:** 0.1 (Draft)  
**Статус:** В разработке (после Singularity v1)  
**Дата:** 3 января 2026  
**Основа:** Гибрид Python (читаемость) + Rust (типизация) + ASM (контроль)

> *"v1 Singularity достигнут — компилятор скомпилировал сам себя.  
> v2 — следующий шаг: Python-style синтаксис с отступами."*

---

## 1. Общие Принципы

### 1.1 Философия Синтаксиса

| Принцип | Описание |
|---------|----------|
| **Читаемость** | Код должен читаться как текст |
| **Явность** | Типы указываются явно (с выводом типов для простых случаев) |
| **Минимализм** | Минимум шума (без `public static void`) |
| **Контроль** | Прямой доступ к железу через `unsafe` |

### 1.2 Отличия от TITAN BASIC

| TITAN (BASIC) | SYNAPSE v1 (текущий) | SYNAPSE v2 (план) |
|---------------|----------------------|-------------------|
| `DIM A(100)` | `let a = alloc(100)` | `let a: tensor<100>` |
| `LET X = 5` | `let x = 5` | `let x = 5` |
| `FUNC NAME` / `ENDFUNC` | `fn name { }` | `fn name():` + отступы |
| `IF ... THEN` / `ENDIF` | `if cond { }` | `if cond:` + отступы |
| `FOR ... NEXT` | `while cond { }` | `for ... in ...:` |
| `GOTO label` | Нет | Нет |

> **Примечание:** SYNAPSE v1 достиг Singularity 3 января 2026.  
> v2 добавит Python-style отступы вместо фигурных скобок.

---

## 2. Структура Блоков

### 2.1 Отступы (Indentation-Based)

Блоки кода определяются отступами (4 пробела), как в Python.

```synapse
fn example():
    if condition:
        do_something()
        do_more()
    else:
        do_other()
```

### 2.2 Токены Лексера

При разборе генерируются специальные токены:

| Токен | Генерируется когда |
|-------|-------------------|
| `INDENT` | Отступ увеличился |
| `DEDENT` | Отступ уменьшился |
| `NEWLINE` | Конец строки |
| `COLON` | Начало блока (`:`) |

---

## 3. Переменные и Типы

### 3.1 Объявление Переменных

```synapse
// Неизменяемая переменная (по умолчанию)
let pi = 3.14159
let name: string = "SYNAPSE"

// Изменяемая переменная
mut counter = 0
counter = counter + 1

// С явным типом
let x: int = 42
let y: f64 = 3.14
```

### 3.2 Ключевые Слова

| Ключевое слово | Значение |
|----------------|----------|
| `let` | Объявление неизменяемой переменной |
| `mut` | Объявление изменяемой переменной |
| `const` | Константа времени компиляции |
| `chain` | Переменная в Ledger Zone (блокчейн) |
| `global` | Глобальная переменная |

### 3.3 Базовые Типы

```synapse
// Целые числа
let a: int = 42           // int64 по умолчанию
let b: int8 = -128
let c: uint32 = 0xFFFFFFFF

// Числа с плавающей точкой
let x: f32 = 3.14
let y: f64 = 2.718281828

// Булевы
let flag: bool = true

// Байты
let byte_val: byte = 0xFF

// Указатели
let ptr: ptr = 0xB8000
```

### 3.4 Нейро-Типы

```synapse
// Тензоры (многомерные массивы)
let weights: tensor<f32, [784, 128]>
let input: tensor<f32, [784]>
let batch: tensor<f32, [64, 784]>

// Квантованные веса (для VNNI)
let quant_weights: tensor<quant8, [784, 128]>
```

### 3.5 Крипто-Типы

```synapse
let hash: hash256 = sha256("data")
let signature: sign = ed25519_sign(data, private_key)
let block: block = Block { data: payload, prev_hash: last.hash }
```

---

## 4. Функции

### 4.1 Объявление Функций

```synapse
// Простая функция
fn greet():
    print("Hello, SYNAPSE!")

// С параметрами и возвратом
fn add(a: int, b: int) -> int:
    return a + b

// Рекурсия
fn factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)
```

### 4.2 Типы Функций

| Тип | Синтаксис | Описание |
|-----|-----------|----------|
| **Обычная** | `fn name():` | Стандартная функция |
| **Контракт** | `contract fn name():` | Выполняется как транзакция |
| **Нейрон** | `neuron fn name():` | Функция активации |
| **Unsafe** | `unsafe fn name():` | Доступ к низкому уровню |

### 4.3 Контрактные Функции

```synapse
// Требуется подпись для вызова
contract fn transfer(amount: int) signed_by(Admin):
    if amount > balance:
        return Error("Insufficient funds")
    
    balance -= amount
    chain.commit()
```

### 4.4 Нейронные Функции

```synapse
// Встроенная оптимизация через SIMD
neuron fn relu(x: f32) -> f32:
    return max(0.0, x)

neuron fn sigmoid(x: f32) -> f32:
    return 1.0 / (1.0 + exp(-x))
```

---

## 5. Управляющие Конструкции

### 5.1 Условия (if/else)

```synapse
if condition:
    do_something()
elif other_condition:
    do_other()
else:
    do_default()
```

### 5.2 Циклы

```synapse
// For с диапазоном
for i in 0..10:
    print(i)

// For с коллекцией
for item in collection:
    process(item)

// For с индексом и значением
for i, value in enumerate(array):
    print(i, value)

// While
while condition:
    do_work()

// Loop (бесконечный)
loop:
    if should_break:
        break
```

### 5.3 Match (Pattern Matching)

```synapse
match value:
    0:
        print("Zero")
    1..10:
        print("Small")
    _:
        print("Large")
```

---

## 6. Операторы

### 6.1 Арифметические

| Оператор | Описание |
|----------|----------|
| `+`, `-`, `*`, `/` | Базовые операции |
| `%` | Остаток от деления |
| `**` | Возведение в степень |
| `//` | Целочисленное деление |

### 6.2 Сравнения

| Оператор | Описание |
|----------|----------|
| `==`, `!=` | Равенство / неравенство |
| `<`, `>`, `<=`, `>=` | Сравнения |

### 6.3 Логические

| Оператор | Описание |
|----------|----------|
| `and`, `or`, `not` | Логические операции |

### 6.4 Битовые

| Оператор | Описание |
|----------|----------|
| `&`, `\|`, `^` | AND, OR, XOR |
| `<<`, `>>` | Сдвиги |
| `~` | NOT |

### 6.5 Тензорные (Neural)

| Оператор | Описание | ASM эквивалент |
|----------|----------|----------------|
| `<dot>` | Скалярное произведение / MATMUL | VFMADD |
| `<+>` | Поэлементное сложение (SIMD) | VADDPS |
| `<*>` | Поэлементное умножение (SIMD) | VMULPS |
| `<->` | Поэлементное вычитание (SIMD) | VSUBPS |

```synapse
let a: tensor<f32, [256]>
let b: tensor<f32, [256]>

let sum = a <+> b      // Векторное сложение
let product = a <*> b  // Векторное умножение
let result = a <dot> b // Скалярное произведение
```

---

## 7. Структуры Данных

### 7.1 Массивы

```synapse
let arr: [int; 10]            // Статический массив
let dynamic: Vec<int>         // Динамический массив
let matrix: [[f32; 10]; 10]   // 2D массив
```

### 7.2 Структуры

```synapse
struct Point:
    x: f32
    y: f32

struct NeuralLayer:
    weights: tensor<f32, [?, ?]>
    bias: tensor<f32, [?]>
    activation: neuron
```

### 7.3 Enums

```synapse
enum Result<T>:
    Ok(T)
    Error(string)

enum Activation:
    ReLU
    Sigmoid
    Tanh
```

---

## 8. Модули и Импорты

### 8.1 Импорт Модулей

```synapse
import core.io
import core.ai
import core.crypto

// Импорт конкретных элементов
from core.ai import tensor, matmul
from core.crypto import sha256, ed25519_sign
```

### 8.2 Определение Модуля

```synapse
module neural_network:
    
    fn create_layer(input_size: int, output_size: int) -> NeuralLayer:
        return NeuralLayer {
            weights: tensor.zeros([input_size, output_size]),
            bias: tensor.zeros([output_size]),
            activation: relu
        }
```

---

## 9. Unsafe и ASM

### 9.1 Unsafe Блоки

```synapse
fn direct_memory_access():
    unsafe:
        let ptr: ptr = 0xB8000
        *ptr = 0x0F41  // Записать 'A' в VGA буфер
```

### 9.2 Inline Assembler

```synapse
fn cpuid_check() -> int:
    let result: int = 0
    
    unsafe asm:
        MOV EAX, 1
        CPUID
        MOV [result], ECX
    
    return result
```

### 9.3 Именованные ASM

```synapse
fn optimized_copy(dst: ptr, src: ptr, size: int):
    unsafe asm(dst=RDI, src=RSI, size=RCX):
        REP MOVSB
```

---

## 10. Блокчейн Конструкции

### 10.1 Переменные Ledger Zone

```synapse
// Переменная в блокчейн-памяти
chain let balance: int = 1000

// Глобальная сетевая переменная
global chain let shared_state: List<Transaction>
```

### 10.2 Транзакции и Откаты

```synapse
// Транзакция
chain.begin()
balance -= 100
recipient += 100
chain.commit()

// Откат
chain.rollback(5)  // На 5 транзакций назад
```

### 10.3 Проверка Целостности

```synapse
if chain.verify():
    print("Memory integrity OK")
else:
    panic("Memory corrupted!")
```

---

## 11. Комментарии

```synapse
// Однострочный комментарий

/*
 * Многострочный
 * комментарий
 */

/// Документационный комментарий
/// Поддерживает Markdown
fn documented_function():
    pass
```

---

## 12. Примеры Полных Программ

### 12.1 Hello World

```synapse
fn main():
    print("Welcome to SYNAPSE!")
```

### 12.2 Neural Network Inference

```synapse
import core.ai
import core.io

fn main():
    // Загрузка весов
    let w1: tensor<f32, [784, 128]> = load_tensor("w1.bin")
    let w2: tensor<f32, [128, 10]> = load_tensor("w2.bin")
    
    // Входное изображение (28x28 = 784)
    let input: tensor<f32, [784]> = load_image("digit.png")
    
    // Forward pass
    let hidden = (input <dot> w1).relu()
    let output = hidden <dot> w2
    
    // Результат
    let prediction = output.argmax()
    print("Predicted digit:", prediction)
```

### 12.3 Smart Contract

```synapse
import core.crypto
import core.chain

chain let balance: int = 10000
chain let transactions: List<Transaction>

contract fn transfer(to: hash256, amount: int) signed_by(Owner):
    if amount > balance:
        return Error("Insufficient funds")
    
    balance -= amount
    
    let tx = Transaction {
        from: Owner.pubkey,
        to: to,
        amount: amount,
        timestamp: now()
    }
    
    transactions.append(tx)
    chain.commit()
    
    return Ok(tx.hash)
```

### 12.4 Bare Metal VGA Output

```synapse
import core.vga

fn main():
    let message = "SYNAPSE OS Booting..."
    
    vga.clear(Color.Black)
    vga.set_cursor(0, 0)
    vga.print(message, Color.White)
    
    // Прямой доступ к VGA буферу
    unsafe:
        let vga_ptr: ptr = 0xB8000
        for i in 0..80*25:
            *(vga_ptr + i*2) = ' '
            *(vga_ptr + i*2 + 1) = 0x0F
```

---

## 13. Зарезервированные Слова

```
// Объявления
let, mut, const, fn, struct, enum, module, import, from

// Типы функций
contract, neuron, unsafe

// Управление потоком
if, elif, else, for, while, loop, match, break, continue, return

// Типы
int, int8, int16, int32, int64, uint8, uint16, uint32, uint64
f32, f64, bool, byte, ptr, string
tensor, hash256, sign, block

// Модификаторы
chain, global, signed_by

// Логика
and, or, not, true, false

// Специальные
asm, pass, _
```

---

*© 2025-2026 mjojo & GLK-Dev. SYNAPSE v2 Syntax Specification.*

---

**История:**
- v1 Singularity: 3 января 2026 — `"I am alive!"`
- v2 Draft: В разработке — Python-style синтаксис
