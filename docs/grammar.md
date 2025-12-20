# TITAN Language — Формальная грамматика

> Спецификация синтаксиса v0.13.0
> © 2025 mjojo & GLK-Dev

> [!NOTE]
> Это грамматика текущего TITAN с BASIC-синтаксисом.
> Для грамматики нового языка **SYNAPSE** см. [SYNAPSE_GRAMMAR.md](SYNAPSE_GRAMMAR.md)

---

## 📖 Нотация

```
<rule>      ::= определение правила
|               альтернатива (ИЛИ)
[ ... ]         необязательный элемент (0 или 1)
{ ... }         повторение (0 или более)
( ... )         группировка
'...'           терминал (литерал)
KEYWORD         ключевое слово
```

---

## 🔤 Лексические элементы (Tokens)

### Числа
```bnf
<digit>         ::= '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
<integer>       ::= <digit> { <digit> }
<float>         ::= <integer> '.' <integer>
<number>        ::= <integer> | <float>
```

### Строки
```bnf
<string>        ::= '"' { <any-char-except-quote> } '"'
```

### Идентификаторы
```bnf
<letter>        ::= 'A'..'Z' | 'a'..'z'
<identifier>    ::= <letter> { <letter> | <digit> | '_' }
<variable>      ::= <letter> [ '$' ]
                    ; A, B, X — числовые переменные
                    ; A$, B$ — строковые переменные
```

### Метки строк
```bnf
<line-number>   ::= <integer>
                    ; 10, 20, 100, 9999
```

---

## 🎯 Операторы

### Арифметические
```bnf
<add-op>        ::= '+' | '-'
<mul-op>        ::= '*' | '/'
<power-op>      ::= '^'
```

### Сравнения
```bnf
<rel-op>        ::= '=' | '<>' | '<' | '>' | '<=' | '>='
```

### Логические
```bnf
<logic-op>      ::= 'AND' | 'OR' | 'NOT'
```

### Присваивание
```bnf
<assign-op>     ::= '='
```

---

## 📐 Выражения (Expressions)

### Приоритет операций (от низшего к высшему)
1. `OR`
2. `AND`
3. `NOT`
4. `=`, `<>`, `<`, `>`, `<=`, `>=`
5. `+`, `-`
6. `*`, `/`
7. `^`
8. Унарный `-`
9. `(`, `)`

### Грамматика выражений
```bnf
<expression>    ::= <or-expr>

<or-expr>       ::= <and-expr> { 'OR' <and-expr> }

<and-expr>      ::= <not-expr> { 'AND' <not-expr> }

<not-expr>      ::= [ 'NOT' ] <rel-expr>

<rel-expr>      ::= <add-expr> [ <rel-op> <add-expr> ]

<add-expr>      ::= <mul-expr> { <add-op> <mul-expr> }

<mul-expr>      ::= <power-expr> { <mul-op> <power-expr> }

<power-expr>    ::= <unary-expr> [ '^' <power-expr> ]

<unary-expr>    ::= [ '-' ] <primary>

<primary>       ::= <number>
                  | <string>
                  | <variable>
                  | <function-call>
                  | '(' <expression> ')'
```

### Вызов функции
```bnf
<function-call> ::= <identifier> '(' [ <arg-list> ] ')'
<arg-list>      ::= <expression> { ',' <expression> }
```

---

## 📝 Команды (Statements)

### Программа
```bnf
<program>       ::= { <line> }
<line>          ::= [ <line-number> ] <statement> <EOL>
<statement>     ::= <command> | <assignment>
```

### Присваивание
```bnf
<assignment>    ::= [ 'LET' ] <variable> '=' <expression>
                    ; LET A = 10
                    ; A = 10
                    ; A$ = "Hello"
```

### Вывод
```bnf
<print-stmt>    ::= 'PRINT' <print-list>
<print-list>    ::= <print-item> { ( ',' | ';' ) <print-item> }
<print-item>    ::= <expression> | <empty>
                    ; PRINT "Hello"
                    ; PRINT A, B, C
                    ; PRINT "X = "; X
```

### Ввод
```bnf
<input-stmt>    ::= 'INPUT' [ <string> ( ',' | ';' ) ] <variable> { ',' <variable> }
                    ; INPUT A
                    ; INPUT "Enter value: ", X
                    ; INPUT A, B, C
```

### Управление потоком
```bnf
<goto-stmt>     ::= 'GOTO' <line-number>
                    ; GOTO 100

<if-stmt>       ::= 'IF' <expression> 'THEN' ( <statement> | <line-number> )
                    [ 'ELSE' ( <statement> | <line-number> ) ]
                    ; IF A > 10 THEN PRINT "Big"
                    ; IF A > 10 THEN 100
                    ; IF A > 10 THEN PRINT "Yes" ELSE PRINT "No"

<gosub-stmt>    ::= 'GOSUB' <line-number>
                    ; GOSUB 1000

<return-stmt>   ::= 'RETURN'
```

### Функции (Phase 12)
```bnf
<func-stmt>     ::= 'FUNC' <identifier>
                    ; FUNC FACTORIAL
                    ; FUNC FIB

<endfunc-stmt>  ::= 'ENDFUNC'

<local-stmt>    ::= 'LOCAL' <variable> { ',' <variable> }
                    ; LOCAL R
                    ; LOCAL A, B, N

; Пример полной функции:
; 100 FUNC FACTORIAL
; 110 LOCAL R
; 120 IF N <= 1 THEN LET R = 1 : RETURN
; 130 LET R = N : LET N = N - 1
; 140 GOSUB 100
; 150 LET N = N + 1 : LET R = R * N
; 160 RETURN
; 170 ENDFUNC
```

### FFI — Foreign Function Interface (Phase 13)
```bnf
<msgbox-stmt>   ::= 'MSGBOX' <string-expr> ',' <string-expr>
                    ; MSGBOX "Hello", "Title"
                    ; MSGBOX A$, "Title"
                    ; MSGBOX "Hello, " + N$ + "!", "Greeting"

<declare-stmt>  ::= 'DECLARE' <identifier> 'LIB' <string> [ 'ALIAS' <string> ]
                    ; DECLARE BEEP LIB "kernel32.dll"
                    ; DECLARE MSGBOX LIB "user32.dll" ALIAS "MessageBoxA"
                    ; (в разработке)
```

### Циклы
```bnf
<for-stmt>      ::= 'FOR' <variable> '=' <expression> 'TO' <expression> [ 'STEP' <expression> ]
                    ; FOR I = 1 TO 10
                    ; FOR I = 10 TO 1 STEP -1

<next-stmt>     ::= 'NEXT' [ <variable> ]
                    ; NEXT I
                    ; NEXT

<while-stmt>    ::= 'WHILE' <expression>
                    ; WHILE A < 100

<wend-stmt>     ::= 'WEND'
```

### Данные
```bnf
<dim-stmt>      ::= 'DIM' <variable> '(' <expression> { ',' <expression> } ')'
                    ; DIM A(100)
                    ; DIM B(10, 10)

<data-stmt>     ::= 'DATA' <constant> { ',' <constant> }
                    ; DATA 1, 2, 3, 4, 5
                    ; DATA "Hello", "World"

<read-stmt>     ::= 'READ' <variable> { ',' <variable> }
                    ; READ A, B, C

<restore-stmt>  ::= 'RESTORE' [ <line-number> ]
                    ; RESTORE
                    ; RESTORE 100
```

### Системные команды (REPL)
```bnf
<run-cmd>       ::= 'RUN' [ <line-number> ]
                    ; RUN
                    ; RUN 100

<list-cmd>      ::= 'LIST' [ <line-number> [ '-' <line-number> ] ]
                    ; LIST
                    ; LIST 10
                    ; LIST 10-50

<new-cmd>       ::= 'NEW'

<save-cmd>      ::= 'SAVE' <string>
                    ; SAVE "game.bas"

<load-cmd>      ::= 'LOAD' <string>
                    ; LOAD "game.bas"

<exit-cmd>      ::= 'EXIT' | 'QUIT' | 'BYE'

<help-cmd>      ::= 'HELP' [ <keyword> ]
                    ; HELP
                    ; HELP PRINT
```

### Отладка (TITAN-специфичные)
```bnf
<dump-cmd>      ::= 'DUMP'
                    ; Вывод HEX-дампа JIT-кода

<regs-cmd>      ::= 'REGS'
                    ; Вывод состояния регистров

<vars-cmd>      ::= 'VARS'
                    ; Вывод всех переменных
```

### Прочие
```bnf
<rem-stmt>      ::= 'REM' <any-text>
                  | "'" <any-text>
                    ; REM This is a comment
                    ; ' This is also a comment

<end-stmt>      ::= 'END'

<stop-stmt>     ::= 'STOP'

<cls-stmt>      ::= 'CLS'
```

---

## 🔧 Встроенные функции

### Математические
```bnf
ABS(x)          ; Абсолютное значение
SGN(x)          ; Знак числа (-1, 0, 1)
INT(x)          ; Целая часть
SQR(x)          ; Квадратный корень
SIN(x)          ; Синус
COS(x)          ; Косинус
TAN(x)          ; Тангенс
ATN(x)          ; Арктангенс
LOG(x)          ; Натуральный логарифм
EXP(x)          ; Экспонента
RND(x)          ; Случайное число (0..1)
```

### Строковые
```bnf
LEN(s$)         ; Длина строки
LEFT$(s$, n)    ; Левые n символов
RIGHT$(s$, n)   ; Правые n символов
MID$(s$, p, n)  ; n символов с позиции p
CHR$(n)         ; Символ по коду ASCII
ASC(s$)         ; Код ASCII первого символа
STR$(n)         ; Число в строку
VAL(s$)         ; Строка в число
INSTR(s$, t$)   ; Поиск подстроки
```

### Ввод/вывод
```bnf
INKEY$          ; Чтение клавиши (без ожидания)
INPUT$(n)       ; Чтение n символов
```

---

## 📊 Примеры программ

### Hello World
```basic
10 PRINT "Hello, World!"
20 END
```

### Цикл FOR
```basic
10 FOR I = 1 TO 10
20   PRINT I
30 NEXT I
```

### Условие IF
```basic
10 INPUT "Enter a number: ", N
20 IF N > 0 THEN PRINT "Positive" ELSE PRINT "Negative or zero"
30 END
```

### Вычисление факториала
```basic
10 INPUT "N = ", N
20 F = 1
30 FOR I = 1 TO N
40   F = F * I
50 NEXT I
60 PRINT "Factorial = "; F
70 END
```

### Использование массива
```basic
10 DIM A(10)
20 FOR I = 1 TO 10
30   A(I) = I * I
40 NEXT I
50 FOR I = 1 TO 10
60   PRINT A(I)
70 NEXT I
```

---

## 🚀 TITAN-специфичные расширения (v2.0+)

### SIMD-операции
```bnf
<simd-stmt>     ::= 'VDIM' <variable> '[' <size> ']'
                  | 'VADD' <variable> ',' <variable>
                  | 'VMUL' <variable> ',' <variable>
                    ; VDIM V[8]      — вектор из 8 float
                    ; VADD A, B      — A = A + B (векторно)
```

### FFI (Foreign Function Interface)
```bnf
<declare-stmt>  ::= 'DECLARE' 'FUNCTION' <identifier> 'LIB' <string> [ 'ALIAS' <string> ]
                    ; DECLARE FUNCTION MessageBoxA LIB "user32.dll"
                    ; DECLARE FUNCTION printf LIB "msvcrt.dll" ALIAS "_printf"
```

---

## ⚠️ Зарезервированные слова

```
ABS AND ASC ATN
CHR CLS COS
DATA DIM DECLARE DUMP
ELSE END EXIT EXP
FOR FUNCTION
GOSUB GOTO
HELP
IF INKEY INPUT INSTR INT
LEFT LEN LET LIST LOAD LOG
MID
NEW NEXT NOT
OR
PRINT
READ REM RESTORE RETURN RIGHT RND RUN
SAVE SGN SIN STOP SQR STR STEP
TAN THEN TO
VAL VARS VDIM VADD VMUL
WEND WHILE
```

---

*Версия грамматики: 0.1.0*
*Дата: 2025-12-17*
*Авторы: mjojo & GLK-Dev*
