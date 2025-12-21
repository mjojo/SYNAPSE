; =============================================================================
; SYNAPSE Control Flow Test (Phase 6)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; =============================================================================

format PE64 console
entry start

MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
ERR_SYNTAX      = 1

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
                db '  SYNAPSE Phase 6: Control Flow Test',13,10
                db '============================================',13,10,13,10,0
    
    test1_msg   db '[TEST 1] Simple if...',13,10,0
    test2_msg   db '[TEST 2] If/else...',13,10,0
    test3_msg   db '[TEST 3] While loop...',13,10,0
    
    ok_msg      db '[PASS]',13,10,0
    fail_msg    db '[FAIL]',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Phase 6 Parser Works! ***',13,10,0
    
    test1_src   db 'if x > 0:',13,10
                db '    return true',13,10
                db 0
    
    test2_src   db 'if x > 0:',13,10
                db '    return 1',13,10
                db 'else:',13,10
                db '    return 0',13,10
                db 0
    
    test3_src   db 'while i < 10:',13,10
                db '    i = i + 1',13,10
                db 0

section '.bss' data readable writeable
    stdout          dq ?
    bytes_written   dd ?
    tests_passed    dd ?
    test_tokens     rb 24 * 4096

include '..\include\synapse_tokens.inc'
include '..\include\ast.inc'
include '..\src\lexer_v2.asm'
include '..\src\parser_v2.asm'

section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    mov dword [tests_passed], 0
    
    ; TEST 1
    lea rcx, [test1_msg]
    call print_string
    lea rcx, [test1_src]
    call run_test
    test eax, eax
    jz .t1_fail
    inc dword [tests_passed]
    lea rcx, [ok_msg]
    call print_string
    jmp .t2
.t1_fail:
    lea rcx, [fail_msg]
    call print_string

.t2:
    ; TEST 2
    lea rcx, [test2_msg]
    call print_string
    lea rcx, [test2_src]
    call run_test
    test eax, eax
    jz .t2_fail
    inc dword [tests_passed]
    lea rcx, [ok_msg]
    call print_string
    jmp .t3
.t2_fail:
    lea rcx, [fail_msg]
    call print_string

.t3:
    ; TEST 3
    lea rcx, [test3_msg]
    call print_string
    lea rcx, [test3_src]
    call run_test
    test eax, eax
    jz .t3_fail
    inc dword [tests_passed]
    lea rcx, [ok_msg]
    call print_string
    jmp .summary
.t3_fail:
    lea rcx, [fail_msg]
    call print_string

.summary:
    cmp dword [tests_passed], 3
    jne .exit
    lea rcx, [success_msg]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

run_test:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    
    ; RCX = source code pointer (passed by caller)
    call synlex_init
    
    lea rbx, [test_tokens]
    mov rsi, rbx

.tok_loop:
    mov rdi, rsi                    ; RDI = token output pointer
    call synlex_next_token
    test eax, eax
    jz .tok_done
    cmp eax, STOK_EOF
    je .tok_done
    add rsi, 24
    jmp .tok_loop

.tok_done:
    mov rcx, rbx
    mov rdx, rsi
    call parser_init
    call parse_program
    
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

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
