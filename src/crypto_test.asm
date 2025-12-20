; =============================================================================
; SYNAPSE SHA-256 Crypto Core Test - Phase 3.1
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Pure x64 Assembly SHA-256 implementation
; No external crypto libraries!
;
; Test: SHA256("abc") = ba7816bf8f01cfea414140de5dae2223...
; =============================================================================

format PE64 console
entry start

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
                        dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0

; =============================================================================
; Data
; =============================================================================
section '.data' data readable writeable

    banner      db '================================================',13,10
                db '  SYNAPSE Crypto Core - SHA-256 Test',13,10
                db '  Phase 3.1: Blockchain Foundation',13,10
                db '================================================',13,10,13,10,0
    
    msg_input   db '[TEST] Input: "abc" (3 bytes)',13,10,0
    msg_hash    db '[HASH] Computing SHA-256...',13,10,0
    msg_result  db '[RESULT] ',0
    msg_expect  db 13,10,'[EXPECT] ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',13,10,0
    msg_success db 13,10,'*** SUCCESS! SHA-256 verified! ***',13,10,0
    msg_fail    db 13,10,'[FAIL] Hash mismatch!',13,10,0
    newline     db 13,10,0
    
    ; Test input
    test_abc    db 'abc'
    
    ; Expected hash (first and last bytes for quick check)
    expect_first db 0xBA
    expect_last  db 0xAD
    
    ; Hex chars
    hex_chars   db '0123456789abcdef'

    ; SHA-256 K constants (first 32 bits of fractional parts of cube roots of first 64 primes)
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

    ; SHA-256 Initial Hash Values
    h_init  dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
            dd 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    
    ; Hash output (32 bytes)
    hash_output     rb 32
    
    ; Working state (8 dwords = 32 bytes)
    state           rd 8
    
    ; Message schedule W (64 dwords = 256 bytes)
    w_schedule      rd 64
    
    ; Padded block (64 bytes)
    block_buffer    rb 64
    
    ; Temp for hex printing
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
    
    lea rcx, [msg_input]
    call print_string
    
    lea rcx, [msg_hash]
    call print_string
    
    ; Compute SHA-256("abc")
    lea rcx, [test_abc]
    mov rdx, 3
    lea r8, [hash_output]
    call sha256_compute
    
    ; Print result
    lea rcx, [msg_result]
    call print_string
    
    ; Print hash as hex
    lea rsi, [hash_output]
    mov ecx, 32
.print_hash:
    push rcx
    movzx eax, byte [rsi]
    call print_hex_byte
    inc rsi
    pop rcx
    dec ecx
    jnz .print_hash
    
    ; Print expected
    lea rcx, [msg_expect]
    call print_string
    
    ; Verify first byte = 0xBA
    mov al, [hash_output]
    cmp al, 0xBA
    jne .fail
    
    ; Verify last byte = 0xAD
    mov al, [hash_output + 31]
    cmp al, 0xAD
    jne .fail
    
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
; sha256_compute: Full SHA-256 hash computation
; RCX = input_ptr, RDX = size, R8 = output_ptr (32 bytes)
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
    
    mov [rsp+40], rcx       ; input
    mov [rsp+48], rdx       ; size
    mov r14, r8             ; output
    
    ; Initialize state from h_init
    lea rsi, [h_init]
    lea rdi, [state]
    mov ecx, 8
.init_state:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .init_state
    
    ; Prepare padded message
    ; For "abc" (3 bytes), we need:
    ; 3 bytes data + 0x80 + zeros + 8 bytes length = 64 bytes
    
    ; Clear block buffer
    lea rdi, [block_buffer]
    xor eax, eax
    mov ecx, 16
    rep stosd
    
    ; Copy input to block
    mov rsi, [rsp+40]
    lea rdi, [block_buffer]
    mov rcx, [rsp+48]
    rep movsb
    
    ; Add 0x80 padding byte
    mov rax, [rsp+48]
    mov byte [block_buffer + rax], 0x80
    
    ; Add length in bits at the end (big endian)
    mov rax, [rsp+48]
    shl rax, 3              ; bits = bytes * 8
    bswap rax
    mov qword [block_buffer + 56], rax
    
    ; Process the block
    call sha256_process_block
    
    ; Output state as hash (convert to big endian)
    lea rsi, [state]
    mov rdi, r14
    mov ecx, 8
.output:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .output
    
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

; =============================================================================
; sha256_process_block: Process one 64-byte block
; =============================================================================
sha256_process_block:
    push rbx
    push rsi
    push rdi
    push rbp
    push r12
    push r13
    push r14
    push r15
    
    ; 1. Prepare message schedule W[0..63]
    ; W[0..15] = block words (big endian)
    lea rsi, [block_buffer]
    lea rdi, [w_schedule]
    mov ecx, 16
.load_w:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .load_w
    
    ; W[16..63] = expanded
    ; s0 = (w[i-15] rotr 7) ^ (w[i-15] rotr 18) ^ (w[i-15] shr 3)
    ; s1 = (w[i-2] rotr 17) ^ (w[i-2] rotr 19) ^ (w[i-2] shr 10)
    ; w[i] = w[i-16] + s0 + w[i-7] + s1
    
    lea rdi, [w_schedule]
    mov ebx, 16
.expand:
    ; s0 from w[i-15]
    mov eax, [rdi + rbx*4 - 60]
    mov edx, eax
    ror edx, 7
    mov r8d, eax
    ror r8d, 18
    xor edx, r8d
    mov r8d, eax
    shr r8d, 3
    xor edx, r8d            ; edx = s0
    
    ; s1 from w[i-2]
    mov eax, [rdi + rbx*4 - 8]
    mov r9d, eax
    ror r9d, 17
    mov r8d, eax
    ror r8d, 19
    xor r9d, r8d
    mov r8d, eax
    shr r8d, 10
    xor r9d, r8d            ; r9d = s1
    
    ; w[i] = w[i-16] + s0 + w[i-7] + s1
    mov eax, [rdi + rbx*4 - 64]
    add eax, edx
    add eax, [rdi + rbx*4 - 28]
    add eax, r9d
    mov [rdi + rbx*4], eax
    
    inc ebx
    cmp ebx, 64
    jl .expand
    
    ; 2. Initialize working variables
    lea rsi, [state]
    mov eax, [rsi]          ; a
    mov ebx, [rsi+4]        ; b
    mov ecx, [rsi+8]        ; c
    mov edx, [rsi+12]       ; d
    mov r8d, [rsi+16]       ; e
    mov r9d, [rsi+20]       ; f
    mov r10d, [rsi+24]      ; g
    mov r11d, [rsi+28]      ; h
    
    ; 3. Compression loop (64 rounds)
    lea rbp, [k_table]
    lea rdi, [w_schedule]
    xor rsi, rsi            ; round counter
    
.round:
    ; T1 = h + Sigma1(e) + Ch(e,f,g) + K[i] + W[i]
    
    ; Sigma1(e) = (e rotr 6) ^ (e rotr 11) ^ (e rotr 25)
    mov r12d, r8d
    ror r12d, 6
    mov r13d, r8d
    ror r13d, 11
    xor r12d, r13d
    mov r13d, r8d
    ror r13d, 25
    xor r12d, r13d          ; r12d = Sigma1
    
    ; Ch(e,f,g) = (e & f) ^ (~e & g)
    mov r13d, r8d
    and r13d, r9d
    mov r14d, r8d
    not r14d
    and r14d, r10d
    xor r13d, r14d          ; r13d = Ch
    
    ; T1
    add r12d, r13d
    add r12d, r11d
    add r12d, [rbp + rsi*4]
    add r12d, [rdi + rsi*4] ; r12d = T1
    
    ; T2 = Sigma0(a) + Maj(a,b,c)
    
    ; Sigma0(a) = (a rotr 2) ^ (a rotr 13) ^ (a rotr 22)
    mov r13d, eax
    ror r13d, 2
    mov r14d, eax
    ror r14d, 13
    xor r13d, r14d
    mov r14d, eax
    ror r14d, 22
    xor r13d, r14d          ; r13d = Sigma0
    
    ; Maj(a,b,c) = (a & b) ^ (a & c) ^ (b & c)
    mov r14d, eax
    and r14d, ebx
    mov r15d, eax
    and r15d, ecx
    xor r14d, r15d
    mov r15d, ebx
    and r15d, ecx
    xor r14d, r15d          ; r14d = Maj
    
    add r13d, r14d          ; r13d = T2
    
    ; Update working variables
    mov r11d, r10d          ; h = g
    mov r10d, r9d           ; g = f
    mov r9d, r8d            ; f = e
    mov r8d, edx
    add r8d, r12d           ; e = d + T1
    mov edx, ecx            ; d = c
    mov ecx, ebx            ; c = b
    mov ebx, eax            ; b = a
    mov eax, r12d
    add eax, r13d           ; a = T1 + T2
    
    inc rsi
    cmp rsi, 64
    jl .round
    
    ; 4. Add to state
    lea rsi, [state]
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

print_hex_byte:
    push rbx
    push rdi
    
    mov ebx, eax
    
    ; High nibble
    shr eax, 4
    and eax, 0xF
    lea rdi, [hex_chars]
    mov al, [rdi + rax]
    mov [hex_buffer], al
    
    ; Low nibble
    mov eax, ebx
    and eax, 0xF
    mov al, [rdi + rax]
    mov [hex_buffer + 1], al
    
    mov byte [hex_buffer + 2], 0
    
    lea rcx, [hex_buffer]
    call print_string
    
    pop rdi
    pop rbx
    ret
