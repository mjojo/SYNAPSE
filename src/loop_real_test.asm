; =============================================================================
; SYNAPSE Real Loop Test (Phase 7.4)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests: let i = 0; while (i < 5) { alloc(64); let i = i + 1 }
; Expected: 5 memory allocations
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
                db '  SYNAPSE Phase 7.4: Real Loop Test',13,10
                db '  while (i < 5) { alloc(64) }',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] AST: let i = 0; while (i < 5) ...',13,10,0
    compile_msg db '[JIT] Compiling loop with ADD and LT...',13,10,0
    exec_msg    db '[EXEC] Running JIT...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Loop executed 5 times! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Expected 5 allocations ***',13,10,0
    
    str_i       db 'i',0
    str_alloc   db 'alloc',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    alloc_count     dq ?                ; Count allocations
    
    off_i           dq ?
    
    ; AST Nodes
    ast_let_init    rb AST_NODE_SIZE    ; let i = 0
    ast_val_0       rb AST_NODE_SIZE    ; NUMBER 0
    ast_while       rb AST_NODE_SIZE    ; while
    ast_cond        rb AST_NODE_SIZE    ; i < 5
    ast_var_i       rb AST_NODE_SIZE    ; VAR i (for condition)
    ast_val_5       rb AST_NODE_SIZE    ; NUMBER 5
    ast_body        rb AST_NODE_SIZE    ; alloc(64)
    ast_arg_64      rb AST_NODE_SIZE    ; NUMBER 64
    ast_inc         rb AST_NODE_SIZE    ; let i = i + 1
    ast_add         rb AST_NODE_SIZE    ; i + 1
    ast_var_i2      rb AST_NODE_SIZE    ; VAR i (for add)
    ast_val_1       rb AST_NODE_SIZE    ; NUMBER 1

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
    
    ; Reset allocation counter
    mov qword [alloc_count], 0
    
    ; === BUILD AST ===
    lea rcx, [build_msg]
    call print_string
    
    ; Register 'i'
    lea rcx, [str_i]
    call sym_add
    mov [off_i], rax                    ; i -> -8
    
    ; --- NODE 1: let i = 0 ---
    lea rbx, [ast_let_init]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax          ; offset -8
    lea rax, [ast_val_0]
    mov [rbx + AST_CHILD], rax          ; value = 0
    lea rax, [ast_while]
    mov [rbx + AST_NEXT], rax           ; next = while
    
    ; Value: 0
    lea rbx, [ast_val_0]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0
    
    ; --- NODE 2: while (i < 5) ---
    lea rbx, [ast_while]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond]
    mov [rbx + AST_CHILD], rax          ; condition
    lea rax, [ast_body]
    mov [rbx + AST_VALUE], rax          ; body
    
    ; Condition: i < 5 (NODE_OP_LT)
    lea rbx, [ast_cond]
    mov qword [rbx + AST_TYPE], NODE_OP_LT
    lea rax, [ast_var_i]
    mov [rbx + AST_CHILD], rax          ; left = i
    lea rax, [ast_val_5]
    mov [rbx + AST_VALUE], rax          ; right = 5
    
    ; Var i (for condition)
    lea rbx, [ast_var_i]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    
    ; Value: 5
    lea rbx, [ast_val_5]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 5
    
    ; --- BODY: alloc(64); let i = i + 1 ---
    lea rbx, [ast_body]
    mov qword [rbx + AST_TYPE], NODE_CALL
    lea rax, [str_alloc]
    mov [rbx + AST_VALUE], rax          ; function name
    lea rax, [ast_arg_64]
    mov [rbx + AST_CHILD], rax          ; argument
    lea rax, [ast_inc]
    mov [rbx + AST_NEXT], rax           ; next = increment
    
    ; Arg: 64
    lea rbx, [ast_arg_64]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 64
    
    ; --- INCREMENT: let i = i + 1 ---
    lea rbx, [ast_inc]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax          ; offset -8 (same i)
    lea rax, [ast_add]
    mov [rbx + AST_CHILD], rax          ; value = i + 1
    
    ; ADD: i + 1
    lea rbx, [ast_add]
    mov qword [rbx + AST_TYPE], NODE_OP_ADD
    lea rax, [ast_var_i2]
    mov [rbx + AST_CHILD], rax          ; left = i
    lea rax, [ast_val_1]
    mov [rbx + AST_VALUE], rax          ; right = 1
    
    ; Var i (for add)
    lea rbx, [ast_var_i2]
    mov qword [rbx + AST_TYPE], NODE_VAR
    mov rax, [off_i]
    mov [rbx + AST_VALUE], rax
    
    ; Value: 1
    lea rbx, [ast_val_1]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 1
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_let_init]
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
    
    add rsp, 64
    pop rbp
    
    ; === VERIFY ===
    mov rax, [alloc_count]
    cmp rax, 5
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

merkle_alloc:
    ; ECX = size (we just count allocations for this test)
    inc qword [alloc_count]
    mov rax, [heap_ptr]
    mov edx, ecx
    add [heap_ptr], rdx
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
; CODEGEN with all Phase 7 ops
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
    cmp eax, NODE_CALL
    je .gen_call
    cmp eax, NODE_WHILE
    je .gen_while
    cmp eax, NODE_OP_ADD
    je .gen_add
    cmp eax, NODE_OP_LT
    je .gen_lt
    
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
    mov dword [rdi], 0x458948           ; MOV [RBP+disp8], RAX
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

; --- gen_var ---
.gen_var:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458B48           ; MOV RAX, [RBP+disp8]
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    jmp .next_node

; --- gen_call (alloc) ---
.gen_call:
    mov rbx, [rsi + AST_VALUE]
    cmp byte [rbx], 'a'
    jne .next_node
    
    mov r12, [rsi + AST_CHILD]
    test r12, r12
    jz .next_node
    mov r13, [r12 + AST_VALUE]
    
    push rsi
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xB9                ; MOV ECX, imm32
    mov [rdi+1], r13d
    add rdi, 5
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [merkle_alloc]
    mov [rdi+2], rax
    add rdi, 10
    mov word [rdi], 0xD0FF              ; CALL RAX
    add rdi, 2
    mov [jit_cursor], rdi
    pop rsi
    jmp .next_node

; --- gen_while ---
.gen_while:
    mov rbx, [jit_cursor]
    push rbx
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548           ; TEST RAX, RAX
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F              ; JZ
    add qword [jit_cursor], 2
    mov rdx, [jit_cursor]
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    push rdx
    
    mov rsi, [rsp+8]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE9                ; JMP
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

; --- gen_add: RAX = Left + Right ---
.gen_add:
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50                ; PUSH RAX
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59                ; POP RCX
    inc qword [jit_cursor]
    
    ; ADD RAX, RCX (48 01 C8)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC80148
    add qword [jit_cursor], 3
    
    pop rsi
    jmp .next_node

; --- gen_lt: RAX = (Left < Right) ? 1 : 0 ---
.gen_lt:
    push rsi
    
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50                ; PUSH RAX
    inc qword [jit_cursor]
    
    mov rsi, [rsp]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59                ; POP RCX
    inc qword [jit_cursor]
    
    ; CMP RCX, RAX (48 39 C1)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948
    add qword [jit_cursor], 3
    
    ; SETL AL (0F 9C C0)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC09C0F
    add qword [jit_cursor], 3
    
    ; MOVZX RAX, AL (48 0F B6 C0)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48
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
