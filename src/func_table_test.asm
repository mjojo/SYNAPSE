; =============================================================================
; SYNAPSE Function Table Test (Phase 8.1)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests function registration and lookup in the function table
; =============================================================================

format PE64 console
entry start

section '.idata' import data readable
    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetStdHandle    dq RVA _GetStdHandle
        WriteConsoleA   dq RVA _WriteConsoleA
        ExitProcess     dq RVA _ExitProcess
                        dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0

section '.data' data readable writeable

    banner      db '============================================',13,10
                db '  SYNAPSE Phase 8.1: Function Table Test',13,10
                db '============================================',13,10,13,10,0
    
    reg_init    db '[REG] Registering "init" at 0x12345678',13,10,0
    reg_main    db '[REG] Registering "main" at 0xDEADBEEF',13,10,0
    reg_train   db '[REG] Registering "train" at 0xCAFEBABE',13,10,0
    
    find_init   db '[FIND] Looking for "init"...',13,10,0
    find_main   db '[FIND] Looking for "main"...',13,10,0
    find_train  db '[FIND] Looking for "train"...',13,10,0
    find_none   db '[FIND] Looking for "unknown"...',13,10,0
    
    success_msg db '*** SUCCESS! All function lookups correct! ***',13,10,0
    fail_msg    db '*** FAIL! Lookup mismatch ***',13,10,0
    not_found_ok db '        -> Not found (expected)',13,10,0
    found_ok    db '        -> Found! Address correct.',13,10,0
    
    str_init    db 'init',0
    str_main    db 'main',0
    str_train   db 'train',0
    str_unknown db 'unknown',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    test_results    dq ?

include 'functions.asm'

section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    call func_init
    mov qword [test_results], 0
    
    ; === REGISTER FUNCTIONS ===
    
    ; Register 'init' at 0x12345678
    lea rcx, [reg_init]
    call print_string
    lea rcx, [str_init]
    mov rdx, 0x12345678
    call func_add
    
    ; Register 'main' at 0xDEADBEEF
    lea rcx, [reg_main]
    call print_string
    lea rcx, [str_main]
    mov rdx, 0xDEADBEEF
    call func_add
    
    ; Register 'train' at 0xCAFEBABE
    lea rcx, [reg_train]
    call print_string
    lea rcx, [str_train]
    mov rdx, 0xCAFEBABE
    call func_add
    
    ; === TEST 1: Find 'init' ===
    lea rcx, [find_init]
    call print_string
    
    lea rcx, [str_init]
    call func_find
    cmp rax, 0x12345678
    jne .fail
    
    lea rcx, [found_ok]
    call print_string
    or qword [test_results], 1
    
    ; === TEST 2: Find 'main' ===
    lea rcx, [find_main]
    call print_string
    
    lea rcx, [str_main]
    call func_find
    mov rbx, 0xDEADBEEF
    cmp rax, rbx
    jne .fail
    
    lea rcx, [found_ok]
    call print_string
    or qword [test_results], 2
    
    ; === TEST 3: Find 'train' ===
    lea rcx, [find_train]
    call print_string
    
    lea rcx, [str_train]
    call func_find
    mov rbx, 0xCAFEBABE
    cmp rax, rbx
    jne .fail
    
    lea rcx, [found_ok]
    call print_string
    or qword [test_results], 4
    
    ; === TEST 4: Find 'unknown' (should return 0) ===
    lea rcx, [find_none]
    call print_string
    
    lea rcx, [str_unknown]
    call func_find
    test rax, rax
    jnz .fail
    
    lea rcx, [not_found_ok]
    call print_string
    or qword [test_results], 8
    
    ; === SUMMARY ===
    mov rax, [test_results]
    cmp rax, 15                         ; All 4 tests passed (1+2+4+8)
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
