; ============================================================================
; TITAN Language - Лексер (Tokenizer)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Разбивает исходный текст на токены
; ============================================================================

; ----------------------------------------------------------------------------
; Структура токена (16 байт)
; ----------------------------------------------------------------------------
; struct Token {
;     u8  type;       // Тип токена (TOKEN_*)
;     u8  subtype;    // Подтип (для ключевых слов/операторов)
;     u16 length;     // Длина значения
;     u32 reserved;   // Выравнивание
;     u64 value;      // Значение (число) или указатель на строку
; }
TOKEN_SIZE = 16

; Смещения в структуре Token
TOKEN_TYPE      = 0
TOKEN_SUBTYPE   = 1
TOKEN_LENGTH    = 2
TOKEN_VALUE     = 8

; ----------------------------------------------------------------------------
; Таблица ключевых слов
; Формат: длина (1 байт), строка, код (1 байт)
; ----------------------------------------------------------------------------
keywords_table:
    ; Команды вывода/ввода
    db 5, 'PRINT', KW_PRINT
    db 5, 'INPUT', KW_INPUT
    db 3, 'CLS',   KW_CLS
    
    ; Переменные
    db 3, 'LET',   KW_LET
    db 3, 'DIM',   KW_DIM
    
    ; Управление потоком
    db 4, 'GOTO',  KW_GOTO
    db 2, 'IF',    KW_IF
    db 4, 'THEN',  KW_THEN
    db 4, 'ELSE',  KW_ELSE
    db 5, 'GOSUB', KW_GOSUB
    db 6, 'RETURN',KW_RETURN
    db 3, 'END',   KW_END
    db 4, 'STOP',  KW_STOP
    
    ; Циклы
    db 3, 'FOR',   KW_FOR
    db 2, 'TO',    KW_TO
    db 4, 'STEP',  KW_STEP
    db 4, 'NEXT',  KW_NEXT
    db 5, 'WHILE', KW_WHILE
    db 4, 'WEND',  KW_WEND
    
    ; Данные
    db 4, 'DATA',  KW_DATA
    db 4, 'READ',  KW_READ
    db 7, 'RESTORE', KW_RESTORE
    
    ; Логические
    db 3, 'AND',   KW_AND
    db 2, 'OR',    KW_OR
    db 3, 'NOT',   KW_NOT
    
    ; Системные
    db 3, 'RUN',   KW_RUN
    db 4, 'LIST',  KW_LIST
    db 3, 'NEW',   KW_NEW
    db 4, 'SAVE',  KW_SAVE
    db 4, 'LOAD',  KW_LOAD
    db 4, 'EXIT',  KW_EXIT
    db 4, 'QUIT',  KW_EXIT
    db 3, 'BYE',   KW_EXIT
    db 4, 'HELP',  KW_HELP
    
    ; Отладка TITAN
    db 4, 'DUMP',  KW_DUMP
    db 4, 'VARS',  KW_VARS
    db 4, 'REGS',  KW_REGS
    
    ; Комментарий
    db 3, 'REM',   KW_REM
    
    db 0  ; Конец таблицы

; ----------------------------------------------------------------------------
; lexer_init: Инициализация лексера
; Вход: RSI = указатель на исходный текст
; ----------------------------------------------------------------------------
lexer_init:
    mov [lexer_source], rsi
    mov [lexer_pos], rsi
    mov byte [lexer_error], 0
    ret

; ----------------------------------------------------------------------------
; lexer_next_token: Получить следующий токен
; Вход: RDI = указатель на структуру Token для заполнения
; Выход: RAX = тип токена (0 = конец/ошибка)
; ----------------------------------------------------------------------------
lexer_next_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rsi, [lexer_pos]
    
    ; Сохраняем указатель на Token
    mov r8, rdi
    
    ; Очищаем структуру токена
    xor eax, eax
    mov [rdi + TOKEN_TYPE], al
    mov [rdi + TOKEN_SUBTYPE], al
    mov word [rdi + TOKEN_LENGTH], ax
    mov qword [rdi + TOKEN_VALUE], rax
    
.skip_whitespace:
    ; Пропускаем пробелы и табы
    mov al, [rsi]
    cmp al, ' '
    je .next_char
    cmp al, 9           ; Tab
    je .next_char
    jmp .check_end
    
.next_char:
    inc rsi
    jmp .skip_whitespace
    
.check_end:
    ; Проверяем конец строки
    cmp al, 0
    je .token_eol
    cmp al, 13          ; CR
    je .token_eol
    cmp al, 10          ; LF
    je .token_eol
    
    ; Проверяем комментарий '
    cmp al, "'"
    je .token_comment
    
    ; Проверяем строку в кавычках
    cmp al, '"'
    je .token_string
    
    ; Проверяем число (цифра)
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .token_number
    
.check_alpha:
    ; Проверяем букву (идентификатор или ключевое слово)
    cmp al, 'A'
    jl .check_operator
    cmp al, 'Z'
    jle .token_identifier
    cmp al, 'a'
    jl .check_operator
    cmp al, 'z'
    jle .token_identifier
    
.check_operator:
    ; Это оператор или спецсимвол
    jmp .token_operator

; --- Обработка разных типов токенов ---

.token_eol:
    mov byte [r8 + TOKEN_TYPE], TOKEN_EOL
    mov [lexer_pos], rsi
    mov eax, TOKEN_EOL
    jmp .done

.token_comment:
    ; Пропускаем всё до конца строки
    mov byte [r8 + TOKEN_TYPE], TOKEN_EOL
.comment_loop:
    inc rsi
    mov al, [rsi]
    cmp al, 0
    je .comment_end
    cmp al, 13
    je .comment_end
    cmp al, 10
    je .comment_end
    jmp .comment_loop
.comment_end:
    mov [lexer_pos], rsi
    mov eax, TOKEN_EOL
    jmp .done

.token_string:
    ; Парсим строку в кавычках
    mov byte [r8 + TOKEN_TYPE], TOKEN_STRING
    inc rsi                     ; Пропускаем открывающую кавычку
    mov [r8 + TOKEN_VALUE], rsi ; Начало строки
    xor ecx, ecx                ; Счётчик длины
    
.string_loop:
    mov al, [rsi]
    cmp al, '"'
    je .string_end
    cmp al, 0
    je .string_error
    cmp al, 13
    je .string_error
    inc ecx
    inc rsi
    jmp .string_loop
    
.string_end:
    mov word [r8 + TOKEN_LENGTH], cx
    inc rsi                     ; Пропускаем закрывающую кавычку
    mov [lexer_pos], rsi
    mov eax, TOKEN_STRING
    jmp .done
    
.string_error:
    mov byte [lexer_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.token_number:
    ; Парсим целое число
    mov byte [r8 + TOKEN_TYPE], TOKEN_NUMBER
    xor rax, rax                ; Результат
    xor rbx, rbx
    
.number_loop:
    mov bl, [rsi]
    cmp bl, '0'
    jl .number_done
    cmp bl, '9'
    jg .number_done
    
    ; result = result * 10 + digit
    imul rax, 10
    sub bl, '0'
    add rax, rbx
    inc rsi
    jmp .number_loop
    
.number_done:
    mov [r8 + TOKEN_VALUE], rax
    mov [lexer_pos], rsi
    mov eax, TOKEN_NUMBER
    jmp .done

.token_identifier:
    ; Парсим идентификатор (может быть ключевым словом)
    mov byte [r8 + TOKEN_TYPE], TOKEN_IDENTIFIER
    mov [r8 + TOKEN_VALUE], rsi ; Начало идентификатора
    xor ecx, ecx                ; Длина
    
.ident_loop:
    mov al, [rsi]
    
    ; Буква A-Z?
    cmp al, 'A'
    jl .ident_check_lower
    cmp al, 'Z'
    jle .ident_continue
    
.ident_check_lower:
    ; Буква a-z?
    cmp al, 'a'
    jl .ident_check_digit
    cmp al, 'z'
    jle .ident_continue
    
.ident_check_digit:
    ; Цифра 0-9?
    cmp al, '0'
    jl .ident_check_special
    cmp al, '9'
    jle .ident_continue
    
.ident_check_special:
    ; Подчёркивание?
    cmp al, '_'
    je .ident_continue
    ; Знак $ (строковая переменная)?
    cmp al, '$'
    je .ident_string_var
    jmp .ident_end
    
.ident_continue:
    inc ecx
    inc rsi
    jmp .ident_loop
    
.ident_string_var:
    ; Добавляем $ к идентификатору
    inc ecx
    inc rsi
    
.ident_end:
    mov word [r8 + TOKEN_LENGTH], cx
    mov [lexer_pos], rsi
    
    ; Проверяем, не ключевое ли это слово
    push rsi
    mov rsi, [r8 + TOKEN_VALUE]  ; Начало идентификатора
    movzx edx, cx                 ; Длина
    call check_keyword
    pop rsi
    
    ; Если RAX != 0, это ключевое слово
    test eax, eax
    jz .ident_not_keyword
    
    mov byte [r8 + TOKEN_TYPE], TOKEN_KEYWORD
    mov byte [r8 + TOKEN_SUBTYPE], al
    mov eax, TOKEN_KEYWORD
    jmp .done
    
.ident_not_keyword:
    mov eax, TOKEN_IDENTIFIER
    jmp .done

.token_operator:
    ; Парсим оператор
    mov byte [r8 + TOKEN_TYPE], TOKEN_OPERATOR
    mov [r8 + TOKEN_VALUE], rsi
    
    ; Определяем тип оператора
    mov al, [rsi]
    
    cmp al, '+'
    je .op_plus
    cmp al, '-'
    je .op_minus
    cmp al, '*'
    je .op_mul
    cmp al, '/'
    je .op_div
    cmp al, '^'
    je .op_power
    cmp al, '='
    je .op_equal
    cmp al, '<'
    je .op_less
    cmp al, '>'
    je .op_greater
    cmp al, '('
    je .op_lparen
    cmp al, ')'
    je .op_rparen
    cmp al, ','
    je .op_comma
    cmp al, ';'
    je .op_semicolon
    cmp al, ':'
    je .op_colon
    
    ; Неизвестный символ — ошибка
    mov byte [lexer_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.op_plus:
    mov byte [r8 + TOKEN_SUBTYPE], OP_PLUS
    jmp .op_single

.op_minus:
    mov byte [r8 + TOKEN_SUBTYPE], OP_MINUS
    jmp .op_single

.op_mul:
    mov byte [r8 + TOKEN_SUBTYPE], OP_MUL
    jmp .op_single

.op_div:
    mov byte [r8 + TOKEN_SUBTYPE], OP_DIV
    jmp .op_single

.op_power:
    mov byte [r8 + TOKEN_SUBTYPE], OP_POWER
    jmp .op_single

.op_equal:
    mov byte [r8 + TOKEN_SUBTYPE], OP_EQ
    jmp .op_single

.op_lparen:
    mov byte [r8 + TOKEN_SUBTYPE], OP_LPAREN
    jmp .op_single

.op_rparen:
    mov byte [r8 + TOKEN_SUBTYPE], OP_RPAREN
    jmp .op_single

.op_comma:
    mov byte [r8 + TOKEN_SUBTYPE], OP_COMMA
    jmp .op_single

.op_semicolon:
    mov byte [r8 + TOKEN_SUBTYPE], OP_SEMICOLON
    jmp .op_single

.op_colon:
    mov byte [r8 + TOKEN_SUBTYPE], OP_COLON
    jmp .op_single

.op_less:
    ; Может быть <, <=, <>
    inc rsi
    mov al, [rsi]
    cmp al, '='
    je .op_le
    cmp al, '>'
    je .op_ne
    ; Просто <
    mov byte [r8 + TOKEN_SUBTYPE], OP_LT
    mov word [r8 + TOKEN_LENGTH], 1
    mov [lexer_pos], rsi
    mov eax, TOKEN_OPERATOR
    jmp .done

.op_le:
    mov byte [r8 + TOKEN_SUBTYPE], OP_LE
    mov word [r8 + TOKEN_LENGTH], 2
    inc rsi
    mov [lexer_pos], rsi
    mov eax, TOKEN_OPERATOR
    jmp .done

.op_ne:
    mov byte [r8 + TOKEN_SUBTYPE], OP_NE
    mov word [r8 + TOKEN_LENGTH], 2
    inc rsi
    mov [lexer_pos], rsi
    mov eax, TOKEN_OPERATOR
    jmp .done

.op_greater:
    ; Может быть > или >=
    inc rsi
    mov al, [rsi]
    cmp al, '='
    je .op_ge
    ; Просто >
    mov byte [r8 + TOKEN_SUBTYPE], OP_GT
    mov word [r8 + TOKEN_LENGTH], 1
    mov [lexer_pos], rsi
    mov eax, TOKEN_OPERATOR
    jmp .done

.op_ge:
    mov byte [r8 + TOKEN_SUBTYPE], OP_GE
    mov word [r8 + TOKEN_LENGTH], 2
    inc rsi
    mov [lexer_pos], rsi
    mov eax, TOKEN_OPERATOR
    jmp .done

.op_single:
    mov word [r8 + TOKEN_LENGTH], 1
    inc rsi
    mov [lexer_pos], rsi
    mov eax, TOKEN_OPERATOR
    jmp .done

.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; check_keyword: Проверяет, является ли идентификатор ключевым словом
; Вход: RSI = указатель на идентификатор, EDX = длина
; Выход: EAX = код ключевого слова (0 если не ключевое)
; ----------------------------------------------------------------------------
check_keyword:
    push rbx
    push rcx
    push rdi
    
    lea rdi, [keywords_table]
    
.kw_loop:
    movzx ecx, byte [rdi]       ; Длина ключевого слова
    test ecx, ecx
    jz .kw_not_found            ; Конец таблицы
    
    cmp ecx, edx                ; Сравниваем длины
    jne .kw_next
    
    ; Длины совпадают — сравниваем строки (регистронезависимо)
    push rsi
    push rdi
    inc rdi                     ; Пропускаем байт длины
    
.kw_compare:
    mov al, [rsi]
    mov bl, [rdi]
    
    ; Приводим к верхнему регистру
    cmp al, 'a'
    jl .kw_skip_upper1
    cmp al, 'z'
    jg .kw_skip_upper1
    sub al, 32
.kw_skip_upper1:
    
    cmp al, bl
    jne .kw_mismatch
    
    inc rsi
    inc rdi
    dec ecx
    jnz .kw_compare
    
    ; Совпадение! Возвращаем код
    pop rdi
    pop rsi
    add rdi, edx
    inc rdi                     ; +1 за байт длины
    movzx eax, byte [rdi]       ; Код ключевого слова
    jmp .kw_done
    
.kw_mismatch:
    pop rdi
    pop rsi
    
.kw_next:
    ; Переходим к следующему слову в таблице
    movzx ecx, byte [rdi]
    add rdi, rcx
    add rdi, 2                  ; +1 длина, +1 код
    jmp .kw_loop
    
.kw_not_found:
    xor eax, eax
    
.kw_done:
    pop rdi
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; Данные лексера (BSS)
; ----------------------------------------------------------------------------
section '.bss' readable writeable
    lexer_source    rq 1        ; Указатель на исходный текст
    lexer_pos       rq 1        ; Текущая позиция
    lexer_error     rb 1        ; Код ошибки
