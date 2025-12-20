; =============================================================================
; SYNAPSE Lexer + Parser Test
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Combined test: Lexer -> Parser -> Results
; =============================================================================

format PE64 console
entry start

; Token constants
include '..\include\synapse_tokens.inc'

; Error constant
ERR_SYNTAX = 1

; Token structure size
PARSER_TOKEN_SIZE = 24

; =============================================================================
; Import Windows API
; =============================================================================
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

; =============================================================================
; Data Section
; =============================================================================
section '.data' data readable writeable

    ; === Banners ===
    banner      db 'SYNAPSE Language - Lexer + Parser Test',13,10
                db '=======================================',13,10,13,10,0
    
    lexer_done  db 13,10,'=== Lexer Complete ===',13,10,13,10,0
    parser_start db '=== Starting Parser ===',13,10,0
    parser_done db 13,10,'=== Parser Complete ===',13,10,0
    
    all_pass    db 13,10,'[SUCCESS] All tests passed!',13,10,0
    test_fail   db 13,10,'[FAILED] Parser errors detected',13,10,0
    
    newline     db 13,10,0

    ; === Parser messages ===
    parse_ok_msg    db '[PARSE] OK: ',0
    parse_err_msg   db '[PARSE] ERROR: ',0
    parse_let_msg   db 'let declaration',13,10,0
    parse_fn_msg    db 'fn declaration',13,10,0
    
    err_expect_ident    db 'Expected identifier',13,10,0
    err_expect_colon    db 'Expected ":"',13,10,0
    err_expect_type     db 'Expected type',13,10,0
    err_expect_eq       db 'Expected "="',13,10,0
    err_expect_lt       db 'Expected "<"',13,10,0
    err_expect_gt       db 'Expected ">"',13,10,0
    err_expect_comma    db 'Expected ","',13,10,0
    err_expect_lbracket db 'Expected "["',13,10,0
    err_expect_rbracket db 'Expected "]"',13,10,0
    err_expect_lparen   db 'Expected "("',13,10,0
    err_expect_rparen   db 'Expected ")"',13,10,0

    ; === SYNAPSE Keywords table ===
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
        db 0

    ; === Test Input - SYNAPSE code ===
    test_input  db 'fn main():',13,10
                db '    let x: int = 10',13,10
                db '    let y: f32 = 3.14',13,10
                db '    let weights: tensor<f32, [784, 128]> = 0',13,10
                db 0

; =============================================================================
; BSS Section
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    
    ; Token storage
    MAX_TOKENS = 1024
    token_storage   rb PARSER_TOKEN_SIZE * MAX_TOKENS
    token_count     dd ?
    token_write_ptr dq ?
    
    ; Current token for lexer
    current_token   rb 24
    
    ; Lexer state
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
    
    ; Parser state
    parse_token_ptr dq ?
    parse_error     db ?
    parsed_var_name dq ?
    parsed_var_len  dd ?
    parsed_var_type dd ?

; =============================================================================
; Code Section
; =============================================================================
section '.text' code readable executable

; =============================================================================
; Entry Point
; =============================================================================
start:
    sub rsp, 40
    
    ; Get stdout
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    ; Print banner
    lea rcx, [banner]
    call print_string
    
    ; === PHASE 1: Lexing ===
    lea rcx, [test_input]
    call synlex_init
    
    ; Reset token storage
    lea rax, [token_storage]
    mov [token_write_ptr], rax
    mov dword [token_count], 0
    
    ; Tokenize all input
.lex_loop:
    lea rdi, [current_token]
    call synlex_next_token
    
    ; Store token
    mov rsi, [token_write_ptr]
    lea rdi, [current_token]
    mov ecx, 24
    rep movsb
    mov [token_write_ptr], rsi
    inc dword [token_count]
    
    ; Check for EOF
    movzx eax, byte [current_token]
    test eax, eax
    jnz .lex_loop
    
    lea rcx, [lexer_done]
    call print_string
    
    ; === PHASE 2: Parsing ===
    lea rcx, [parser_start]
    call print_string
    
    ; Calculate token list end
    lea rcx, [token_storage]
    mov eax, [token_count]
    imul eax, PARSER_TOKEN_SIZE
    lea rdx, [rcx + rax]
    
    call parser_init
    call parse_program
    
    ; Check result
    test eax, eax
    jz .failed
    
    lea rcx, [parser_done]
    call print_string
    lea rcx, [all_pass]
    call print_string
    jmp .exit

.failed:
    lea rcx, [test_fail]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; LEXER (embedded)
; =============================================================================

synlex_init:
    mov [lex_source], rcx
    mov [lex_pos], rcx
    mov [lex_line_start], rcx
    mov dword [lex_line_num], 1
    mov byte [lex_error], 0
    mov byte [lex_at_line_start], 1
    lea rax, [indent_stack]
    mov dword [rax], 0
    mov dword [indent_top], 0
    mov dword [current_indent], 0
    mov dword [pending_dedents], 0
    ret

synlex_next_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    
    mov r8, rdi
    xor eax, eax
    mov [rdi], al
    mov [rdi + 1], al
    mov word [rdi + 2], ax
    mov word [rdi + 4], ax
    mov word [rdi + 6], ax
    mov qword [rdi + 8], rax
    mov qword [rdi + 16], rax
    
    mov rsi, [lex_pos]
    
    mov eax, [pending_dedents]
    test eax, eax
    jnz .emit_dedent
    
    cmp byte [lex_at_line_start], 1
    jne .skip_ws
    
    call lex_count_indent
    mov byte [lex_at_line_start], 0
    call lex_handle_indent
    
    cmp byte [r8], STOK_INDENT
    je .done
    
    mov eax, [pending_dedents]
    test eax, eax
    jnz .emit_dedent
    
    mov rsi, [lex_pos]

.skip_ws:
    mov al, [rsi]
    cmp al, ' '
    jne .check_char
    inc rsi
    jmp .skip_ws

.check_char:
    mov eax, [lex_line_num]
    mov word [r8 + 4], ax
    mov rax, rsi
    sub rax, [lex_line_start]
    mov word [r8 + 6], ax
    
    mov al, [rsi]
    test al, al
    jz .token_eof
    cmp al, 13
    je .token_nl
    cmp al, 10
    je .token_nl
    cmp al, '#'
    je .token_comment
    cmp al, '/'
    je .check_comment
    cmp al, '"'
    je .token_str
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .token_num
.check_alpha:
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .token_id
.check_lower:
    cmp al, 'a'
    jl .check_under
    cmp al, 'z'
    jle .token_id
.check_under:
    cmp al, '_'
    je .token_id
    jmp .token_op

.emit_dedent:
    dec dword [pending_dedents]
    mov byte [r8], STOK_DEDENT
    mov eax, [lex_line_num]
    mov word [r8 + 4], ax
    mov eax, STOK_DEDENT
    jmp .done

.token_eof:
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

.token_nl:
    mov byte [r8], STOK_NEWLINE
    cmp byte [rsi], 13
    jne .nl1
    inc rsi
.nl1:
    cmp byte [rsi], 10
    jne .nl2
    inc rsi
.nl2:
    inc dword [lex_line_num]
    mov [lex_line_start], rsi
    mov byte [lex_at_line_start], 1
    mov [lex_pos], rsi
    mov eax, STOK_NEWLINE
    jmp .done

.check_comment:
    cmp byte [rsi + 1], '/'
    je .token_comment
    jmp .token_op

.token_comment:
    mov byte [r8], STOK_COMMENT
.cmnt_loop:
    inc rsi
    mov al, [rsi]
    test al, al
    jz .cmnt_end
    cmp al, 13
    je .cmnt_end
    cmp al, 10
    je .cmnt_end
    jmp .cmnt_loop
.cmnt_end:
    mov [lex_pos], rsi
    mov eax, STOK_COMMENT
    jmp .done

.token_str:
    mov byte [r8], STOK_STRING
    inc rsi
    mov [r8 + 8], rsi
    xor ecx, ecx
.str_loop:
    mov al, [rsi]
    cmp al, '"'
    je .str_end
    test al, al
    jz .str_err
    cmp al, 10
    je .str_err
    inc ecx
    inc rsi
    jmp .str_loop
.str_end:
    mov word [r8 + 2], cx
    inc rsi
    mov [lex_pos], rsi
    mov eax, STOK_STRING
    jmp .done
.str_err:
    mov byte [lex_error], 1
    xor eax, eax
    jmp .done

.token_num:
    mov byte [r8], STOK_NUMBER
    mov [r8 + 8], rsi
    xor ecx, ecx
.num_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_dot
    cmp al, '9'
    jg .num_dot
    inc ecx
    inc rsi
    jmp .num_loop
.num_dot:
    cmp al, '.'
    jne .num_end
    mov byte [r8], STOK_FLOAT
    inc ecx
    inc rsi
.num_frac:
    mov al, [rsi]
    cmp al, '0'
    jl .num_end
    cmp al, '9'
    jg .num_end
    inc ecx
    inc rsi
    jmp .num_frac
.num_end:
    mov word [r8 + 2], cx
    mov [lex_pos], rsi
    movzx eax, byte [r8]
    jmp .done

.token_id:
    mov byte [r8], STOK_IDENT
    mov [r8 + 8], rsi
    xor ecx, ecx
.id_loop:
    mov al, [rsi]
    cmp al, 'A'
    jl .id_low
    cmp al, 'Z'
    jle .id_cont
.id_low:
    cmp al, 'a'
    jl .id_dig
    cmp al, 'z'
    jle .id_cont
.id_dig:
    cmp al, '0'
    jl .id_und
    cmp al, '9'
    jle .id_cont
.id_und:
    cmp al, '_'
    jne .id_end
.id_cont:
    inc ecx
    inc rsi
    jmp .id_loop
.id_end:
    mov word [r8 + 2], cx
    mov [lex_pos], rsi
    push rsi
    mov rsi, [r8 + 8]
    mov edx, ecx
    call lex_check_kw
    pop rsi
    test eax, eax
    jz .id_not_kw
    mov byte [r8], STOK_KEYWORD
    mov byte [r8 + 1], al
    mov eax, STOK_KEYWORD
    jmp .done
.id_not_kw:
    mov eax, STOK_IDENT
    jmp .done

.token_op:
    mov byte [r8], STOK_OPERATOR
    mov al, [rsi]
    cmp al, '('
    je .op_lp
    cmp al, ')'
    je .op_rp
    cmp al, ':'
    je .op_col
    cmp al, '='
    je .op_eq
    cmp al, '>'
    je .op_gt
    cmp al, '<'
    je .op_lt
    cmp al, '+'
    je .op_plus
    cmp al, '-'
    je .op_min
    cmp al, '*'
    je .op_mul
    cmp al, ','
    je .op_com
    cmp al, '.'
    je .op_dot
    cmp al, '['
    je .op_lb
    cmp al, ']'
    je .op_rb
    mov byte [r8 + 1], 0
    inc rsi
    jmp .op_done

.op_lp:
    mov byte [r8 + 1], SOP_LPAREN
    jmp .op_1
.op_rp:
    mov byte [r8 + 1], SOP_RPAREN
    jmp .op_1
.op_col:
    mov byte [r8 + 1], SOP_COLON
    jmp .op_1
.op_com:
    mov byte [r8 + 1], SOP_COMMA
    jmp .op_1
.op_lb:
    mov byte [r8 + 1], SOP_LBRACKET
    jmp .op_1
.op_rb:
    mov byte [r8 + 1], SOP_RBRACKET
    jmp .op_1
.op_plus:
    mov byte [r8 + 1], SOP_PLUS
    jmp .op_1
.op_mul:
    mov byte [r8 + 1], SOP_MUL
    jmp .op_1
.op_dot:
    mov byte [r8 + 1], SOP_DOT
    jmp .op_1
    
.op_min:
    cmp byte [rsi + 1], '>'
    jne .op_min1
    mov byte [r8 + 1], SOP_ARROW
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_min1:
    mov byte [r8 + 1], SOP_MINUS
    jmp .op_1

.op_eq:
    cmp byte [rsi + 1], '='
    jne .op_asgn
    mov byte [r8 + 1], SOP_EQ
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_asgn:
    mov byte [r8 + 1], SOP_ASSIGN
    jmp .op_1

.op_gt:
    cmp byte [rsi + 1], '='
    jne .op_gt1
    mov byte [r8 + 1], SOP_GE
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_gt1:
    mov byte [r8 + 1], SOP_GT
    jmp .op_1

.op_lt:
    cmp byte [rsi + 1], '='
    je .op_le
    cmp byte [rsi + 1], 'd'
    je .op_dot_check
    mov byte [r8 + 1], SOP_LT
    jmp .op_1
.op_le:
    mov byte [r8 + 1], SOP_LE
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done
.op_dot_check:
    cmp byte [rsi + 2], 'o'
    jne .op_lt1
    cmp byte [rsi + 3], 't'
    jne .op_lt1
    cmp byte [rsi + 4], '>'
    jne .op_lt1
    mov byte [r8 + 1], SOP_DOT_PRODUCT
    mov word [r8 + 2], 5
    add rsi, 5
    jmp .op_done
.op_lt1:
    mov byte [r8 + 1], SOP_LT
    jmp .op_1

.op_1:
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

lex_count_indent:
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

lex_handle_indent:
    mov eax, [current_indent]
    mov ebx, [indent_top]
    lea rdi, [indent_stack]
    mov ecx, [rdi + rbx*4]
    cmp eax, ecx
    je .same
    jg .ind
    jl .ded
.same:
    ret
.ind:
    inc ebx
    cmp ebx, MAX_INDENT_DEPTH
    jge .err
    mov [rdi + rbx*4], eax
    mov [indent_top], ebx
    mov byte [r8], STOK_INDENT
    mov eax, [lex_line_num]
    mov word [r8 + 4], ax
    ret
.ded:
    xor r9d, r9d
.ded_loop:
    cmp ebx, 0
    jle .err
    dec ebx
    mov ecx, [rdi + rbx*4]
    inc r9d
    cmp eax, ecx
    jl .ded_loop
    jne .err
    mov [indent_top], ebx
    mov [pending_dedents], r9d
    ret
.err:
    mov byte [lex_error], 1
    ret

lex_check_kw:
    push rbx
    push rcx
    push rdi
    push r10
    lea rdi, [synapse_keywords]
.loop:
    movzx ecx, byte [rdi]
    test ecx, ecx
    jz .nf
    cmp ecx, edx
    jne .next
    push rsi
    push rdi
    inc rdi
    mov r10d, ecx
.cmp:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, 'A'
    jl .s1
    cmp al, 'Z'
    jg .s1
    add al, 32
.s1:
    cmp bl, 'A'
    jl .s2
    cmp bl, 'Z'
    jg .s2
    add bl, 32
.s2:
    cmp al, bl
    jne .mm
    inc rsi
    inc rdi
    dec r10d
    jnz .cmp
    pop rdi
    pop rsi
    movzx rax, dl
    add rdi, rax
    inc rdi
    movzx eax, byte [rdi]
    jmp .done
.mm:
    pop rdi
    pop rsi
.next:
    movzx ecx, byte [rdi]
    add rdi, rcx
    add rdi, 2
    jmp .loop
.nf:
    xor eax, eax
.done:
    pop r10
    pop rdi
    pop rcx
    pop rbx
    ret

; =============================================================================
; PARSER
; =============================================================================

parser_init:
    mov [parse_token_ptr], rcx
    mov byte [parse_error], 0
    ret

ps_current:
    mov rax, [parse_token_ptr]
    cmp rax, rdx
    jae .eof
    ret
.eof:
    xor rax, rax
    ret

ps_type:
    call ps_current
    test rax, rax
    jz .eof
    movzx eax, byte [rax]
    ret
.eof:
    mov eax, STOK_EOF
    ret

ps_subtype:
    call ps_current
    test rax, rax
    jz .none
    movzx eax, byte [rax + 1]
    ret
.none:
    xor eax, eax
    ret

ps_advance:
    mov rax, [parse_token_ptr]
    add rax, PARSER_TOKEN_SIZE
    mov [parse_token_ptr], rax
    ret

ps_expect_kw:
    push rcx
    call ps_type
    cmp eax, STOK_KEYWORD
    pop rcx
    jne .no
    push rcx
    call ps_subtype
    pop rcx
    cmp eax, ecx
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

ps_expect_op:
    push rcx
    call ps_type
    cmp eax, STOK_OPERATOR
    pop rcx
    jne .no
    push rcx
    call ps_subtype
    pop rcx
    cmp eax, ecx
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

parse_program:
    push rbx
    push r12
    push r13
    mov r13, rdx            ; Save end pointer
    
.loop:
    call ps_type
    cmp eax, STOK_EOF
    je .success
    cmp eax, STOK_NEWLINE
    je .skip
    cmp eax, STOK_COMMENT
    je .skip
    cmp eax, STOK_INDENT
    je .skip
    cmp eax, STOK_DEDENT
    je .skip
    cmp eax, STOK_KEYWORD
    jne .skip
    
    call ps_subtype
    cmp eax, SKW_LET
    je .let
    cmp eax, SKW_FN
    je .fn
    cmp eax, SKW_MUT
    je .mut
    jmp .skip

.skip:
    call ps_advance
    jmp .loop

.let:
    call parse_let
    test eax, eax
    jz .error
    jmp .loop

.fn:
    call parse_fn
    test eax, eax
    jz .error
    jmp .loop

.mut:
    call ps_advance
    call parse_let_body
    test eax, eax
    jz .error
    jmp .loop

.success:
    mov eax, 1
    jmp .done
.error:
    xor eax, eax
.done:
    pop r13
    pop r12
    pop rbx
    ret

parse_let:
    push rbx
    call ps_advance         ; Skip 'let'
    call parse_let_body
    pop rbx
    ret

parse_let_body:
    push rbx
    push r12
    
    call ps_type
    cmp eax, STOK_IDENT
    jne .err_id
    call ps_advance
    
    mov ecx, SOP_COLON
    call ps_expect_op
    test eax, eax
    jz .check_eq
    call ps_advance
    
    call parse_type
    test eax, eax
    jz .err_type

.check_eq:
    mov ecx, SOP_ASSIGN
    call ps_expect_op
    test eax, eax
    jz .success
    call ps_advance
    
    call parse_expr
    test eax, eax
    jz .error

.success:
    lea rcx, [parse_ok_msg]
    call print_string
    lea rcx, [parse_let_msg]
    call print_string
    mov eax, 1
    jmp .done

.err_id:
    lea rcx, [err_expect_ident]
    call print_string
    jmp .error
.err_type:
    lea rcx, [err_expect_type]
    call print_string
.error:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

parse_fn:
    push rbx
    call ps_advance         ; Skip 'fn'
    
    call ps_type
    cmp eax, STOK_IDENT
    jne .err_id
    call ps_advance
    
    mov ecx, SOP_LPAREN
    call ps_expect_op
    test eax, eax
    jz .err_lp
    call ps_advance
    
.param_loop:
    mov ecx, SOP_RPAREN
    call ps_expect_op
    test eax, eax
    jnz .param_done
    call ps_advance
    jmp .param_loop
.param_done:
    call ps_advance
    
    mov ecx, SOP_ARROW
    call ps_expect_op
    test eax, eax
    jz .check_col
    call ps_advance
    call parse_type
    test eax, eax
    jz .err_type

.check_col:
    mov ecx, SOP_COLON
    call ps_expect_op
    test eax, eax
    jz .err_col
    call ps_advance
    
    lea rcx, [parse_ok_msg]
    call print_string
    lea rcx, [parse_fn_msg]
    call print_string
    mov eax, 1
    jmp .done

.err_id:
    lea rcx, [err_expect_ident]
    call print_string
    jmp .error
.err_lp:
    lea rcx, [err_expect_lparen]
    call print_string
    jmp .error
.err_type:
    lea rcx, [err_expect_type]
    call print_string
    jmp .error
.err_col:
    lea rcx, [err_expect_colon]
    call print_string
.error:
    xor eax, eax
.done:
    pop rbx
    ret

parse_type:
    push rbx
    push r12
    
    call ps_type
    cmp eax, STOK_KEYWORD
    jne .error
    
    call ps_subtype
    mov r12d, eax
    
    cmp eax, SKW_INT
    je .simple
    cmp eax, SKW_INT8
    je .simple
    cmp eax, SKW_INT16
    je .simple
    cmp eax, SKW_INT32
    je .simple
    cmp eax, SKW_INT64
    je .simple
    cmp eax, SKW_F32
    je .simple
    cmp eax, SKW_F64
    je .simple
    cmp eax, SKW_BOOL
    je .simple
    cmp eax, SKW_STRING
    je .simple
    cmp eax, SKW_TENSOR
    je .tensor
    cmp eax, SKW_VEC
    je .vec
    cmp eax, SKW_HASH256
    je .simple
    jmp .error

.simple:
    call ps_advance
    mov eax, r12d
    jmp .done

.tensor:
    call ps_advance
    mov ecx, SOP_LT
    call ps_expect_op
    test eax, eax
    jz .err_lt
    call ps_advance
    
    call parse_type
    test eax, eax
    jz .error
    mov r12d, eax
    
    mov ecx, SOP_COMMA
    call ps_expect_op
    test eax, eax
    jz .err_com
    call ps_advance
    
    mov ecx, SOP_LBRACKET
    call ps_expect_op
    test eax, eax
    jz .err_lb
    call ps_advance
    
.shape_loop:
    mov ecx, SOP_RBRACKET
    call ps_expect_op
    test eax, eax
    jnz .shape_done
    call ps_advance
    jmp .shape_loop
.shape_done:
    call ps_advance
    
    mov ecx, SOP_GT
    call ps_expect_op
    test eax, eax
    jz .err_gt
    call ps_advance
    
    mov eax, 100
    add eax, r12d
    jmp .done

.vec:
    call ps_advance
    mov ecx, SOP_LT
    call ps_expect_op
    test eax, eax
    jz .err_lt
    call ps_advance
    call parse_type
    test eax, eax
    jz .error
    mov r12d, eax
    mov ecx, SOP_GT
    call ps_expect_op
    test eax, eax
    jz .err_gt
    call ps_advance
    mov eax, 200
    add eax, r12d
    jmp .done

.err_lt:
    lea rcx, [err_expect_lt]
    call print_string
    jmp .error
.err_gt:
    lea rcx, [err_expect_gt]
    call print_string
    jmp .error
.err_com:
    lea rcx, [err_expect_comma]
    call print_string
    jmp .error
.err_lb:
    lea rcx, [err_expect_lbracket]
    call print_string
    jmp .error

.error:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

parse_expr:
    call ps_type
    cmp eax, STOK_NUMBER
    je .ok
    cmp eax, STOK_FLOAT
    je .ok
    cmp eax, STOK_STRING
    je .ok
    cmp eax, STOK_IDENT
    je .ok
    xor eax, eax
    ret
.ok:
    call ps_advance
    mov eax, 1
    ret

; =============================================================================
; Utility functions
; =============================================================================

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
