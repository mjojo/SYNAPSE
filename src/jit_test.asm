; =============================================================================
; SYNAPSE Full System Test - "The 42 Test"
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Lexer -> Parser -> AST -> JIT CodeGen -> Execute -> Return 42
; =============================================================================

format PE64 console
entry start

include '..\include\synapse_tokens.inc'
include '..\include\ast.inc'

ERR_SYNTAX = 1
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
                db '  SYNAPSE JIT Compiler - "The 42 Test"',13,10
                db '================================================',13,10,13,10,0
    
    phase1_msg  db '[PHASE 1] Lexing source code...',13,10,0
    phase2_msg  db '[PHASE 2] Parsing to AST...',13,10,0
    phase3_msg  db '[PHASE 3] Generating x64 machine code...',13,10,0
    phase4_msg  db '[PHASE 4] Executing JIT code...',13,10,0
    
    result_msg  db 13,10,'[RESULT] JIT returned: ',0
    success_msg db 13,10,13,10,'*** SUCCESS! SYNAPSE compiled and ran code! ***',13,10,0
    fail_msg    db 13,10,'[FAILED] Something went wrong',13,10,0
    
    jit_bytes_msg db '[JIT] Generated ',0
    jit_bytes_end db ' bytes of machine code',13,10,0
    
    newline     db 13,10,0

    ; Keywords table
    synapse_keywords:
        db 2, 'fn',       SKW_FN
        db 3, 'let',      SKW_LET
        db 6, 'return',   SKW_RETURN
        db 3, 'int',      SKW_INT
        db 0

    ; Debug messages
    dbg_found_kw    db '[DEBUG] Found keyword, subtype=',0
    dbg_found_ret   db '[DEBUG] Found RETURN!',13,10,0
    dbg_found_num   db '[DEBUG] Found number: ',0
    dbg_token_type  db '[DEBUG] Token type=',0
    dbg_token_sub   db ' subtype=',0
    
    ; === TEST SOURCE CODE ===
    source_code db 'fn main():',13,10
                db '    return 42',13,10
                db 0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    
    ; Tokens
    MAX_TOKENS = 256
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
    parse_depth     dd ?
    
    ; AST storage (simplified - just track return value)
    ast_return_value dq ?   ; Value to return
    ast_has_return  db ?    ; Flag: found return statement
    
    ; JIT
    jit_buffer      dq ?    ; Executable memory
    jit_cursor      dq ?    ; Write position
    jit_start       dq ?    ; Start of code (for size calc)

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
    
    ; Copy token from current_token to token_storage
    ; rep movsb copies FROM [RSI] TO [RDI]
    lea rsi, [current_token]        ; Source = current_token
    mov rdi, [token_write_ptr]      ; Destination = token_storage
    mov ecx, 24
    rep movsb
    mov [token_write_ptr], rdi      ; Update write pointer (RDI advanced)
    inc dword [token_count]
    
    movzx eax, byte [current_token]
    test eax, eax
    jnz .lex_loop
    
    ; ===========================================
    ; PHASE 2: PARSING (Simplified for this test)
    ; ===========================================
    lea rcx, [phase2_msg]
    call print_string
    
    lea rcx, [token_storage]
    mov eax, [token_count]
    imul eax, PARSER_TOKEN_SIZE
    lea rdx, [rcx + rax]
    call parser_init
    
    call parse_for_return
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
    
    call codegen_emit
    
    ; Print bytes generated
    lea rcx, [jit_bytes_msg]
    call print_string
    mov rax, [jit_cursor]
    sub rax, [jit_start]
    call print_num
    lea rcx, [jit_bytes_end]
    call print_string
    
    ; ===========================================
    ; PHASE 4: EXECUTE JIT CODE
    ; ===========================================
    lea rcx, [phase4_msg]
    call print_string
    
    ; Call the JIT-compiled code!
    mov rax, [jit_buffer]
    call rax                ; <<< THE MOMENT OF TRUTH
    
    ; RAX now contains the return value from JIT code
    push rax                ; Save result
    
    ; Print result
    lea rcx, [result_msg]
    call print_string
    pop rax
    push rax
    call print_num
    lea rcx, [newline]
    call print_string
    
    ; Check if result is 42
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
; PARSER (Simplified - just find return value)
; =============================================================================

parser_init:
    mov [parse_token_ptr], rcx
    mov [parse_token_end], rdx
    mov byte [parse_error], 0
    mov qword [ast_return_value], 0
    mov byte [ast_has_return], 0
    ret

parse_for_return:
    push rbx
    push r12
    
.loop:
    mov rax, [parse_token_ptr]
    cmp rax, [parse_token_end]
    jae .done
    
    ; Get token type
    mov r12, rax            ; Save token pointer
    movzx eax, byte [rax]
    
    ; Debug: print token type
    push rax
    lea rcx, [dbg_token_type]
    call print_string
    pop rax
    push rax
    call print_num
    
    ; Check for EOF
    pop rax
    cmp eax, STOK_EOF
    je .done
    
    ; Check for KEYWORD
    cmp eax, STOK_KEYWORD
    jne .next
    
    ; Get subtype
    movzx eax, byte [r12 + 1]
    
    ; Debug: print subtype
    push rax
    lea rcx, [dbg_token_sub]
    call print_string
    pop rax
    push rax
    call print_num
    lea rcx, [newline]
    call print_string
    pop rax
    
    ; Check if it's RETURN (SKW_RETURN = 30)
    cmp eax, SKW_RETURN
    je .found_return
    
.next:
    add qword [parse_token_ptr], PARSER_TOKEN_SIZE
    jmp .loop

.found_return:
    add qword [parse_token_ptr], PARSER_TOKEN_SIZE
    
    ; Next token should be a number
    mov rax, [parse_token_ptr]
    cmp rax, [parse_token_end]
    jae .error
    
    movzx ebx, byte [rax]
    cmp ebx, STOK_NUMBER
    jne .error
    
    ; Get number value (pointer to string)
    mov rsi, qword [rax + 8]    ; value pointer
    movzx ecx, word [rax + 2]   ; length
    
    ; Parse number from string
    xor rax, rax
    xor rbx, rbx
.parse_num:
    test ecx, ecx
    jz .num_done
    movzx ebx, byte [rsi]
    sub ebx, '0'
    imul rax, 10
    add rax, rbx
    inc rsi
    dec ecx
    jmp .parse_num
    
.num_done:
    mov [ast_return_value], rax
    mov byte [ast_has_return], 1
    
.done:
    cmp byte [ast_has_return], 0
    je .error
    mov eax, 1
    pop r12
    pop rbx
    ret

.error:
    xor eax, eax
    pop r12
    pop rbx
    ret

; =============================================================================
; CODE GENERATOR
; =============================================================================

codegen_init:
    push rbx
    
    ; VirtualAlloc(NULL, 4096, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE)
    sub rsp, 32
    xor ecx, ecx                    ; lpAddress = NULL
    mov edx, 4096                   ; dwSize = 4KB
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_READWRITE
    call [VirtualAlloc]
    add rsp, 32
    
    test rax, rax
    jz .fail
    
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    mov [jit_start], rax
    
    pop rbx
    ret

.fail:
    xor rax, rax
    pop rbx
    ret

codegen_emit:
    push rbx
    push rdi
    
    mov rdi, [jit_cursor]
    
    ; =========================================
    ; Emit function prologue:
    ;   push rbp          ; 55
    ;   mov rbp, rsp      ; 48 89 E5
    ; =========================================
    mov byte [rdi + 0], 0x55        ; push rbp
    mov byte [rdi + 1], 0x48        ; REX.W
    mov byte [rdi + 2], 0x89        ; MOV
    mov byte [rdi + 3], 0xE5        ; rbp, rsp
    add rdi, 4
    
    ; =========================================
    ; Emit: mov rax, <return_value>
    ;   REX.W MOV RAX, imm64  ; 48 B8 xx xx xx xx xx xx xx xx
    ; =========================================
    mov byte [rdi + 0], 0x48        ; REX.W
    mov byte [rdi + 1], 0xB8        ; MOV RAX, imm64
    mov rax, [ast_return_value]
    mov [rdi + 2], rax              ; 8 bytes immediate
    add rdi, 10
    
    ; =========================================
    ; Emit function epilogue:
    ;   pop rbp           ; 5D
    ;   ret               ; C3
    ; =========================================
    mov byte [rdi + 0], 0x5D        ; pop rbp
    mov byte [rdi + 1], 0xC3        ; ret
    add rdi, 2
    
    mov [jit_cursor], rdi
    
    pop rdi
    pop rbx
    ret

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

.token_num:
    mov byte [r8], STOK_NUMBER
    mov [r8 + 8], rsi
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
    mov word [r8 + 2], cx
    mov [lex_pos], rsi
    mov eax, STOK_NUMBER
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
.op_eq:
    mov byte [r8 + 1], SOP_ASSIGN
    jmp .op_1
.op_gt:
    mov byte [r8 + 1], SOP_GT
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
