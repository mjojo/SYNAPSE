; =============================================================================
; SYNAPSE Merkle Ledger Test - Phase 3.2
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Blockchain Memory: Every allocation is a block in a chain.
; Tampering with any block changes the hash.
; =============================================================================

format PE64 console
entry start

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04

; Block Header Structure (48 bytes)
; 00-03: MAGIC ('BLOK')
; 04-07: SIZE (user data size)
; 08-15: PREV_PTR (previous block)
; 16-47: HASH (32 bytes SHA-256)
; 48+:   DATA (user data)
BLOCK_HEADER_SIZE = 48
MAGIC_BLOK = 0x4B4F4C42

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

    banner      db '================================================',13,10
                db '  SYNAPSE Merkle Ledger Test - Phase 3.2',13,10
                db '  Blockchain Memory with Tamper Detection',13,10
                db '================================================',13,10,13,10,0
    
    msg_init    db '[INIT] Initializing Ledger Heap...',13,10,0
    msg_alloc_a db '[MEM] Allocated Block A: "Hello"',13,10,0
    msg_alloc_b db '[MEM] Allocated Block B: "World"',13,10,0
    msg_commit1 db 13,10,'[CHAIN] Committing state...',13,10,0
    msg_hash1   db 'Root Hash 1: ',0
    msg_hack    db 13,10,'[HACK] ALERT! Unauthorized modification!',13,10
                db '       Changing "Hello" -> "Hxllo"',13,10,0
    msg_commit2 db 13,10,'[CHAIN] Re-committing...',13,10,0
    msg_hash2   db 'Root Hash 2: ',0
    msg_success db 13,10,'*** SUCCESS! TAMPERING DETECTED! ***',13,10
                db '    Hashes differ - Memory integrity verified!',13,10,0
    msg_fail    db 13,10,'[FAIL] Hashes match - Tampering undetected!',13,10,0
    msg_debug_hash db '  [DEBUG] Hashing block, size=',0
    newline     db 13,10,0
    
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
    
    ; Ledger
    last_block_ptr  dq ?
    
    ; Block pointers
    ptr_a           dq ?
    ptr_b           dq ?
    
    ; Saved hash for comparison
    saved_hash      rb 32
    
    ; SHA-256 working area
    sha_state       rd 8
    sha_w           rd 64
    sha_block       rb 64
    
    ; Hex output buffer
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
    
    ; Initialize systems
    lea rcx, [msg_init]
    call print_string
    
    call mem_init
    call merkle_init
    
    ; ===========================================
    ; Allocate Block A: "Hello"
    ; ===========================================
    mov rcx, 16
    call merkle_alloc
    mov [ptr_a], rax
    
    mov dword [rax], 'Hell'
    mov byte [rax+4], 'o'
    mov byte [rax+5], 0
    
    lea rcx, [msg_alloc_a]
    call print_string
    
    ; ===========================================
    ; Allocate Block B: "World"
    ; ===========================================
    mov rcx, 16
    call merkle_alloc
    mov [ptr_b], rax
    
    mov dword [rax], 'Worl'
    mov byte [rax+4], 'd'
    mov byte [rax+5], 0
    
    lea rcx, [msg_alloc_b]
    call print_string
    
    ; ===========================================
    ; COMMIT 1: Calculate and save hash
    ; ===========================================
    lea rcx, [msg_commit1]
    call print_string
    
    call merkle_commit
    
    ; Save hash OF BLOCK A (which we will modify)
    ; Block A header is at ptr_a - 48, hash is at offset 16
    mov rax, [ptr_a]
    sub rax, BLOCK_HEADER_SIZE
    lea rsi, [rax+16]           ; Hash of Block A
    lea rdi, [saved_hash]
    mov rcx, 4
    rep movsq
    
    ; Print Hash 1
    lea rcx, [msg_hash1]
    call print_string
    lea rsi, [saved_hash]
    call print_hash
    lea rcx, [newline]
    call print_string
    
    ; ===========================================
    ; TAMPERING: Modify Block A
    ; ===========================================
    lea rcx, [msg_hack]
    call print_string
    
    mov rax, [ptr_a]
    mov byte [rax+1], 'x'       ; "Hello" -> "Hxllo"
    
    ; ===========================================
    ; COMMIT 2: Recalculate hash
    ; ===========================================
    lea rcx, [msg_commit2]
    call print_string
    
    call merkle_commit
    
    ; Get Hash of Block A again
    mov rax, [ptr_a]
    sub rax, BLOCK_HEADER_SIZE
    lea r12, [rax+16]
    
    ; Print Hash 2
    lea rcx, [msg_hash2]
    call print_string
    mov rsi, r12
    call print_hash
    lea rcx, [newline]
    call print_string
    
    ; ===========================================
    ; COMPARE: Check if tampering detected
    ; ===========================================
    lea rsi, [saved_hash]
    mov rdi, r12
    mov rcx, 32
    repe cmpsb
    je .fail
    
    ; SUCCESS - Hashes differ!
    lea rcx, [msg_success]
    call print_string
    jmp .exit

.fail:
    lea rcx, [msg_fail]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

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
; MERKLE LEDGER
; =============================================================================
merkle_init:
    mov qword [last_block_ptr], 0
    ret

merkle_alloc:
    ; RCX = user data size
    push rbx
    mov rbx, rcx                ; Save user size
    
    ; Allocate: header + data
    add rcx, BLOCK_HEADER_SIZE
    mov rdx, 32
    call mem_alloc_aligned
    
    ; Fill header
    mov dword [rax], MAGIC_BLOK
    mov dword [rax+4], ebx      ; Size
    
    mov rdx, [last_block_ptr]
    mov [rax+8], rdx            ; Prev ptr
    
    ; Clear hash field
    xor rcx, rcx
    mov [rax+16], rcx
    mov [rax+24], rcx
    mov [rax+32], rcx
    mov [rax+40], rcx
    
    ; Update chain head
    mov [last_block_ptr], rax
    
    ; Return ptr to data
    add rax, BLOCK_HEADER_SIZE
    
    pop rbx
    ret

merkle_commit:
    ; Walk chain and compute hashes
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15                    ; 7 pushes = 56 bytes (odd, for alignment)
    sub rsp, 40                 ; Shadow space
    
    mov r12, [last_block_ptr]
    
.walk:
    test r12, r12
    jz .done
    
    ; Save next block ptr to stack (sha256 may trash r12/r13)
    mov rax, [r12+8]
    mov [rsp+32], rax           ; Save next ptr on stack
    
    ; Get size
    mov r14d, [r12+4]
    
    ; Call sha256_compute(input, size, output)
    lea rcx, [r12+48]           ; input = data
    mov rdx, r14                ; size
    lea r8, [r12+16]            ; output = hash field
    
    ; Save r12 before call
    mov [rsp+24], r12
    
    call sha256_compute
    
    ; Restore and get next block
    mov r12, [rsp+32]           ; Next block ptr
    jmp .walk

.done:
    ; Return ptr to last block's hash
    mov rax, [last_block_ptr]
    test rax, rax
    jz .empty
    lea rax, [rax+16]
    jmp .exit
.empty:
    xor eax, eax
.exit:
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
; SHA-256 (Inline version)
; =============================================================================
sha256_compute:
    ; RCX = input, RDX = size, R8 = output
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
    
    ; Init state
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
    
    ; Prepare block - clear it
    lea rdi, [sha_block]
    mov r15, rdi                ; Save sha_block ptr in r15
    xor eax, eax
    mov ecx, 16
    rep stosd
    
    ; Copy input
    mov rsi, [rsp+40]
    mov rdi, r15                ; sha_block
    mov rcx, [rsp+48]
    cmp rcx, 55
    jg .toolong
    rep movsb
    
    ; Padding: sha_block[size] = 0x80
    mov rax, [rsp+48]
    mov byte [r15 + rax], 0x80
    
    ; Length in bits at sha_block[56]
    mov rax, [rsp+48]
    shl rax, 3
    bswap rax
    mov qword [r15 + 56], rax
    
    ; Transform
    call sha256_transform
    
    ; Output
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
    
    ; Load W[0..15]
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
    
    ; Expand W[16..63]
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
    
    ; Init working vars
    lea rsi, [sha_state]
    mov eax, [rsi]
    mov ebx, [rsi+4]
    mov ecx, [rsi+8]
    mov edx, [rsi+12]
    mov r8d, [rsi+16]
    mov r9d, [rsi+20]
    mov r10d, [rsi+24]
    mov r11d, [rsi+28]
    
    ; 64 rounds
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
    
    ; Add to state
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

print_num:
    push rbx
    push rdi
    lea rdi, [hex_buffer + 3]
    mov byte [rdi], 0
    dec rdi
    test rax, rax
    jnz .cv
    mov byte [rdi], '0'
    dec rdi
    jmp .pt
.cv:
    mov rbx, 10
.lp:
    test rax, rax
    jz .pt
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    jmp .lp
.pt:
    inc rdi
    mov rcx, rdi
    call print_string
    pop rdi
    pop rbx
    ret
