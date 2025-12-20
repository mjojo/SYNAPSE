; =============================================================================
; SYNAPSE AVX2 Dot Product Test - Phase 2.3
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Test: a <dot> b (Scalar Dot Product)
; a = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
; b = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
; result = sum(a[i] * b[i]) = 1.0 * 0.5 * 8 = 4.0
; =============================================================================

format PE64 console
entry start

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_READWRITE = 0x40

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
                db '  SYNAPSE Dot Product Test - Phase 2.3',13,10
                db '  The Heart of Neural Networks!',13,10
                db '================================================',13,10,13,10,0
    
    msg_alloc   db '[MEM] Allocating aligned tensors...',13,10,0
    msg_init    db '[INIT] Setting tensor values:',13,10,0
    msg_init_a  db '  A = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]',13,10,0
    msg_init_b  db '  B = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]',13,10,0
    
    msg_jit     db '[JIT] Generating AVX2 DOT PRODUCT code...',13,10,0
    msg_jit_det db '  - VMULPS (vertical multiply)',13,10
                db '  - VEXTRACTF128 (split 256->128)',13,10
                db '  - VADDPS (combine halves)',13,10
                db '  - VHADDPS x2 (horizontal sum)',13,10,0
    
    msg_exec    db '[EXEC] Running JIT dot product...',13,10,0
    
    msg_result  db 13,10,'[RESULT] a <dot> b = ',0
    msg_hex     db ' (hex: 0x',0
    msg_close   db ')',13,10,0
    msg_expect  db '[EXPECT] 1.0 * 0.5 * 8 = 4.0 (hex: 0x40800000)',13,10,0
    
    msg_success db 13,10,'*** SUCCESS! DOT PRODUCT WORKS! ***',13,10
                db '    SYNAPSE can now run Neural Networks!',13,10,0
    msg_fail    db 13,10,'[FAILED] Result != 4.0',13,10,0
    
    newline     db 13,10,0

    ; Float constants
    float_one   dd 0x3F800000   ; 1.0
    float_half  dd 0x3F000000   ; 0.5
    float_four  dd 0x40800000   ; 4.0 (expected result)

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    hex_buffer      rb 16
    
    ; Heap
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; Tensor pointers
    tensor_a        dq ?
    tensor_b        dq ?
    result_ptr      dq ?
    
    ; JIT buffer
    jit_buffer      dq ?
    jit_cursor      dq ?

; =============================================================================
; Code
; =============================================================================
section '.text' code readable executable

start:
    sub rsp, 40
    
    ; Get stdout
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    ; Banner
    lea rcx, [banner]
    call print_string
    
    ; ===========================================
    ; STEP 1: Allocate aligned memory
    ; ===========================================
    lea rcx, [msg_alloc]
    call print_string
    
    call mem_init
    test rax, rax
    jz .failed
    
    ; Allocate tensor A (8 floats = 32 bytes, aligned to 32)
    mov rcx, 32
    mov rdx, 32
    call mem_alloc_aligned
    mov [tensor_a], rax
    
    ; Allocate tensor B
    mov rcx, 32
    mov rdx, 32
    call mem_alloc_aligned
    mov [tensor_b], rax
    
    ; Allocate result (1 float, aligned to 4)
    mov rcx, 4
    mov rdx, 4
    call mem_alloc_aligned
    mov [result_ptr], rax
    
    ; ===========================================
    ; STEP 2: Initialize tensors
    ; ===========================================
    lea rcx, [msg_init]
    call print_string
    lea rcx, [msg_init_a]
    call print_string
    lea rcx, [msg_init_b]
    call print_string
    
    ; Fill tensor A with 1.0
    mov rdi, [tensor_a]
    mov eax, [float_one]
    mov ecx, 8
.fill_a:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_a
    
    ; Fill tensor B with 0.5
    mov rdi, [tensor_b]
    mov eax, [float_half]
    mov ecx, 8
.fill_b:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_b
    
    ; Clear result
    mov rdi, [result_ptr]
    mov dword [rdi], 0
    
    ; ===========================================
    ; STEP 3: Generate JIT code for DOT PRODUCT
    ; ===========================================
    lea rcx, [msg_jit]
    call print_string
    lea rcx, [msg_jit_det]
    call print_string
    
    call jit_init
    test rax, rax
    jz .failed
    
    call emit_avx2_dot
    
    ; ===========================================
    ; STEP 4: Execute JIT code
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    ; Setup arguments for JIT function
    ; Our function uses: RCX = A ptr, RDX = B ptr, R8 = result ptr
    mov rcx, [tensor_a]
    mov rdx, [tensor_b]
    mov r8, [result_ptr]
    
    ; Call JIT code!
    mov rax, [jit_buffer]
    call rax
    
    ; ===========================================
    ; STEP 5: Display result
    ; ===========================================
    lea rcx, [msg_result]
    call print_string
    
    ; Load result float
    mov rdi, [result_ptr]
    mov eax, [rdi]
    push rax            ; Save for comparison
    
    ; Print as float (integer part)
    movd xmm0, eax
    cvttss2si eax, xmm0
    call print_num
    
    ; Print ".0"
    mov byte [num_buffer], '.'
    mov byte [num_buffer+1], '0'
    mov byte [num_buffer+2], 0
    lea rcx, [num_buffer]
    call print_string
    
    ; Print hex
    lea rcx, [msg_hex]
    call print_string
    
    pop rax
    push rax
    call print_hex
    
    lea rcx, [msg_close]
    call print_string
    
    lea rcx, [msg_expect]
    call print_string
    
    ; ===========================================
    ; STEP 6: Verify result
    ; ===========================================
    pop rax
    cmp eax, [float_four]
    jne .failed
    
    lea rcx, [msg_success]
    call print_string
    jmp .exit

.failed:
    lea rcx, [msg_fail]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; Memory Manager
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 1024*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call [VirtualAlloc]
    add rsp, 40
    
    test rax, rax
    jz .fail
    
    mov [heap_base], rax
    mov [heap_ptr], rax
    ret

.fail:
    xor rax, rax
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
; JIT Code Generator
; =============================================================================
jit_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 4096
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_READWRITE
    call [VirtualAlloc]
    add rsp, 40
    
    test rax, rax
    jz .fail
    
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    ret

.fail:
    xor rax, rax
    ret

; =============================================================================
; emit_avx2_dot: Generate AVX2 Dot Product
; Function signature: void dot(rcx=A, rdx=B, r8=result)
; =============================================================================
emit_avx2_dot:
    push rdi
    push rbx
    
    mov rdi, [jit_cursor]
    
    ; =========================================
    ; 1. VMOVAPS ymm0, [rcx]  - Load A
    ; VEX.256.0F.WIG 28 /r
    ; C5 FC 28 01
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC
    mov byte [rdi + 2], 0x28
    mov byte [rdi + 3], 0x01    ; [rcx]
    add rdi, 4
    
    ; =========================================
    ; 2. VMOVAPS ymm1, [rdx]  - Load B
    ; C5 FC 28 0A
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC
    mov byte [rdi + 2], 0x28
    mov byte [rdi + 3], 0x0A    ; [rdx]
    add rdi, 4
    
    ; =========================================
    ; 3. VMULPS ymm0, ymm0, ymm1  - Vertical multiply
    ; C5 FC 59 C1
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC    ; vvvv=0000 (ymm0)
    mov byte [rdi + 2], 0x59    ; MULPS
    mov byte [rdi + 3], 0xC1    ; ymm0, ymm1
    add rdi, 4
    
    ; =========================================
    ; HORIZONTAL SUM BEGINS
    ; =========================================
    
    ; =========================================
    ; 4. VEXTRACTF128 xmm1, ymm0, 1
    ; Extract high 128 bits of ymm0 to xmm1
    ; C4 E3 7D 19 C1 01
    ; =========================================
    mov byte [rdi + 0], 0xC4    ; VEX 3-byte
    mov byte [rdi + 1], 0xE3    ; R=1,X=1,B=1, m-mmmm=00011
    mov byte [rdi + 2], 0x7D    ; W=0,vvvv=1111,L=1,pp=01
    mov byte [rdi + 3], 0x19    ; opcode
    mov byte [rdi + 4], 0xC1    ; ymm0 -> xmm1
    mov byte [rdi + 5], 0x01    ; imm8 = 1 (upper half)
    add rdi, 6
    
    ; =========================================
    ; 5. VADDPS xmm0, xmm0, xmm1
    ; Combine: xmm0 = [a0+a4, a1+a5, a2+a6, a3+a7]
    ; C5 F8 58 C1
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xF8    ; VEX.128, vvvv=0000
    mov byte [rdi + 2], 0x58    ; ADDPS
    mov byte [rdi + 3], 0xC1    ; xmm0 + xmm1 -> xmm0
    add rdi, 4
    
    ; =========================================
    ; 6. VHADDPS xmm0, xmm0, xmm0
    ; Horizontal add: [x0+x1, x2+x3, x0+x1, x2+x3]
    ; VEX.128.F2.0F.WIG 7C /r
    ; C5 FB 7C C0
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFB    ; VEX.128.F2 (pp=11)
    mov byte [rdi + 2], 0x7C    ; HADDPS
    mov byte [rdi + 3], 0xC0    ; xmm0, xmm0
    add rdi, 4
    
    ; =========================================
    ; 7. VHADDPS xmm0, xmm0, xmm0
    ; Final horizontal: [sum, sum, sum, sum]
    ; C5 FB 7C C0
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFB    ; VEX.128.F2 (pp=11)
    mov byte [rdi + 2], 0x7C
    mov byte [rdi + 3], 0xC0
    add rdi, 4
    
    ; =========================================
    ; 8. VMOVSS [r8], xmm0  - Store scalar result
    ; Need REX for r8
    ; C4 C1 7A 11 00
    ; =========================================
    mov byte [rdi + 0], 0xC4    ; VEX 3-byte
    mov byte [rdi + 1], 0xC1    ; R=1,X=1,B=0 (r8)
    mov byte [rdi + 2], 0x7A    ; W=0,vvvv=1111,L=0,pp=10 (F3)
    mov byte [rdi + 3], 0x11    ; MOVSS store
    mov byte [rdi + 4], 0x00    ; [r8]
    add rdi, 5
    
    ; =========================================
    ; 9. VZEROUPPER
    ; C5 F8 77
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xF8
    mov byte [rdi + 2], 0x77
    add rdi, 3
    
    ; =========================================
    ; 10. RET
    ; =========================================
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    pop rbx
    pop rdi
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
    je .print
    inc ecx
    jmp .len
.print:
    test ecx, ecx
    jz .done
    sub rsp, 48
    mov rdx, rsi
    mov r8d, ecx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call [WriteConsoleA]
    add rsp, 48
.done:
    pop rsi
    ret

print_num:
    push rbx
    push rdi
    lea rdi, [num_buffer + 20]
    mov byte [rdi], 0
    dec rdi
    test eax, eax
    jnz .conv
    mov byte [rdi], '0'
    dec rdi
    jmp .print
.conv:
    mov ebx, 10
.loop:
    test eax, eax
    jz .print
    xor edx, edx
    div ebx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    jmp .loop
.print:
    inc rdi
    mov rcx, rdi
    call print_string
    pop rdi
    pop rbx
    ret

print_hex:
    push rbx
    push rdi
    
    lea rdi, [hex_buffer + 8]
    mov byte [rdi], 0
    dec rdi
    
    mov ecx, 8
.loop:
    mov ebx, eax
    and ebx, 0xF
    cmp ebx, 10
    jl .digit
    add ebx, 'A' - 10
    jmp .store
.digit:
    add ebx, '0'
.store:
    mov [rdi], bl
    shr eax, 4
    dec rdi
    dec ecx
    jnz .loop
    
    inc rdi
    mov rcx, rdi
    call print_string
    
    pop rdi
    pop rbx
    ret
