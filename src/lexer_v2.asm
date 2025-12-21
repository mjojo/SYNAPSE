; ============================================================================
; SYNAPSE Language - Лексер v2.0 (Indentation Aware)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; SYNAPSE: Python-like синтаксис на базе движка TITAN
; Основные отличия от TITAN Lexer:
; - Отслеживание отступов (INDENT/DEDENT токены)
; - Новые ключевые слова (fn, let, mut, tensor, chain, contract)
; - Новые операторы (->, <dot>, <+>)
; - Поддержка типов (tensor<f32, [784]>)
; ============================================================================

; ----------------------------------------------------------------------------
; Включаемые файлы
; ----------------------------------------------------------------------------
include '..\include\synapse_tokens.inc'

; ----------------------------------------------------------------------------
; Структура токена SYNAPSE (24 байта - расширена)
; ----------------------------------------------------------------------------
; struct Token {
;     u8  type;       // Тип токена (STOK_*)
;     u8  subtype;    // Подтип (для ключевых слов/операторов)
;     u16 length;     // Длина значения
;     u16 line;       // Номер строки (для ошибок)
;     u16 column;     // Номер колонки
;     u64 value;      // Значение (число) или указатель на строку
;     u64 extra;      // Дополнительные данные (для шаблонов типов)
; }
STOKEN_SIZE     = 24

; Смещения в структуре Token
STOKEN_TYPE     = 0
STOKEN_SUBTYPE  = 1
STOKEN_LENGTH   = 2
STOKEN_LINE     = 4
STOKEN_COLUMN   = 6
STOKEN_VALUE    = 8
STOKEN_EXTRA    = 16

; ----------------------------------------------------------------------------
; Константы лексера
; ----------------------------------------------------------------------------
MAX_INDENT_DEPTH = 32       ; Максимальная глубина вложенности
INDENT_UNIT      = 4        ; Пробелов на один уровень отступа
MAX_TOKENS       = 4096     ; Максимум токенов

; ============================================================================
; Секция данных
; ============================================================================
section '.data' data readable writeable

    ; --- Сообщения ---
    lexer_banner    db '[SYNAPSE Lexer v2.0]',13,10,0
    lexer_indent_msg db '  [INDENT lvl=',0
    lexer_dedent_msg db '  [DEDENT lvl=',0
    lexer_close_msg db ']',13,10,0
    lexer_err_indent db 'Error: Inconsistent indentation',13,10,0
    lexer_err_tab   db 'Error: Tabs not allowed, use 4 spaces',13,10,0
    
    ; --- Таблица ключевых слов SYNAPSE ---
    ; Формат: длина (1 байт), строка, код (1 байт)
    synapse_keywords:
        ; Объявления
        db 2, 'fn',       SKW_FN
        db 3, 'let',      SKW_LET
        db 3, 'mut',      SKW_MUT
        db 5, 'const',    SKW_CONST
        db 6, 'struct',   SKW_STRUCT
        db 4, 'enum',     SKW_ENUM
        db 6, 'module',   SKW_MODULE
        db 6, 'import',   SKW_IMPORT
        db 4, 'from',     SKW_FROM
        
        ; Модификаторы функций
        db 8, 'contract', SKW_CONTRACT
        db 6, 'neuron',   SKW_NEURON
        db 6, 'unsafe',   SKW_UNSAFE
        db 9, 'signed_by',SKW_SIGNED_BY
        
        ; Управление потоком
        db 2, 'if',       SKW_IF
        db 4, 'elif',     SKW_ELIF
        db 4, 'else',     SKW_ELSE
        db 3, 'for',      SKW_FOR
        db 2, 'in',       SKW_IN
        db 5, 'while',    SKW_WHILE
        db 4, 'loop',     SKW_LOOP
        db 5, 'match',    SKW_MATCH
        db 5, 'break',    SKW_BREAK
        db 8, 'continue', SKW_CONTINUE
        db 6, 'return',   SKW_RETURN
        db 4, 'pass',     SKW_PASS
        
        ; Типы
        db 3, 'int',      SKW_INT
        db 4, 'int8',     SKW_INT8
        db 5, 'int16',    SKW_INT16
        db 5, 'int32',    SKW_INT32
        db 5, 'int64',    SKW_INT64
        db 5, 'uint8',    SKW_UINT8
        db 6, 'uint16',   SKW_UINT16
        db 6, 'uint32',   SKW_UINT32
        db 6, 'uint64',   SKW_UINT64
        db 3, 'f32',      SKW_F32
        db 3, 'f64',      SKW_F64
        db 4, 'bool',     SKW_BOOL
        db 4, 'byte',     SKW_BYTE
        db 6, 'string',   SKW_STRING
        db 3, 'ptr',      SKW_PTR
        db 6, 'tensor',   SKW_TENSOR
        db 3, 'Vec',      SKW_VEC
        db 7, 'hash256',  SKW_HASH256
        db 4, 'sign',     SKW_SIGN
        db 5, 'block',    SKW_BLOCK
        
        ; Логические
        db 3, 'and',      SKW_AND
        db 2, 'or',       SKW_OR
        db 3, 'not',      SKW_NOT
        db 4, 'true',     SKW_TRUE
        db 5, 'false',    SKW_FALSE
        
        ; Блокчейн
        db 5, 'chain',    SKW_CHAIN
        db 6, 'global',   SKW_GLOBAL
        
        ; ASM
        db 3, 'asm',      SKW_ASM
        
        ; Системные (для обратной совместимости с REPL)
        db 5, 'print',    SKW_PRINT
        db 4, 'exit',     SKW_EXIT
        db 4, 'help',     SKW_HELP
        db 4, 'dump',     SKW_DUMP
        db 4, 'vars',     SKW_VARS
        
        db 0  ; Конец таблицы

; ============================================================================
; Секция BSS (неинициализированные данные)
; ============================================================================
section '.bss' data readable writeable

    ; --- Состояние лексера ---
    lex_source      rq 1        ; Указатель на исходный текст
    lex_pos         rq 1        ; Текущая позиция
    lex_line_start  rq 1        ; Начало текущей строки (для column)
    lex_line_num    dd 1        ; Номер текущей строки
    lex_error       rb 1        ; Код ошибки
    lex_at_line_start rb 1      ; Флаг: мы в начале строки (нужно проверить indent)
    
    ; --- Стек отступов (Python-style) ---
    indent_stack    rd MAX_INDENT_DEPTH ; Уровни отступов [0, 4, 8, 12, ...]
    indent_top      dd 1        ; Индекс вершины стека (indent_stack[0] = 0)
    current_indent  dd 1        ; Отступ текущей строки
    pending_dedents dd 1        ; Количество ожидающих DEDENT токенов
    
    ; --- Вывод ---
    token_buffer    rb STOKEN_SIZE * MAX_TOKENS
    token_count     dd 1
    token_write_ptr rq 1        ; Указатель для записи следующего токена

; ============================================================================
; Секция кода
; ============================================================================
section '.text' code readable executable

; ----------------------------------------------------------------------------
; synlex_init: Инициализация лексера SYNAPSE
; Вход: RCX = указатель на исходный текст
; ----------------------------------------------------------------------------
; synlex_init - exported function
synlex_init:
    ; Сохраняем указатель на исходник
    mov [lex_source], rcx
    mov [lex_pos], rcx
    mov [lex_line_start], rcx
    
    ; Сброс состояния
    mov dword [lex_line_num], 1
    mov byte [lex_error], 0
    mov byte [lex_at_line_start], 1     ; Начинаем в начале строки
    
    ; Инициализация стека отступов: indent_stack[0] = 0
    lea rax, [indent_stack]
    mov dword [rax], 0                  ; Базовый уровень = 0
    mov dword [indent_top], 0           ; Вершина стека = 0
    mov dword [current_indent], 0
    mov dword [pending_dedents], 0
    
    ; Сброс буфера токенов
    mov dword [token_count], 0
    lea rax, [token_buffer]
    mov [token_write_ptr], rax
    
    ret

; ----------------------------------------------------------------------------
; synlex_next_token: Получить следующий токен
; Вход: RDI = указатель на структуру Token для заполнения
; Выход: RAX = тип токена (0 = EOF)
; ----------------------------------------------------------------------------
; synlex_next_token - exported function
synlex_next_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    
    ; Сохраняем указатель на Token
    mov r8, rdi
    
    ; Очищаем структуру токена
    xor eax, eax
    mov [rdi + STOKEN_TYPE], al
    mov [rdi + STOKEN_SUBTYPE], al
    mov word [rdi + STOKEN_LENGTH], ax
    mov word [rdi + STOKEN_LINE], ax
    mov word [rdi + STOKEN_COLUMN], ax
    mov qword [rdi + STOKEN_VALUE], rax
    mov qword [rdi + STOKEN_EXTRA], rax
    
    ; Загружаем текущую позицию
    mov rsi, [lex_pos]
    
    ; ========================================
    ; Шаг 0: Проверяем ожидающие DEDENT
    ; ========================================
    mov eax, [pending_dedents]
    test eax, eax
    jnz .emit_pending_dedent
    
    ; ========================================
    ; Шаг 1: Проверяем начало строки (отступы)
    ; ========================================
    cmp byte [lex_at_line_start], 1
    jne .skip_whitespace
    
    ; Мы в начале строки — считаем отступ
    call count_indentation
    mov byte [lex_at_line_start], 0
    
    ; Сравниваем с вершиной стека
    call handle_indentation
    
    ; Если были сгенерированы DEDENT — вернуть первый
    mov eax, [pending_dedents]
    test eax, eax
    jnz .emit_pending_dedent
    
    ; Проверяем на INDENT
    cmp byte [r8 + STOKEN_TYPE], STOK_INDENT
    je .done
    
    ; Продолжаем парсить контент
    mov rsi, [lex_pos]

.skip_whitespace:
    ; Пропускаем пробелы (но НЕ в начале строки!)
    mov al, [rsi]
    cmp al, ' '
    je .skip_space
    cmp al, 9           ; Tab — ошибка!
    je .error_tab
    jmp .check_end

.skip_space:
    inc rsi
    jmp .skip_whitespace

.check_end:
    ; Заполняем номер строки/колонки
    mov eax, [lex_line_num]
    mov word [r8 + STOKEN_LINE], ax
    mov rax, rsi
    sub rax, [lex_line_start]
    mov word [r8 + STOKEN_COLUMN], ax
    
    ; Проверяем конец файла
    mov al, [rsi]
    test al, al
    jz .token_eof
    
    ; Проверяем конец строки
    cmp al, 13          ; CR
    je .token_newline
    cmp al, 10          ; LF
    je .token_newline
    
    ; Комментарий // или #
    cmp al, '/'
    je .check_comment
    cmp al, '#'
    je .token_line_comment
    
    ; Строка в кавычках
    cmp al, '"'
    je .token_string
    
    ; Число
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .token_number
    
.check_alpha:
    ; Буква или _ (начало идентификатора)
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .token_identifier
    
.check_lower:
    cmp al, 'a'
    jl .check_underscore
    cmp al, 'z'
    jle .token_identifier
    
.check_underscore:
    cmp al, '_'
    je .token_identifier
    
    ; Оператор или спецсимвол
    jmp .token_operator

; ========================================
; Обработчики разных типов токенов
; ========================================

.emit_pending_dedent:
    ; Генерируем DEDENT из pending_dedents
    dec dword [pending_dedents]
    mov byte [r8 + STOKEN_TYPE], STOK_DEDENT
    
    ; Номер строки
    mov eax, [lex_line_num]
    mov word [r8 + STOKEN_LINE], ax
    
    mov eax, STOK_DEDENT
    jmp .done

.token_eof:
    ; Перед EOF — генерируем все оставшиеся DEDENT
    mov eax, [indent_top]
    test eax, eax
    jz .real_eof
    
    ; Есть незакрытые блоки
    mov [pending_dedents], eax
    mov dword [indent_top], 0
    jmp .emit_pending_dedent
    
.real_eof:
    mov byte [r8 + STOKEN_TYPE], STOK_EOF
    xor eax, eax
    jmp .done

.token_newline:
    mov byte [r8 + STOKEN_TYPE], STOK_NEWLINE
    
    ; Пропускаем CR LF
    cmp byte [rsi], 13
    jne .newline_lf
    inc rsi
.newline_lf:
    cmp byte [rsi], 10
    jne .newline_done
    inc rsi
.newline_done:
    inc dword [lex_line_num]
    mov [lex_line_start], rsi
    mov byte [lex_at_line_start], 1     ; Следующий токен — проверяем отступ
    mov [lex_pos], rsi
    mov eax, STOK_NEWLINE
    jmp .done

.check_comment:
    ; Проверяем //
    cmp byte [rsi + 1], '/'
    je .token_line_comment
    ; Проверяем /* */
    cmp byte [rsi + 1], '*'
    je .token_block_comment
    ; Обычный /
    jmp .token_operator

.token_line_comment:
    ; Пропускаем до конца строки
    mov byte [r8 + STOKEN_TYPE], STOK_COMMENT
.comment_loop:
    inc rsi
    mov al, [rsi]
    test al, al
    jz .comment_end
    cmp al, 13
    je .comment_end
    cmp al, 10
    je .comment_end
    jmp .comment_loop
.comment_end:
    mov [lex_pos], rsi
    mov eax, STOK_COMMENT
    jmp .done

.token_block_comment:
    ; Пропускаем /* ... */
    mov byte [r8 + STOKEN_TYPE], STOK_COMMENT
    add rsi, 2      ; Пропускаем /*
.block_comment_loop:
    mov al, [rsi]
    test al, al
    jz .comment_end
    cmp al, 10      ; Новая строка внутри комментария
    jne .block_check_end
    inc dword [lex_line_num]
.block_check_end:
    cmp al, '*'
    jne .block_continue
    cmp byte [rsi + 1], '/'
    jne .block_continue
    add rsi, 2      ; Пропускаем */
    jmp .comment_end
.block_continue:
    inc rsi
    jmp .block_comment_loop

.token_string:
    ; Парсим строку в кавычках
    mov byte [r8 + STOKEN_TYPE], STOK_STRING
    inc rsi                     ; Пропускаем "
    mov [r8 + STOKEN_VALUE], rsi
    xor ecx, ecx
    
.string_loop:
    mov al, [rsi]
    cmp al, '"'
    je .string_end
    cmp al, 0
    je .string_error
    cmp al, 10
    je .string_error
    ; Обработка escape-последовательностей
    cmp al, '\'
    jne .string_normal
    inc rsi
    inc ecx
.string_normal:
    inc ecx
    inc rsi
    jmp .string_loop
    
.string_end:
    mov word [r8 + STOKEN_LENGTH], cx
    inc rsi                     ; Пропускаем закрывающую "
    mov [lex_pos], rsi
    mov eax, STOK_STRING
    jmp .done
    
.string_error:
    mov byte [lex_error], 1
    xor eax, eax
    jmp .done

.token_number:
    ; Парсим число (int или float)
    mov byte [r8 + STOKEN_TYPE], STOK_NUMBER
    mov [r8 + STOKEN_VALUE], rsi    ; Сохраняем начало
    xor ecx, ecx                    ; Длина
    
    ; Проверяем hex (0x) или binary (0b)
    cmp byte [rsi], '0'
    jne .number_decimal
    cmp byte [rsi + 1], 'x'
    je .number_hex
    cmp byte [rsi + 1], 'X'
    je .number_hex
    cmp byte [rsi + 1], 'b'
    je .number_binary
    cmp byte [rsi + 1], 'B'
    je .number_binary
    
.number_decimal:
    ; Десятичное число (возможно float)
.num_int_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_check_dot
    cmp al, '9'
    jg .num_check_dot
    inc ecx
    inc rsi
    jmp .num_int_loop
    
.num_check_dot:
    cmp al, '.'
    jne .num_check_exp
    
    ; Дробная часть
    mov byte [r8 + STOKEN_TYPE], STOK_FLOAT
    inc ecx
    inc rsi
    
.num_frac_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_check_exp
    cmp al, '9'
    jg .num_check_exp
    inc ecx
    inc rsi
    jmp .num_frac_loop
    
.num_check_exp:
    ; Проверяем экспоненту (e/E)
    cmp al, 'e'
    je .num_exp
    cmp al, 'E'
    je .num_exp
    jmp .number_done
    
.num_exp:
    mov byte [r8 + STOKEN_TYPE], STOK_FLOAT
    inc ecx
    inc rsi
    mov al, [rsi]
    cmp al, '+'
    je .num_exp_sign
    cmp al, '-'
    je .num_exp_sign
    jmp .num_exp_digits
.num_exp_sign:
    inc ecx
    inc rsi
.num_exp_digits:
    mov al, [rsi]
    cmp al, '0'
    jl .number_done
    cmp al, '9'
    jg .number_done
    inc ecx
    inc rsi
    jmp .num_exp_digits

.number_hex:
    mov byte [r8 + STOKEN_SUBTYPE], 16  ; База = 16
    add rsi, 2
    add ecx, 2
.hex_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .number_done
    cmp al, '9'
    jle .hex_continue
    cmp al, 'A'
    jl .number_done
    cmp al, 'F'
    jle .hex_continue
    cmp al, 'a'
    jl .number_done
    cmp al, 'f'
    jg .number_done
.hex_continue:
    inc ecx
    inc rsi
    jmp .hex_loop

.number_binary:
    mov byte [r8 + STOKEN_SUBTYPE], 2   ; База = 2
    add rsi, 2
    add ecx, 2
.bin_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .number_done
    cmp al, '1'
    jg .number_done
    inc ecx
    inc rsi
    jmp .bin_loop

.number_done:
    mov word [r8 + STOKEN_LENGTH], cx
    mov [lex_pos], rsi
    movzx eax, byte [r8 + STOKEN_TYPE]
    jmp .done

.token_identifier:
    ; Парсим идентификатор
    mov byte [r8 + STOKEN_TYPE], STOK_IDENT
    mov [r8 + STOKEN_VALUE], rsi
    xor ecx, ecx
    
.ident_loop:
    mov al, [rsi]
    
    ; A-Z
    cmp al, 'A'
    jl .ident_check_lower
    cmp al, 'Z'
    jle .ident_continue
    
.ident_check_lower:
    ; a-z
    cmp al, 'a'
    jl .ident_check_digit
    cmp al, 'z'
    jle .ident_continue
    
.ident_check_digit:
    ; 0-9
    cmp al, '0'
    jl .ident_check_under
    cmp al, '9'
    jle .ident_continue
    
.ident_check_under:
    ; _
    cmp al, '_'
    je .ident_continue
    jmp .ident_end
    
.ident_continue:
    inc ecx
    inc rsi
    jmp .ident_loop
    
.ident_end:
    mov word [r8 + STOKEN_LENGTH], cx
    mov [lex_pos], rsi
    
    ; Проверяем ключевое слово
    push rsi
    mov rsi, [r8 + STOKEN_VALUE]
    mov edx, ecx
    call synlex_check_keyword
    pop rsi
    
    test eax, eax
    jz .ident_not_kw
    
    ; Это ключевое слово
    mov byte [r8 + STOKEN_TYPE], STOK_KEYWORD
    mov byte [r8 + STOKEN_SUBTYPE], al
    mov eax, STOK_KEYWORD
    jmp .done
    
.ident_not_kw:
    mov eax, STOK_IDENT
    jmp .done

.token_operator:
    ; Парсим оператор
    mov byte [r8 + STOKEN_TYPE], STOK_OPERATOR
    mov al, [rsi]
    
    ; Однозначные операторы
    cmp al, '+'
    je .op_plus
    cmp al, '*'
    je .op_star
    cmp al, '/'
    je .op_slash
    cmp al, '%'
    je .op_percent
    cmp al, '='
    je .op_eq
    cmp al, '!'
    je .op_bang
    cmp al, '<'
    je .op_less
    cmp al, '>'
    je .op_greater
    cmp al, '&'
    je .op_amp
    cmp al, '|'
    je .op_pipe
    cmp al, '^'
    je .op_caret
    cmp al, '~'
    je .op_tilde
    cmp al, '('
    je .op_lparen
    cmp al, ')'
    je .op_rparen
    cmp al, '['
    je .op_lbracket
    cmp al, ']'
    je .op_rbracket
    cmp al, '{'
    je .op_lbrace
    cmp al, '}'
    je .op_rbrace
    cmp al, ','
    je .op_comma
    cmp al, ';'
    je .op_semicolon
    cmp al, ':'
    je .op_colon
    cmp al, '.'
    je .op_dot
    cmp al, '-'
    je .op_minus
    
    ; Неизвестный символ
    mov byte [lex_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.op_plus:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_PLUS
    jmp .op_single

.op_star:
    ; Может быть * или **
    cmp byte [rsi + 1], '*'
    jne .op_star_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_POWER
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_star_single:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_MUL
    jmp .op_single

.op_slash:
    ; Может быть / или //
    cmp byte [rsi + 1], '/'
    jne .op_slash_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_FLOORDIV
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_slash_single:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_DIV
    jmp .op_single

.op_percent:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_MOD
    jmp .op_single

.op_eq:
    ; Может быть = или ==
    cmp byte [rsi + 1], '='
    jne .op_eq_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_EQ
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_eq_single:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_ASSIGN
    jmp .op_single

.op_bang:
    ; Должно быть !=
    cmp byte [rsi + 1], '='
    jne .op_error
    mov byte [r8 + STOKEN_SUBTYPE], SOP_NE
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update

.op_less:
    ; <, <=, <<, <dot>, <+>, <->
    cmp byte [rsi + 1], '='
    je .op_le
    cmp byte [rsi + 1], '<'
    je .op_shl
    cmp byte [rsi + 1], 'd'
    je .op_check_dot
    cmp byte [rsi + 1], '+'
    je .op_tensor_add
    cmp byte [rsi + 1], '-'
    je .op_tensor_sub
    cmp byte [rsi + 1], '*'
    je .op_tensor_mul
    cmp byte [rsi + 1], '/'
    je .op_tensor_div
    ; Просто <
    mov byte [r8 + STOKEN_SUBTYPE], SOP_LT
    jmp .op_single
.op_le:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_LE
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_shl:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_SHL
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_check_dot:
    ; Проверяем <dot>
    cmp byte [rsi + 2], 'o'
    jne .op_less_single
    cmp byte [rsi + 3], 't'
    jne .op_less_single
    cmp byte [rsi + 4], '>'
    jne .op_less_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_DOT_PRODUCT
    mov word [r8 + STOKEN_LENGTH], 5
    add rsi, 5
    jmp .op_done_update
.op_tensor_add:
    cmp byte [rsi + 2], '>'
    jne .op_less_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_TENSOR_ADD
    mov word [r8 + STOKEN_LENGTH], 3
    add rsi, 3
    jmp .op_done_update
.op_tensor_sub:
    cmp byte [rsi + 2], '>'
    jne .op_less_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_TENSOR_SUB
    mov word [r8 + STOKEN_LENGTH], 3
    add rsi, 3
    jmp .op_done_update
.op_tensor_mul:
    cmp byte [rsi + 2], '>'
    jne .op_less_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_TENSOR_MUL
    mov word [r8 + STOKEN_LENGTH], 3
    add rsi, 3
    jmp .op_done_update
.op_tensor_div:
    cmp byte [rsi + 2], '>'
    jne .op_less_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_TENSOR_DIV
    mov word [r8 + STOKEN_LENGTH], 3
    add rsi, 3
    jmp .op_done_update
.op_less_single:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_LT
    jmp .op_single

.op_greater:
    ; >, >=, >>
    cmp byte [rsi + 1], '='
    je .op_ge
    cmp byte [rsi + 1], '>'
    je .op_shr
    mov byte [r8 + STOKEN_SUBTYPE], SOP_GT
    jmp .op_single
.op_ge:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_GE
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_shr:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_SHR
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update

.op_amp:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_BITAND
    jmp .op_single

.op_pipe:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_BITOR
    jmp .op_single

.op_caret:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_BITXOR
    jmp .op_single

.op_tilde:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_BITNOT
    jmp .op_single

.op_lparen:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_LPAREN
    jmp .op_single

.op_rparen:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_RPAREN
    jmp .op_single

.op_lbracket:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_LBRACKET
    jmp .op_single

.op_rbracket:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_RBRACKET
    jmp .op_single

.op_lbrace:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_LBRACE
    jmp .op_single

.op_rbrace:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_RBRACE
    jmp .op_single

.op_comma:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_COMMA
    jmp .op_single

.op_semicolon:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_SEMICOLON
    jmp .op_single

.op_colon:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_COLON
    jmp .op_single

.op_dot:
    ; . или ..
    cmp byte [rsi + 1], '.'
    jne .op_dot_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_RANGE
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_dot_single:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_DOT
    jmp .op_single

.op_minus:
    ; - или ->
    cmp byte [rsi + 1], '>'
    jne .op_minus_single
    mov byte [r8 + STOKEN_SUBTYPE], SOP_ARROW
    mov word [r8 + STOKEN_LENGTH], 2
    add rsi, 2
    jmp .op_done_update
.op_minus_single:
    mov byte [r8 + STOKEN_SUBTYPE], SOP_MINUS
    jmp .op_single

.op_single:
    mov word [r8 + STOKEN_LENGTH], 1
    inc rsi
    
.op_done_update:
    mov [lex_pos], rsi
    mov eax, STOK_OPERATOR
    jmp .done

.op_error:
    mov byte [lex_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.error_tab:
    ; Табы запрещены
    mov byte [lex_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.done:
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; count_indentation: Подсчёт пробелов в начале строки
; Обновляет: current_indent, lex_pos
; ----------------------------------------------------------------------------
count_indentation:
    mov rsi, [lex_pos]
    xor edx, edx            ; Счётчик пробелов
    
.count_loop:
    mov al, [rsi]
    cmp al, ' '
    jne .count_done
    inc edx
    inc rsi
    jmp .count_loop
    
.count_done:
    ; Проверяем, что это не пустая строка
    cmp al, 10
    je .empty_line
    cmp al, 13
    je .empty_line
    cmp al, 0
    je .empty_line
    
    mov [current_indent], edx
    mov [lex_pos], rsi
    ret
    
.empty_line:
    ; Пустая строка — пропускаем
    mov [lex_pos], rsi
    ret

; ----------------------------------------------------------------------------
; handle_indentation: Генерация INDENT/DEDENT
; Вход: r8 = указатель на Token
; Обновляет: pending_dedents, indent_stack, indent_top
; ----------------------------------------------------------------------------
handle_indentation:
    mov eax, [current_indent]
    mov ebx, [indent_top]
    
    ; Получаем текущий уровень из стека
    lea rdi, [indent_stack]
    mov ecx, [rdi + rbx*4]      ; indent_stack[indent_top]
    
    ; Сравниваем
    cmp eax, ecx
    je .same_level
    jg .indent_in
    jl .indent_out
    
.same_level:
    ret

.indent_in:
    ; Отступ увеличился — генерируем INDENT
    ; Проверяем, что это корректный отступ (кратный 4)
    mov edx, eax
    sub edx, ecx
    test edx, 3             ; edx & 3 == 0?
    jnz .indent_error
    
    ; Push на стек
    inc ebx
    cmp ebx, MAX_INDENT_DEPTH
    jge .indent_error
    
    mov [rdi + rbx*4], eax
    mov [indent_top], ebx
    
    ; Генерируем INDENT токен
    mov byte [r8 + STOKEN_TYPE], STOK_INDENT
    mov eax, [lex_line_num]
    mov word [r8 + STOKEN_LINE], ax
    
    ret

.indent_out:
    ; Отступ уменьшился — генерируем DEDENT(ы)
    xor r9d, r9d            ; Счётчик DEDENT
    
.dedent_loop:
    cmp ebx, 0
    jle .dedent_error
    
    dec ebx
    mov ecx, [rdi + rbx*4]  ; Предыдущий уровень
    inc r9d
    
    cmp eax, ecx
    jl .dedent_loop         ; Ещё не дошли
    jne .dedent_error       ; Не совпало — ошибка
    
    ; Готово
    mov [indent_top], ebx
    mov [pending_dedents], r9d
    ret

.indent_error:
.dedent_error:
    mov byte [lex_error], ERR_SYNTAX
    ret

; ----------------------------------------------------------------------------
; synlex_check_keyword: Проверка ключевого слова
; Вход: RSI = указатель на строку, EDX = длина
; Выход: EAX = код ключевого слова (0 если не ключевое)
; ----------------------------------------------------------------------------
synlex_check_keyword:
    push rbx
    push rcx
    push rdi
    push r10
    
    lea rdi, [synapse_keywords]
    
.kw_loop:
    movzx ecx, byte [rdi]
    test ecx, ecx
    jz .kw_not_found
    
    cmp ecx, edx
    jne .kw_next
    
    ; Сравниваем строки (регистронезависимо)
    push rsi
    push rdi
    inc rdi
    mov r10d, ecx
    
.kw_compare:
    mov al, [rsi]
    mov bl, [rdi]
    
    ; Приводим к нижнему регистру
    cmp al, 'A'
    jl .kw_no_lower1
    cmp al, 'Z'
    jg .kw_no_lower1
    add al, 32
.kw_no_lower1:
    cmp bl, 'A'
    jl .kw_no_lower2
    cmp bl, 'Z'
    jg .kw_no_lower2
    add bl, 32
.kw_no_lower2:
    
    cmp al, bl
    jne .kw_mismatch
    
    inc rsi
    inc rdi
    dec r10d
    jnz .kw_compare
    
    ; Совпадение!
    pop rdi
    pop rsi
    movzx rdx, byte [rdi]           ; Get length again (fixes operand size)
    add rdi, rdx
    inc rdi
    movzx eax, byte [rdi]
    jmp .kw_done
    
.kw_mismatch:
    pop rdi
    pop rsi
    
.kw_next:
    movzx ecx, byte [rdi]
    add rdi, rcx
    add rdi, 2
    jmp .kw_loop
    
.kw_not_found:
    xor eax, eax
    
.kw_done:
    pop r10
    pop rdi
    pop rcx
    pop rbx
    ret
