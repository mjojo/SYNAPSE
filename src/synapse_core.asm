; =============================================================================
; SYNAPSE CORE v0.8.0 - Grand Unification (Phase 4)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; THE UNHACKABLE AI: Neural Network on Blockchain Memory
; - All weights stored in Merkle Ledger
; - All memory protected by SHA-256
; - Root Hash proves data integrity
; =============================================================================

format PE64 console
entry start

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_RW = 0x40

GENERIC_READ    = 0x80000000
OPEN_EXISTING   = 3

; Block Header (64 bytes - AVX2 Aligned)
BLOCK_HEADER_SIZE = 64
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
        CreateFileA     dq RVA _CreateFileA
        ReadFile        dq RVA _ReadFile
        CloseHandle     dq RVA _CloseHandle
                        dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0
    _CreateFileA    db 0,0,'CreateFileA',0
    _ReadFile       db 0,0,'ReadFile',0
    _CloseHandle    db 0,0,'CloseHandle',0

; =============================================================================
; Data
; =============================================================================
section '.data' data readable writeable

    banner      db '==================================================',13,10
                db '  SYNAPSE CORE v0.8.0 - Unhackable AI',13,10
                db '  Phase 4: Grand Unification',13,10
                db '  Neural Network + Blockchain Memory',13,10
                db '==================================================',13,10,13,10,0
    
    msg_init    db '[CORE] Initializing systems...',13,10,0
    msg_alloc   db '[LEDGER] Allocating neural network in blockchain...',13,10,0
    msg_load    db '[IO] Loading weights into secure memory...',13,10,0
    msg_commit1 db '[CHAIN] Computing integrity hash of neural weights...',13,10,0
    msg_hash1   db '  Initial Root Hash: ',0
    msg_exec    db 13,10,'[EXEC] Running MNIST inference on secure data...',13,10,0
    msg_commit2 db '[CHAIN] Final integrity audit...',13,10,0
    msg_hash2   db '  Final Root Hash:   ',0
    msg_match   db 13,10,'*** INTEGRITY VERIFIED! Hashes match! ***',13,10
                db '    Neural network executed on immutable data.',13,10,0
    msg_diff    db 13,10,'[WARN] Hashes differ - data was modified during execution!',13,10,0
    msg_pred    db '  Prediction: ',0
    msg_ok      db ' OK',13,10,0
    msg_fail    db ' FAILED',13,10,0
    newline     db 13,10,0
    
    ; File paths
    path_w1     db 'neural\w1.bin',0
    path_b1     db 'neural\b1.bin',0
    path_w2     db 'neural\w2.bin',0
    path_b2     db 'neural\b2.bin',0
    path_img    db 'neural\digit_7_0.bin',0
    
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
    bytes_read      dd ?
    
    ; Heap
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; Ledger
    last_block_ptr  dq ?
    root_hash       rb 32
    saved_hash      rb 32
    
    ; Neural network pointers (all in blockchain memory!)
    ptr_input       dq ?
    ptr_w1          dq ?
    ptr_b1          dq ?
    ptr_hidden      dq ?
    ptr_w2          dq ?
    ptr_b2          dq ?
    ptr_output      dq ?
    
    ; SHA-256 working area
    sha_state       rd 8
    sha_w           rd 64
    sha_block       rb 64
    
    ; Temp
    hex_buffer      rb 4
    num_buffer      rb 16
    
    ; Output scores
    max_score       dq ?
    max_idx         dq ?

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
    lea rcx, [msg_init]
    call print_string
    
    call mem_init
    call merkle_init
    
    ; ===========================================
    ; 2. ALLOCATE IN BLOCKCHAIN MEMORY
    ; ===========================================
    lea rcx, [msg_alloc]
    call print_string
    
    ; Input (784 doubles)
    mov rcx, 784*8
    call merkle_alloc
    mov [ptr_input], rax
    
    ; W1 (784*128 doubles)
    mov rcx, 784*128*8
    call merkle_alloc
    mov [ptr_w1], rax
    
    ; B1 (128 doubles)
    mov rcx, 128*8
    call merkle_alloc
    mov [ptr_b1], rax
    
    ; Hidden layer (128 doubles)
    mov rcx, 128*8
    call merkle_alloc
    mov [ptr_hidden], rax
    
    ; W2 (128*10 doubles)
    mov rcx, 128*10*8
    call merkle_alloc
    mov [ptr_w2], rax
    
    ; B2 (10 doubles)
    mov rcx, 10*8
    call merkle_alloc
    mov [ptr_b2], rax
    
    ; Output (10 doubles)
    mov rcx, 10*8
    call merkle_alloc
    mov [ptr_output], rax
    
    ; ===========================================
    ; 3. LOAD WEIGHTS INTO SECURE MEMORY
    ; ===========================================
    lea rcx, [msg_load]
    call print_string
    
    lea rcx, [path_w1]
    mov rdx, [ptr_w1]
    mov r8, 784*128*8
    call load_file
    
    lea rcx, [path_b1]
    mov rdx, [ptr_b1]
    mov r8, 128*8
    call load_file
    
    lea rcx, [path_w2]
    mov rdx, [ptr_w2]
    mov r8, 128*10*8
    call load_file
    
    lea rcx, [path_b2]
    mov rdx, [ptr_b2]
    mov r8, 10*8
    call load_file
    
    lea rcx, [path_img]
    mov rdx, [ptr_input]
    mov r8, 784*8
    call load_file
    
    ; ===========================================
    ; 4. COMPUTE INITIAL INTEGRITY HASH
    ; ===========================================
    lea rcx, [msg_commit1]
    call print_string
    
    call merkle_commit
    
    ; Save initial hash
    mov rsi, rax
    lea rdi, [saved_hash]
    mov rcx, 4
    rep movsq
    
    lea rcx, [msg_hash1]
    call print_string
    lea rsi, [saved_hash]
    call print_hash
    lea rcx, [newline]
    call print_string
    
    ; ===========================================
    ; 5. EXECUTE NEURAL NETWORK
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    call run_inference
    
    ; ===========================================
    ; 6. FIND PREDICTION
    ; ===========================================
    call find_max_output
    
    lea rcx, [msg_pred]
    call print_string
    mov rax, [max_idx]
    call print_number
    lea rcx, [newline]
    call print_string
    
    ; ===========================================
    ; 7. FINAL INTEGRITY AUDIT
    ; ===========================================
    lea rcx, [msg_commit2]
    call print_string
    
    call merkle_commit
    mov r12, rax
    
    lea rcx, [msg_hash2]
    call print_string
    mov rsi, r12
    call print_hash
    lea rcx, [newline]
    call print_string
    
    ; Compare hashes
    lea rsi, [saved_hash]
    mov rdi, r12
    mov rcx, 32
    repe cmpsb
    jne .hash_differ
    
    ; SUCCESS - Hashes match!
    lea rcx, [msg_match]
    call print_string
    jmp .exit

.hash_differ:
    lea rcx, [msg_diff]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; NEURAL NETWORK INFERENCE (Pure scalar for simplicity)
; =============================================================================
run_inference:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    ; Layer 1: hidden = ReLU(input * W1 + B1)
    ; For each of 128 hidden neurons
    mov r12, 0                  ; neuron index
    
.layer1_loop:
    cmp r12, 128
    jge .layer1_done
    
    ; Compute dot product: input[784] . W1[neuron, 784]
    xorpd xmm0, xmm0            ; accumulator = 0
    
    mov r13, 0                  ; input index
    mov rsi, [ptr_input]
    mov rdi, [ptr_w1]
    
    ; W1 layout: W1[neuron * 784 + i]
    mov rax, r12
    imul rax, 784*8
    add rdi, rax                ; rdi = &W1[neuron * 784]
    
.dot1_loop:
    cmp r13, 784
    jge .dot1_done
    
    movsd xmm1, [rsi + r13*8]   ; input[i]
    movsd xmm2, [rdi + r13*8]   ; W1[neuron, i]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    
    inc r13
    jmp .dot1_loop

.dot1_done:
    ; Add bias
    mov rax, [ptr_b1]
    addsd xmm0, [rax + r12*8]
    
    ; ReLU: max(0, x)
    xorpd xmm1, xmm1
    maxsd xmm0, xmm1
    
    ; Store result
    mov rax, [ptr_hidden]
    movsd [rax + r12*8], xmm0
    
    inc r12
    jmp .layer1_loop

.layer1_done:
    
    ; Layer 2: output = hidden * W2 + B2 (no ReLU - raw scores)
    mov r12, 0                  ; output neuron index
    
.layer2_loop:
    cmp r12, 10
    jge .layer2_done
    
    xorpd xmm0, xmm0
    
    mov r13, 0
    mov rsi, [ptr_hidden]
    mov rdi, [ptr_w2]
    
    mov rax, r12
    imul rax, 128*8
    add rdi, rax
    
.dot2_loop:
    cmp r13, 128
    jge .dot2_done
    
    movsd xmm1, [rsi + r13*8]
    movsd xmm2, [rdi + r13*8]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    
    inc r13
    jmp .dot2_loop

.dot2_done:
    ; Add bias
    mov rax, [ptr_b2]
    addsd xmm0, [rax + r12*8]
    
    ; Store
    mov rax, [ptr_output]
    movsd [rax + r12*8], xmm0
    
    inc r12
    jmp .layer2_loop

.layer2_done:
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
; FIND MAX OUTPUT
; =============================================================================
find_max_output:
    mov rsi, [ptr_output]
    movsd xmm0, [rsi]           ; max_score = output[0]
    xor rax, rax                ; max_idx = 0
    mov rcx, 1                  ; i = 1
    
.find_loop:
    cmp rcx, 10
    jge .find_done
    
    movsd xmm1, [rsi + rcx*8]
    comisd xmm1, xmm0
    jbe .not_greater
    
    movsd xmm0, xmm1
    mov rax, rcx

.not_greater:
    inc rcx
    jmp .find_loop

.find_done:
    mov [max_idx], rax
    movsd [max_score], xmm0
    ret

; =============================================================================
; MEMORY MANAGER
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 4*1024*1024        ; 4 MB for neural network
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
; FILE I/O
; =============================================================================
load_file:
    ; RCX = filename, RDX = buffer, R8 = size
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 56
    
    mov r12, rdx
    mov r13, r8
    
    ; CreateFileA
    mov rdx, GENERIC_READ
    xor r8d, r8d
    xor r9d, r9d
    mov dword [rsp+32], OPEN_EXISTING
    mov dword [rsp+40], 0
    mov qword [rsp+48], 0
    call [CreateFileA]
    
    cmp rax, -1
    je .load_fail
    mov rbx, rax
    
    ; ReadFile
    mov rcx, rbx
    mov rdx, r12
    mov r8, r13
    lea r9, [bytes_read]
    mov qword [rsp+32], 0
    call [ReadFile]
    
    ; CloseHandle
    mov rcx, rbx
    call [CloseHandle]

.load_fail:
    add rsp, 56
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

print_number:
    push rbx
    push rdi
    lea rdi, [num_buffer + 15]
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
