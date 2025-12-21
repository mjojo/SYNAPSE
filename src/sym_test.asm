; =============================================================================
; SYNAPSE Symbol Table Test (Phase 7.1)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests variable registration and lookup in the symbol table
; Expected: 'a' -> -8, 'b' -> -16, 'count' -> -24
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
                db '  SYNAPSE Phase 7.1: Symbol Table Test',13,10
                db '============================================',13,10,13,10,0
    
    add_a_msg   db '[ADD] Variable "a"   -> Offset: ',0
    add_b_msg   db '[ADD] Variable "b"   -> Offset: ',0
    add_c_msg   db '[ADD] Variable "count" -> Offset: ',0
    find_a_msg  db '[FIND] Variable "a"  -> Offset: ',0
    find_b_msg  db '[FIND] Variable "b"  -> Offset: ',0
    find_x_msg  db '[FIND] Variable "x"  -> Offset: ',0
    
    success_msg db 13,10,'*** SUCCESS! Symbol Table Works! ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Unexpected results ***',13,10,0
    newline     db 13,10,0
    
    ; Variable names
    str_a       db 'a',0
    str_b       db 'b',0
    str_count   db 'count',0
    str_x       db 'x',0    ; Not added - should return 0
    
    hex_chars   db '0123456789ABCDEF'

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    hex_buf         rb 20
    test_results    dq ?        ; Bit flags for test results

; Include symbol table module
include 'symbols.asm'

section '.text' code readable executable

start:
    sub rsp, 40
    
    ; Get stdout
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    ; Print banner
    lea rcx, [banner]
    call print_string
    
    ; Initialize
    call sym_init
    mov qword [test_results], 0
    
    ; === TEST 1: Add 'a' ===
    lea rcx, [add_a_msg]
    call print_string
    
    lea rcx, [str_a]
    call sym_add
    mov rsi, rax
    call print_hex_qword
    
    lea rcx, [newline]
    call print_string
    
    ; Check: should be -8 (0xFFFFFFFFFFFFFFF8)
    cmp rsi, -8
    jne .t1_fail
    or qword [test_results], 1
.t1_fail:

    ; === TEST 2: Add 'b' ===
    lea rcx, [add_b_msg]
    call print_string
    
    lea rcx, [str_b]
    call sym_add
    mov rsi, rax
    call print_hex_qword
    
    lea rcx, [newline]
    call print_string
    
    ; Check: should be -16 (0xFFFFFFFFFFFFFFF0)
    cmp rsi, -16
    jne .t2_fail
    or qword [test_results], 2
.t2_fail:

    ; === TEST 3: Add 'count' ===
    lea rcx, [add_c_msg]
    call print_string
    
    lea rcx, [str_count]
    call sym_add
    mov rsi, rax
    call print_hex_qword
    
    lea rcx, [newline]
    call print_string
    
    ; Check: should be -24 (0xFFFFFFFFFFFFFFE8)
    cmp rsi, -24
    jne .t3_fail
    or qword [test_results], 4
.t3_fail:

    ; === TEST 4: Find 'a' ===
    lea rcx, [find_a_msg]
    call print_string
    
    lea rcx, [str_a]
    call sym_find
    mov rsi, rax
    call print_hex_qword
    
    lea rcx, [newline]
    call print_string
    
    ; Check: should be -8
    cmp rsi, -8
    jne .t4_fail
    or qword [test_results], 8
.t4_fail:

    ; === TEST 5: Find 'b' ===
    lea rcx, [find_b_msg]
    call print_string
    
    lea rcx, [str_b]
    call sym_find
    mov rsi, rax
    call print_hex_qword
    
    lea rcx, [newline]
    call print_string
    
    ; Check: should be -16
    cmp rsi, -16
    jne .t5_fail
    or qword [test_results], 16
.t5_fail:

    ; === TEST 6: Find 'x' (not added) ===
    lea rcx, [find_x_msg]
    call print_string
    
    lea rcx, [str_x]
    call sym_find
    mov rsi, rax
    call print_hex_qword
    
    lea rcx, [newline]
    call print_string
    
    ; Check: should be 0 (not found)
    cmp rsi, 0
    jne .t6_fail
    or qword [test_results], 32
.t6_fail:

    ; === SUMMARY ===
    mov rax, [test_results]
    cmp rax, 63                     ; All 6 tests passed (1+2+4+8+16+32)
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
; Helper: Print 64-bit Hex
; RSI = value to print
; =============================================================================
print_hex_qword:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    lea rdi, [hex_buf]
    mov rcx, 16                     ; 16 hex digits
    
.digit_loop:
    rol rsi, 4                      ; Rotate top nibble to bottom
    mov rax, rsi
    and rax, 0xF
    lea rbx, [hex_chars]
    mov al, [rbx + rax]
    stosb
    loop .digit_loop
    
    mov byte [rdi], 0               ; Null terminate
    
    ; Print the hex string
    lea rcx, [hex_buf]
    call print_string
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; =============================================================================
; Helper: Print String
; RCX = pointer to null-terminated string
; =============================================================================
print_string:
    push rsi
    push rdx
    push r8
    push r9
    
    mov rsi, rcx
    
    ; Count length
    xor ecx, ecx
.len:
    cmp byte [rsi + rcx], 0
    je .print
    inc ecx
    jmp .len
    
.print:
    test ecx, ecx
    jz .done
    
    sub rsp, 48
    mov r8d, ecx
    mov rdx, rsi
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp+32], 0
    call [WriteConsoleA]
    add rsp, 48
    
.done:
    pop r9
    pop r8
    pop rdx
    pop rsi
    ret
