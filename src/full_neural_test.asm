; =============================================================================
; SYNAPSE Full Neural Test (Phase 11) - THE FINAL TEST
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests: Dot Product = sum(inputs[i] * weights[i])
;   inputs  = [2, 3, 4]
;   weights = [10, 20, 30]
;   Expected: (2*10) + (3*20) + (4*30) = 20 + 60 + 120 = 200
;
; This proves SYNAPSE can run neural network calculations!
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
                db '  SYNAPSE Phase 11: THE ARTIFICIAL NEURON',13,10
                db '  Dot Product: inputs * weights',13,10
                db '  [2,3,4] * [10,20,30] = 200',13,10
                db '============================================',13,10,13,10,0
    
    setup_msg   db '[DATA] Setting up inputs and weights...',13,10,0
    compile_msg db '[JIT] Compiling neural loop...',13,10,0
    exec_msg    db '[EXEC] Running neuron...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Dot Product = 200 ***',13,10
                db '*** THE NEURON IS ALIVE! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Wrong result ***',13,10,0
    
    str_inputs  db 'inputs',0
    str_weights db 'weights',0
    str_sum     db 'sum',0
    str_i       db 'i',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ; Data pointers
    ptr_inputs      dq ?
    ptr_weights     dq ?
    
    ; Symbol offsets
    off_inputs      dq ?
    off_weights     dq ?
    off_sum         dq ?
    off_i           dq ?
    
    ; AST Nodes (много!)
    ast_while       rb AST_NODE_SIZE
    ast_cond        rb AST_NODE_SIZE
    ast_var_i       rb AST_NODE_SIZE
    ast_val_3       rb AST_NODE_SIZE
    ast_body        rb AST_NODE_SIZE
    ast_add_sum     rb AST_NODE_SIZE
    ast_var_sum     rb AST_NODE_SIZE
    ast_mul         rb AST_NODE_SIZE
    ast_get_in      rb AST_NODE_SIZE
    ast_get_w       rb AST_NODE_SIZE
    ast_ptr_in      rb AST_NODE_SIZE
    ast_idx_i       rb AST_NODE_SIZE
    ast_ptr_w       rb AST_NODE_SIZE
    ast_idx_i2      rb AST_NODE_SIZE
    ast_inc         rb AST_NODE_SIZE
    ast_add_i       rb AST_NODE_SIZE
    ast_var_i2      rb AST_NODE_SIZE
    ast_val_1       rb AST_NODE_SIZE

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
    
    ; Allocate inputs = [2, 3, 4]
    mov rax, [heap_ptr]
    mov [ptr_inputs], rax
    mov qword [rax], 2
    mov qword [rax+8], 3
    mov qword [rax+16], 4
    add qword [heap_ptr], 32
    
    ; Allocate weights = [10, 20, 30]
    mov rax, [heap_ptr]
    mov [ptr_weights], rax
    mov qword [rax], 10
    mov qword [rax+8], 20
    mov qword [rax+16], 30
    add qword [heap_ptr], 32
    
    ; Register symbols
    lea rcx, [str_inputs]
    call sym_add
    mov [off_inputs], rax           ; -8
    
    lea rcx, [str_weights]
    call sym_add
    mov [off_weights], rax          ; -16
    
    lea rcx, [str_sum]
    call sym_add
    mov [off_sum], rax              ; -24
    
    lea rcx, [str_i]
    call sym_add
    mov [off_i], rax                ; -32
    
    ; === BUILD AST ===
    ; while (i < 3) { sum = sum + (inputs[i] * weights[i]); i = i + 1 }
    
    ; WHILE node
    lea rbx, [ast_while]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_body]
    mov [rbx + AST_VALUE], rax
    
    ; CONDITION: i < 3
    lea rbx, [ast_cond]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_i]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_3]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_i]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_3]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 3
    
    ; BODY: let sum = sum + (inputs[i] * weights[i])
    lea rbx, [ast_body]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_sum]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_inc]
    mov [rbx + AST_NEXT], rax
    
    ; ADD: sum + MUL
    lea rbx, [ast_add_sum]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_var_sum]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_mul]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_sum]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_sum]
    mov [rbx + AST_VALUE], rax
    
    ; MUL: inputs[i] * weights[i]
    lea rbx, [ast_mul]
    mov qword [rbx + AST_TYPE], NODE_OP_MUL
    lea rax, [ast_get_in]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_get_w]
    mov [rbx + AST_VALUE], rax
    
    ; ARRAY GET: inputs[i]
    lea rbx, [ast_get_in]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_GET
    lea rax, [ast_ptr_in]
    mov [rbx + AST_CHILD], rax          ; Base (inputs pointer)
    lea rax, [ast_idx_i]
    mov [rbx + AST_VALUE], rax          ; Index (i)
    
    lea rbx, [ast_ptr_in]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_inputs]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_idx_i]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    
    ; ARRAY GET: weights[i]
    lea rbx, [ast_get_w]
    mov qword [rbx + AST_TYPE], NODE_ARRAY_GET
    lea rax, [ast_ptr_w]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_idx_i2]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_ptr_w]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_weights]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_idx_i2]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    
    ; INCREMENT: let i = i + 1
    lea rbx, [ast_inc]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_add_i]
    mov [rbx + AST_CHILD], rax
    
    lea rbx, [ast_add_i]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_var_i2]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_1]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_i2]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_1]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 1
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_while]
    call codegen_run
    
    ; Add RET
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; === EXECUTE ===
    lea rcx, [exec_msg]
    call print_string
    
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    ; Initialize stack variables
    mov rax, [ptr_inputs]
    mov [rbp - 8], rax              ; inputs = ptr
    mov rax, [ptr_weights]
    mov [rbp - 16], rax             ; weights = ptr
    mov qword [rbp - 24], 0         ; sum = 0
    mov qword [rbp - 32], 0         ; i = 0
    
    mov rax, [jit_buffer]
    call rax
    
    ; Get result
    mov rax, [rbp - 24]
    mov r12, rax
    
    add rsp, 64
    pop rbp
    
    ; === VERIFY ===
    cmp r12, 200
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
; COMPLETE CODEGEN (All Phase 6-11 ops)
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
    
    jmp .next_node

; --- gen_number ---
.gen_number:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov [rdi+2], rax
    add rdi, 10
    mov [jit_cursor], rdi
    jmp .next_node

; --- gen_let ---
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

; --- gen_var ---
.gen_var:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458B48
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    jmp .next_node

; --- gen_while ---
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

; --- gen_add ---
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

; --- gen_lt ---
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

; --- gen_mul ---
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

; --- gen_array_get: RAX = Base[Index] ---
.gen_array_get:
    push rsi
    
    ; 1. Index -> RAX
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; SHL RAX, 3 (multiply by 8 for qword)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x03E0C148
    add qword [jit_cursor], 4
    
    ; PUSH RAX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; 2. Base -> RAX
    mov rsi, [rsp]
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; POP RCX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; 3. ADD RAX, RCX (address = base + offset)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC80148
    add qword [jit_cursor], 3
    
    ; 4. MOV RAX, [RAX] (read value)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x008B48
    add qword [jit_cursor], 3
    
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
