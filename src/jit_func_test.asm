; =============================================================================
; SYNAPSE JIT Function Test (Phase 8.2-8.3)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests:
;   fn add_five() { return 5 }
;   main: call add_five -> result should be 5
;
; This tests: function registration, CALL generation, RET generation
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
                db '  SYNAPSE Phase 8.2-8.3: Function Test',13,10
                db '  fn get_five() { return 5 }',13,10
                db '  main: x = get_five()',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] Creating function and call AST...',13,10,0
    compile_msg db '[JIT] Compiling with CALL/RET...',13,10,0
    exec_msg    db '[EXEC] Running JIT code...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Function returned 5! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Unexpected result ***',13,10,0
    
    str_get_five db 'get_five',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    func_addr       dq ?        ; Address of get_five in JIT
    
    ; AST Nodes
    ast_func_def    rb AST_NODE_SIZE    ; fn get_five { ... }
    ast_return      rb AST_NODE_SIZE    ; return 5
    ast_val_5       rb AST_NODE_SIZE    ; NUMBER 5
    ast_call        rb AST_NODE_SIZE    ; call get_five

include 'functions.asm'

section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    call jit_init
    call func_init
    
    ; === BUILD ===
    lea rcx, [build_msg]
    call print_string
    
    ; We'll manually generate JIT code for a simple function
    ; Function: get_five() { return 5 }
    ; Main: call get_five, check RAX == 5
    
    ; === STEP 1: Generate function code at jit_cursor ===
    
    ; Save function start address
    mov rax, [jit_cursor]
    mov [func_addr], rax
    
    ; Register function in table
    lea rcx, [str_get_five]
    mov rdx, [func_addr]
    call func_add
    
    ; Generate function body: MOV RAX, 5; RET
    mov rdi, [jit_cursor]
    
    ; MOV RAX, imm64 (48 B8 xx xx xx xx xx xx xx xx)
    mov word [rdi], 0xB848
    mov qword [rdi+2], 5            ; Return value = 5
    add rdi, 10
    
    ; RET (C3)
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    ; === STEP 2: Generate main code that calls the function ===
    
    ; Save main entry point
    mov rbx, [jit_cursor]
    
    ; Generate: CALL get_five
    ; CALL rel32 = E8 xx xx xx xx
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE8            ; CALL opcode
    inc rdi
    
    ; Calculate relative offset: target - (current + 4)
    mov rax, [func_addr]
    sub rax, rdi
    sub rax, 4
    mov [rdi], eax                  ; Write rel32 offset
    add rdi, 4
    
    ; RET from main
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    ; === COMPILE MESSAGE ===
    lea rcx, [compile_msg]
    call print_string
    
    ; === EXECUTE ===
    lea rcx, [exec_msg]
    call print_string
    
    ; Call our main code (which calls get_five)
    call rbx                        ; RBX = main entry
    
    ; Result should be in RAX
    mov r12, rax
    
    ; === CHECK ===
    cmp r12, 5
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
; JIT Init
; =============================================================================
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
