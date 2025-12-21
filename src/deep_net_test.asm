; =============================================================================
; SYNAPSE Deep Network Test (Phase 14) - FULL JIT
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Two-layer feed-forward network with FULL JIT compilation
;   Input: [1, 1]
;   Layer 1: 2 neurons, weights [10,20,30,40] → Hidden [30, 70]
;   Layer 2: 1 neuron, weights [2,3] → Output = 270
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
                db '  SYNAPSE Phase 14: Deep Neural Network',13,10
                db '  FULL JIT - Two Layer Feed Forward',13,10
                db '  [1,1] -> [30,70] -> 270',13,10
                db '============================================',13,10,13,10,0
    
    setup_msg   db '[DATA] Allocating tensors...',13,10,0
    jit1_msg    db '[JIT] Compiling Layer 1 (2x2)...',13,10,0
    exec1_msg   db '[EXEC] Layer 1...',13,10,0
    jit2_msg    db '[JIT] Compiling Layer 2 (1x2)...',13,10,0
    exec2_msg   db '[EXEC] Layer 2...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! DEEP NETWORK = 270 ***',13,10
                db '*** FULL JIT FEED FORWARD COMPLETE! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! ***',13,10,0
    
    str_in      db 'in',0
    str_w       db 'w',0
    str_out     db 'out',0
    str_n       db 'n',0
    str_k       db 'k',0
    str_sum     db 'sum',0
    
    cfg_neurons dq 0
    cfg_inputs  dq 0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ptr_input       dq ?
    ptr_w1          dq ?
    ptr_hidden      dq ?
    ptr_w2          dq ?
    ptr_output      dq ?
    
    off_in          dq ?
    off_w           dq ?
    off_out         dq ?
    off_n           dq ?
    off_k           dq ?
    off_sum         dq ?

    ; AST nodes
    ast_outer       rb AST_NODE_SIZE
    ast_cond_n      rb AST_NODE_SIZE
    ast_var_n       rb AST_NODE_SIZE
    ast_val_neurons rb AST_NODE_SIZE
    
    ast_init_sum    rb AST_NODE_SIZE
    ast_val_0       rb AST_NODE_SIZE
    
    ast_init_k      rb AST_NODE_SIZE
    ast_val_0k      rb AST_NODE_SIZE
    
    ast_inner       rb AST_NODE_SIZE
    ast_cond_k      rb AST_NODE_SIZE
    ast_var_k       rb AST_NODE_SIZE
    ast_val_inputs  rb AST_NODE_SIZE
    
    ast_update_sum  rb AST_NODE_SIZE
    ast_add_sum     rb AST_NODE_SIZE
    ast_var_sum     rb AST_NODE_SIZE
    ast_mul_iw      rb AST_NODE_SIZE
    ast_get_in      rb AST_NODE_SIZE
    ast_ptr_in      rb AST_NODE_SIZE
    ast_idx_k       rb AST_NODE_SIZE
    ast_get_w       rb AST_NODE_SIZE
    ast_ptr_w       rb AST_NODE_SIZE
    ast_idx_wc      rb AST_NODE_SIZE
    ast_mul_n2      rb AST_NODE_SIZE
    ast_var_n2      rb AST_NODE_SIZE
    ast_val_stride  rb AST_NODE_SIZE
    ast_var_kc      rb AST_NODE_SIZE
    
    ast_inc_k       rb AST_NODE_SIZE
    ast_add_k       rb AST_NODE_SIZE
    ast_var_ki      rb AST_NODE_SIZE
    ast_val_1k      rb AST_NODE_SIZE
    
    ast_save_out    rb AST_NODE_SIZE
    ast_set_target  rb AST_NODE_SIZE
    ast_ptr_out     rb AST_NODE_SIZE
    ast_idx_n       rb AST_NODE_SIZE
    ast_val_sum     rb AST_NODE_SIZE
    
    ast_inc_n       rb AST_NODE_SIZE
    ast_add_n       rb AST_NODE_SIZE
    ast_var_ni      rb AST_NODE_SIZE
    ast_val_1n      rb AST_NODE_SIZE

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
    
    ; === SETUP DATA ===
    lea rcx, [setup_msg]
    call print_string
    
    ; Input = [1, 1]
    mov rax, [heap_ptr]
    mov [ptr_input], rax
    mov qword [rax], 1
    mov qword [rax+8], 1
    add qword [heap_ptr], 32
    
    ; Weights L1 = [10, 20, 30, 40]
    mov rax, [heap_ptr]
    mov [ptr_w1], rax
    mov qword [rax], 10
    mov qword [rax+8], 20
    mov qword [rax+16], 30
    mov qword [rax+24], 40
    add qword [heap_ptr], 64
    
    ; Hidden = [0, 0]
    mov rax, [heap_ptr]
    mov [ptr_hidden], rax
    mov qword [rax], 0
    mov qword [rax+8], 0
    add qword [heap_ptr], 32
    
    ; Weights L2 = [2, 3]
    mov rax, [heap_ptr]
    mov [ptr_w2], rax
    mov qword [rax], 2
    mov qword [rax+8], 3
    add qword [heap_ptr], 32
    
    ; Output = [0]
    mov rax, [heap_ptr]
    mov [ptr_output], rax
    mov qword [rax], 0
    add qword [heap_ptr], 16
    
    ; =====================================================================
    ; LAYER 1: 2 neurons x 2 inputs
    ; =====================================================================
    lea rcx, [jit1_msg]
    call print_string
    
    call sym_init
    
    lea rcx, [str_in]
    call sym_add
    mov [off_in], rax
    
    lea rcx, [str_w]
    call sym_add
    mov [off_w], rax
    
    lea rcx, [str_out]
    call sym_add
    mov [off_out], rax
    
    lea rcx, [str_n]
    call sym_add
    mov [off_n], rax
    
    lea rcx, [str_k]
    call sym_add
    mov [off_k], rax
    
    lea rcx, [str_sum]
    call sym_add
    mov [off_sum], rax
    
    ; Build AST
    mov qword [cfg_neurons], 2
    mov qword [cfg_inputs], 2
    call build_layer_ast
    
    ; Reset JIT cursor
    mov rax, [jit_buffer]
    mov [jit_cursor], rax
    
    ; Compile
    lea rsi, [ast_outer]
    call codegen_run
    
    ; Add RET
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; Execute Layer 1
    lea rcx, [exec1_msg]
    call print_string
    
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    mov rax, [ptr_input]
    mov [rbp - 8], rax
    mov rax, [ptr_w1]
    mov [rbp - 16], rax
    mov rax, [ptr_hidden]
    mov [rbp - 24], rax
    mov qword [rbp - 32], 0
    mov qword [rbp - 40], 0
    mov qword [rbp - 48], 0
    
    mov rax, [jit_buffer]
    call rax
    
    add rsp, 64
    pop rbp
    
    ; =====================================================================
    ; LAYER 2: 1 neuron x 2 inputs
    ; =====================================================================
    lea rcx, [jit2_msg]
    call print_string
    
    call sym_init
    
    lea rcx, [str_in]
    call sym_add
    mov [off_in], rax
    
    lea rcx, [str_w]
    call sym_add
    mov [off_w], rax
    
    lea rcx, [str_out]
    call sym_add
    mov [off_out], rax
    
    lea rcx, [str_n]
    call sym_add
    mov [off_n], rax
    
    lea rcx, [str_k]
    call sym_add
    mov [off_k], rax
    
    lea rcx, [str_sum]
    call sym_add
    mov [off_sum], rax
    
    ; Build AST for Layer 2
    mov qword [cfg_neurons], 1
    mov qword [cfg_inputs], 2
    call build_layer_ast
    
    ; Reset JIT cursor
    mov rax, [jit_buffer]
    mov [jit_cursor], rax
    
    ; Compile
    lea rsi, [ast_outer]
    call codegen_run
    
    ; Add RET
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; Execute Layer 2 (INPUT = HIDDEN!)
    lea rcx, [exec2_msg]
    call print_string
    
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    mov rax, [ptr_hidden]       ; <-- FEED FORWARD!
    mov [rbp - 8], rax
    mov rax, [ptr_w2]
    mov [rbp - 16], rax
    mov rax, [ptr_output]
    mov [rbp - 24], rax
    mov qword [rbp - 32], 0
    mov qword [rbp - 40], 0
    mov qword [rbp - 48], 0
    
    mov rax, [jit_buffer]
    call rax
    
    add rsp, 64
    pop rbp
    
    ; =====================================================================
    ; VERIFY
    ; =====================================================================
    mov rsi, [ptr_output]
    mov rax, [rsi]
    
    cmp rax, 270
    je .success
    
    lea rcx, [fail_msg]
    call print_string
    jmp .exit
    
.success:
    lea rcx, [success_msg]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; build_layer_ast
; =============================================================================
build_layer_ast:
    push rbx
    
    ; OUTER WHILE
    lea rbx, [ast_outer]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond_n]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_init_sum]
    mov [rbx + AST_VALUE], rax
    mov qword [rbx + AST_NEXT], 0
    
    lea rbx, [ast_cond_n]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_n]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_neurons]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_n]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_neurons]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov rax, [cfg_neurons]
    mov [rbx + AST_VALUE], rax
    
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
    
    lea rbx, [ast_init_k]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_val_0k]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_inner]
    mov [rbx + AST_NEXT], rax
    
    lea rbx, [ast_val_0k]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; INNER WHILE
    lea rbx, [ast_inner]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond_k]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_update_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_save_out]
    mov [rbx + AST_NEXT], rax
    
    lea rbx, [ast_cond_k]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_k]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_inputs]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_k]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_inputs]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov rax, [cfg_inputs]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_update_sum]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_sum]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_inc_k]
    mov [rbx + AST_NEXT], rax
    
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
    
    lea rbx, [ast_mul_iw]
    mov qword [rbx + AST_TYPE], NODE_OP_MUL
    lea rax, [ast_get_in]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_get_w]
    mov [rbx + AST_VALUE], rax
    
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
    
    lea rbx, [ast_idx_wc]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_mul_n2]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_var_kc]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_mul_n2]
    mov qword [rbx + AST_TYPE], NODE_OP_MUL
    lea rax, [ast_var_n2]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_stride]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_n2]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_stride]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov rax, [cfg_inputs]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_kc]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_inc_k]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_k]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_k]
    mov [rbx + AST_CHILD], rax
    mov qword [rbx + AST_NEXT], 0
    
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
    
    ; SAVE out[n] = sum
    lea rbx, [ast_save_out]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_SET
    lea rax, [ast_set_target]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_inc_n]
    mov [rbx + AST_NEXT], rax
    
    lea rbx, [ast_set_target]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_GET
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
    
    lea rbx, [ast_val_sum]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_inc_n]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_n]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_n]
    mov [rbx + AST_CHILD], rax
    mov qword [rbx + AST_NEXT], 0
    
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
    
    pop rbx
    ret

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
; Codegen
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

.gen_array_set:
    push rsi
    
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_CHILD]
    
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
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
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
