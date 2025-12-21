; =============================================================================
; SYNAPSE v1.1 - Control Flow Test Suite
; Тестирование парсинга условных операторов
; =============================================================================

format PE64 console
entry start

include 'win64a.inc'

; Включаем определения токенов и AST
include '..\include\synapse_tokens.inc'
include '..\include\ast.inc'

section '.text' code readable executable

start:
    sub rsp, 40
    
    ; Инициализация системы
    call synlex_init
    call parser_init
    
    ; Заголовок
    invoke WriteFile, [stdout], banner, banner_len, bytes_written, 0
    
    ; === Тест 1: Простое if ===
    invoke WriteFile, [stdout], test1_header, test1_header_len, bytes_written, 0
    
    lea rcx, [test1_code]
    mov edx, test1_code_len
    call run_parser_test
    
    ; === Тест 2: if-else ===
    invoke WriteFile, [stdout], test2_header, test2_header_len, bytes_written, 0
    
    lea rcx, [test2_code]
    mov edx, test2_code_len
    call run_parser_test
    
    ; === Тест 3: if-elif-else ===
    invoke WriteFile, [stdout], test3_header, test3_header_len, bytes_written, 0
    
    lea rcx, [test3_code]
    mov edx, test3_code_len
    call run_parser_test
    
    ; === Тест 4: Вложенные условия ===
    invoke WriteFile, [stdout], test4_header, test4_header_len, bytes_written, 0
    
    lea rcx, [test4_code]
    mov edx, test4_code_len
    call run_parser_test
    
    ; === Тест 5: while loop ===
    invoke WriteFile, [stdout], test5_header, test5_header_len, bytes_written, 0
    
    lea rcx, [test5_code]
    mov edx, test5_code_len
    call run_parser_test
    
    ; Завершение
    invoke WriteFile, [stdout], complete_msg, complete_msg_len, bytes_written, 0
    
    xor ecx, ecx
    call ExitProcess

; -----------------------------------------------------------------------------
; run_parser_test: Запуск теста парсера
; Вход: RCX = указатель на код, EDX = длина кода
; -----------------------------------------------------------------------------
run_parser_test:
    push rbx
    push rdi
    push rsi
    
    ; Сохраняем параметры
    mov rsi, rcx
    mov edi, edx
    
    ; Инициализируем лексер
    call synlex_reset
    
    ; Сканируем код
    mov rcx, rsi
    mov edx, edi
    call synlex_scan
    
    ; Проверяем результат
    test eax, eax
    jnz .lex_error
    
    ; Выводим токены (отладка)
    call print_tokens
    
    ; Парсим токены
    call parser_reset
    call parser_parse_program
    
    test eax, eax
    jnz .parse_error
    
    ; Выводим AST (отладка)
    call print_ast
    
    ; Успех
    invoke WriteFile, [stdout], success_msg, success_msg_len, bytes_written, 0
    jmp .done
    
.lex_error:
    invoke WriteFile, [stdout], lex_error_msg, lex_error_msg_len, bytes_written, 0
    jmp .done
    
.parse_error:
    invoke WriteFile, [stdout], parse_error_msg, parse_error_msg_len, bytes_written, 0
    
.done:
    pop rsi
    pop rdi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; print_tokens: Вывод списка токенов (отладка)
; -----------------------------------------------------------------------------
print_tokens:
    push rbx
    push rdi
    
    invoke WriteFile, [stdout], tokens_header, tokens_header_len, bytes_written, 0
    
    ; TODO: Реализовать обход списка токенов
    ; Для каждого токена выводим: тип, подтип, значение
    
    pop rdi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; print_ast: Вывод AST дерева (отладка)
; -----------------------------------------------------------------------------
print_ast:
    push rbx
    push rdi
    
    invoke WriteFile, [stdout], ast_header, ast_header_len, bytes_written, 0
    
    ; TODO: Реализовать рекурсивный обход AST
    ; Выводим структуру дерева с отступами
    
    pop rdi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; Заглушки для функций лексера и парсера
; (Будут заменены включением реальных модулей)
; -----------------------------------------------------------------------------
synlex_init:
    ret

synlex_reset:
    ret

synlex_scan:
    xor eax, eax  ; Успех
    ret

parser_init:
    ret

parser_reset:
    ret

parser_parse_program:
    xor eax, eax  ; Успех
    ret

; =============================================================================
; Секция данных
; =============================================================================
section '.data' data readable writeable

    ; Вывод
    stdout          dq ?
    bytes_written   dd ?
    
    ; Баннер
    banner          db '========================================', 13, 10
                    db 'SYNAPSE v1.1 - Control Flow Test Suite', 13, 10
                    db '========================================', 13, 10, 0
    banner_len      = $ - banner
    
    ; Тестовые кейсы
    test1_header    db 13, 10, '[TEST 1] Simple if condition', 13, 10, 0
    test1_header_len = $ - test1_header
    test1_code      db 'if x > 0:', 13, 10
                    db '    return true', 13, 10, 0
    test1_code_len  = $ - test1_code
    
    test2_header    db 13, 10, '[TEST 2] if-else', 13, 10, 0
    test2_header_len = $ - test2_header
    test2_code      db 'if x > 0:', 13, 10
                    db '    return 1', 13, 10
                    db 'else:', 13, 10
                    db '    return -1', 13, 10, 0
    test2_code_len  = $ - test2_code
    
    test3_header    db 13, 10, '[TEST 3] if-elif-else', 13, 10, 0
    test3_header_len = $ - test3_header
    test3_code      db 'if x > 0:', 13, 10
                    db '    return 1', 13, 10
                    db 'elif x < 0:', 13, 10
                    db '    return -1', 13, 10
                    db 'else:', 13, 10
                    db '    return 0', 13, 10, 0
    test3_code_len  = $ - test3_code
    
    test4_header    db 13, 10, '[TEST 4] Nested conditions', 13, 10, 0
    test4_header_len = $ - test4_header
    test4_code      db 'if a > 0:', 13, 10
                    db '    if b > 0:', 13, 10
                    db '        return 1', 13, 10
                    db '    else:', 13, 10
                    db '        return 2', 13, 10
                    db 'else:', 13, 10
                    db '    return 0', 13, 10, 0
    test4_code_len  = $ - test4_code
    
    test5_header    db 13, 10, '[TEST 5] while loop', 13, 10, 0
    test5_header_len = $ - test5_header
    test5_code      db 'while i < 10:', 13, 10
                    db '    i = i + 1', 13, 10, 0
    test5_code_len  = $ - test5_code
    
    ; Сообщения
    success_msg     db '  [OK] Test passed', 13, 10, 0
    success_msg_len = $ - success_msg
    
    lex_error_msg   db '  [ERROR] Lexer failed', 13, 10, 0
    lex_error_msg_len = $ - lex_error_msg
    
    parse_error_msg db '  [ERROR] Parser failed', 13, 10, 0
    parse_error_msg_len = $ - parse_error_msg
    
    tokens_header   db '  Tokens: ', 0
    tokens_header_len = $ - tokens_header
    
    ast_header      db '  AST: ', 0
    ast_header_len  = $ - ast_header
    
    complete_msg    db 13, 10, '========================================', 13, 10
                    db 'All tests completed', 13, 10
                    db '========================================', 13, 10, 0
    complete_msg_len = $ - complete_msg

; =============================================================================
; Секция импорта
; =============================================================================
section '.idata' import data readable

    library kernel32, 'KERNEL32.DLL'
    
    import kernel32, \
        ExitProcess, 'ExitProcess', \
        GetStdHandle, 'GetStdHandle', \
        WriteFile, 'WriteFile'

; =============================================================================
; Инициализация
; =============================================================================
section '.bss' readable writeable

    ; Буферы будут инициализированы в synlex_init

; =============================================================================
; Точка входа - получение stdout
; =============================================================================
section '.text' code readable executable

synlex_init:
    push rcx
    push rdx
    
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax
    
    pop rdx
    pop rcx
    ret

STD_OUTPUT_HANDLE = -11
