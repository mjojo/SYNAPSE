; =============================================================================
; SYNAPSE JIT Array Test (Phase 9)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests: 
;   let ptr = alloc(64)
;   ptr[0] = 42
;   let x = ptr[0]  -> x should be 42
;
; Tests pointer arithmetic: MOV [RAX + RCX*8], value
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
                db '  SYNAPSE Phase 9: Array Access Test',13,10
                db '  ptr[0] = 42; x = ptr[0]',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] Creating array access test...',13,10,0
    compile_msg db '[JIT] Compiling MOV [ptr+idx], val...',13,10,0
    exec_msg    db '[EXEC] Running JIT...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! ptr[0] = 42 works! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Array access broken ***',13,10,0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    array_ptr       dq ?        ; Pointer to allocated array

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
    
    ; === BUILD ===
    lea rcx, [build_msg]
    call print_string
    
    ; Allocate array (64 bytes = 8 qwords)
    mov rax, [heap_ptr]
    mov [array_ptr], rax
    add qword [heap_ptr], 64
    
    ; Clear the array
    mov rdi, [array_ptr]
    mov rcx, 8
    xor rax, rax
    rep stosq
    
    ; === GENERATE JIT CODE ===
    lea rcx, [compile_msg]
    call print_string
    
    mov rdi, [jit_cursor]
    
    ; --- Code: ptr[0] = 42 ---
    ; Load ptr into RAX
    ; MOV RAX, imm64 (48 B8 xx...)
    mov word [rdi], 0xB848
    mov rax, [array_ptr]
    mov [rdi+2], rax
    add rdi, 10
    
    ; Load value 42 into RCX
    ; MOV RCX, imm64 (48 B9 xx...)
    mov word [rdi], 0xB948
    mov qword [rdi+2], 42
    add rdi, 10
    
    ; Store: MOV [RAX], RCX
    ; Opcode: 48 89 08
    mov dword [rdi], 0x088948
    add rdi, 3
    
    ; --- Code: x = ptr[0] ---
    ; Load ptr into RAX (already there, but reload for clarity)
    mov word [rdi], 0xB848
    mov rax, [array_ptr]
    mov [rdi+2], rax
    add rdi, 10
    
    ; Load: MOV RAX, [RAX]
    ; Opcode: 48 8B 00
    mov dword [rdi], 0x008B48
    add rdi, 3
    
    ; RET
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    ; === EXECUTE ===
    lea rcx, [exec_msg]
    call print_string
    
    mov rax, [jit_buffer]
    call rax
    
    ; Result in RAX
    mov r12, rax
    
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
