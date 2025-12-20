; ============================================================================
; TITAN Language v0.3.0
; JIT-компилируемый BASIC на чистом Ассемблере x64
; 
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; https://github.com/GLK-Dev
;
; Phase 2: REPL + Лексер + JIT Core
; Платформа: Windows x64 (кроссплатформенная архитектура)
; ============================================================================

format PE64 console
entry start

; ----------------------------------------------------------------------------
; Подключение платформо-независимых констант
; ----------------------------------------------------------------------------
include '..\include\constants.inc'

; ----------------------------------------------------------------------------
; Дополнительные константы (локальные для main)
; ----------------------------------------------------------------------------
; Структура Token
TOKEN_SIZE    = 16
TOKEN_TYPE    = 0
TOKEN_SUBTYPE = 1
TOKEN_LENGTH  = 2
TOKEN_VALUE   = 8

; JIT константы
JIT_BUFFER_SIZE = 4096
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
MEM_RELEASE     = 0x8000
PAGE_EXECUTE_READWRITE = 0x40

; ----------------------------------------------------------------------------
; Импорт функций Windows API
; ----------------------------------------------------------------------------
section '.idata' import data readable

    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetStdHandle        dq RVA _GetStdHandle
        WriteConsoleA       dq RVA _WriteConsoleA
        ReadConsoleA        dq RVA _ReadConsoleA
        ExitProcess         dq RVA _ExitProcess
        VirtualAlloc        dq RVA _VirtualAlloc
        VirtualFree         dq RVA _VirtualFree
                            dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ReadConsoleA   db 0,0,'ReadConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0
    _VirtualFree    db 0,0,'VirtualFree',0

; ----------------------------------------------------------------------------
; Данные
; ----------------------------------------------------------------------------
section '.data' data readable writeable

    ; Заголовок при старте
    banner      db 'TITAN Language v0.3.0',13,10
                db 'JIT-Compiled BASIC for x64',13,10
                db '(c) 2025 mjojo & GLK-Dev',13,10
                db 'Type EXIT to quit, HELP for commands',13,10,13,10,0
    banner_len  = $ - banner - 1
    
    ; Приглашение ввода
    prompt      db 'TITAN> ',0
    prompt_len  = $ - prompt - 1
    
    ; Сообщение выхода
    bye_msg     db 13,10,'Goodbye!',13,10,0
    bye_len     = $ - bye_msg - 1
    
    newline     db 13,10,0
    
    ; Сообщения токенов для отладки
    msg_tok_num db '  [NUM: ',0
    msg_tok_str db '  [STR: "',0
    msg_tok_id  db '  [ID: ',0
    msg_tok_kw  db '  [KW: ',0
    msg_tok_op  db '  [OP: ',0
    msg_close   db ']',13,10,0
    msg_quote   db '"]',13,10,0
    
    ; Сообщения об ошибках
    err_jit_alloc   db 'ERROR: Failed to allocate JIT memory',13,10,0
    err_jit_alloc_len = $ - err_jit_alloc - 1
    
    ; Отладочные сообщения
    dbg_jit_exec    db '[JIT: Executing...]',13,10,0
    
    ; Названия ключевых слов для вывода
    kw_names:
        dq kw_print, kw_input, kw_cls, kw_let, kw_dim
        dq kw_goto, kw_if, kw_then, kw_else, kw_gosub
        dq kw_return, kw_end, kw_stop, kw_for, kw_to
        dq kw_step, kw_next, kw_while, kw_wend, kw_data
        dq kw_read, kw_restore, kw_and, kw_or, kw_not
        dq kw_run, kw_list, kw_new, kw_save, kw_load
        dq kw_exit_str, kw_help, kw_dump, kw_vars, kw_regs
        dq kw_rem
    
    kw_print    db 'PRINT',0
    kw_input    db 'INPUT',0
    kw_cls      db 'CLS',0
    kw_let      db 'LET',0
    kw_dim      db 'DIM',0
    kw_goto     db 'GOTO',0
    kw_if       db 'IF',0
    kw_then     db 'THEN',0
    kw_else     db 'ELSE',0
    kw_gosub    db 'GOSUB',0
    kw_return   db 'RETURN',0
    kw_end      db 'END',0
    kw_stop     db 'STOP',0
    kw_for      db 'FOR',0
    kw_to       db 'TO',0
    kw_step     db 'STEP',0
    kw_next     db 'NEXT',0
    kw_while    db 'WHILE',0
    kw_wend     db 'WEND',0
    kw_data     db 'DATA',0
    kw_read     db 'READ',0
    kw_restore  db 'RESTORE',0
    kw_and      db 'AND',0
    kw_or       db 'OR',0
    kw_not      db 'NOT',0
    kw_run      db 'RUN',0
    kw_list     db 'LIST',0
    kw_new      db 'NEW',0
    kw_save     db 'SAVE',0
    kw_load     db 'LOAD',0
    kw_exit_str db 'EXIT',0
    kw_help     db 'HELP',0
    kw_dump     db 'DUMP',0
    kw_vars     db 'VARS',0
    kw_regs     db 'REGS',0
    kw_rem      db 'REM',0
    
    ; Названия операторов
    op_names:
        dq op_plus, op_minus, op_mul, op_div, op_power
        dq op_eq, op_lt, op_gt, op_le, op_ge
        dq op_ne, op_lparen, op_rparen, op_comma, op_semi
        dq op_colon
    
    op_plus     db '+',0
    op_minus    db '-',0
    op_mul      db '*',0
    op_div      db '/',0
    op_power    db '^',0
    op_eq       db '=',0
    op_lt       db '<',0
    op_gt       db '>',0
    op_le       db '<=',0
    op_ge       db '>=',0
    op_ne       db '<>',0
    op_lparen   db '(',0
    op_rparen   db ')',0
    op_comma    db ',',0
    op_semi     db ';',0
    op_colon    db ':',0

    ; Таблица ключевых слов для лексера
    keywords_table:
        db 5, 'PRINT', KW_PRINT
        db 5, 'INPUT', KW_INPUT
        db 3, 'CLS',   KW_CLS
        db 3, 'LET',   KW_LET
        db 3, 'DIM',   KW_DIM
        db 4, 'GOTO',  KW_GOTO
        db 2, 'IF',    KW_IF
        db 4, 'THEN',  KW_THEN
        db 4, 'ELSE',  KW_ELSE
        db 5, 'GOSUB', KW_GOSUB
        db 6, 'RETURN',KW_RETURN
        db 3, 'END',   KW_END
        db 4, 'STOP',  KW_STOP
        db 3, 'FOR',   KW_FOR
        db 2, 'TO',    KW_TO
        db 4, 'STEP',  KW_STEP
        db 4, 'NEXT',  KW_NEXT
        db 5, 'WHILE', KW_WHILE
        db 4, 'WEND',  KW_WEND
        db 4, 'DATA',  KW_DATA
        db 4, 'READ',  KW_READ
        db 7, 'RESTORE', KW_RESTORE
        db 3, 'AND',   KW_AND
        db 2, 'OR',    KW_OR
        db 3, 'NOT',   KW_NOT
        db 3, 'RUN',   KW_RUN
        db 4, 'LIST',  KW_LIST
        db 3, 'NEW',   KW_NEW
        db 4, 'SAVE',  KW_SAVE
        db 4, 'LOAD',  KW_LOAD
        db 4, 'EXIT',  KW_EXIT
        db 4, 'QUIT',  KW_EXIT
        db 3, 'BYE',   KW_EXIT
        db 4, 'HELP',  KW_HELP
        db 4, 'DUMP',  KW_DUMP
        db 4, 'VARS',  KW_VARS
        db 4, 'REGS',  KW_REGS
        db 3, 'REM',   KW_REM
        db 0  ; Конец таблицы

; ----------------------------------------------------------------------------
; BSS (неинициализированные данные)
; ----------------------------------------------------------------------------
section '.bss' data readable writeable

    ; Платформо-зависимые переменные
    stdin_handle    dq ?
    stdout_handle   dq ?
    bytes_written   dd ?
    bytes_read      dd ?
    
    ; Буферы
    input_buffer    rb INPUT_BUFFER_SIZE
    
    ; Данные лексера
    lexer_pos       dq ?
    lexer_error     db ?
    
    ; Текущий токен
    current_token   rb TOKEN_SIZE
    
    ; Буфер для числа
    num_buffer      rb 24
    
    ; JIT буфер
    jit_buffer      dq ?            ; Указатель на JIT память
    jit_pos         dq ?            ; Текущая позиция в JIT буфере
    
    ; Временные переменные для JIT
    jit_str_ptr     dq ?            ; Указатель на строку для PRINT
    jit_str_len     dd ?            ; Длина строки для PRINT

; ----------------------------------------------------------------------------
; Код
; ----------------------------------------------------------------------------
section '.text' code readable executable

start:
    sub rsp, 40
    
    ; === Инициализация платформы ===
    mov ecx, STD_OUTPUT_HANDLE
    call [GetStdHandle]
    mov [stdout_handle], rax
    
    mov ecx, STD_INPUT_HANDLE
    call [GetStdHandle]
    mov [stdin_handle], rax
    
    ; === Выделение JIT памяти ===
    xor ecx, ecx                        ; lpAddress = NULL
    mov edx, JIT_BUFFER_SIZE            ; dwSize = 4096
    mov r8d, MEM_COMMIT or MEM_RESERVE  ; flAllocationType
    mov r9d, PAGE_EXECUTE_READWRITE     ; flProtect
    call [VirtualAlloc]
    test rax, rax
    jz .jit_alloc_failed
    mov [jit_buffer], rax
    mov [jit_pos], rax                  ; jit_pos = начало буфера
    jmp .jit_alloc_ok
    
.jit_alloc_failed:
    lea rdx, [err_jit_alloc]
    mov r8d, err_jit_alloc_len
    call print_string
    jmp exit_program
    
.jit_alloc_ok:
    ; Выводим баннер
    lea rdx, [banner]
    mov r8d, banner_len
    call print_string

; ----------------------------------------------------------------------------
; Главный цикл REPL
; ----------------------------------------------------------------------------
repl_loop:
    ; Выводим prompt
    lea rdx, [prompt]
    mov r8d, prompt_len
    call print_string
    
    ; Читаем ввод
    mov rcx, [stdin_handle]
    lea rdx, [input_buffer]
    mov r8d, INPUT_BUFFER_SIZE - 1
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call [ReadConsoleA]
    add rsp, 40
    
    ; Проверяем на EOF (bytes_read == 0)
    mov eax, [bytes_read]
    test eax, eax
    jz exit_program             ; EOF - выходим
    
    ; Убираем CR/LF
    cmp eax, 2
    jl repl_loop
    lea rdi, [input_buffer]
    add rdi, rax                ; rax уже содержит bytes_read после test
    sub rdi, 2
    mov byte [rdi], 0
    
    ; Инициализируем лексер
    lea rsi, [input_buffer]
    mov [lexer_pos], rsi
    mov byte [lexer_error], 0
    
    ; Читаем и выводим все токены
.tokenize_loop:
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Проверяем тип токена
    cmp al, TOKEN_EOL
    je .tokenize_done
    cmp al, 0
    je .tokenize_done
    
    ; Обрабатываем токен
    cmp al, TOKEN_KEYWORD
    je .handle_keyword
    cmp al, TOKEN_NUMBER
    je .handle_number
    cmp al, TOKEN_STRING
    je .handle_string
    cmp al, TOKEN_IDENTIFIER
    je .handle_identifier
    cmp al, TOKEN_OPERATOR
    je .handle_operator
    jmp .tokenize_loop

.handle_keyword:
    ; Проверяем на EXIT
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_EXIT
    je exit_program
    
    ; Проверяем на PRINT - пока временно отключено для отладки
    ; cmp al, KW_PRINT
    ; je .jit_print
    
    ; Остальные ключевые слова - отладочный вывод
    jmp .print_keyword_debug
    
; ============================================================================
; JIT-компиляция PRINT
; ============================================================================
.jit_print:
    ; Сбрасываем JIT указатель на начало буфера
    mov rax, [jit_buffer]
    mov [jit_pos], rax
    
    ; Получаем следующий токен (должна быть строка)
    ; lexer_next_token использует [lexer_pos] и rdi как указатель на токен
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Проверяем что это строка
    lea rbx, [current_token]
    movzx eax, byte [rbx + TOKEN_TYPE]
    cmp al, TOKEN_STRING
    jne .print_keyword_debug      ; Если не строка - просто отладка
    
    ; === Генерируем JIT код ===
    ; Сохраняем указатель на строку и её длину в статические переменные
    mov rax, qword [rbx + TOKEN_VALUE]
    mov [jit_str_ptr], rax
    movzx eax, word [rbx + TOKEN_LENGTH]
    mov [jit_str_len], eax
    
    ; Эмитим пролог
    mov rdi, [jit_pos]
    
    ; push rbp
    mov byte [rdi], 0x55
    inc rdi
    
    ; mov rbp, rsp
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x89
    mov byte [rdi+2], 0xE5
    add rdi, 3
    
    ; sub rsp, 40  (для shadow space + alignment)
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x83
    mov byte [rdi+2], 0xEC
    mov byte [rdi+3], 40
    add rdi, 4
    
    ; mov rcx, stdout_handle_value
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB9
    mov rax, [stdout_handle]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; mov rdx, string_ptr
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xBA
    mov rax, [jit_str_ptr]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; mov r8d, string_len
    mov byte [rdi], 0x41
    mov byte [rdi+1], 0xB8
    mov eax, [jit_str_len]
    mov dword [rdi+2], eax
    add rdi, 6
    
    ; mov r9, bytes_written_addr
    mov byte [rdi], 0x49
    mov byte [rdi+1], 0xB9
    lea rax, [bytes_written]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; mov qword [rsp+32], 0  (lpReserved = NULL)
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xC7
    mov byte [rdi+2], 0x44
    mov byte [rdi+3], 0x24
    mov byte [rdi+4], 32
    mov dword [rdi+5], 0
    add rdi, 9
    
    ; mov rax, WriteConsoleA_addr
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    mov rax, [WriteConsoleA]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; call rax
    mov byte [rdi], 0xFF
    mov byte [rdi+1], 0xD0
    add rdi, 2
    
    ; === Выводим перевод строки ===
    ; mov rcx, [stdout_handle]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB9
    mov rax, [stdout_handle]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; mov rdx, newline_addr
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xBA
    lea rax, [newline]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; mov r8d, 2 (длина CRLF)
    mov byte [rdi], 0x41
    mov byte [rdi+1], 0xB8
    mov dword [rdi+2], 2
    add rdi, 6
    
    ; mov r9, bytes_written_addr
    mov byte [rdi], 0x49
    mov byte [rdi+1], 0xB9
    lea rax, [bytes_written]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; mov qword [rsp+32], 0
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xC7
    mov byte [rdi+2], 0x44
    mov byte [rdi+3], 0x24
    mov byte [rdi+4], 32
    mov dword [rdi+5], 0
    add rdi, 9
    
    ; mov rax, WriteConsoleA_addr
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    mov rax, [WriteConsoleA]
    mov qword [rdi+2], rax
    add rdi, 10
    
    ; call rax
    mov byte [rdi], 0xFF
    mov byte [rdi+1], 0xD0
    add rdi, 2
    
    ; Эпилог
    ; add rsp, 40
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x83
    mov byte [rdi+2], 0xC4
    mov byte [rdi+3], 40
    add rdi, 4
    
    ; pop rbp
    mov byte [rdi], 0x5D
    inc rdi
    
    ; ret
    mov byte [rdi], 0xC3
    inc rdi
    
    ; Сохраняем позицию
    mov [jit_pos], rdi
    
    ; === Выполняем JIT код ===
    mov rax, [jit_buffer]
    call rax
    
    jmp .tokenize_loop

; Отладочный вывод ключевого слова
.print_keyword_debug:
    ; Выводим "[KW: название]"
    lea rdx, [msg_tok_kw]
    call print_cstring
    
    ; Получаем название ключевого слова
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    dec eax
    lea rbx, [kw_names]
    mov rdx, [rbx + rax*8]
    call print_cstring
    
    lea rdx, [msg_close]
    call print_cstring
    jmp .tokenize_loop

.handle_number:
    ; Выводим "[NUM: число]"
    lea rdx, [msg_tok_num]
    call print_cstring
    
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    call print_number
    
    lea rdx, [msg_close]
    call print_cstring
    jmp .tokenize_loop

.handle_string:
    ; Выводим '[STR: "строка"]'
    lea rdx, [msg_tok_str]
    call print_cstring
    
    ; Выводим саму строку
    lea rbx, [current_token]
    mov rdx, qword [rbx + TOKEN_VALUE]
    movzx r8d, word [rbx + TOKEN_LENGTH]
    call print_string
    
    lea rdx, [msg_quote]
    call print_cstring
    jmp .tokenize_loop

.handle_identifier:
    ; Выводим "[ID: имя]"
    lea rdx, [msg_tok_id]
    call print_cstring
    
    lea rbx, [current_token]
    mov rdx, qword [rbx + TOKEN_VALUE]
    movzx r8d, word [rbx + TOKEN_LENGTH]
    call print_string
    
    lea rdx, [msg_close]
    call print_cstring
    jmp .tokenize_loop

.handle_operator:
    ; Выводим "[OP: символ]"
    lea rdx, [msg_tok_op]
    call print_cstring
    
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    dec eax
    lea rbx, [op_names]
    mov rdx, [rbx + rax*8]
    call print_cstring
    
    lea rdx, [msg_close]
    call print_cstring
    jmp .tokenize_loop

.tokenize_done:
    jmp repl_loop

; ----------------------------------------------------------------------------
; Выход из программы
; ----------------------------------------------------------------------------
exit_program:
    lea rdx, [bye_msg]
    mov r8d, bye_len
    call print_string
    
    xor ecx, ecx
    call [ExitProcess]

; ============================================================================
; ЛЕКСЕР
; ============================================================================

lexer_next_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push r8
    push r9
    
    mov rsi, [lexer_pos]
    mov r8, rdi

    xor eax, eax
    mov [rdi + TOKEN_TYPE], al
    mov [rdi + TOKEN_SUBTYPE], al
    mov word [rdi + TOKEN_LENGTH], ax
    mov qword [rdi + TOKEN_VALUE], rax

.skip_whitespace:
    mov al, [rsi]
    cmp al, ' '
    je .next_ws
    cmp al, 9
    je .next_ws
    jmp .check_end
.next_ws:
    inc rsi
    jmp .skip_whitespace

.check_end:
    cmp al, 0
    je .token_eol
    cmp al, 13
    je .token_eol
    cmp al, 10
    je .token_eol
    cmp al, "'"
    je .token_comment
    cmp al, '"'
    je .token_string
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .token_number
.check_alpha:
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .token_identifier
.check_lower:
    cmp al, 'a'
    jl .token_operator
    cmp al, 'z'
    jle .token_identifier
    jmp .token_operator

.token_eol:
    mov byte [r8 + TOKEN_TYPE], TOKEN_EOL
    mov [lexer_pos], rsi
    mov al, TOKEN_EOL
    jmp .done

.token_comment:
.comment_skip:
    inc rsi
    mov al, [rsi]
    cmp al, 0
    je .token_eol
    cmp al, 13
    je .token_eol
    cmp al, 10
    je .token_eol
    jmp .comment_skip

.token_string:
    mov byte [r8 + TOKEN_TYPE], TOKEN_STRING
    inc rsi
    mov [r8 + TOKEN_VALUE], rsi
    xor ecx, ecx
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
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_STRING
    jmp .done
.string_error:
    mov byte [lexer_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.token_number:
    mov byte [r8 + TOKEN_TYPE], TOKEN_NUMBER
    xor rax, rax
    xor rbx, rbx
.number_loop:
    mov bl, [rsi]
    cmp bl, '0'
    jl .number_done
    cmp bl, '9'
    jg .number_done
    imul rax, 10
    sub bl, '0'
    add rax, rbx
    inc rsi
    jmp .number_loop
.number_done:
    mov [r8 + TOKEN_VALUE], rax
    mov [lexer_pos], rsi
    mov al, TOKEN_NUMBER
    jmp .done

.token_identifier:
    mov byte [r8 + TOKEN_TYPE], TOKEN_IDENTIFIER
    mov [r8 + TOKEN_VALUE], rsi
    xor ecx, ecx
.ident_loop:
    mov al, [rsi]
    cmp al, 'A'
    jl .ident_check_lower
    cmp al, 'Z'
    jle .ident_cont
.ident_check_lower:
    cmp al, 'a'
    jl .ident_check_digit
    cmp al, 'z'
    jle .ident_cont
.ident_check_digit:
    cmp al, '0'
    jl .ident_check_special
    cmp al, '9'
    jle .ident_cont
.ident_check_special:
    cmp al, '_'
    je .ident_cont
    cmp al, '$'
    je .ident_dollar
    jmp .ident_end
.ident_cont:
    inc ecx
    inc rsi
    jmp .ident_loop
.ident_dollar:
    inc ecx
    inc rsi
.ident_end:
    mov word [r8 + TOKEN_LENGTH], cx
    mov [lexer_pos], rsi
    
    push rsi
    mov rsi, [r8 + TOKEN_VALUE]
    mov edx, ecx
    call check_keyword
    pop rsi
    
    test eax, eax
    jz .ident_not_kw
    mov byte [r8 + TOKEN_TYPE], TOKEN_KEYWORD
    mov byte [r8 + TOKEN_SUBTYPE], al
    mov al, TOKEN_KEYWORD
    jmp .done
.ident_not_kw:
    mov al, TOKEN_IDENTIFIER
    jmp .done

.token_operator:
    mov byte [r8 + TOKEN_TYPE], TOKEN_OPERATOR
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
    je .op_eq
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
    je .op_semi
    cmp al, ':'
    je .op_colon
    
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
.op_eq:
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
.op_semi:
    mov byte [r8 + TOKEN_SUBTYPE], OP_SEMICOLON
    jmp .op_single
.op_colon:
    mov byte [r8 + TOKEN_SUBTYPE], OP_COLON
    jmp .op_single

.op_less:
    inc rsi
    mov al, [rsi]
    cmp al, '='
    je .op_le
    cmp al, '>'
    je .op_ne
    mov byte [r8 + TOKEN_SUBTYPE], OP_LT
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done
.op_le:
    mov byte [r8 + TOKEN_SUBTYPE], OP_LE
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done
.op_ne:
    mov byte [r8 + TOKEN_SUBTYPE], OP_NE
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done

.op_greater:
    inc rsi
    mov al, [rsi]
    cmp al, '='
    je .op_ge
    mov byte [r8 + TOKEN_SUBTYPE], OP_GT
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done
.op_ge:
    mov byte [r8 + TOKEN_SUBTYPE], OP_GE
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done

.op_single:
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done

.done:
    pop r9
    pop r8
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; check_keyword
; ----------------------------------------------------------------------------
check_keyword:
    push rbx
    push rcx
    push rdi
    push r10
    
    lea rdi, [keywords_table]

.kw_loop:
    movzx ecx, byte [rdi]
    test ecx, ecx
    jz .kw_not_found
    
    cmp ecx, edx
    jne .kw_next
    
    push rsi
    push rdi
    inc rdi
    mov r10d, ecx
    
.kw_compare:
    mov al, [rsi]
    mov bl, [rdi]
    
    cmp al, 'a'
    jl .kw_no_upper
    cmp al, 'z'
    jg .kw_no_upper
    sub al, 32
.kw_no_upper:
    
    cmp al, bl
    jne .kw_mismatch
    
    inc rsi
    inc rdi
    dec r10d
    jnz .kw_compare
    
    pop rdi
    pop rsi
    movzx rcx, byte [keywords_table]
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

; ============================================================================
; УТИЛИТЫ ВЫВОДА
; ============================================================================

print_string:
    push rcx
    mov rcx, [stdout_handle]
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    pop rcx
    ret

print_cstring:
    push rcx
    push r8
    push rsi
    
    mov rsi, rdx
    xor r8d, r8d
.count:
    cmp byte [rsi + r8], 0
    je .print
    inc r8d
    jmp .count
.print:
    mov rcx, [stdout_handle]
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    
    pop rsi
    pop r8
    pop rcx
    ret

print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    
    lea rcx, [num_buffer + 20]
    mov byte [rcx], 0
    mov rbx, 10
    
.conv_loop:
    xor edx, edx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .conv_loop
    
    lea rsi, [num_buffer + 20]
    sub rsi, rcx
    
    mov rdx, rcx
    mov r8d, esi
    call print_string
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
