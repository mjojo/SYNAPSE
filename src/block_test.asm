; =============================================================================
; SYNAPSE Block Parser Test (Phase 1.4)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests recursive block parsing: fn -> if -> nested blocks
; =============================================================================

format PE64 console
entry start

; Includes
include '..\include\synapse_tokens.inc'
include '..\include\ast.inc'

ERR_SYNTAX = 1
PARSER_TOKEN_SIZE = 24
MAX_INDENT_DEPTH = 32

; =============================================================================
; Imports
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
; Data
; =============================================================================
section '.data' data readable writeable

    banner      db 'SYNAPSE Block Parser Test (Phase 1.4)',13,10
                db '======================================',13,10,13,10,0
    
    phase1_msg  db '[PHASE 1] Lexing...',13,10,0
    phase2_msg  db '[PHASE 2] Parsing with block recursion...',13,10,0
    
    ; AST Messages
    msg_func        db '[AST] fn ',0
    msg_block_in    db '[AST] BLOCK_START (depth=',0
    msg_block_out   db '[AST] BLOCK_END   (depth=',0
    msg_if          db '[AST] if statement',13,10,0
    msg_elif        db '[AST] elif statement',13,10,0
    msg_else        db '[AST] else statement',13,10,0
    msg_let         db '[AST] let ',0
    msg_return      db '[AST] return',13,10,0
    msg_for         db '[AST] for loop',13,10,0
    msg_while       db '[AST] while loop',13,10,0
    msg_pass        db '[AST] pass',13,10,0
    msg_assign      db '[AST] assignment',13,10,0
    msg_call        db '[AST] function call',13,10,0
    
    msg_close       db ')',13,10,0
    msg_newline     db 13,10,0
    
    success_msg     db 13,10,'[SUCCESS] All blocks parsed correctly!',13,10,0
    fail_msg        db 13,10,'[FAILED] Parse error encountered',13,10,0
    
    ; Error messages
    err_indent      db '[ERROR] Expected INDENT',13,10,0
    err_dedent      db '[ERROR] Unexpected DEDENT',13,10,0
    err_colon       db '[ERROR] Expected ":"',13,10,0
    err_ident       db '[ERROR] Expected identifier',13,10,0
    err_eof         db '[ERROR] Unexpected end of file',13,10,0

    ; Keywords table
    synapse_keywords:
        db 2, 'fn',       SKW_FN
        db 3, 'let',      SKW_LET
        db 3, 'mut',      SKW_MUT
        db 5, 'const',    SKW_CONST
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
        db 5, 'print',    SKW_PRINT
        db 3, 'and',      SKW_AND
        db 2, 'or',       SKW_OR
        db 3, 'not',      SKW_NOT
        db 4, 'true',     SKW_TRUE
        db 5, 'false',    SKW_FALSE
        db 0

    ; === TEST INPUT ===
    ; Nested blocks test
    test_input  db 'fn main():',13,10
                db '    let x: int = 1',13,10
                db '    if x > 0:',13,10
                db '        let y: int = 2',13,10
                db '        if y > 1:',13,10
                db '            return',13,10
                db '    let z: int = 3',13,10
                db 0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    
    ; Tokens
    MAX_TOKENS = 2048
    token_storage   rb PARSER_TOKEN_SIZE * MAX_TOKENS
    token_count     dd ?
    token_write_ptr dq ?
    current_token   rb 24
    
    ; Lexer state
    lex_source      rq 1
    lex_pos         rq 1
    lex_line_start  rq 1
    lex_line_num    dd ?
    lex_error       rb 1
    lex_at_line_start rb 1
    indent_stack    rd MAX_INDENT_DEPTH
    indent_top      dd ?
    current_indent  dd ?
    pending_dedents dd ?
    
    ; Parser state
    parse_token_ptr dq ?
    parse_token_end dq ?
    parse_error     db ?
    parse_depth     dd ?      ; Block nesting depth
    
    ; AST storage
    ast_buffer      rb AST_NODE_SIZE * 1024
    ast_ptr         dq ?

; =============================================================================
; Code
; =============================================================================
section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    ; === PHASE 1: LEXING ===
    lea rcx, [phase1_msg]
    call print_string
    
    lea rcx, [test_input]
    call synlex_init
    
    lea rax, [token_storage]
    mov [token_write_ptr], rax
    mov dword [token_count], 0
    
.lex_loop:
    lea rdi, [current_token]
    call synlex_next_token
    
    mov rsi, [token_write_ptr]
    lea rdi, [current_token]
    mov ecx, 24
    rep movsb
    mov [token_write_ptr], rsi
    inc dword [token_count]
    
    movzx eax, byte [current_token]
    test eax, eax
    jnz .lex_loop
    
    ; === PHASE 2: PARSING ===
    lea rcx, [phase2_msg]
    call print_string
    
    lea rcx, [token_storage]
    mov eax, [token_count]
    imul eax, PARSER_TOKEN_SIZE
    lea rdx, [rcx + rax]
    call parser_init
    
    call parse_program
    test eax, eax
    jz .failed
    
    lea rcx, [success_msg]
    call print_string
    jmp .exit

.failed:
    lea rcx, [fail_msg]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; PARSER (Block-Aware)
; =============================================================================

parser_init:
    mov [parse_token_ptr], rcx
    mov [parse_token_end], rdx
    mov byte [parse_error], 0
    mov dword [parse_depth], 0
    lea rax, [ast_buffer]
    mov [ast_ptr], rax
    ret

; Get current token pointer
ps_current:
    mov rax, [parse_token_ptr]
    mov rdx, [parse_token_end]
    cmp rax, rdx
    jae .eof
    ret
.eof:
    xor rax, rax
    ret

; Get token type
ps_type:
    call ps_current
    test rax, rax
    jz .eof
    movzx eax, byte [rax]
    ret
.eof:
    mov eax, STOK_EOF
    ret

; Get token subtype
ps_subtype:
    call ps_current
    test rax, rax
    jz .none
    movzx eax, byte [rax + 1]
    ret
.none:
    xor eax, eax
    ret

; Get token value pointer
ps_value:
    call ps_current
    test rax, rax
    jz .none
    mov rax, qword [rax + 8]
    ret
.none:
    xor rax, rax
    ret

; Get token length
ps_length:
    call ps_current
    test rax, rax
    jz .none
    movzx eax, word [rax + 2]
    ret
.none:
    xor eax, eax
    ret

; Advance to next token
ps_advance:
    mov rax, [parse_token_ptr]
    add rax, PARSER_TOKEN_SIZE
    mov [parse_token_ptr], rax
    ret

; Check if current is specific keyword
ps_is_keyword:
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

; Check if current is specific operator
ps_is_operator:
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

; =============================================================================
; parse_program - Main entry
; =============================================================================
parse_program:
    push rbx
    push r12
    
.loop:
    call ps_type
    cmp eax, STOK_EOF
    je .success
    
    ; Skip whitespace tokens
    cmp eax, STOK_NEWLINE
    je .skip
    cmp eax, STOK_COMMENT
    je .skip
    
    ; Check for function declaration
    cmp eax, STOK_KEYWORD
    jne .skip
    
    call ps_subtype
    cmp eax, SKW_FN
    je .do_fn
    
    jmp .skip

.skip:
    call ps_advance
    jmp .loop

.do_fn:
    call parse_fn
    test eax, eax
    jz .error
    jmp .loop

.success:
    mov eax, 1
    jmp .done
.error:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

; =============================================================================
; parse_fn - Function declaration
; Grammar: 'fn' IDENT '(' ... ')' ['->' TYPE] ':' NEWLINE BLOCK
; =============================================================================
parse_fn:
    push rbx
    push r12
    
    call ps_advance         ; Skip 'fn'
    
    ; Print message
    lea rcx, [msg_func]
    call print_string
    
    ; Get function name
    call ps_type
    cmp eax, STOK_IDENT
    jne .err_ident
    
    ; Print name
    call ps_value
    mov rsi, rax
    call ps_length
    mov ecx, eax
    call print_n
    
    lea rcx, [msg_newline]
    call print_string
    
    call ps_advance
    
    ; Skip until ':'
.skip_until_colon:
    mov ecx, SOP_COLON
    call ps_is_operator
    test eax, eax
    jnz .found_colon
    call ps_type
    cmp eax, STOK_EOF
    je .err_eof
    call ps_advance
    jmp .skip_until_colon

.found_colon:
    call ps_advance         ; Skip ':'
    
    ; Skip NEWLINE if present
    call ps_type
    cmp eax, STOK_NEWLINE
    jne .parse_body
    call ps_advance

.parse_body:
    ; Parse function body (BLOCK)
    call parse_block
    test eax, eax
    jz .error
    
    mov eax, 1
    jmp .done

.err_ident:
    lea rcx, [err_ident]
    call print_string
    jmp .error
.err_eof:
    lea rcx, [err_eof]
    call print_string
.error:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

; =============================================================================
; parse_block - Recursive block parsing
; Grammar: INDENT statement* DEDENT
; =============================================================================
parse_block:
    push rbx
    push r12
    push r13
    
    ; Check for INDENT
    call ps_type
    cmp eax, STOK_INDENT
    jne .err_indent
    
    call ps_advance
    inc dword [parse_depth]
    
    ; Print block start
    lea rcx, [msg_block_in]
    call print_string
    mov eax, [parse_depth]
    call print_num
    lea rcx, [msg_close]
    call print_string
    
    ; Statement loop
.stmt_loop:
    call ps_type
    
    ; Check for DEDENT (end of block)
    cmp eax, STOK_DEDENT
    je .block_done
    
    ; Check for EOF
    cmp eax, STOK_EOF
    je .err_eof
    
    ; Skip newlines
    cmp eax, STOK_NEWLINE
    je .skip_nl
    cmp eax, STOK_COMMENT
    je .skip_nl
    
    ; Dispatch statements
    cmp eax, STOK_KEYWORD
    jne .try_ident
    
    call ps_subtype
    
    cmp eax, SKW_IF
    je .do_if
    cmp eax, SKW_ELIF
    je .do_elif
    cmp eax, SKW_ELSE
    je .do_else
    cmp eax, SKW_LET
    je .do_let
    cmp eax, SKW_MUT
    je .do_let
    cmp eax, SKW_RETURN
    je .do_return
    cmp eax, SKW_FOR
    je .do_for
    cmp eax, SKW_WHILE
    je .do_while
    cmp eax, SKW_PASS
    je .do_pass
    cmp eax, SKW_BREAK
    je .do_simple
    cmp eax, SKW_CONTINUE
    je .do_simple
    
    ; Unknown keyword - skip
    jmp .skip_stmt

.try_ident:
    ; Could be assignment or function call
    cmp eax, STOK_IDENT
    je .do_ident_stmt
    
    ; Skip unknown
    jmp .skip_stmt

.skip_nl:
    call ps_advance
    jmp .stmt_loop

.skip_stmt:
    call ps_advance
    jmp .stmt_loop

.do_if:
    call parse_if
    test eax, eax
    jz .error
    jmp .stmt_loop

.do_elif:
    lea rcx, [msg_elif]
    call print_string
    call parse_conditional_block
    test eax, eax
    jz .error
    jmp .stmt_loop

.do_else:
    lea rcx, [msg_else]
    call print_string
    call ps_advance         ; Skip 'else'
    mov ecx, SOP_COLON
    call ps_is_operator
    test eax, eax
    jz .err_colon
    call ps_advance
    call ps_type
    cmp eax, STOK_NEWLINE
    jne .else_block
    call ps_advance
.else_block:
    call parse_block
    test eax, eax
    jz .error
    jmp .stmt_loop

.do_let:
    call parse_let
    test eax, eax
    jz .error
    jmp .stmt_loop

.do_return:
    lea rcx, [msg_return]
    call print_string
    call ps_advance         ; Skip 'return'
    ; Skip expression until newline
.ret_skip:
    call ps_type
    cmp eax, STOK_NEWLINE
    je .stmt_loop
    cmp eax, STOK_DEDENT
    je .stmt_loop
    cmp eax, STOK_EOF
    je .stmt_loop
    call ps_advance
    jmp .ret_skip

.do_for:
    lea rcx, [msg_for]
    call print_string
    call parse_conditional_block
    test eax, eax
    jz .error
    jmp .stmt_loop

.do_while:
    lea rcx, [msg_while]
    call print_string
    call parse_conditional_block
    test eax, eax
    jz .error
    jmp .stmt_loop

.do_pass:
    lea rcx, [msg_pass]
    call print_string
    call ps_advance
    jmp .stmt_loop

.do_simple:
    call ps_advance
    jmp .stmt_loop

.do_ident_stmt:
    ; Could be assignment: x = value
    ; Or function call: print(x)
    lea rcx, [msg_assign]
    call print_string
    ; Skip until newline
.ident_skip:
    call ps_type
    cmp eax, STOK_NEWLINE
    je .stmt_loop
    cmp eax, STOK_DEDENT
    je .stmt_loop
    cmp eax, STOK_EOF
    je .stmt_loop
    call ps_advance
    jmp .ident_skip

.block_done:
    call ps_advance         ; Consume DEDENT
    
    ; Print block end
    lea rcx, [msg_block_out]
    call print_string
    mov eax, [parse_depth]
    call print_num
    lea rcx, [msg_close]
    call print_string
    
    dec dword [parse_depth]
    
    mov eax, 1
    jmp .done

.err_indent:
    lea rcx, [err_indent]
    call print_string
    jmp .error
.err_colon:
    lea rcx, [err_colon]
    call print_string
    jmp .error
.err_eof:
    lea rcx, [err_eof]
    call print_string
.error:
    xor eax, eax
.done:
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; parse_if - If statement
; Grammar: 'if' EXPR ':' NEWLINE BLOCK
; =============================================================================
parse_if:
    push rbx
    
    lea rcx, [msg_if]
    call print_string
    
    call parse_conditional_block
    
    pop rbx
    ret

; =============================================================================
; parse_conditional_block - Shared by if/elif/for/while
; Skips condition, expects ':', then parses block
; =============================================================================
parse_conditional_block:
    push rbx
    
    call ps_advance         ; Skip keyword (if/elif/for/while)
    
    ; Skip until ':'
.skip_cond:
    mov ecx, SOP_COLON
    call ps_is_operator
    test eax, eax
    jnz .found_colon
    call ps_type
    cmp eax, STOK_EOF
    je .err_eof
    cmp eax, STOK_NEWLINE
    je .err_colon
    call ps_advance
    jmp .skip_cond

.found_colon:
    call ps_advance         ; Skip ':'
    
    ; Skip newline
    call ps_type
    cmp eax, STOK_NEWLINE
    jne .do_block
    call ps_advance

.do_block:
    call parse_block
    
    pop rbx
    ret

.err_colon:
    lea rcx, [err_colon]
    call print_string
    xor eax, eax
    pop rbx
    ret
.err_eof:
    lea rcx, [err_eof]
    call print_string
    xor eax, eax
    pop rbx
    ret

; =============================================================================
; parse_let - Variable declaration
; =============================================================================
parse_let:
    push rbx
    
    lea rcx, [msg_let]
    call print_string
    
    call ps_advance         ; Skip 'let' or 'mut'
    
    ; Get variable name
    call ps_type
    cmp eax, STOK_IDENT
    jne .err_ident
    
    call ps_value
    mov rsi, rax
    call ps_length
    mov ecx, eax
    call print_n
    
    lea rcx, [msg_newline]
    call print_string
    
    ; Skip until newline
.skip_rest:
    call ps_type
    cmp eax, STOK_NEWLINE
    je .done
    cmp eax, STOK_DEDENT
    je .done
    cmp eax, STOK_EOF
    je .done
    call ps_advance
    jmp .skip_rest

.done:
    mov eax, 1
    pop rbx
    ret

.err_ident:
    lea rcx, [err_ident]
    call print_string
    xor eax, eax
    pop rbx
    ret

; =============================================================================
; LEXER (embedded - same as before)
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
    je .token_cmt
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

.token_cmt:
    mov byte [r8], STOK_COMMENT
.cmt_loop:
    inc rsi
    mov al, [rsi]
    test al, al
    jz .cmt_end
    cmp al, 13
    je .cmt_end
    cmp al, 10
    je .cmt_end
    jmp .cmt_loop
.cmt_end:
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
    mov byte [r8 + 1], SOP_LT
    jmp .op_1
.op_le:
    mov byte [r8 + 1], SOP_LE
    mov word [r8 + 2], 2
    add rsi, 2
    jmp .op_done

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
; Utility
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
