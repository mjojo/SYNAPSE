; =============================================================================
; SYNAPSE Perceptron Test (Phase 10.1)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests: let res = 5 * 10 -> res should be 50
; This tests IMUL instruction generation for neural network calculations
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
                db '  SYNAPSE Phase 10.1: Perceptron Test',13,10
                db '  let res = 5 * 10 (Input * Weight)',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] Creating multiplication AST...',13,10,0
    compile_msg db '[JIT] Compiling IMUL instruction...',13,10,0
    exec_msg    db '[EXEC] Running neural calculation...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! 5 * 10 = 50 ***',13,10
                db '*** The Neuron is Working! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Multiplication broken ***',13,10,0
    
    str_res     db 'res',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ; AST Nodes
    ast_let_node    rb AST_NODE_SIZE
    ast_mul_node    rb AST_NODE_SIZE
    ast_val_5       rb AST_NODE_SIZE
    ast_val_10      rb AST_NODE_SIZE

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
    
    ; === BUILD AST: let res = 5 * 10 ===
    lea rcx, [build_msg]
    call print_string
    
    ; Register variable 'res'
    lea rcx, [str_res]
    call sym_add
    mov r8, rax                         ; Save offset (-8)
    
    ; Create NODE_LET
    lea rbx, [ast_let_node]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov [rbx + AST_VALUE], r8           ; Stack offset
    lea rax, [ast_mul_node]
    mov [rbx + AST_CHILD], rax          ; Child = MUL
    
    ; Create NODE_OP_MUL (5 * 10)
    lea rbx, [ast_mul_node]
    mov qword [rbx + AST_TYPE], NODE_OP_MUL
    lea rax, [ast_val_5]
    mov [rbx + AST_CHILD], rax          ; Left = 5
    lea rax, [ast_val_10]
    mov [rbx + AST_VALUE], rax          ; Right = 10
    
    ; Value: 5
    lea rbx, [ast_val_5]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 5
    
    ; Value: 10
    lea rbx, [ast_val_10]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 10
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_let_node]
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
    
    mov rax, [jit_buffer]
    call rax
    
    ; Read result from [RBP-8]
    mov rax, [rbp - 8]
    mov r12, rax
    
    add rsp, 64
    pop rbp
    
    ; === CHECK ===
    cmp r12, 50
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
; CODEGEN with MUL support
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
    cmp eax, NODE_OP_ADD
    je .gen_add
    cmp eax, NODE_OP_MUL
    je .gen_mul
    
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

; --- gen_mul: RAX = Left * Right ---
.gen_mul:
    push rsi
    
    ; 1. Left -> RAX
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; PUSH RAX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; 2. Right -> RAX
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; POP RCX (Left value)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; 3. IMUL RAX, RCX (48 0F AF C1)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC1AF0F48
    add qword [jit_cursor], 4
    
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
