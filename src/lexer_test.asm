; ============================================================================
; SYNAPSE Lexer Test Harness
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Простой тестовый драйвер для проверки lexer_v2.asm
; Читает тестовый ввод и выводит список токенов
; ============================================================================

format PE64 console
entry start

; ============================================================================
; Token constants
; ============================================================================
include '..\include\synapse_tokens.inc'

; Error constants (from TITAN)
ERR_SYNTAX = 1

; ============================================================================
; Import Windows API
; ============================================================================
section '.idata' import data readable
    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetStdHandle    dq RVA _GetStdHandle
        WriteConsoleA   dq RVA _WriteConsoleA
        ExitProcess     dq RVA _ExitProcess
                        dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0

; ============================================================================
; Data Section
; ============================================================================
section '.data' data readable writeable

    ; === Test Harness Messages ===
    banner      db 'SYNAPSE Lexer v2.0 - Test Harness',13,10
                db '==================================',13,10,13,10,0
    
    test_header db 'Tokenizing test input:',13,10
                db '----------------------',13,10,0

    done_msg    db 13,10,'Tokenization complete!',13,10,0
    
    ; Token type names
    tok_eof     db 'EOF',0
    tok_ident   db 'IDENT',0
    tok_number  db 'NUMBER',0
    tok_float   db 'FLOAT',0
    tok_string  db 'STRING',0
    tok_keyword db 'KEYWORD',0
    tok_operator db 'OPERATOR',0
    tok_newline db 'NEWLINE',0
    tok_indent  db 'INDENT',0
    tok_dedent  db 'DEDENT',0
    tok_comment db 'COMMENT',0
    tok_unknown db '?',0
    
    tok_names:
        dq tok_eof, tok_ident, tok_number, tok_float, tok_string
        dq tok_keyword, tok_operator, tok_newline, tok_indent, tok_dedent
        dq tok_comment
    
    ; Formatting
    fmt_prefix  db '  [',0
    fmt_line    db ' L',0
    fmt_col     db ':C',0
    fmt_close   db ']',13,10,0
    fmt_space   db ' ',0
    fmt_eq      db '=',0
    fmt_quote   db '"',0
    newline     db 13,10,0
    
    ; Keyword names for display
    kw_fn       db 'fn',0
    kw_let      db 'let',0
    kw_mut      db 'mut',0
    kw_if       db 'if',0
    kw_else     db 'else',0
    kw_for      db 'for',0
    kw_return   db 'return',0
    kw_tensor   db 'tensor',0
    kw_chain    db 'chain',0
    kw_contract db 'contract',0
    kw_print    db 'print',0
    kw_int      db 'int',0
    kw_other    db '?',0
    
    ; === Lexer Data (from lexer_v2) ===
    lexer_banner    db '[SYNAPSE Lexer v2.0]',13,10,0
    lexer_err_indent db 'Error: Inconsistent indentation',13,10,0
    lexer_err_tab   db 'Error: Tabs not allowed, use 4 spaces',13,10,0
    
    ; SYNAPSE Keywords table
    synapse_keywords:
        db 2, 'fn',       SKW_FN
        db 3, 'let',      SKW_LET
        db 3, 'mut',      SKW_MUT
        db 5, 'const',    SKW_CONST
        db 6, 'struct',   SKW_STRUCT
        db 4, 'enum',     SKW_ENUM
        db 6, 'module',   SKW_MODULE
        db 6, 'import',   SKW_IMPORT
        db 4, 'from',     SKW_FROM
        db 8, 'contract', SKW_CONTRACT
        db 6, 'neuron',   SKW_NEURON
        db 6, 'unsafe',   SKW_UNSAFE
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
        db 3, 'int',      SKW_INT
        db 4, 'int8',     SKW_INT8
        db 5, 'int16',    SKW_INT16
        db 5, 'int32',    SKW_INT32
        db 5, 'int64',    SKW_INT64
        db 3, 'f32',      SKW_F32
        db 3, 'f64',      SKW_F64
        db 4, 'bool',     SKW_BOOL
        db 6, 'string',   SKW_STRING
        db 6, 'tensor',   SKW_TENSOR
        db 3, 'Vec',      SKW_VEC
        db 7, 'hash256',  SKW_HASH256
        db 5, 'chain',    SKW_CHAIN
        db 6, 'global',   SKW_GLOBAL
        db 3, 'asm',      SKW_ASM
        db 3, 'and',      SKW_AND
        db 2, 'or',       SKW_OR
        db 3, 'not',      SKW_NOT
        db 4, 'true',     SKW_TRUE
        db 5, 'false',    SKW_FALSE
        db 5, 'print',    SKW_PRINT
        db 0  ; End of table
    
    ; === Test Input ===
    test_input  db 'fn main():',13,10
                db '    let x = 10',13,10
                db '    if x > 5:',13,10
                db '        print("Hello")',13,10
                db 0

; ============================================================================
; BSS Section
; ============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    
    ; Current token being parsed
    current_token   rb 24       ; STOKEN_SIZE = 24
    
    ; === Lexer State ===
    lex_source      rq 1
    lex_pos         rq 1
    lex_line_start  rq 1
    lex_line_num    dd ?
    lex_error       rb 1
    lex_at_line_start rb 1
    
    ; Indent stack
    MAX_INDENT_DEPTH = 32
    indent_stack    rd MAX_INDENT_DEPTH
    indent_top      dd ?
    current_indent  dd ?
    pending_dedents dd ?

; ============================================================================
; Code Section
; ============================================================================
section '.text' code readable executable

; ----------------------------------------------------------------------------
; Entry Point
; ----------------------------------------------------------------------------
start:
    sub rsp, 40             ; Shadow space
    
    ; Get stdout handle
    mov ecx, -11            ; STD_OUTPUT_HANDLE
    call [GetStdHandle]
    mov [stdout], rax
    
    ; Print banner
    lea rcx, [banner]
    call print_string
    
    ; Initialize lexer with test input
    lea rcx, [test_input]
    call synlex_init
    
    ; Print header
    lea rcx, [test_header]
    call print_string
    
.token_loop:
    ; Get next token
    lea rdi, [current_token]
    call synlex_next_token
    
    ; Print token
    call print_token
    
    ; Check for EOF (type == 0)
    movzx eax, byte [current_token]
    test eax, eax
    jnz .token_loop
    
    ; Done
    lea rcx, [done_msg]
    call print_string
    
    xor ecx, ecx
    call [ExitProcess]

; ----------------------------------------------------------------------------
; synlex_init: Initialize lexer
; Input: RCX = source pointer
; ----------------------------------------------------------------------------
synlex_init:
    mov [lex_source], rcx
    mov [lex_pos], rcx
    mov [lex_line_start], rcx
    mov dword [lex_line_num], 1
    mov byte [lex_error], 0
    mov byte [lex_at_line_start], 1
    
    ; Init indent stack
    lea rax, [indent_stack]
    mov dword [rax], 0
    mov dword [indent_top], 0
    mov dword [current_indent], 0
    mov dword [pending_dedents], 0
    ret

; ----------------------------------------------------------------------------
; synlex_next_token: Get next token
; Input: RDI = pointer to token structure
; Output: RAX = token type
; ----------------------------------------------------------------------------
synlex_next_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    
    mov r8, rdi             ; Save token pointer
    
    ; Clear token structure
    xor eax, eax
    mov [rdi], al           ; type
    mov [rdi + 1], al       ; subtype
    mov word [rdi + 2], ax  ; length
    mov word [rdi + 4], ax  ; line
    mov word [rdi + 6], ax  ; column
    mov qword [rdi + 8], rax ; value
    mov qword [rdi + 16], rax ; extra
    
    mov rsi, [lex_pos]
    
    ; Check pending dedents
    mov eax, [pending_dedents]
    test eax, eax
    jnz .emit_dedent
    
    ; Check if at line start (need to handle indentation)
    cmp byte [lex_at_line_start], 1
    jne .skip_whitespace
    
    ; Count indentation
    call count_indentation
    mov byte [lex_at_line_start], 0
    
    ; Handle indentation changes
    call handle_indentation
    
    ; Check if INDENT was generated
    cmp byte [r8], STOK_INDENT
    je .done
    
    ; Check pending dedents again
    mov eax, [pending_dedents]
    test eax, eax
    jnz .emit_dedent
    
    mov rsi, [lex_pos]

.skip_whitespace:
    mov al, [rsi]
    cmp al, ' '
    jne .check_char
    inc rsi
    jmp .skip_whitespace

.check_char:
    ; Set line/column
    mov eax, [lex_line_num]
    mov word [r8 + 4], ax
    mov rax, rsi
    sub rax, [lex_line_start]
    mov word [r8 + 6], ax
    
    mov al, [rsi]
    
    ; EOF?
    test al, al
    jz .token_eof
    
    ; Newline?
    cmp al, 13
    je .token_newline
    cmp al, 10
    je .token_newline
    
    ; Comment?
    cmp al, '/'
    je .check_comment
    cmp al, '#'
    je .line_comment
    
    ; String?
    cmp al, '"'
    je .token_string
    
    ; Number?
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .token_number

.check_alpha:
    ; Letter or underscore?
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .token_ident
.check_lower:
    cmp al, 'a'
    jl .check_under
    cmp al, 'z'
    jle .token_ident
.check_under:
    cmp al, '_'
    je .token_ident
    
    ; Operator
    jmp .token_operator

.emit_dedent:
    dec dword [pending_dedents]
    mov byte [r8], STOK_DEDENT
    mov eax, [lex_line_num]
    mov word [r8 + 4], ax
    mov eax, STOK_DEDENT
    jmp .done

.token_eof:
    ; Emit remaining dedents
    mov eax, [indent_top]
    test eax, eax
    jz .real_eof
    mov [pending_dedents], eax
    mov dword [indent_top], 0
    jmp .emit_dedent
.real_eof:
    mov byte [r8], STOK_EOF
    xor eax, eax
    jmp .done

.token_newline:
    mov byte [r8], STOK_NEWLINE
    cmp byte [rsi], 13
    jne .nl_lf
    inc rsi
.nl_lf:
    cmp byte [rsi], 10
    jne .nl_done
    inc rsi
.nl_done:
    inc dword [lex_line_num]
    mov [lex_line_start], rsi
    mov byte [lex_at_line_start], 1
    mov [lex_pos], rsi
    mov eax, STOK_NEWLINE
    jmp .done

.check_comment:
    cmp byte [rsi + 1], '/'
    je .line_comment
    jmp .token_operator

.line_comment:
    mov byte [r8], STOK_COMMENT
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

.token_string:
    mov byte [r8], STOK_STRING
    inc rsi
    mov [r8 + 8], rsi       ; value = string start
    xor ecx, ecx
.string_loop:
    mov al, [rsi]
    cmp al, '"'
    je .string_end
    test al, al
    jz .string_err
    cmp al, 10
    je .string_err
    inc ecx
    inc rsi
    jmp .string_loop
.string_end:
    mov word [r8 + 2], cx
    inc rsi
    mov [lex_pos], rsi
    mov eax, STOK_STRING
    jmp .done
.string_err:
    mov byte [lex_error], 1
    xor eax, eax
    jmp .done

.token_number:
    mov byte [r8], STOK_NUMBER
    mov [r8 + 8], rsi       ; value = number start
    xor ecx, ecx
.num_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_check_dot
    cmp al, '9'
    jg .num_check_dot
    inc ecx
    inc rsi
    jmp .num_loop
.num_check_dot:
    cmp al, '.'
    jne .num_done
    mov byte [r8], STOK_FLOAT
    inc ecx
    inc rsi
.num_frac:
    mov al, [rsi]
    cmp al, '0'
    jl .num_done
    cmp al, '9'
    jg .num_done
    inc ecx
    inc rsi
    jmp .num_frac
.num_done:
    mov word [r8 + 2], cx
    mov [lex_pos], rsi
    movzx eax, byte [r8]
    jmp .done

.token_ident:
    mov byte [r8], STOK_IDENT
    mov [r8 + 8], rsi
    xor ecx, ecx
.ident_loop:
    mov al, [rsi]
    cmp al, 'A'
    jl .id_lower
    cmp al, 'Z'
    jle .id_cont
.id_lower:
    cmp al, 'a'
    jl .id_digit
    cmp al, 'z'
    jle .id_cont
.id_digit:
    cmp al, '0'
    jl .id_under
    cmp al, '9'
    jle .id_cont
.id_under:
    cmp al, '_'
    jne .ident_end
.id_cont:
    inc ecx
    inc rsi
    jmp .ident_loop
.ident_end:
    mov word [r8 + 2], cx
    mov [lex_pos], rsi
    
    ; Check if keyword
    push rsi
    mov rsi, [r8 + 8]
    mov edx, ecx
    call check_keyword
    pop rsi
    test eax, eax
    jz .not_kw
    mov byte [r8], STOK_KEYWORD
    mov byte [r8 + 1], al
    mov eax, STOK_KEYWORD
    jmp .done
.not_kw:
    mov eax, STOK_IDENT
    jmp .done

.token_operator:
    mov byte [r8], STOK_OPERATOR
    mov al, [rsi]
    
    cmp al, '('
    je .op_lparen
    cmp al, ')'
    je .op_rparen
    cmp al, ':'
    je .op_colon
    cmp al, '='
    je .op_eq
    cmp al, '>'
    je .op_gt
    cmp al, '<'
    je .op_lt
    cmp al, '+'
    je .op_plus
    cmp al, '-'
    je .op_minus
    cmp al, '*'
    je .op_star
    cmp al, ','
    je .op_comma
    cmp al, '.'
    je .op_dot
    cmp al, '['
    je .op_lbracket
    cmp al, ']'
    je .op_rbracket
    
    ; Unknown - skip
    mov byte [r8 + 1], 0
    inc rsi
    jmp .op_done

.op_lparen:
    mov byte [r8 + 1], SOP_LPAREN
    jmp .op_single
.op_rparen:
    mov byte [r8 + 1], SOP_RPAREN
    jmp .op_single
.op_colon:
    mov byte [r8 + 1], SOP_COLON
    jmp .op_single
.op_comma:
    mov byte [r8 + 1], SOP_COMMA
    jmp .op_single
.op_lbracket:
    mov byte [r8 + 1], SOP_LBRACKET
    jmp .op_single
.op_rbracket:
    mov byte [r8 + 1], SOP_RBRACKET
    jmp .op_single
.op_plus:
    mov byte [r8 + 1], SOP_PLUS
    jmp .op_single
.op_star:
    mov byte [r8 + 1], SOP_MUL
    jmp .op_single
.op_dot:
    mov byte [r8 + 1], SOP_DOT
    jmp .op_single

.op_minus:
    cmp byte [rsi + 1], '>'
    jne .op_minus_single
    mov byte [r8 + 1], SOP_ARROW
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_minus_single:
    mov byte [r8 + 1], SOP_MINUS
    jmp .op_single

.op_eq:
    cmp byte [rsi + 1], '='
    jne .op_assign
    mov byte [r8 + 1], SOP_EQ
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_assign:
    mov byte [r8 + 1], SOP_ASSIGN
    jmp .op_single

.op_gt:
    cmp byte [rsi + 1], '='
    jne .op_gt_single
    mov byte [r8 + 1], SOP_GE
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_gt_single:
    mov byte [r8 + 1], SOP_GT
    jmp .op_single

.op_lt:
    ; Check for <dot>, <+>, etc
    cmp byte [rsi + 1], '='
    je .op_le
    cmp byte [rsi + 1], 'd'
    je .op_check_dot
    mov byte [r8 + 1], SOP_LT
    jmp .op_single
.op_le:
    mov byte [r8 + 1], SOP_LE
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_check_dot:
    cmp byte [rsi + 2], 'o'
    jne .op_lt_single
    cmp byte [rsi + 3], 't'
    jne .op_lt_single
    cmp byte [rsi + 4], '>'
    jne .op_lt_single
    mov byte [r8 + 1], SOP_DOT_PRODUCT
    mov word [r8 + 2], 5
    add rsi, 5
    jmp .op_done
.op_lt_single:
    mov byte [r8 + 1], SOP_LT
    jmp .op_single

.op_single:
    mov word [r8 + 2], 1
    inc rsi
.op_done:
    mov [lex_pos], rsi
    mov eax, STOK_OPERATOR
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
; count_indentation: Count spaces at line start
; ----------------------------------------------------------------------------
count_indentation:
    mov rsi, [lex_pos]
    xor edx, edx
.loop:
    mov al, [rsi]
    cmp al, ' '
    jne .done
    inc edx
    inc rsi
    jmp .loop
.done:
    ; Skip empty lines
    cmp al, 10
    je .empty
    cmp al, 13
    je .empty
    test al, al
    jz .empty
    mov [current_indent], edx
    mov [lex_pos], rsi
    ret
.empty:
    mov [lex_pos], rsi
    ret

; ----------------------------------------------------------------------------  
; handle_indentation: Generate INDENT/DEDENT tokens
; Input: r8 = token pointer
; ----------------------------------------------------------------------------
handle_indentation:
    mov eax, [current_indent]
    mov ebx, [indent_top]
    lea rdi, [indent_stack]
    mov ecx, [rdi + rbx*4]
    
    cmp eax, ecx
    je .same
    jg .indent
    jl .dedent
    
.same:
    ret

.indent:
    ; Push new level
    inc ebx
    cmp ebx, MAX_INDENT_DEPTH
    jge .error
    mov [rdi + rbx*4], eax
    mov [indent_top], ebx
    mov byte [r8], STOK_INDENT
    mov eax, [lex_line_num]
    mov word [r8 + 4], ax
    ret

.dedent:
    xor r9d, r9d
.dedent_loop:
    cmp ebx, 0
    jle .error
    dec ebx
    mov ecx, [rdi + rbx*4]
    inc r9d
    cmp eax, ecx
    jl .dedent_loop
    jne .error
    mov [indent_top], ebx
    mov [pending_dedents], r9d
    ret

.error:
    mov byte [lex_error], 1
    ret

; ----------------------------------------------------------------------------
; check_keyword: Check if identifier is keyword
; Input: RSI = string, EDX = length
; Output: EAX = keyword code (0 if not keyword)
; ----------------------------------------------------------------------------
check_keyword:
    push rbx
    push rcx
    push rdi
    push r10
    
    lea rdi, [synapse_keywords]
.loop:
    movzx ecx, byte [rdi]
    test ecx, ecx
    jz .not_found
    cmp ecx, edx
    jne .next
    
    ; Compare strings
    push rsi
    push rdi
    inc rdi
    mov r10d, ecx
.compare:
    mov al, [rsi]
    mov bl, [rdi]
    ; To lowercase
    cmp al, 'A'
    jl .skip1
    cmp al, 'Z'
    jg .skip1
    add al, 32
.skip1:
    cmp bl, 'A'
    jl .skip2
    cmp bl, 'Z'
    jg .skip2
    add bl, 32
.skip2:
    cmp al, bl
    jne .mismatch
    inc rsi
    inc rdi
    dec r10d
    jnz .compare
    
    ; Match!
    pop rdi
    pop rsi
    movzx rax, dl           ; edx contains length, extend to 64-bit
    add rdi, rax
    inc rdi
    movzx eax, byte [rdi]
    jmp .done

.mismatch:
    pop rdi
    pop rsi
.next:
    movzx ecx, byte [rdi]
    add rdi, rcx
    add rdi, 2
    jmp .loop
    
.not_found:
    xor eax, eax
.done:
    pop r10
    pop rdi
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; print_token: Print token info
; ----------------------------------------------------------------------------
print_token:
    push rbx
    push rsi
    
    lea rcx, [fmt_prefix]
    call print_string
    
    ; Get type name
    movzx eax, byte [current_token]
    cmp eax, 10
    ja .unknown
    lea rbx, [tok_names]
    mov rcx, [rbx + rax*8]
    call print_string
    jmp .print_value
.unknown:
    lea rcx, [tok_unknown]
    call print_string

.print_value:
    movzx eax, byte [current_token]
    
    cmp eax, STOK_KEYWORD
    je .print_kw
    cmp eax, STOK_IDENT
    je .print_id
    cmp eax, STOK_STRING
    je .print_str
    cmp eax, STOK_NUMBER
    je .print_num
    cmp eax, STOK_OPERATOR
    je .print_op
    jmp .print_loc

.print_kw:
    lea rcx, [fmt_eq]
    call print_string
    movzx eax, byte [current_token + 1]
    call get_kw_name
    mov rcx, rax
    call print_string
    jmp .print_loc

.print_id:
.print_num:
    lea rcx, [fmt_eq]
    call print_string
    mov rsi, qword [current_token + 8]
    movzx ecx, word [current_token + 2]
    call print_n
    jmp .print_loc

.print_str:
    lea rcx, [fmt_eq]
    call print_string
    lea rcx, [fmt_quote]
    call print_string
    mov rsi, qword [current_token + 8]
    movzx ecx, word [current_token + 2]
    call print_n
    lea rcx, [fmt_quote]
    call print_string
    jmp .print_loc

.print_op:
    lea rcx, [fmt_eq]
    call print_string
    movzx eax, byte [current_token + 1]
    call print_num
    jmp .print_loc

.print_loc:
    lea rcx, [fmt_line]
    call print_string
    movzx eax, word [current_token + 4]
    call print_num
    lea rcx, [fmt_col]
    call print_string
    movzx eax, word [current_token + 6]
    call print_num
    lea rcx, [fmt_close]
    call print_string
    
    pop rsi
    pop rbx
    ret

; ----------------------------------------------------------------------------
; get_kw_name: Get keyword name
; ----------------------------------------------------------------------------
get_kw_name:
    cmp eax, SKW_FN
    je .fn
    cmp eax, SKW_LET
    je .let
    cmp eax, SKW_MUT
    je .mut
    cmp eax, SKW_IF
    je .if
    cmp eax, SKW_ELSE
    je .else
    cmp eax, SKW_FOR
    je .for
    cmp eax, SKW_RETURN
    je .ret
    cmp eax, SKW_TENSOR
    je .tensor
    cmp eax, SKW_CHAIN
    je .chain
    cmp eax, SKW_CONTRACT
    je .contract
    cmp eax, SKW_PRINT
    je .print
    cmp eax, SKW_INT
    je .int
    lea rax, [kw_other]
    ret
.fn:    lea rax, [kw_fn]
        ret
.let:   lea rax, [kw_let]
        ret
.mut:   lea rax, [kw_mut]
        ret
.if:    lea rax, [kw_if]
        ret
.else:  lea rax, [kw_else]
        ret
.for:   lea rax, [kw_for]
        ret
.ret:   lea rax, [kw_return]
        ret
.tensor: lea rax, [kw_tensor]
        ret
.chain: lea rax, [kw_chain]
        ret
.contract: lea rax, [kw_contract]
        ret
.print: lea rax, [kw_print]
        ret
.int:   lea rax, [kw_int]
        ret

; ----------------------------------------------------------------------------
; print_string: Print null-terminated string
; ----------------------------------------------------------------------------
print_string:
    push rsi
    mov rsi, rcx
    xor ecx, ecx
.len:
    cmp byte [rsi + rcx], 0
    je .print
    inc ecx
    jmp .len
.print:
    sub rsp, 48
    mov rdx, rsi
    mov r8d, ecx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call [WriteConsoleA]
    add rsp, 48
    pop rsi
    ret

; ----------------------------------------------------------------------------
; print_n: Print N characters
; ----------------------------------------------------------------------------
print_n:
    test ecx, ecx
    jz .done
    sub rsp, 48
    mov rdx, rsi
    mov r8d, ecx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call [WriteConsoleA]
    add rsp, 48
.done:
    ret

; ----------------------------------------------------------------------------
; print_num: Print integer
; ----------------------------------------------------------------------------
print_num:
    push rbx
    push rdi
    
    lea rdi, [num_buffer + 20]
    mov byte [rdi], 0
    dec rdi
    
    test eax, eax
    jnz .conv
    mov byte [rdi], '0'
    dec rdi
    jmp .print
.conv:
    mov ebx, 10
.loop:
    test eax, eax
    jz .print
    xor edx, edx
    div ebx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    jmp .loop
.print:
    inc rdi
    mov rcx, rdi
    call print_string
    
    pop rdi
    pop rbx
    ret
