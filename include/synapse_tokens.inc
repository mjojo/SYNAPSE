; ============================================================================
; SYNAPSE Language - Token Constants
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Константы токенов для лексера SYNAPSE v2.0
; ============================================================================

; ============================================================================
; Типы токенов SYNAPSE
; ============================================================================
STOK_EOF        = 0     ; Конец файла
STOK_IDENT      = 1     ; Идентификатор (my_var, Point, x)
STOK_NUMBER     = 2     ; Целое число (42, 0xFF, 0b1010)
STOK_FLOAT      = 3     ; Число с плавающей точкой (3.14, 1e-5)
STOK_STRING     = 4     ; Строка ("hello")
STOK_KEYWORD    = 5     ; Ключевое слово (fn, let, if)
STOK_OPERATOR   = 6     ; Оператор (+, -, <dot>)
STOK_NEWLINE    = 7     ; Конец строки
STOK_INDENT     = 8     ; Увеличение отступа (начало блока)
STOK_DEDENT     = 9     ; Уменьшение отступа (конец блока)
STOK_COMMENT    = 10    ; Комментарий (// или /* */)

; ============================================================================
; Коды ключевых слов SYNAPSE
; ============================================================================

; --- Объявления ---
SKW_FN          = 1     ; fn
SKW_LET         = 2     ; let
SKW_MUT         = 3     ; mut
SKW_CONST       = 4     ; const
SKW_STRUCT      = 5     ; struct
SKW_ENUM        = 6     ; enum
SKW_MODULE      = 7     ; module
SKW_IMPORT      = 8     ; import
SKW_FROM        = 9     ; from

; --- Модификаторы функций ---
SKW_CONTRACT    = 10    ; contract
SKW_NEURON      = 11    ; neuron
SKW_UNSAFE      = 12    ; unsafe
SKW_SIGNED_BY   = 13    ; signed_by

; --- Управление потоком ---
SKW_IF          = 20    ; if
SKW_ELIF        = 21    ; elif
SKW_ELSE        = 22    ; else
SKW_FOR         = 23    ; for
SKW_IN          = 24    ; in
SKW_WHILE       = 25    ; while
SKW_LOOP        = 26    ; loop
SKW_MATCH       = 27    ; match
SKW_BREAK       = 28    ; break
SKW_CONTINUE    = 29    ; continue
SKW_RETURN      = 30    ; return
SKW_PASS        = 31    ; pass

; --- Базовые типы ---
SKW_INT         = 40    ; int
SKW_INT8        = 41    ; int8
SKW_INT16       = 42    ; int16
SKW_INT32       = 43    ; int32
SKW_INT64       = 44    ; int64
SKW_UINT8       = 45    ; uint8
SKW_UINT16      = 46    ; uint16
SKW_UINT32      = 47    ; uint32
SKW_UINT64      = 48    ; uint64
SKW_F32         = 49    ; f32
SKW_F64         = 50    ; f64
SKW_BOOL        = 51    ; bool
SKW_BYTE        = 52    ; byte
SKW_STRING      = 53    ; string
SKW_PTR         = 54    ; ptr

; --- Составные типы ---
SKW_TENSOR      = 60    ; tensor
SKW_VEC         = 61    ; Vec
SKW_HASH256     = 62    ; hash256
SKW_SIGN        = 63    ; sign
SKW_BLOCK       = 64    ; block
SKW_TRANSACTION = 65    ; transaction

; --- Логические ---
SKW_AND         = 70    ; and
SKW_OR          = 71    ; or
SKW_NOT         = 72    ; not
SKW_TRUE        = 73    ; true
SKW_FALSE       = 74    ; false

; --- Блокчейн ---
SKW_CHAIN       = 80    ; chain
SKW_GLOBAL      = 81    ; global

; --- Специальные ---
SKW_ASM         = 90    ; asm

; --- Системные (REPL) ---
SKW_PRINT       = 100   ; print
SKW_EXIT        = 101   ; exit
SKW_HELP        = 102   ; help
SKW_DUMP        = 103   ; dump
SKW_VARS        = 104   ; vars

; ============================================================================
; Коды операторов SYNAPSE
; ============================================================================

; --- Арифметические ---
SOP_PLUS        = 1     ; +
SOP_MINUS       = 2     ; -
SOP_MUL         = 3     ; *
SOP_DIV         = 4     ; /
SOP_MOD         = 5     ; %
SOP_POWER       = 6     ; **
SOP_FLOORDIV    = 7     ; //

; --- Присваивание ---
SOP_ASSIGN      = 10    ; =
SOP_PLUS_ASSIGN = 11    ; +=
SOP_MINUS_ASSIGN= 12    ; -=
SOP_MUL_ASSIGN  = 13    ; *=
SOP_DIV_ASSIGN  = 14    ; /=

; --- Сравнение ---
SOP_EQ          = 20    ; ==
SOP_NE          = 21    ; !=
SOP_LT          = 22    ; <
SOP_GT          = 23    ; >
SOP_LE          = 24    ; <=
SOP_GE          = 25    ; >=

; --- Битовые ---
SOP_BITAND      = 30    ; &
SOP_BITOR       = 31    ; |
SOP_BITXOR      = 32    ; ^
SOP_BITNOT      = 33    ; ~
SOP_SHL         = 34    ; <<
SOP_SHR         = 35    ; >>

; --- Скобки ---
SOP_LPAREN      = 40    ; (
SOP_RPAREN      = 41    ; )
SOP_LBRACKET    = 42    ; [
SOP_RBRACKET    = 43    ; ]
SOP_LBRACE      = 44    ; {
SOP_RBRACE      = 45    ; }

; --- Разделители ---
SOP_COMMA       = 50    ; ,
SOP_SEMICOLON   = 51    ; ;
SOP_COLON       = 52    ; :
SOP_DOT         = 53    ; .
SOP_ARROW       = 54    ; ->
SOP_RANGE       = 55    ; ..

; --- Тензорные операторы (SYNAPSE-специфичные) ---
SOP_DOT_PRODUCT = 60    ; <dot>  - скалярное произведение / MATMUL
SOP_TENSOR_ADD  = 61    ; <+>    - поэлементное сложение
SOP_TENSOR_SUB  = 62    ; <->    - поэлементное вычитание
SOP_TENSOR_MUL  = 63    ; <*>    - поэлементное умножение
SOP_TENSOR_DIV  = 64    ; </>    - поэлементное деление

; ============================================================================
; Структура токена
; ============================================================================
STOKEN_SIZE     = 24

STOKEN_TYPE     = 0     ; u8  - тип токена
STOKEN_SUBTYPE  = 1     ; u8  - подтип (KW или OP код)
STOKEN_LENGTH   = 2     ; u16 - длина значения
STOKEN_LINE     = 4     ; u16 - номер строки
STOKEN_COLUMN   = 6     ; u16 - номер колонки
STOKEN_VALUE    = 8     ; u64 - значение или указатель
STOKEN_EXTRA    = 16    ; u64 - дополнительные данные

; ============================================================================
; Коды ошибок
; ============================================================================
SERR_NONE       = 0     ; Нет ошибки
SERR_SYNTAX     = 1     ; Синтаксическая ошибка
SERR_INDENT     = 2     ; Некорректный отступ
SERR_UNTERMINATED_STRING = 3  ; Незакрытая строка
SERR_INVALID_CHAR = 4   ; Недопустимый символ
SERR_OVERFLOW   = 5     ; Переполнение (слишком глубокая вложенность)
