; =============================================================================
; SYNAPSE JIT Variable Read Test (Phase 7.3)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests JIT code generation for variable reading:
;   let x = 42
;   let y = x  (y should copy value from x)
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
                db '  SYNAPSE Phase 7.3: Read Variable Test',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] AST: let x = 42; let y = x',13,10,0
    compile_msg db '[JIT] Compiling read/write to stack...',13,10,0
    exec_msg    db '[EXEC] Running JIT...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Variable y copied from x = 42 ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Variable y has wrong value ***',13,10,0
    
    str_x       db 'x',0
    str_y       db 'y',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    off_x           dq ?
    off_y           dq ?
    
    ; AST Nodes (chained: let_x -> let_y)
    ast_let_x       rb AST_NODE_SIZE     ; let x = 42
    ast_val_42      rb AST_NODE_SIZE     ; NUMBER 42
    ast_let_y       rb AST_NODE_SIZE     ; let y = x
    ast_var_x       rb AST_NODE_SIZE     ; VAR x

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
    
    ; === BUILD AST ===
    lea rcx, [build_msg]
    call print_string
    
    ; 1. Register variables
    lea rcx, [str_x]
    call sym_add
    mov [off_x], rax                    ; x -> -8
    
    lea rcx, [str_y]
    call sym_add
    mov [off_y], rax                    ; y -> -16
    
    ; 2. Build: let x = 42
    lea rbx, [ast_let_x]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_x]
    mov [rbx + AST_VALUE], rax          ; offset -8
    lea rax, [ast_val_42]
    mov [rbx + AST_CHILD], rax          ; child = 42
    lea rax, [ast_let_y]
    mov [rbx + AST_NEXT], rax           ; next = let y
    
    ; Child: 42
    lea rbx, [ast_val_42]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 42
    
    ; 3. Build: let y = x
    lea rbx, [ast_let_y]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_y]
    mov [rbx + AST_VALUE], rax          ; offset -16
    lea rax, [ast_var_x]
    mov [rbx + AST_CHILD], rax          ; child = var x
    
    ; Child: var x
    lea rbx, [ast_var_x]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_x]
    mov [rbx + AST_VALUE], rax          ; read from -8
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_let_x]
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
    
    ; Read y from [RBP-16]
    mov rax, [rbp - 16]
    mov r12, rax
    
    add rsp, 64
    pop rbp
    
    ; === CHECK ===
    cmp r12, 42
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
; CODEGEN with NODE_LET and NODE_VAR
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
    
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_number: MOV RAX, imm64
; -----------------------------------------------------------------------------
.gen_number:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov [rdi+2], rax
    add rdi, 10
    mov [jit_cursor], rdi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_let: Evaluate expression, write to stack
; -----------------------------------------------------------------------------
.gen_let:
    push rsi
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rsi, [rsp]
    mov rax, [rsi + AST_VALUE]          ; Stack offset
    
    ; MOV [RBP + disp8], RAX (48 89 45 XX)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458948
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_var: Read variable from stack  
; MOV RAX, [RBP + disp8] (48 8B 45 XX)
; -----------------------------------------------------------------------------
.gen_var:
    mov rax, [rsi + AST_VALUE]          ; Stack offset
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458B48           ; 48 8B 45
    mov [rdi + 3], al                   ; disp8
    add qword [jit_cursor], 4
    
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
