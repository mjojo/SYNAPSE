; =============================================================================
; SYNAPSE Layer Test (Phase 13) - MATRIX MULTIPLICATION
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests: 2 neurons × 2 inputs = Dense Layer
;   Inputs:  [1, 2]
;   Weights: [10, 20, 30, 40] (flattened 2x2)
;   
;   Neuron 0: (1*10) + (2*20) = 10 + 40 = 50
;   Neuron 1: (1*30) + (2*40) = 30 + 80 = 110
;
; Features: Nested loops + Array Store (outputs[n] = sum)
; =============================================================================

format PE64 console
entry start

MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_RW = 0x40

include '..\include\ast.inc'

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

section '.data' data readable writeable

    banner      db '============================================',13,10
                db '  SYNAPSE Phase 13: Hidden Layer (Matrix)',13,10
                db '  2 neurons x 2 inputs = Dense Layer',13,10
                db '============================================',13,10,13,10,0
    
    setup_msg   db '[DATA] Setting up inputs/weights/outputs...',13,10,0
    compile_msg db '[JIT] Compiling nested loops...',13,10,0
    exec_msg    db '[EXEC] Running matrix layer...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Layer calculated correctly! ***',13,10
                db 'Neuron 0: 50',13,10
                db 'Neuron 1: 110',13,10,0
    fail_msg    db 13,10,'*** FAIL! Wrong output ***',13,10,0
    
    str_in      db 'in',0
    str_w       db 'w',0
    str_out     db 'out',0
    str_n       db 'n',0
    str_k       db 'k',0
    str_sum     db 'sum',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ptr_in          dq ?
    ptr_w           dq ?
    ptr_out         dq ?
    
    off_in          dq ?
    off_w           dq ?
    off_out         dq ?
    off_n           dq ?
    off_k           dq ?
    off_sum         dq ?
    
    ; AST Nodes (много для вложенных циклов!)
    ast_outer_while     rb AST_NODE_SIZE
    ast_cond_n          rb AST_NODE_SIZE
    ast_var_n           rb AST_NODE_SIZE
    ast_val_2           rb AST_NODE_SIZE
    
    ast_init_sum        rb AST_NODE_SIZE
    ast_val_0           rb AST_NODE_SIZE
    
    ast_init_k          rb AST_NODE_SIZE
    ast_val_0k          rb AST_NODE_SIZE
    
    ast_inner_while     rb AST_NODE_SIZE
    ast_cond_k          rb AST_NODE_SIZE
    ast_var_k           rb AST_NODE_SIZE
    ast_val_2k          rb AST_NODE_SIZE
    
    ast_update_sum      rb AST_NODE_SIZE
    ast_add_sum         rb AST_NODE_SIZE
    ast_var_sum         rb AST_NODE_SIZE
    ast_mul_iw          rb AST_NODE_SIZE
    ast_get_in          rb AST_NODE_SIZE
    ast_ptr_in          rb AST_NODE_SIZE
    ast_idx_k           rb AST_NODE_SIZE
    ast_get_w           rb AST_NODE_SIZE
    ast_ptr_w           rb AST_NODE_SIZE
    ast_idx_wc          rb AST_NODE_SIZE
    ast_add_idx         rb AST_NODE_SIZE
    ast_mul_n2          rb AST_NODE_SIZE
    ast_var_n2          rb AST_NODE_SIZE
    ast_val_2c          rb AST_NODE_SIZE
    ast_var_kc          rb AST_NODE_SIZE
    
    ast_inc_k           rb AST_NODE_SIZE
    ast_add_k           rb AST_NODE_SIZE
    ast_var_ki          rb AST_NODE_SIZE
    ast_val_1k          rb AST_NODE_SIZE
    
    ast_save_out        rb AST_NODE_SIZE
    ast_set_target      rb AST_NODE_SIZE
    ast_ptr_out         rb AST_NODE_SIZE
    ast_idx_n           rb AST_NODE_SIZE
    ast_val_sum         rb AST_NODE_SIZE
    
    ast_inc_n           rb AST_NODE_SIZE
    ast_add_n           rb AST_NODE_SIZE
    ast_var_ni          rb AST_NODE_SIZE
    ast_val_1n          rb AST_NODE_SIZE

include 'symbols.asm'

section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    call mem_init
    call jit_init
    call sym_init
    
    ; === SETUP DATA ===
    lea rcx, [setup_msg]
    call print_string
    
    ; Inputs = [1, 2]
    mov rax, [heap_ptr]
    mov [ptr_in], rax
    mov qword [rax], 1
    mov qword [rax+8], 2
    add qword [heap_ptr], 32
    
    ; Weights = [10, 20, 30, 40] (flattened 2x2)
    mov rax, [heap_ptr]
    mov [ptr_w], rax
    mov qword [rax], 10
    mov qword [rax+8], 20
    mov qword [rax+16], 30
    mov qword [rax+24], 40
    add qword [heap_ptr], 64
    
    ; Outputs = [0, 0]
    mov rax, [heap_ptr]
    mov [ptr_out], rax
    mov qword [rax], 0
    mov qword [rax+8], 0
    add qword [heap_ptr], 32
    
    ; Register symbols
    lea rcx, [str_in]
    call sym_add
    mov [off_in], rax       ; -8
    
    lea rcx, [str_w]
    call sym_add
    mov [off_w], rax        ; -16
    
    lea rcx, [str_out]
    call sym_add
    mov [off_out], rax      ; -24
    
    lea rcx, [str_n]
    call sym_add
    mov [off_n], rax        ; -32
    
    lea rcx, [str_k]
    call sym_add
    mov [off_k], rax        ; -40
    
    lea rcx, [str_sum]
    call sym_add
    mov [off_sum], rax      ; -48
    
    ; === BUILD AST: Nested Loops ===
    ; n = 0  (pre-init in stack)
    ; while (n < 2) {
    ;     sum = 0
    ;     k = 0
    ;     while (k < 2) {
    ;         sum = sum + (in[k] * w[n*2 + k])
    ;         k = k + 1
    ;     }
    ;     out[n] = sum
    ;     n = n + 1
    ; }
    
    ; OUTER WHILE: while (n < 2)
    lea rbx, [ast_outer_while]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond_n]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_init_sum]
    mov [rbx + AST_VALUE], rax
    
    ; COND: n < 2
    lea rbx, [ast_cond_n]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_n]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_2]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_n]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_2]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 2
    
    ; === BODY OUTER: sum = 0 ===
    lea rbx, [ast_init_sum]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_val_0]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_init_k]
    mov [rbx + AST_NEXT], rax
    
    lea rbx, [ast_val_0]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; k = 0
    lea rbx, [ast_init_k]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_val_0k]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_inner_while]
    mov [rbx + AST_NEXT], rax
    
    lea rbx, [ast_val_0k]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; === INNER WHILE: while (k < 2) ===
    lea rbx, [ast_inner_while]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond_k]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_update_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_save_out]
    mov [rbx + AST_NEXT], rax
    
    ; COND: k < 2
    lea rbx, [ast_cond_k]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_k]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_2k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_k]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_2k]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 2
    
    ; === BODY INNER: sum = sum + (in[k] * w[n*2+k]) ===
    lea rbx, [ast_update_sum]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_sum]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_inc_k]
    mov [rbx + AST_NEXT], rax
    
    ; ADD: sum + MUL
    lea rbx, [ast_add_sum]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_var_sum]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_mul_iw]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_sum]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    
    ; MUL: in[k] * w[idx]
    lea rbx, [ast_mul_iw]
    mov qword [rbx + AST_TYPE], NODE_OP_MUL
    lea rax, [ast_get_in]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_get_w]
    mov [rbx + AST_VALUE], rax
    
    ; GET: in[k]
    lea rbx, [ast_get_in]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_GET
    lea rax, [ast_ptr_in]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_idx_k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_ptr_in]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_in]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_idx_k]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    
    ; GET: w[n*2 + k]
    lea rbx, [ast_get_w]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_GET
    lea rax, [ast_ptr_w]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_idx_wc]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_ptr_w]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_w]
    mov [rbx + AST_VALUE], rax
    
    ; Complex index: n*2 + k
    lea rbx, [ast_idx_wc]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_mul_n2]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_var_kc]
    mov [rbx + AST_VALUE], rax
    
    ; n * 2
    lea rbx, [ast_mul_n2]
    mov qword [rbx + AST_TYPE], NODE_OP_MUL
    lea rax, [ast_var_n2]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_2c]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_n2]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_2c]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 2
    
    lea rbx, [ast_var_kc]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    
    ; k = k + 1
    lea rbx, [ast_inc_k]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_k]
    mov [rbx + AST_CHILD], rax
    
    lea rbx, [ast_add_k]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_var_ki]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_1k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_ki]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_1k]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 1
    
    ; === AFTER INNER: out[n] = sum ===
    lea rbx, [ast_save_out]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_SET
    lea rax, [ast_set_target]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_inc_n]
    mov [rbx + AST_NEXT], rax
    
    ; Target: out[n]
    lea rbx, [ast_set_target]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_GET  ; Structure holder
    lea rax, [ast_ptr_out]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_idx_n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_ptr_out]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_out]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_idx_n]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    
    ; Value: sum
    lea rbx, [ast_val_sum]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    
    ; n = n + 1
    lea rbx, [ast_inc_n]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_n]
    mov [rbx + AST_CHILD], rax
    
    lea rbx, [ast_add_n]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_var_ni]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_1n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_ni]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_1n]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 1
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_outer_while]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; === EXECUTE ===
    lea rcx, [exec_msg]
    call print_string
    
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    ; Init stack vars
    mov rax, [ptr_in]
    mov [rbp - 8], rax
    mov rax, [ptr_w]
    mov [rbp - 16], rax
    mov rax, [ptr_out]
    mov [rbp - 24], rax
    mov qword [rbp - 32], 0     ; n = 0
    mov qword [rbp - 40], 0     ; k = 0
    mov qword [rbp - 48], 0     ; sum = 0
    
    mov rax, [jit_buffer]
    call rax
    
    add rsp, 64
    pop rbp
    
    ; === VERIFY ===
    mov rsi, [ptr_out]
    mov rax, [rsi]              ; out[0]
    mov rbx, [rsi + 8]          ; out[1]
    
    cmp rax, 50
    jne .fail
    cmp rbx, 110
    jne .fail
    
    lea rcx, [success_msg]
    call print_string
    jmp .exit
    
.fail:
    lea rcx, [fail_msg]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; Memory & JIT
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 1024*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call [VirtualAlloc]
    mov [heap_base], rax
    mov [heap_ptr], rax
    add rsp, 40
    ret

jit_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 64*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_RW
    call [VirtualAlloc]
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    add rsp, 40
    ret

; =============================================================================
; FULL CODEGEN (Phase 13 - All ops)
; =============================================================================
codegen_run:
    push rbx
    push r12
    push r13

.process_node:
    test rsi, rsi
    jz .codegen_done
    
    mov eax, [rsi]
    
    cmp eax, NODE_NUMBER
    je .gen_number
    cmp eax, NODE_LET
    je .gen_let
    cmp eax, NODE_VAR
    je .gen_var
    cmp eax, NODE_WHILE
    je .gen_while
    cmp eax, NODE_OP_ADD
    je .gen_add
    cmp eax, NODE_OP_LT
    je .gen_lt
    cmp eax, NODE_OP_MUL
    je .gen_mul
    cmp eax, NODE_OP_SUB
    je .gen_sub
    cmp eax, NODE_ARRAY_GET
    je .gen_array_get
    cmp eax, NODE_ARRAY_SET
    je .gen_array_set
    
    jmp .next_node

.gen_number:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov [rdi+2], rax
    add rdi, 10
    mov [jit_cursor], rdi
    jmp .next_node

.gen_let:
    push rsi
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rsi, [rsp]
    mov rax, [rsi + AST_VALUE]
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458948
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

.gen_var:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458B48
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    jmp .next_node

.gen_while:
    mov rbx, [jit_cursor]
    push rbx
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F
    add qword [jit_cursor], 2
    mov rdx, [jit_cursor]
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    push rdx
    
    mov rsi, [rsp+8]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE9
    inc qword [jit_cursor]
    
    mov rax, [rsp+16]
    sub rax, [jit_cursor]
    sub rax, 4
    mov rdi, [jit_cursor]
    mov [rdi], eax
    add qword [jit_cursor], 4
    
    pop rdx
    pop rsi
    pop rbx
    
    mov rax, [jit_cursor]
    sub rax, rdx
    sub rax, 4
    mov [rdx], eax
    
    jmp .next_node

.gen_add:
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC80148
    add qword [jit_cursor], 3
    
    pop rsi
    jmp .next_node

.gen_lt:
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC09C0F
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

.gen_mul:
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC1AF0F48
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

.gen_sub:
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC12948
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC88948
    add qword [jit_cursor], 3
    
    pop rsi
    jmp .next_node

.gen_array_get:
    push rsi
    
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x03E0C148
    add qword [jit_cursor], 4
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC80148
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x008B48
    add qword [jit_cursor], 3
    
    pop rsi
    jmp .next_node

; --- gen_array_set: MEM[Base + Index*8] = Value ---
.gen_array_set:
    push rsi
    
    ; 1. Value -> RAX
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; PUSH RAX (Value)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; 2. Get target structure (CHILD is the array access node)
    mov rsi, [rsp]
    mov rsi, [rsi + AST_CHILD]
    
    push rsi
    
    ; 2a. Index -> RAX
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; SHL RAX, 3 (Index * 8)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x03E0C148
    add qword [jit_cursor], 4
    
    ; PUSH RAX (Offset)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; 2b. Base -> RAX
    mov rsi, [rsp]
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; POP RCX (Offset)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; ADD RAX, RCX (Address = Base + Offset)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC80148
    add qword [jit_cursor], 3
    
    ; POP RCX (Value)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; MOV [RAX], RCX (Store!)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x088948
    add qword [jit_cursor], 3
    
    pop rsi
    pop rsi
    jmp .next_node

.next_node:
    mov rsi, [rsi + AST_NEXT]
    jmp .process_node

.codegen_done:
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; Print
; =============================================================================
print_string:
    push rsi
    push rdx
    push r8
    push r9
    mov rsi, rcx
    xor ecx, ecx
.len:
    cmp byte [rsi + rcx], 0
    je .pr
    inc ecx
    jmp .len
.pr:
    test ecx, ecx
    jz .dn
    sub rsp, 48
    mov r8d, ecx
    mov rdx, rsi
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp+32], 0
    call [WriteConsoleA]
    add rsp, 48
.dn:
    pop r9
    pop r8
    pop rdx
    pop rsi
    ret
