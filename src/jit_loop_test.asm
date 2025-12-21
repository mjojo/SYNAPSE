; =============================================================================
; SYNAPSE JIT Loop Test (Phase 6.4)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests JIT code generation for WHILE loop with backward jump
; Test: while (0) { alloc(64) } - body should be SKIPPED
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
                db '  SYNAPSE Phase 6.4: JIT Loop Test',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] AST: while (0) { alloc(64) }',13,10,0
    compile_msg db '[JIT] Compiling with backward jump...',13,10,0
    exec_msg    db '[EXEC] Running (should skip body)...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Loop body skipped correctly! ***',13,10
                db '    While(0) generated proper JZ exit.',13,10,0
    fail_msg    db 13,10,'*** FAIL! Loop executed despite condition = 0 ***',13,10,0
    
    str_alloc   db 'alloc',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    last_block_ptr  dq ?
    
    ; AST Nodes
    ast_while_node  rb AST_NODE_SIZE
    ast_cond_node   rb AST_NODE_SIZE
    ast_body_node   rb AST_NODE_SIZE
    ast_arg_node    rb AST_NODE_SIZE
    
    intrinsics_table rq 16
    ID_MERKLE_ALLOC = 0

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
    call init_intrinsics
    
    ; === BUILD AST: while (0) { alloc(64) } ===
    lea rcx, [build_msg]
    call print_string
    
    ; WHILE NODE
    lea rbx, [ast_while_node]
    mov qword [rbx + AST_TYPE], NODE_WHILE
    lea rax, [ast_cond_node]
    mov [rbx + AST_CHILD], rax
    lea rax, [ast_body_node]
    mov [rbx + AST_VALUE], rax
    
    ; CONDITION: 0 (false)
    lea rbx, [ast_cond_node]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 0           ; 0 = FALSE
    
    ; BODY: alloc(64)
    lea rbx, [ast_body_node]
    mov qword [rbx + AST_TYPE], NODE_CALL
    lea rax, [ast_arg_node]
    mov [rbx + AST_CHILD], rax
    lea rax, [str_alloc]
    mov [rbx + AST_VALUE], rax
    
    lea rbx, [ast_arg_node]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 64
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    ; Clear last_block_ptr to detect if alloc is called
    mov qword [last_block_ptr], 0
    
    lea rsi, [ast_while_node]
    call codegen_run
    
    ; Add RET
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; === EXECUTE ===
    lea rcx, [exec_msg]
    call print_string
    
    mov rax, [jit_buffer]
    call rax
    
    ; === CHECK ===
    mov rax, [last_block_ptr]
    test rax, rax
    jnz .fail                               ; If memory was allocated = FAIL
    
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
; Memory & JIT init (same as jit_logic_test)
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
    mov rax, [heap_ptr]
    mov [last_block_ptr], rax
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

init_intrinsics:
    lea rdi, [intrinsics_table]
    lea rax, [merkle_alloc]
    mov [rdi + ID_MERKLE_ALLOC*8], rax
    ret

; =============================================================================
; CODEGEN (with while loop support)
; =============================================================================
codegen_run:
    push rbx
    push r12
    push r13

.process_node:
    test rsi, rsi
    jz .codegen_done
    
    mov eax, [rsi]
    
    cmp eax, NODE_CALL
    je .gen_call
    cmp eax, NODE_WHILE
    je .gen_while
    cmp eax, NODE_NUMBER
    je .gen_number
    
    jmp .next_node

.gen_call:
    mov rbx, [rsi + AST_VALUE]
    cmp byte [rbx], 'a'
    je .do_alloc
    jmp .next_node

.do_alloc:
    mov r12, [rsi + AST_CHILD]
    test r12, r12
    jz .next_node
    mov r13, [r12 + AST_VALUE]
    
    push rsi
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xB9
    mov [rdi+1], r13d
    add rdi, 5
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [merkle_alloc]
    mov [rdi+2], rax
    add rdi, 10
    mov word [rdi], 0xD0FF
    add rdi, 2
    mov [jit_cursor], rdi
    pop rsi
    jmp .next_node

.gen_number:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov [rdi+2], rax
    add rdi, 10
    mov [jit_cursor], rdi
    jmp .next_node

.gen_while:
    ; 1. Save loop start
    mov rbx, [jit_cursor]
    push rbx
    push rsi
    
    ; 2. Generate condition
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; 3. TEST RAX, RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    ; 4. JZ EXIT (placeholder)
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F
    add qword [jit_cursor], 2
    mov rdx, [jit_cursor]
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    push rdx
    
    ; 5. Generate body
    mov rsi, [rsp+8]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    
    ; 6. JMP START (backward)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE9
    inc qword [jit_cursor]
    
    mov rax, [rsp+16]
    sub rax, [jit_cursor]
    sub rax, 4
    mov rdi, [jit_cursor]
    mov [rdi], eax
    add qword [jit_cursor], 4
    
    ; 7. Patch exit
    pop rdx
    pop rsi
    pop rbx
    
    mov rax, [jit_cursor]
    sub rax, rdx
    sub rax, 4
    mov [rdx], eax
    
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
    pop rsi
    ret
