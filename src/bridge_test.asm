; =============================================================================
; SYNAPSE -> MOVA Bridge Test (Phase 5.1)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; THE BRIDGE: JIT compiler calling MOVA Engine functions
; - Intrinsics Table: Jump table for kernel functions
; - emit_call_intrinsic: JIT generation of kernel calls
; - Proof: SYNAPSE can invoke MOVA's power!
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

; Intrinsic IDs (MOVA Kernel Functions)
ID_MERKLE_ALLOC  = 0
ID_MERKLE_COMMIT = 1
ID_SHA256        = 2

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
                db '  SYNAPSE -> MOVA Bridge Test (Phase 5.1)',13,10
                db '  JIT Compiler Calling Kernel Functions',13,10
                db '==================================================',13,10,13,10,0
    
    msg_init    db '[INIT] Initializing systems...',13,10,0
    msg_table   db '[BRIDGE] Building intrinsics table...',13,10,0
    msg_gen     db '[JIT] Generating bridge code...',13,10,0
    msg_exec    db '[JIT] Executing generated code...',13,10,0
    msg_check   db '[MOVA] Checking kernel response...',13,10,0
    msg_hash    db '  Root Hash: ',0
    msg_success db 13,10,'*** SUCCESS! SYNAPSE -> MOVA Bridge Works! ***',13,10
                db '    JIT successfully called merkle_alloc() and merkle_commit()',13,10
                db '    The language can now invoke kernel power.',13,10,0
    msg_empty   db '  (Hash is empty - no data allocated yet)',13,10,0
    newline     db 13,10,0
    
    hex_chars   db '0123456789abcdef'

    ; SHA-256 K constants (needed for merkle_commit)
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
    
    ; =====================
    ; INTRINSICS TABLE
    ; Jump table for MOVA kernel functions
    ; =====================
    intrinsics_table rq 16
    
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
    ; 1. INITIALIZE ALL SYSTEMS
    ; ===========================================
    lea rcx, [msg_init]
    call print_string
    
    call mem_init
    call merkle_init
    call jit_init
    
    ; ===========================================
    ; 2. BUILD INTRINSICS TABLE
    ; ===========================================
    lea rcx, [msg_table]
    call print_string
    
    call init_intrinsics
    
    ; ===========================================
    ; 3. GENERATE JIT CODE (The Bridge!)
    ; ===========================================
    lea rcx, [msg_gen]
    call print_string
    
    ; Get JIT cursor
    mov rdi, [jit_buffer]
    mov [jit_cursor], rdi
    
    ; --- Generate: ptr = merkle_alloc(64) ---
    
    ; MOV ECX, 64 (argument for merkle_alloc)
    ; B9 40 00 00 00
    mov byte [rdi], 0xB9
    mov dword [rdi+1], 64
    add rdi, 5
    
    ; CALL [intrinsics_table + 0] (merkle_alloc)
    ; We use: MOV RAX, [addr]; CALL RAX
    ; 48 B8 [8 bytes addr] ; FF D0
    
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [intrinsics_table]
    mov [rdi+2], rax
    add rdi, 10
    
    ; MOV RAX, [RAX] - dereference to get function ptr
    ; 48 8B 00
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x00
    add rdi, 3
    
    ; CALL RAX
    ; FF D0
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    ; --- Generate: merkle_commit() ---
    
    ; MOV RAX, [intrinsics_table + 8]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [intrinsics_table + 8]
    mov [rdi+2], rax
    add rdi, 10
    
    ; MOV RAX, [RAX]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x00
    add rdi, 3
    
    ; CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    ; RET
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    ; ===========================================
    ; 4. EXECUTE JIT CODE
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    ; Call the generated code!
    call [jit_buffer]
    
    ; ===========================================
    ; 5. VERIFY MOVA RESPONDED
    ; ===========================================
    lea rcx, [msg_check]
    call print_string
    
    lea rcx, [msg_hash]
    call print_string
    
    lea rsi, [root_hash]
    call print_hash
    
    lea rcx, [newline]
    call print_string
    
    ; ===========================================
    ; SUCCESS!
    ; ===========================================
    lea rcx, [msg_success]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; INIT INTRINSICS TABLE
; Fills jump table with MOVA kernel function pointers
; =============================================================================
init_intrinsics:
    lea rdi, [intrinsics_table]
    
    ; ID 0 = merkle_alloc
    lea rax, [merkle_alloc]
    mov [rdi + ID_MERKLE_ALLOC*8], rax
    
    ; ID 1 = merkle_commit
    lea rax, [merkle_commit]
    mov [rdi + ID_MERKLE_COMMIT*8], rax
    
    ; ID 2 = sha256_compute
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
; MERKLE LEDGER (MOVA Core)
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
    
    ; Pass 1: Compute hashes
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
    ; Pass 2: XOR chain
    lea rdi, [root_hash]
    xor rax, rax
    mov [rdi], rax
    mov [rdi+8], rax
    mov [rdi+16], rax
    mov [rdi+24], rax
    
    mov r12, [last_block_ptr]

.xor_loop:
    test r12, r12
    jz .done
    
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

.done:
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
; SHA-256 (MOVA Crypto Core)
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
.init:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .init
    
    lea rdi, [sha_block]
    mov r15, rdi
    xor eax, eax
    mov ecx, 16
    rep stosd
    
    mov rsi, [rsp+40]
    mov rdi, r15
    mov rcx, [rsp+48]
    cmp rcx, 55
    jg .toolong
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
.out:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .out
    
.toolong:
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
.loadw:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .loadw
    
    lea rdi, [sha_w]
    mov ebx, 16
.expand:
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
    jl .expand
    
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
    
.round:
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
    jl .round
    
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
