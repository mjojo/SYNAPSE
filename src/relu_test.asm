; =============================================================================
; SYNAPSE ReLU Test (Phase 12)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests: ReLU activation function
;   relu(-50) = 0  (negative -> 0)
;   relu(50) = 50  (positive -> same)
;
; ReLU: if (x < 0) return 0; else return x;
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
                db '  SYNAPSE Phase 12: ReLU Activation Test',13,10
                db '  relu(x) = max(0, x)',13,10
                db '============================================',13,10,13,10,0
    
    test1_msg   db '[TEST 1] relu(0 - 50) = relu(-50)...',13,10,0
    test2_msg   db '[TEST 2] relu(50) = 50...',13,10,0
    compile_msg db '[JIT] Compiling with SUB...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! ReLU activation works! ***',13,10,0
    pass1_msg   db '        -> PASS: relu(-50) = 0',13,10,0
    pass2_msg   db '        -> PASS: relu(50) = 50',13,10,0
    fail_msg    db 13,10,'*** FAIL! ReLU broken ***',13,10,0
    
    str_val     db 'val',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    off_val         dq ?
    
    ; AST Nodes for: let val = 0 - 50; if (val < 0) val = 0
    ast_let_sub     rb AST_NODE_SIZE
    ast_sub         rb AST_NODE_SIZE
    ast_val_0       rb AST_NODE_SIZE
    ast_val_50      rb AST_NODE_SIZE
    ast_if          rb AST_NODE_SIZE
    ast_cond        rb AST_NODE_SIZE
    ast_var_val     rb AST_NODE_SIZE
    ast_zero        rb AST_NODE_SIZE
    ast_set_zero    rb AST_NODE_SIZE
    ast_zero_val    rb AST_NODE_SIZE

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
    
    ; Register 'val'
    lea rcx, [str_val]
    call sym_add
    mov [off_val], rax              ; -8
    
    ; === TEST 1: relu(-50) should be 0 ===
    lea rcx, [test1_msg]
    call print_string
    
    ; Reset JIT
    mov rax, [jit_buffer]
    mov [jit_cursor], rax
    
    ; Build AST: let val = 0 - 50
    lea rbx, [ast_let_sub]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_val]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_sub]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_if]
    mov [rbx + AST_NEXT], rax
    
    ; SUB: 0 - 50
    lea rbx, [ast_sub]
    mov qword [rbx + AST_TYPE], NODE_OP_SUB
    lea rax, [ast_val_0]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_val_50]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_val_0]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    lea rbx, [ast_val_50]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 50
    
    ; IF: if (val < 0) { val = 0 }
    lea rbx, [ast_if]
    mov qword [rbx + AST_TYPE], NODE_IF
    lea rax, [ast_cond]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_set_zero]
    mov [rbx + AST_VALUE], rax
    
    ; COND: val < 0
    lea rbx, [ast_cond]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_val]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_zero]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_val]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_val]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_zero]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; BODY: let val = 0
    lea rbx, [ast_set_zero]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_val]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_zero_val]
    mov [rbx + AST_CHILD], rax
    
    lea rbx, [ast_zero_val]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; Compile
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_let_sub]
    call codegen_run
    
    ; Add RET
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; Execute
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    mov rax, [jit_buffer]
    call rax
    
    ; Read result
    mov rax, [rbp - 8]
    mov r12, rax
    
    add rsp, 64
    pop rbp
    
    ; Check: should be 0
    cmp r12, 0
    jne .fail
    
    lea rcx, [pass1_msg]
    call print_string
    
    ; === TEST 2: relu(50) should be 50 ===
    lea rcx, [test2_msg]
    call print_string
    
    ; Reset JIT
    mov rax, [jit_buffer]
    mov [jit_cursor], rax
    call sym_init
    
    lea rcx, [str_val]
    call sym_add
    mov [off_val], rax
    
    ; Build AST: let val = 50; if (val < 0) val = 0
    lea rbx, [ast_let_sub]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_val]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_val_50]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_if]
    mov [rbx + AST_NEXT], rax
    
    ; val = 50 (positive)
    lea rbx, [ast_val_50]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 50
    
    ; Same IF structure
    lea rbx, [ast_if]
    mov qword [rbx + AST_TYPE], NODE_IF
    lea rax, [ast_cond]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_set_zero]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_cond]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_val]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_zero]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_var_val]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_val]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_zero]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    lea rbx, [ast_set_zero]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_val]
    mov [rbx + AST_VALUE], rax
    lea rax, [ast_zero_val]
    mov [rbx + AST_CHILD], rax
    
    lea rbx, [ast_zero_val]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; Compile
    lea rsi, [ast_let_sub]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; Execute
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    mov rax, [jit_buffer]
    call rax
    
    mov rax, [rbp - 8]
    mov r13, rax
    
    add rsp, 64
    pop rbp
    
    ; Check: should be 50
    cmp r13, 50
    jne .fail
    
    lea rcx, [pass2_msg]
    call print_string
    
    ; Both tests passed!
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
; CODEGEN with SUB support
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
    cmp eax, NODE_IF
    je .gen_if
    cmp eax, NODE_OP_LT
    je .gen_lt
    cmp eax, NODE_OP_SUB
    je .gen_sub
    
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

; --- gen_if ---
.gen_if:
    push rsi
    
    ; Compile condition
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; TEST RAX, RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    ; JZ (skip body)
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F
    add qword [jit_cursor], 2
    mov rdx, [jit_cursor]
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    push rdx
    
    ; Compile body
    mov rsi, [rsp+8]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; Backpatch
    pop rdx
    mov rax, [jit_cursor]
    sub rax, rdx
    sub rax, 4
    mov [rdx], eax
    
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
    
    ; CMP RCX, RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948
    add qword [jit_cursor], 3
    
    ; SETL AL
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC09C0F
    add qword [jit_cursor], 3
    
    ; MOVZX RAX, AL
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

; --- gen_sub: RAX = Left - Right ---
.gen_sub:
    push rsi
    
    ; Left -> RAX
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; PUSH RAX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; Right -> RAX
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; POP RCX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; SUB RCX, RAX (48 29 C1)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC12948
    add qword [jit_cursor], 3
    
    ; MOV RAX, RCX (48 89 C8)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC88948
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
