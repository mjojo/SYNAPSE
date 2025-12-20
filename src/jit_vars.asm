; =============================================================================
; SYNAPSE JIT v2 - Variables + Arithmetic
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Test: let x = 40; let y = 2; return x + y → 42
; =============================================================================

format PE64 console
entry start

include '..\include\synapse_tokens.inc'
include '..\include\ast.inc'

PARSER_TOKEN_SIZE = 24
MAX_INDENT_DEPTH = 32

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_EXECUTE_READWRITE = 0x40

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
        VirtualAlloc    dq RVA _VirtualAlloc
                        dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0

; =============================================================================
; Data
; =============================================================================
section '.data' data readable writeable

    banner      db '================================================',13,10
                db '  SYNAPSE JIT v2 - Variables + Arithmetic',13,10
                db '================================================',13,10,13,10,0
    
    phase1_msg  db '[PHASE 1] Lexing...',13,10,0
    phase2_msg  db '[PHASE 2] Parsing variables and expressions...',13,10,0
    phase3_msg  db '[PHASE 3] Generating x64 code with stack frame...',13,10,0
    phase4_msg  db '[PHASE 4] Executing JIT...',13,10,0
    
    result_msg  db 13,10,'[RESULT] JIT returned: ',0
    success_msg db 13,10,13,10,'*** SUCCESS! 40 + 2 = 42! ***',13,10,0
    fail_msg    db 13,10,'[FAILED] Expected 42',13,10,0
    
    jit_bytes_msg db '[JIT] Generated ',0
    jit_bytes_end db ' bytes',13,10,0
    
    var_msg     db '[VAR] ',0
    eq_msg      db ' = ',0
    at_msg      db ' @ [rbp-',0
    close_msg   db ']',13,10,0
    
    newline     db 13,10,0

    ; Keywords
    synapse_keywords:
        db 2, 'fn',       SKW_FN
        db 3, 'let',      SKW_LET
        db 6, 'return',   SKW_RETURN
        db 3, 'int',      SKW_INT
        db 0

    ; === TEST SOURCE CODE ===
    source_code db 'fn main():',13,10
                db '    let x: int = 40',13,10
                db '    let y: int = 2',13,10
                db '    return x + y',13,10
                db 0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    
    ; Tokens
    MAX_TOKENS = 512
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
    
    ; Symbol Table (simple: 16 entries max)
    ; Each entry: 8 bytes name_ptr, 4 bytes name_len, 4 bytes stack_offset, 8 bytes value
    MAX_VARS = 16
    VAR_ENTRY_SIZE = 24
    var_table       rb VAR_ENTRY_SIZE * MAX_VARS
    var_count       dd ?
    stack_offset    dd ?      ; Current stack offset (grows negative)
    
    ; Return expression info
    ret_is_expr     db ?      ; 1 if return has expression
    ret_var1_idx    dd ?      ; First variable index
    ret_var2_idx    dd ?      ; Second variable index (for binary op)
    ret_op          db ?      ; Operator (SOP_PLUS, etc)
    ret_immediate   dq ?      ; If returning immediate value
    
    ; JIT
    jit_buffer      dq ?
    jit_cursor      dq ?
    jit_start       dq ?

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
    
    ; ===========================================
    ; PHASE 1: LEXING
    ; ===========================================
    lea rcx, [phase1_msg]
    call print_string
    
    lea rcx, [source_code]
    call synlex_init
    
    lea rax, [token_storage]
    mov [token_write_ptr], rax
    mov dword [token_count], 0
    
.lex_loop:
    lea rdi, [current_token]
    call synlex_next_token
    
    lea rsi, [current_token]
    mov rdi, [token_write_ptr]
    mov ecx, 24
    rep movsb
    mov [token_write_ptr], rdi
    inc dword [token_count]
    
    movzx eax, byte [current_token]
    test eax, eax
    jnz .lex_loop
    
    ; ===========================================
    ; PHASE 2: PARSING
    ; ===========================================
    lea rcx, [phase2_msg]
    call print_string
    
    ; Init parser
    lea rcx, [token_storage]
    mov eax, [token_count]
    imul eax, PARSER_TOKEN_SIZE
    lea rdx, [rcx + rax]
    mov [parse_token_ptr], rcx
    mov [parse_token_end], rdx
    
    ; Init symbol table
    mov dword [var_count], 0
    mov dword [stack_offset], 0
    mov byte [ret_is_expr], 0
    
    ; Parse program
    call parse_program
    test eax, eax
    jz .failed
    
    ; ===========================================
    ; PHASE 3: CODE GENERATION
    ; ===========================================
    lea rcx, [phase3_msg]
    call print_string
    
    call codegen_init
    test rax, rax
    jz .failed
    
    call codegen_function
    
    ; Print bytes
    lea rcx, [jit_bytes_msg]
    call print_string
    mov rax, [jit_cursor]
    sub rax, [jit_start]
    call print_num
    lea rcx, [jit_bytes_end]
    call print_string
    
    ; ===========================================
    ; PHASE 4: EXECUTE
    ; ===========================================
    lea rcx, [phase4_msg]
    call print_string
    
    mov rax, [jit_buffer]
    call rax
    
    push rax
    lea rcx, [result_msg]
    call print_string
    pop rax
    push rax
    call print_num
    lea rcx, [newline]
    call print_string
    
    pop rax
    cmp rax, 42
    jne .failed
    
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
; PARSER
; =============================================================================

parse_program:
    push rbx
    push r12
    
.loop:
    call ps_type
    cmp eax, STOK_EOF
    je .success
    
    ; Skip whitespace
    cmp eax, STOK_NEWLINE
    je .skip
    cmp eax, STOK_INDENT
    je .skip
    cmp eax, STOK_DEDENT
    je .skip
    
    cmp eax, STOK_KEYWORD
    jne .skip
    
    call ps_subtype
    cmp eax, SKW_LET
    je .do_let
    cmp eax, SKW_RETURN
    je .do_return
    jmp .skip

.skip:
    call ps_advance
    jmp .loop

.do_let:
    call parse_let
    test eax, eax
    jz .error
    jmp .loop

.do_return:
    call parse_return
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

; Parse: let NAME [: TYPE] = VALUE
parse_let:
    push rbx
    push r12
    push r13
    
    call ps_advance         ; Skip 'let'
    
    ; Get variable name
    call ps_type
    cmp eax, STOK_IDENT
    jne .error
    
    ; Get name pointer and length
    call ps_current
    mov r12, qword [rax + 8]    ; name ptr
    movzx r13d, word [rax + 2]  ; name len
    
    call ps_advance
    
    ; Skip optional ': TYPE'
.skip_type:
    call ps_type
    cmp eax, STOK_OPERATOR
    jne .check_eq
    call ps_subtype
    cmp eax, SOP_COLON
    jne .check_eq
    call ps_advance
    ; Skip type keyword
    call ps_type
    cmp eax, STOK_KEYWORD
    jne .check_eq
    call ps_advance

.check_eq:
    ; Expect '='
    call ps_type
    cmp eax, STOK_OPERATOR
    jne .error
    call ps_subtype
    cmp eax, SOP_ASSIGN
    jne .error
    call ps_advance
    
    ; Get value (number)
    call ps_type
    cmp eax, STOK_NUMBER
    jne .error
    
    call ps_current
    mov rsi, qword [rax + 8]
    movzx ecx, word [rax + 2]
    call parse_number
    mov rbx, rax              ; value in rbx
    
    call ps_advance
    
    ; Add to symbol table
    mov eax, [var_count]
    cmp eax, MAX_VARS
    jge .error
    
    ; Calculate entry address
    imul eax, VAR_ENTRY_SIZE
    lea rdi, [var_table + rax]
    
    ; Store: name_ptr, name_len, stack_offset, value
    mov [rdi], r12              ; name pointer
    mov [rdi + 8], r13d         ; name length
    
    ; Allocate stack space (8 bytes per variable)
    sub dword [stack_offset], 8
    mov eax, [stack_offset]
    neg eax                     ; Store positive offset
    mov [rdi + 12], eax         ; stack offset
    mov [rdi + 16], rbx         ; initial value
    
    inc dword [var_count]
    
    ; Print variable info
    lea rcx, [var_msg]
    call print_string
    mov rsi, r12
    mov ecx, r13d
    call print_n
    lea rcx, [eq_msg]
    call print_string
    mov rax, rbx
    call print_num
    lea rcx, [at_msg]
    call print_string
    mov eax, [rdi + 12]
    call print_num
    lea rcx, [close_msg]
    call print_string
    
    mov eax, 1
    jmp .done

.error:
    xor eax, eax
.done:
    pop r13
    pop r12
    pop rbx
    ret

; Parse: return EXPR (EXPR = var OP var or immediate)
parse_return:
    push rbx
    push r12
    push r13
    
    call ps_advance         ; Skip 'return'
    
    ; Check what follows
    call ps_type
    
    ; Is it an identifier? (variable)
    cmp eax, STOK_IDENT
    je .var_expr
    
    ; Is it a number?
    cmp eax, STOK_NUMBER
    je .immediate
    
    jmp .error

.immediate:
    call ps_current
    mov rsi, qword [rax + 8]
    movzx ecx, word [rax + 2]
    call parse_number
    mov [ret_immediate], rax
    mov byte [ret_is_expr], 0
    call ps_advance
    jmp .success

.var_expr:
    ; Get first variable
    call ps_current
    mov r12, qword [rax + 8]    ; name ptr
    movzx r13d, word [rax + 2]  ; name len
    
    ; Find in symbol table
    mov rsi, r12
    mov edx, r13d
    call find_variable
    cmp eax, -1
    je .error
    mov [ret_var1_idx], eax
    
    call ps_advance
    
    ; Check for operator
    call ps_type
    cmp eax, STOK_OPERATOR
    jne .single_var
    
    call ps_subtype
    mov [ret_op], al
    call ps_advance
    
    ; Get second variable
    call ps_type
    cmp eax, STOK_IDENT
    jne .error
    
    call ps_current
    mov r12, qword [rax + 8]
    movzx r13d, word [rax + 2]
    
    mov rsi, r12
    mov edx, r13d
    call find_variable
    cmp eax, -1
    je .error
    mov [ret_var2_idx], eax
    
    call ps_advance
    
    mov byte [ret_is_expr], 2   ; Binary expression
    jmp .success

.single_var:
    mov byte [ret_is_expr], 1   ; Single variable
    jmp .success

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

; Find variable by name
; Input: RSI = name ptr, EDX = name len
; Output: EAX = index or -1
find_variable:
    push rbx
    push r12
    
    mov r12d, edx           ; Save length
    xor ebx, ebx            ; Index
    
.loop:
    cmp ebx, [var_count]
    jge .not_found
    
    ; Get entry
    mov eax, ebx
    imul eax, VAR_ENTRY_SIZE
    lea rcx, [var_table + rax]
    
    ; Compare length
    cmp r12d, [rcx + 8]
    jne .next
    
    ; Compare name
    push rsi
    mov rdi, [rcx]          ; stored name ptr
    mov ecx, r12d
.cmp_loop:
    test ecx, ecx
    jz .found
    mov al, [rsi]
    cmp al, [rdi]
    jne .cmp_fail
    inc rsi
    inc rdi
    dec ecx
    jmp .cmp_loop
    
.cmp_fail:
    pop rsi
.next:
    inc ebx
    jmp .loop

.found:
    pop rsi
    mov eax, ebx
    jmp .done

.not_found:
    mov eax, -1
.done:
    pop r12
    pop rbx
    ret

; Parse number string to integer
parse_number:
    xor rax, rax
    xor rbx, rbx
.loop:
    test ecx, ecx
    jz .done
    movzx ebx, byte [rsi]
    sub ebx, '0'
    imul rax, 10
    add rax, rbx
    inc rsi
    dec ecx
    jmp .loop
.done:
    ret

; Parser helpers
ps_current:
    mov rax, [parse_token_ptr]
    ret

ps_type:
    mov rax, [parse_token_ptr]
    cmp rax, [parse_token_end]
    jae .eof
    movzx eax, byte [rax]
    ret
.eof:
    mov eax, STOK_EOF
    ret

ps_subtype:
    mov rax, [parse_token_ptr]
    movzx eax, byte [rax + 1]
    ret

ps_advance:
    add qword [parse_token_ptr], PARSER_TOKEN_SIZE
    ret

; =============================================================================
; CODE GENERATOR
; =============================================================================

codegen_init:
    sub rsp, 32
    xor ecx, ecx
    mov edx, 4096
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_READWRITE
    call [VirtualAlloc]
    add rsp, 32
    
    test rax, rax
    jz .fail
    
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    mov [jit_start], rax
    ret

.fail:
    xor rax, rax
    ret

codegen_function:
    push rbx
    push r12
    push r13
    
    mov rdi, [jit_cursor]
    
    ; =========================================
    ; PROLOGUE: push rbp; mov rbp, rsp; sub rsp, N
    ; =========================================
    mov byte [rdi], 0x55            ; push rbp
    inc rdi
    
    mov byte [rdi], 0x48            ; REX.W
    mov byte [rdi+1], 0x89          ; mov
    mov byte [rdi+2], 0xE5          ; rbp, rsp
    add rdi, 3
    
    ; sub rsp, stack_size (aligned to 16)
    mov eax, [stack_offset]
    neg eax
    add eax, 15
    and eax, 0xFFFFFFF0             ; Align to 16
    test eax, eax
    jz .skip_sub_rsp
    
    mov byte [rdi], 0x48            ; REX.W
    mov byte [rdi+1], 0x83          ; sub
    mov byte [rdi+2], 0xEC          ; rsp,
    mov byte [rdi+3], al            ; imm8
    add rdi, 4
    
.skip_sub_rsp:
    ; =========================================
    ; Initialize variables on stack
    ; =========================================
    xor ebx, ebx
.init_vars:
    cmp ebx, [var_count]
    jge .gen_return
    
    ; Get variable entry
    mov eax, ebx
    imul eax, VAR_ENTRY_SIZE
    lea rcx, [var_table + rax]
    
    mov r12d, [rcx + 12]        ; stack offset (positive)
    mov r13, [rcx + 16]         ; value
    
    ; mov qword [rbp - offset], value
    ; 48 C7 45 xx yy yy yy yy   (if value fits in 32 bits)
    mov byte [rdi], 0x48            ; REX.W
    mov byte [rdi+1], 0xC7          ; mov
    mov byte [rdi+2], 0x45          ; [rbp + disp8]
    neg r12d
    mov byte [rdi+3], r12b          ; displacement (negative)
    mov dword [rdi+4], r13d         ; value (32-bit)
    add rdi, 8
    
    inc ebx
    jmp .init_vars

.gen_return:
    ; =========================================
    ; Generate return expression
    ; =========================================
    cmp byte [ret_is_expr], 0
    je .ret_immediate
    cmp byte [ret_is_expr], 1
    je .ret_single_var
    
    ; Binary expression: return var1 OP var2
    
    ; Load var1 into RAX
    mov eax, [ret_var1_idx]
    imul eax, VAR_ENTRY_SIZE
    lea rcx, [var_table + rax]
    mov r12d, [rcx + 12]            ; offset
    neg r12d
    
    ; mov rax, [rbp + disp8]
    mov byte [rdi], 0x48            ; REX.W
    mov byte [rdi+1], 0x8B          ; mov
    mov byte [rdi+2], 0x45          ; rax, [rbp + disp8]
    mov byte [rdi+3], r12b
    add rdi, 4
    
    ; Load var2 into RCX
    mov eax, [ret_var2_idx]
    imul eax, VAR_ENTRY_SIZE
    lea rcx, [var_table + rax]
    mov r12d, [rcx + 12]
    neg r12d
    
    ; mov rcx, [rbp + disp8]
    mov byte [rdi], 0x48            ; REX.W
    mov byte [rdi+1], 0x8B          ; mov
    mov byte [rdi+2], 0x4D          ; rcx, [rbp + disp8]
    mov byte [rdi+3], r12b
    add rdi, 4
    
    ; Apply operator
    movzx eax, byte [ret_op]
    cmp eax, SOP_PLUS
    je .op_add
    cmp eax, SOP_MINUS
    je .op_sub
    cmp eax, SOP_MUL
    je .op_mul
    jmp .epilogue
    
.op_add:
    ; add rax, rcx
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x01
    mov byte [rdi+2], 0xC8          ; add rax, rcx
    add rdi, 3
    jmp .epilogue
    
.op_sub:
    ; sub rax, rcx
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x29
    mov byte [rdi+2], 0xC8          ; sub rax, rcx
    add rdi, 3
    jmp .epilogue
    
.op_mul:
    ; imul rax, rcx
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x0F
    mov byte [rdi+2], 0xAF
    mov byte [rdi+3], 0xC1          ; imul rax, rcx
    add rdi, 4
    jmp .epilogue
    
.ret_single_var:
    ; Load single variable into RAX
    mov eax, [ret_var1_idx]
    imul eax, VAR_ENTRY_SIZE
    lea rcx, [var_table + rax]
    mov r12d, [rcx + 12]
    neg r12d
    
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x45
    mov byte [rdi+3], r12b
    add rdi, 4
    jmp .epilogue
    
.ret_immediate:
    ; mov rax, immediate
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    mov rax, [ret_immediate]
    mov [rdi+2], rax
    add rdi, 10
    
.epilogue:
    ; =========================================
    ; EPILOGUE: leave; ret
    ; =========================================
    mov byte [rdi], 0xC9            ; leave (mov rsp, rbp; pop rbp)
    mov byte [rdi+1], 0xC3          ; ret
    add rdi, 2
    
    mov [jit_cursor], rdi
    
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; LEXER (same as before, abbreviated)
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
    mov [rdi+1], al
    mov word [rdi+2], ax
    mov word [rdi+4], ax
    mov word [rdi+6], ax
    mov qword [rdi+8], rax
    mov qword [rdi+16], rax
    
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
    mov word [r8+4], ax
    mov rax, rsi
    sub rax, [lex_line_start]
    mov word [r8+6], ax
    mov al, [rsi]
    test al, al
    jz .token_eof
    cmp al, 13
    je .token_nl
    cmp al, 10
    je .token_nl
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

.token_num:
    mov byte [r8], STOK_NUMBER
    mov [r8+8], rsi
    xor ecx, ecx
.num_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_end
    cmp al, '9'
    jg .num_end
    inc ecx
    inc rsi
    jmp .num_loop
.num_end:
    mov word [r8+2], cx
    mov [lex_pos], rsi
    mov eax, STOK_NUMBER
    jmp .done

.token_id:
    mov byte [r8], STOK_IDENT
    mov [r8+8], rsi
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
    mov word [r8+2], cx
    mov [lex_pos], rsi
    push rsi
    mov rsi, [r8+8]
    mov edx, ecx
    call lex_check_kw
    pop rsi
    test eax, eax
    jz .id_not_kw
    mov byte [r8], STOK_KEYWORD
    mov byte [r8+1], al
    mov eax, STOK_KEYWORD
    jmp .done
.id_not_kw:
    mov eax, STOK_IDENT
    jmp .done

.token_op:
    mov byte [r8], STOK_OPERATOR
    mov al, [rsi]
    cmp al, ':'
    je .op_col
    cmp al, '='
    je .op_eq
    cmp al, '+'
    je .op_plus
    cmp al, '-'
    je .op_minus
    cmp al, '*'
    je .op_mul
    cmp al, '/'
    je .op_div
    cmp al, '('
    je .op_lp
    cmp al, ')'
    je .op_rp
    mov byte [r8+1], 0
    inc rsi
    jmp .op_done

.op_col:
    mov byte [r8+1], SOP_COLON
    jmp .op_1
.op_eq:
    mov byte [r8+1], SOP_ASSIGN
    jmp .op_1
.op_plus:
    mov byte [r8+1], SOP_PLUS
    jmp .op_1
.op_minus:
    mov byte [r8+1], SOP_MINUS
    jmp .op_1
.op_mul:
    mov byte [r8+1], SOP_MUL
    jmp .op_1
.op_div:
    mov byte [r8+1], SOP_DIV
    jmp .op_1
.op_lp:
    mov byte [r8+1], SOP_LPAREN
    jmp .op_1
.op_rp:
    mov byte [r8+1], SOP_RPAREN
    jmp .op_1

.op_1:
    mov word [r8+2], 1
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
    test rax, rax
    jnz .conv
    mov byte [rdi], '0'
    dec rdi
    jmp .print
.conv:
    mov rbx, 10
.loop:
    test rax, rax
    jz .print
    xor rdx, rdx
    div rbx
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
