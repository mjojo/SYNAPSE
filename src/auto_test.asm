; =============================================================================
; SYNAPSE Auto-Ledger Test (Phase 5.2)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; THE COMPILER CONTROLS THE KERNEL:
; - AST nodes describe what to do
; - Codegen generates machine code automatically
; - No more hand-written assembly for allocations!
; =============================================================================

format PE64 console
entry start

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_RW = 0x40

; Block Header (64 bytes - AVX2 Aligned)
BLOCK_HEADER_SIZE = 64
MAGIC_BLOK = 0x4B4F4C42

; AST Node Types
NODE_PROGRAM    = 0
NODE_FUNCTION   = 1
NODE_LET        = 2
NODE_RETURN     = 3
NODE_IF         = 4
NODE_BLOCK      = 5
NODE_CALL       = 6
NODE_NUMBER     = 7

; Intrinsic IDs
ID_MERKLE_ALLOC  = 0
ID_MERKLE_COMMIT = 1
ID_SHA256        = 2

; AST Node Layout (32 bytes per node)
; +0:  type (8 bytes)
; +8:  next (8 bytes - pointer to sibling)
; +16: child (8 bytes - pointer to first child)
; +24: value (8 bytes - number or string ptr)

; =============================================================================
; Imports
; =============================================================================
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

; =============================================================================
; Data
; =============================================================================
section '.data' data readable writeable

    banner      db '==================================================',13,10
                db '  SYNAPSE Auto-Ledger Test (Phase 5.2)',13,10
                db '  Compiler Generates Blockchain Calls',13,10
                db '==================================================',13,10,13,10,0
    
    msg_ast     db '[AST] Constructing syntax tree...',13,10,0
    msg_tree    db '  alloc(64)',13,10
                db '  alloc(128)',13,10
                db '  commit()',13,10,0
    msg_compile db '[JIT] Compiling AST -> Machine Code...',13,10,0
    msg_exec    db '[EXEC] Running compiled code...',13,10,0
    msg_done    db '[DONE] Execution complete!',13,10,0
    msg_hash    db '  Root Hash: ',0
    msg_success db 13,10,'*** SUCCESS! Compiler generated blockchain ops! ***',13,10
                db '    3 AST nodes -> 3 kernel calls -> 1 root hash',13,10,0
    newline     db 13,10,0
    
    ; Function names for AST
    str_alloc   db 'alloc',0
    str_commit  db 'commit',0
    
    hex_chars   db '0123456789abcdef'

    ; SHA-256 K constants
    k_table dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
            dd 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
            dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
            dd 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
            dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
            dd 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
            dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
            dd 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
            dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
            dd 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
            dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
            dd 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
            dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
            dd 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
            dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
            dd 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

    h_init  dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
            dd 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    
    ; Heap
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; JIT
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ; Ledger
    last_block_ptr  dq ?
    root_hash       rb 32
    
    ; Intrinsics Table
    intrinsics_table rq 16
    
    ; AST Storage (manual construction)
    ast_node1       rq 4    ; NODE_CALL alloc(64)
    ast_arg1        rq 4    ; NODE_NUMBER 64
    ast_node2       rq 4    ; NODE_CALL alloc(128)
    ast_arg2        rq 4    ; NODE_NUMBER 128
    ast_node3       rq 4    ; NODE_CALL commit()
    
    ; SHA-256 working area
    sha_state       rd 8
    sha_w           rd 64
    sha_block       rb 64
    
    ; Temp
    hex_buffer      rb 4

; =============================================================================
; Code
; =============================================================================
section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    ; ===========================================
    ; 1. INITIALIZE SYSTEMS
    ; ===========================================
    call mem_init
    call merkle_init
    call jit_init
    call init_intrinsics
    
    ; ===========================================
    ; 2. CONSTRUCT AST (Emulating Parser)
    ; ===========================================
    lea rcx, [msg_ast]
    call print_string
    
    lea rcx, [msg_tree]
    call print_string
    
    ; === NODE 1: alloc(64) ===
    lea rax, [ast_node1]
    mov qword [rax], NODE_CALL      ; type
    lea rbx, [ast_node2]
    mov [rax+8], rbx                ; next -> node2
    lea rbx, [ast_arg1]
    mov [rax+16], rbx               ; child -> arg1
    lea rbx, [str_alloc]
    mov [rax+24], rbx               ; value -> "alloc"
    
    ; === ARG 1: 64 ===
    lea rax, [ast_arg1]
    mov qword [rax], NODE_NUMBER
    mov qword [rax+8], 0
    mov qword [rax+16], 0
    mov qword [rax+24], 64          ; value = 64
    
    ; === NODE 2: alloc(128) ===
    lea rax, [ast_node2]
    mov qword [rax], NODE_CALL
    lea rbx, [ast_node3]
    mov [rax+8], rbx                ; next -> node3
    lea rbx, [ast_arg2]
    mov [rax+16], rbx               ; child -> arg2
    lea rbx, [str_alloc]
    mov [rax+24], rbx               ; value -> "alloc"
    
    ; === ARG 2: 128 ===
    lea rax, [ast_arg2]
    mov qword [rax], NODE_NUMBER
    mov qword [rax+8], 0
    mov qword [rax+16], 0
    mov qword [rax+24], 128         ; value = 128
    
    ; === NODE 3: commit() ===
    lea rax, [ast_node3]
    mov qword [rax], NODE_CALL
    mov qword [rax+8], 0            ; next -> NULL (end)
    mov qword [rax+16], 0           ; child -> NULL (no args)
    lea rbx, [str_commit]
    mov [rax+24], rbx               ; value -> "commit"
    
    ; ===========================================
    ; 3. COMPILE AST -> MACHINE CODE
    ; ===========================================
    lea rcx, [msg_compile]
    call print_string
    
    ; Initialize JIT cursor
    mov rax, [jit_buffer]
    mov [jit_cursor], rax
    
    ; Compile the AST
    lea rsi, [ast_node1]            ; Start with first node
    call codegen_run
    
    ; Add RET at end
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3
    
    ; ===========================================
    ; 4. EXECUTE GENERATED CODE
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    ; MAGIC HAPPENS HERE!
    ; The compiled code will:
    ;   1. Call merkle_alloc(64)
    ;   2. Call merkle_alloc(128)
    ;   3. Call merkle_commit()
    call [jit_buffer]
    
    ; ===========================================
    ; 5. SHOW RESULTS
    ; ===========================================
    lea rcx, [msg_done]
    call print_string
    
    lea rcx, [msg_hash]
    call print_string
    
    lea rsi, [root_hash]
    call print_hash
    
    lea rcx, [newline]
    call print_string
    
    lea rcx, [msg_success]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; CODEGEN: AST -> Machine Code
; This is the BRAIN of the compiler!
; =============================================================================
codegen_run:
    ; RSI = pointer to current AST node
    push rbx
    push r12
    push r13
    
.process_node:
    test rsi, rsi
    jz .codegen_done
    
    ; Get node type
    mov eax, [rsi]
    
    cmp eax, NODE_CALL
    je .gen_call
    
    ; --- Phase 6.3-6.4: Control Flow ---
    cmp eax, NODE_IF
    je .gen_if
    
    cmp eax, NODE_WHILE
    je .gen_while
    
    cmp eax, NODE_BINOP
    je .gen_binop
    
    cmp eax, NODE_NUMBER
    je .gen_number
    
    ; Unknown node - skip
    jmp .next_node

.gen_call:
    ; RSI = NODE_CALL
    ; [RSI+24] = function name ptr
    ; [RSI+16] = argument node ptr (or NULL)
    
    mov rbx, [rsi+24]               ; Get function name
    
    ; Check first character
    cmp byte [rbx], 'a'             ; "alloc"?
    je .do_alloc
    
    cmp byte [rbx], 'c'             ; "commit"?
    je .do_commit
    
    jmp .next_node

.do_alloc:
    ; === GENERATE: ptr = merkle_alloc(SIZE) ===
    
    ; Get argument value
    mov r12, [rsi+16]               ; Child node (arg)
    test r12, r12
    jz .next_node                   ; No arg = error
    
    mov r13, [r12+24]               ; Get number value
    
    ; Save RSI (codegen uses it)
    push rsi
    
    ; Generate: MOV ECX, size (argument for alloc)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xB9            ; MOV ECX, imm32
    mov [rdi+1], r13d
    add rdi, 5
    mov [jit_cursor], rdi
    
    ; Generate: MOV RAX, [intrinsics_table+0]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [intrinsics_table]
    mov [rdi+2], rax
    add rdi, 10
    
    ; Generate: MOV RAX, [RAX]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x00
    add rdi, 3
    
    ; Generate: CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    mov [jit_cursor], rdi
    
    pop rsi
    jmp .next_node

.do_commit:
    ; === GENERATE: merkle_commit() ===
    
    push rsi
    
    mov rdi, [jit_cursor]
    
    ; Generate: MOV RAX, [intrinsics_table+8]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [intrinsics_table + 8]
    mov [rdi+2], rax
    add rdi, 10
    
    ; Generate: MOV RAX, [RAX]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x00
    add rdi, 3
    
    ; Generate: CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    mov [jit_cursor], rdi
    
    pop rsi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_number: Generate MOV RAX, immediate
; Node: [RSI+24] = numeric value
; -----------------------------------------------------------------------------
.gen_number:
    mov rax, [rsi+24]               ; Get number value
    
    mov rdi, [jit_cursor]
    
    ; Generate: MOV RAX, imm64 (48 B8 XX XX XX XX XX XX XX XX)
    mov word [rdi], 0xB848          ; REX.W + MOV RAX opcode
    mov [rdi+2], rax                ; 64-bit immediate
    add rdi, 10
    
    mov [jit_cursor], rdi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_binop: Generate comparison (returns 1 or 0 in RAX)
; Node: [RSI+16] = Left node, [RSI+24] = Right node
; -----------------------------------------------------------------------------
.gen_binop:
    push rsi
    
    ; 1. Generate Left side -> RAX
    mov rsi, [rsi + AST_CHILD]      ; Left operand
    call codegen_run
    
    ; Generate: PUSH RAX (50)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; 2. Generate Right side -> RAX
    mov rsi, [rsp]                  ; Restore node ptr
    mov rsi, [rsi + AST_VALUE]      ; Right operand
    call codegen_run
    
    ; Generate: POP RCX (59) - left result now in RCX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; Generate: CMP RCX, RAX (48 39 C1)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948
    add qword [jit_cursor], 3
    
    ; Generate: SETE AL (0F 94 C0) - set AL=1 if equal
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0940F
    add qword [jit_cursor], 3
    
    ; Generate: MOVZX RAX, AL (48 0F B6 C0) - extend to 64-bit
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48
    add qword [jit_cursor], 4
    
    pop rsi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_if: Generate IF statement with backpatching
; Node: [RSI+16] = Condition, [RSI+24] = Body
; -----------------------------------------------------------------------------
.gen_if:
    push rsi
    
    ; 1. Generate Condition code (result in RAX)
    mov rsi, [rsi + AST_CHILD]      ; Condition node
    call codegen_run
    
    ; 2. Generate: TEST RAX, RAX (48 85 C0)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    ; 3. Generate: JZ rel32 (0F 84 XX XX XX XX)
    ;    Reserve space for jump offset (placeholder = 0)
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F          ; JZ opcode
    add qword [jit_cursor], 2
    
    mov rdx, [jit_cursor]           ; SAVE PATCH ADDRESS
    mov dword [rdi+2], 0            ; Placeholder offset
    add qword [jit_cursor], 4
    
    ; 4. Generate Body code
    push rdx                        ; Save patch address
    mov rsi, [rsp+8]                ; Restore node ptr
    mov rsi, [rsi + AST_VALUE]      ; Body node
    call codegen_run
    pop rdx                         ; Restore patch address
    
    ; 5. BACKPATCHING: Calculate and write offset
    ;    offset = current_cursor - patch_address - 4
    mov rax, [jit_cursor]
    sub rax, rdx
    sub rax, 4
    mov [rdx], eax                  ; Write offset to placeholder
    
    pop rsi
    jmp .next_node

; -----------------------------------------------------------------------------
; .gen_while: Generate WHILE loop with backward jump
; Logic: START: cond -> TEST -> JZ EXIT -> body -> JMP START -> EXIT:
; Node: [RSI+16] = Condition, [RSI+24] = Body
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
    
    jmp .next_node

.next_node:
    mov rsi, [rsi+8]                ; Move to next sibling
    jmp .process_node

.codegen_done:
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; INTRINSICS TABLE
; =============================================================================
init_intrinsics:
    lea rdi, [intrinsics_table]
    lea rax, [merkle_alloc]
    mov [rdi + ID_MERKLE_ALLOC*8], rax
    lea rax, [merkle_commit]
    mov [rdi + ID_MERKLE_COMMIT*8], rax
    lea rax, [sha256_compute]
    mov [rdi + ID_SHA256*8], rax
    ret

; =============================================================================
; MEMORY MANAGER
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 1024*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call [VirtualAlloc]
    add rsp, 40
    mov [heap_base], rax
    mov [heap_ptr], rax
    ret

mem_alloc_aligned:
    mov rax, [heap_ptr]
    dec rdx
    add rax, rdx
    not rdx
    and rax, rdx
    mov r8, rax
    add r8, rcx
    mov [heap_ptr], r8
    ret

; =============================================================================
; JIT INIT
; =============================================================================
jit_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 64*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_RW
    call [VirtualAlloc]
    add rsp, 40
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    ret

; =============================================================================
; MERKLE LEDGER
; =============================================================================
merkle_init:
    mov qword [last_block_ptr], 0
    ret

merkle_alloc:
    push rbx
    mov rbx, rcx
    
    add rcx, BLOCK_HEADER_SIZE
    mov rdx, 32
    call mem_alloc_aligned
    
    mov dword [rax], MAGIC_BLOK
    mov dword [rax+4], ebx
    
    mov rdx, [last_block_ptr]
    mov [rax+8], rdx
    
    xor rcx, rcx
    mov [rax+16], rcx
    mov [rax+24], rcx
    mov [rax+32], rcx
    mov [rax+40], rcx
    mov [rax+48], rcx
    mov [rax+56], rcx
    
    mov [last_block_ptr], rax
    add rax, BLOCK_HEADER_SIZE
    
    pop rbx
    ret

merkle_commit:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    mov r12, [last_block_ptr]
    
.pass1:
    test r12, r12
    jz .pass1_done
    
    mov rax, [r12+8]
    mov [rsp+32], rax
    
    mov r14d, [r12+4]
    lea rcx, [r12+64]
    mov rdx, r14
    lea r8, [r12+16]
    
    mov [rsp+24], r12
    call sha256_compute
    
    mov r12, [rsp+32]
    jmp .pass1

.pass1_done:
    lea rdi, [root_hash]
    xor rax, rax
    mov [rdi], rax
    mov [rdi+8], rax
    mov [rdi+16], rax
    mov [rdi+24], rax
    
    mov r12, [last_block_ptr]

.xor_loop:
    test r12, r12
    jz .commit_done
    
    mov rax, [rdi]
    xor rax, [r12+16]
    mov [rdi], rax
    
    mov rax, [rdi+8]
    xor rax, [r12+24]
    mov [rdi+8], rax
    
    mov rax, [rdi+16]
    xor rax, [r12+32]
    mov [rdi+16], rax
    
    mov rax, [rdi+24]
    xor rax, [r12+40]
    mov [rdi+24], rax
    
    mov r12, [r12+8]
    jmp .xor_loop

.commit_done:
    lea rax, [root_hash]
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; SHA-256
; =============================================================================
sha256_compute:
    push rbx
    push rsi
    push rdi
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
    
    mov [rsp+40], rcx
    mov [rsp+48], rdx
    mov r14, r8
    
    lea rsi, [h_init]
    lea rdi, [sha_state]
    mov ecx, 8
.sha_init:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .sha_init
    
    lea rdi, [sha_block]
    mov r15, rdi
    xor eax, eax
    mov ecx, 16
    rep stosd
    
    mov rsi, [rsp+40]
    mov rdi, r15
    mov rcx, [rsp+48]
    cmp rcx, 55
    jg .sha_toolong
    rep movsb
    
    mov rax, [rsp+48]
    mov byte [r15 + rax], 0x80
    
    mov rax, [rsp+48]
    shl rax, 3
    bswap rax
    mov qword [r15 + 56], rax
    
    call sha256_transform
    
    lea rsi, [sha_state]
    mov rdi, r14
    mov ecx, 8
.sha_out:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .sha_out
    
.sha_toolong:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rdi
    pop rsi
    pop rbx
    ret

sha256_transform:
    push rbx
    push rsi
    push rdi
    push rbp
    push r12
    push r13
    push r14
    push r15
    
    lea rsi, [sha_block]
    lea rdi, [sha_w]
    mov ecx, 16
.tf_loadw:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .tf_loadw
    
    lea rdi, [sha_w]
    mov ebx, 16
.tf_expand:
    mov eax, [rdi + rbx*4 - 60]
    mov edx, eax
    ror edx, 7
    mov r8d, eax
    ror r8d, 18
    xor edx, r8d
    mov r8d, eax
    shr r8d, 3
    xor edx, r8d
    
    mov eax, [rdi + rbx*4 - 8]
    mov r9d, eax
    ror r9d, 17
    mov r8d, eax
    ror r8d, 19
    xor r9d, r8d
    mov r8d, eax
    shr r8d, 10
    xor r9d, r8d
    
    mov eax, [rdi + rbx*4 - 64]
    add eax, edx
    add eax, [rdi + rbx*4 - 28]
    add eax, r9d
    mov [rdi + rbx*4], eax
    
    inc ebx
    cmp ebx, 64
    jl .tf_expand
    
    lea rsi, [sha_state]
    mov eax, [rsi]
    mov ebx, [rsi+4]
    mov ecx, [rsi+8]
    mov edx, [rsi+12]
    mov r8d, [rsi+16]
    mov r9d, [rsi+20]
    mov r10d, [rsi+24]
    mov r11d, [rsi+28]
    
    lea rbp, [k_table]
    lea rdi, [sha_w]
    xor rsi, rsi
    
.tf_round:
    mov r12d, r8d
    ror r12d, 6
    mov r13d, r8d
    ror r13d, 11
    xor r12d, r13d
    mov r13d, r8d
    ror r13d, 25
    xor r12d, r13d
    
    mov r13d, r8d
    and r13d, r9d
    mov r14d, r8d
    not r14d
    and r14d, r10d
    xor r13d, r14d
    
    add r12d, r13d
    add r12d, r11d
    add r12d, [rbp + rsi*4]
    add r12d, [rdi + rsi*4]
    
    mov r13d, eax
    ror r13d, 2
    mov r14d, eax
    ror r14d, 13
    xor r13d, r14d
    mov r14d, eax
    ror r14d, 22
    xor r13d, r14d
    
    mov r14d, eax
    and r14d, ebx
    mov r15d, eax
    and r15d, ecx
    xor r14d, r15d
    mov r15d, ebx
    and r15d, ecx
    xor r14d, r15d
    
    add r13d, r14d
    
    mov r11d, r10d
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, edx
    add r8d, r12d
    mov edx, ecx
    mov ecx, ebx
    mov ebx, eax
    mov eax, r12d
    add eax, r13d
    
    inc rsi
    cmp rsi, 64
    jl .tf_round
    
    lea rsi, [sha_state]
    add [rsi], eax
    add [rsi+4], ebx
    add [rsi+8], ecx
    add [rsi+12], edx
    add [rsi+16], r8d
    add [rsi+20], r9d
    add [rsi+24], r10d
    add [rsi+28], r11d
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; Print utilities
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
    mov rdx, rsi
    mov r8d, ecx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call [WriteConsoleA]
    add rsp, 48
.dn:
    pop rsi
    ret

print_hash:
    push rbx
    push rcx
    mov ecx, 32
.lp:
    push rcx
    movzx eax, byte [rsi]
    call print_hex_byte
    inc rsi
    pop rcx
    dec ecx
    jnz .lp
    pop rcx
    pop rbx
    ret

print_hex_byte:
    push rdi
    mov ebx, eax
    shr eax, 4
    and eax, 0xF
    lea rdi, [hex_chars]
    mov al, [rdi + rax]
    mov [hex_buffer], al
    mov eax, ebx
    and eax, 0xF
    mov al, [rdi + rax]
    mov [hex_buffer + 1], al
    mov byte [hex_buffer + 2], 0
    lea rcx, [hex_buffer]
    call print_string
    pop rdi
    ret
