; =============================================================================
; SYNAPSE JIT Let Variable Test (Phase 7.2)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests JIT code generation for variable assignment: let x = 777
; Verifies that value is written to stack at [RBP-8]
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
                db '  SYNAPSE Phase 7.2: Let Variable Test',13,10
                db '============================================',13,10,13,10,0
    
    build_msg   db '[BUILD] AST: let x = 777',13,10,0
    compile_msg db '[JIT] Compiling to MOV [RBP-8], RAX...',13,10,0
    exec_msg    db '[EXEC] Running JIT with stack frame...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! Variable x [RBP-8] = 777 ***',13,10,0
    fail_msg    db 13,10,'*** FAIL! Variable x has wrong value ***',13,10,0
    
    str_x       db 'x',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ; AST Nodes
    ast_let_node    rb AST_NODE_SIZE
    ast_val_node    rb AST_NODE_SIZE

; Include symbol table
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
    
    ; === BUILD AST: let x = 777 ===
    lea rcx, [build_msg]
    call print_string
    
    ; 1. Register variable in symbol table
    lea rcx, [str_x]
    call sym_add                        ; RAX = -8
    mov r8, rax                         ; Save offset
    
    ; 2. Create NODE_LET
    lea rbx, [ast_let_node]
    mov qword [rbx + AST_TYPE], NODE_LET
    mov [rbx + AST_VALUE], r8           ; Stack offset = -8
    lea rax, [ast_val_node]
    mov [rbx + AST_CHILD], rax          ; Child = value expression
    
    ; 3. Create NODE_NUMBER (777)
    lea rbx, [ast_val_node]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 777
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_let_node]
    call codegen_run
    
    ; Add RET at end
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    inc qword [jit_cursor]
    
    ; === EXECUTE WITH STACK FRAME ===
    lea rcx, [exec_msg]
    call print_string
    
    ; Setup stack frame BEFORE calling JIT
    push rbp
    mov rbp, rsp
    sub rsp, 64                         ; Reserve 64 bytes for locals
    
    ; Call JIT-generated code
    mov rax, [jit_buffer]
    call rax
    
    ; Read variable x from [RBP-8]
    mov rax, [rbp - 8]
    mov r12, rax                        ; Save for check
    
    ; Cleanup stack frame
    add rsp, 64
    pop rbp
    
    ; === CHECK RESULT ===
    cmp r12, 777
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
; Memory & JIT init
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
; CODEGEN with NODE_LET support
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
    
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_number: Generate MOV RAX, imm64
; -----------------------------------------------------------------------------
.gen_number:
    mov rax, [rsi + AST_VALUE]
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848              ; MOV RAX, imm64
    mov [rdi+2], rax
    add rdi, 10
    mov [jit_cursor], rdi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_let: Generate variable assignment
; 1. Evaluate expression -> RAX
; 2. MOV [RBP + offset], RAX
; -----------------------------------------------------------------------------
.gen_let:
    push rsi
    
    ; 1. Generate code for value expression
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; 2. Get stack offset from LET node
    mov rsi, [rsp]
    mov rax, [rsi + AST_VALUE]          ; Stack offset (e.g., -8)
    
    ; 3. Generate: MOV [RBP + disp8], RAX
    ;    Opcode: 48 89 45 XX (REX.W MOV r/m64, r64)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458948           ; 48 89 45
    mov [rdi + 3], al                   ; disp8 (e.g., -8 = 0xF8)
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
