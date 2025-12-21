; =============================================================================
; SYNAPSE JIT Logic Test (Phase 6.3)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests JIT code generation for IF statement with backpatching
; Manually builds AST: if (1 == 1) { alloc(64) }
; =============================================================================

format PE64 console
entry start

MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_RW = 0x40

; Import ast.inc definitions
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
                db '  SYNAPSE Phase 6.3: JIT Logic Test',13,10
                db '============================================',13,10,13,10,0
    
    init_msg    db '[INIT] Setting up...',13,10,0
    build_msg   db '[BUILD] Constructing AST: if (1 == 1) { alloc(64) }',13,10,0
    compile_msg db '[JIT] Compiling AST to machine code...',13,10,0
    exec_msg    db '[EXEC] Running generated code...',13,10,0
    
    success_msg db 13,10,'*** SUCCESS! IF condition was TRUE! ***',13,10
                db '    Memory allocated by JIT code.',13,10,0
    fail_msg    db 13,10,'*** FAIL! IF condition did not execute body. ***',13,10,0
    
    str_alloc   db 'alloc',0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    
    ; Memory pools
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    last_block_ptr  dq ?
    
    ; AST Nodes (48 bytes each = AST_NODE_SIZE)
    ast_if_node     rb AST_NODE_SIZE     ; IF node
    ast_cond_node   rb AST_NODE_SIZE     ; BINOP (==)
    ast_left_num    rb AST_NODE_SIZE     ; NUMBER (1)
    ast_right_num   rb AST_NODE_SIZE     ; NUMBER (1)
    ast_body_node   rb AST_NODE_SIZE     ; CALL alloc
    ast_arg_node    rb AST_NODE_SIZE     ; NUMBER (64)
    
    ; Intrinsics table
    intrinsics_table rq 16
    
    ID_MERKLE_ALLOC = 0
    ID_MERKLE_COMMIT = 1
    ID_SHA256 = 2

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
    
    ; === INIT ===
    lea rcx, [init_msg]
    call print_string
    
    call mem_init
    call jit_init
    call init_intrinsics
    
    ; === BUILD AST ===
    lea rcx, [build_msg]
    call print_string
    
    call build_test_ast
    
    ; === COMPILE ===
    lea rcx, [compile_msg]
    call print_string
    
    lea rsi, [ast_if_node]
    call codegen_run
    
    ; Add RET at the end
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3    ; RET
    inc qword [jit_cursor]
    
    ; === EXECUTE ===
    lea rcx, [exec_msg]
    call print_string
    
    mov rax, [jit_buffer]
    call rax
    
    ; === CHECK RESULT ===
    mov rax, [last_block_ptr]
    test rax, rax
    jz .fail
    
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
; BUILD TEST AST: if (1 == 1) { alloc(64) }
; =============================================================================
build_test_ast:
    ; === IF NODE ===
    lea rbx, [ast_if_node]
    mov qword [rbx + AST_TYPE], NODE_IF
    lea rax, [ast_cond_node]
    mov [rbx + AST_CHILD], rax          ; Condition
    lea rax, [ast_body_node]
    mov [rbx + AST_VALUE], rax          ; Body
    
    ; === CONDITION: 1 == 1 (BINOP) ===
    lea rbx, [ast_cond_node]
    mov qword [rbx + AST_TYPE], NODE_BINOP
    lea rax, [ast_left_num]
    mov [rbx + AST_CHILD], rax          ; Left = 1
    lea rax, [ast_right_num]
    mov [rbx + AST_VALUE], rax          ; Right = 1
    
    ; === LEFT NUMBER (1) ===
    lea rbx, [ast_left_num]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 1      ; Value = 1
    
    ; === RIGHT NUMBER (1) ===
    lea rbx, [ast_right_num]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 1      ; Value = 1
    
    ; === BODY: alloc(64) ===
    lea rbx, [ast_body_node]
    mov qword [rbx + AST_TYPE], NODE_CALL
    lea rax, [ast_arg_node]
    mov [rbx + AST_CHILD], rax          ; Argument
    lea rax, [str_alloc]
    mov [rbx + AST_VALUE], rax          ; Function name
    
    ; === ARGUMENT (64) ===
    lea rbx, [ast_arg_node]
    mov qword [rbx + AST_TYPE], NODE_NUMBER
    mov qword [rbx + AST_VALUE], 64     ; Size = 64
    
    ret

; =============================================================================
; Memory Manager (simplified for test)
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

; Simplified merkle_alloc for test
merkle_alloc:
    ; ECX = size
    mov rax, [heap_ptr]
    mov [last_block_ptr], rax           ; Save for verification
    mov edx, ecx                        ; Zero-extend ECX to RDX
    add [heap_ptr], rdx
    ret

; =============================================================================
; JIT Initialization
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
; CODEGEN (from auto_test.asm)
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
    cmp eax, NODE_IF
    je .gen_if
    cmp eax, NODE_WHILE
    je .gen_while
    cmp eax, NODE_BINOP
    je .gen_binop
    cmp eax, NODE_NUMBER
    je .gen_number
    
    jmp .next_node

.gen_call:
    mov rbx, [rsi + AST_VALUE]          ; Function name
    cmp byte [rbx], 'a'
    je .do_alloc
    jmp .next_node

.do_alloc:
    mov r12, [rsi + AST_CHILD]          ; Arg node
    test r12, r12
    jz .next_node
    mov r13, [r12 + AST_VALUE]          ; Get size
    
    push rsi
    mov rdi, [jit_cursor]
    
    ; MOV ECX, size
    mov byte [rdi], 0xB9
    mov [rdi+1], r13d
    add rdi, 5
    
    ; MOV RAX, &merkle_alloc
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [merkle_alloc]
    mov [rdi+2], rax
    add rdi, 10
    
    ; CALL RAX
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

.gen_binop:
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
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948           ; CMP RCX, RAX
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0940F           ; SETE AL
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48         ; MOVZX RAX, AL
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

.gen_if:
    push rsi
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548           ; TEST RAX, RAX
    add qword [jit_cursor], 3
    
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F              ; JZ
    add qword [jit_cursor], 2
    
    mov rdx, [jit_cursor]               ; Patch address
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    push rdx
    mov rsi, [rsp+8]
    mov rsi, [rsi + AST_VALUE]
    call codegen_run
    pop rdx
    
    mov rax, [jit_cursor]
    sub rax, rdx
    sub rax, 4
    mov [rdx], eax
    
    pop rsi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_while: Generate WHILE loop with backward jump
; Logic: START: cond -> TEST -> JZ EXIT -> body -> JMP START -> EXIT:
; -----------------------------------------------------------------------------
.gen_while:
    ; 1. LOOP START - save current cursor position
    mov rbx, [jit_cursor]
    push rbx                            ; [RSP+16] = Loop Start
    push rsi                            ; [RSP+8]  = WHILE node
    
    ; 2. Generate Condition
    mov rsi, [rsi + AST_CHILD]
    call codegen_run
    
    ; 3. TEST RAX, RAX (48 85 C0)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    ; 4. JZ EXIT (0F 84 XX XX XX XX) - placeholder
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F
    add qword [jit_cursor], 2
    
    mov rdx, [jit_cursor]               ; Exit patch address
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    push rdx                            ; [RSP+0] = Exit patch
    
    ; 5. Generate Body
    mov rsi, [rsp+8]                    ; Get WHILE node
    mov rsi, [rsi + AST_VALUE]          ; Body
    call codegen_run
    
    ; 6. JMP START (E9 XX XX XX XX) - backward jump
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE9
    inc qword [jit_cursor]
    
    ; Calculate negative offset: Target - (Current + 4)
    mov rax, [rsp+16]                   ; Loop Start address
    sub rax, [jit_cursor]
    sub rax, 4
    
    mov rdi, [jit_cursor]
    mov [rdi], eax                      ; Write (negative) offset
    add qword [jit_cursor], 4
    
    ; 7. PATCH EXIT JUMP
    pop rdx                             ; Exit patch address
    pop rsi                             ; WHILE node
    pop rbx                             ; Loop start (cleanup)
    
    mov rax, [jit_cursor]
    sub rax, rdx
    sub rax, 4
    mov [rdx], eax                      ; Patch JZ to jump here

.next_node:
    mov rsi, [rsi + AST_NEXT]
    jmp .process_node

.codegen_done:
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; Intrinsics
; =============================================================================
init_intrinsics:
    lea rdi, [intrinsics_table]
    lea rax, [merkle_alloc]
    mov [rdi + ID_MERKLE_ALLOC*8], rax
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
