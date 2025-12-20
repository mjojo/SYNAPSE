; =============================================================================
; SYNAPSE AVX2 Tensor Test - Phase 2.2
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Test: tensor<f32, [8]> addition using AVX2
; a = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
; b = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
; c = a <+> b  → should be [3.0, 3.0, ...]
; return c[0]  → should be 3.0
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
                db '  SYNAPSE AVX2 Tensor Test - Phase 2.2',13,10
                db '================================================',13,10,13,10,0
    
    msg_tier    db '[CPU] Checking tier...',13,10,0
    msg_tier_ok db '[CPU] Tier 2+ detected, using AVX2!',13,10,0
    msg_tier_sse db '[CPU] Tier 1 - fallback to SSE',13,10,0
    
    msg_alloc   db '[MEM] Allocating aligned tensor memory (32-byte)...',13,10,0
    msg_alloc_ok db '[MEM] Tensors allocated successfully',13,10,0
    
    msg_init    db '[INIT] Setting tensor values...',13,10,0
    msg_init_a  db '  tensor A = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]',13,10,0
    msg_init_b  db '  tensor B = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]',13,10,0
    
    msg_jit     db '[JIT] Generating AVX2 VADDPS code...',13,10,0
    msg_exec    db '[EXEC] Running JIT-compiled tensor add...',13,10,0
    
    msg_result  db 13,10,'[RESULT] C[0] = ',0
    msg_expect  db ' (expected: 3.0)',13,10,0
    
    msg_success db 13,10,'*** SUCCESS! AVX2 tensor addition works! ***',13,10,0
    msg_fail    db 13,10,'[FAILED] Result != 3.0',13,10,0
    
    newline     db 13,10,0

    ; CPU tier storage
    cpu_tier_val    dd 0
    
    ; Float constants
    float_one   dd 1.0
    float_two   dd 2.0
    float_three dd 3.0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32
    float_buffer    rb 32
    
    ; Heap for aligned allocations
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; Tensor pointers (aligned to 32 bytes)
    tensor_a        dq ?
    tensor_b        dq ?
    tensor_c        dq ?
    
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
    ; STEP 1: Detect CPU tier
    ; ===========================================
    lea rcx, [msg_tier]
    call print_string
    
    call detect_cpu_tier
    
    cmp dword [cpu_tier_val], 2
    jge .tier_ok
    
    lea rcx, [msg_tier_sse]
    call print_string
    jmp .use_sse
    
.tier_ok:
    lea rcx, [msg_tier_ok]
    call print_string

.use_avx:
    ; ===========================================
    ; STEP 2: Allocate aligned memory
    ; ===========================================
    lea rcx, [msg_alloc]
    call print_string
    
    call mem_init
    test rax, rax
    jz .failed
    
    ; Allocate tensor A (8 floats = 32 bytes, aligned to 32)
    mov rcx, 32         ; size
    mov rdx, 32         ; alignment
    call mem_alloc_aligned
    mov [tensor_a], rax
    
    ; Allocate tensor B
    mov rcx, 32
    mov rdx, 32
    call mem_alloc_aligned
    mov [tensor_b], rax
    
    ; Allocate tensor C (result)
    mov rcx, 32
    mov rdx, 32
    call mem_alloc_aligned
    mov [tensor_c], rax
    
    lea rcx, [msg_alloc_ok]
    call print_string
    
    ; ===========================================
    ; STEP 3: Initialize tensors
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
    
    ; Fill tensor B with 2.0
    mov rdi, [tensor_b]
    mov eax, [float_two]
    mov ecx, 8
.fill_b:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_b
    
    ; ===========================================
    ; STEP 4: Generate JIT code for AVX2 add
    ; ===========================================
    lea rcx, [msg_jit]
    call print_string
    
    call jit_init
    test rax, rax
    jz .failed
    
    ; Generate AVX2 tensor add function
    ; Function signature: void tensor_add(float* a, float* b, float* c)
    ; Uses: RCX = a, RDX = b, R8 = c
    call emit_avx2_tensor_add
    
    ; ===========================================
    ; STEP 5: Execute JIT code
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    ; Call generated code
    mov rcx, [tensor_a]     ; First arg: tensor A
    mov rdx, [tensor_b]     ; Second arg: tensor B
    mov r8, [tensor_c]      ; Third arg: result C
    
    mov rax, [jit_buffer]
    call rax                ; Execute!
    
    ; ===========================================
    ; STEP 6: Check result
    ; ===========================================
    lea rcx, [msg_result]
    call print_string
    
    ; Load first element of C
    mov rdi, [tensor_c]
    movss xmm0, [rdi]       ; Load C[0]
    
    ; Print the float
    call print_float
    
    lea rcx, [msg_expect]
    call print_string
    
    ; Compare with 3.0
    mov rdi, [tensor_c]
    mov eax, [rdi]
    cmp eax, [float_three]
    jne .failed
    
    lea rcx, [msg_success]
    call print_string
    jmp .exit

.use_sse:
    ; SSE fallback path (simplified - just use scalar for now)
    jmp .exit

.failed:
    lea rcx, [msg_fail]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; CPU Detection (simplified from cpu_test.asm)
; =============================================================================
detect_cpu_tier:
    push rbx
    push rcx
    push rdx

    mov dword [cpu_tier_val], 1

    ; Check CPUID EAX=1
    mov eax, 1
    cpuid
    
    ; Check AVX (ECX bit 28)
    bt ecx, 28
    jnc .done
    
    ; Check OSXSAVE (ECX bit 27)
    bt ecx, 27
    jnc .done
    
    ; Check XCR0
    xor ecx, ecx
    xgetbv
    and eax, 0x6
    cmp eax, 0x6
    jne .done
    
    ; Check AVX2 (CPUID EAX=7, EBX bit 5)
    mov eax, 7
    xor ecx, ecx
    cpuid
    bt ebx, 5
    jnc .done
    
    mov dword [cpu_tier_val], 2
    
    ; Check AVX-512 (EBX bit 16)
    bt ebx, 16
    jnc .done
    mov dword [cpu_tier_val], 3
    
.done:
    pop rdx
    pop rcx
    pop rbx
    mov eax, [cpu_tier_val]
    ret

; =============================================================================
; Memory Manager
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 1024*1024      ; 1 MB
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

; mem_alloc_aligned(size, alignment) -> RAX
; RCX = size, RDX = alignment
mem_alloc_aligned:
    mov rax, [heap_ptr]
    
    ; Align: (ptr + align - 1) & ~(align - 1)
    dec rdx
    add rax, rdx
    not rdx
    and rax, rdx
    
    ; Update heap pointer
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
    mov edx, 4096           ; 4 KB
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

; Emit AVX2 tensor add function
; Generates: void tensor_add(rcx=a, rdx=b, r8=c)
emit_avx2_tensor_add:
    push rdi
    
    mov rdi, [jit_cursor]
    
    ; =========================================
    ; PROLOGUE (minimal, no stack frame needed)
    ; =========================================
    
    ; =========================================
    ; VMOVAPS ymm0, [rcx]  - Load 8 floats from A
    ; VEX.256.0F.WIG 28 /r
    ; C5 FC 28 01
    ; =========================================
    mov byte [rdi + 0], 0xC5    ; VEX 2-byte prefix
    mov byte [rdi + 1], 0xFC    ; R=1, X=1, B=1, m-mmmm=01, W=0, vvvv=1111, L=1, pp=00
    mov byte [rdi + 2], 0x28    ; Opcode MOVAPS
    mov byte [rdi + 3], 0x01    ; ModR/M: [rcx] -> ymm0
    add rdi, 4
    
    ; =========================================
    ; VMOVAPS ymm1, [rdx]  - Load 8 floats from B
    ; C5 FC 28 0A
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC
    mov byte [rdi + 2], 0x28
    mov byte [rdi + 3], 0x0A    ; ModR/M: [rdx] -> ymm1
    add rdi, 4
    
    ; =========================================
    ; VADDPS ymm0, ymm0, ymm1  - Add vectors
    ; VEX.256.0F.WIG 58 /r
    ; C5 FC 58 C1
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC    ; vvvv=0000 (ymm0 as first src)
    mov byte [rdi + 2], 0x58    ; Opcode ADDPS
    mov byte [rdi + 3], 0xC1    ; ModR/M: ymm1 -> ymm0
    add rdi, 4
    
    ; =========================================
    ; VMOVAPS [r8], ymm0  - Store result to C
    ; Need to use REX prefix because r8 is extended reg
    ; C4 C1 7C 29 00
    ; =========================================
    mov byte [rdi + 0], 0xC4    ; VEX 3-byte prefix
    mov byte [rdi + 1], 0xC1    ; R=1, X=1, B=0 (r8), m-mmmm=01
    mov byte [rdi + 2], 0x7C    ; W=0, vvvv=1111, L=1, pp=00
    mov byte [rdi + 3], 0x29    ; Opcode MOVAPS (store form)
    mov byte [rdi + 4], 0x00    ; ModR/M: ymm0 -> [r8]
    add rdi, 5
    
    ; =========================================
    ; VZEROUPPER - Clean YMM state (required!)
    ; C5 F8 77
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xF8
    mov byte [rdi + 2], 0x77
    add rdi, 3
    
    ; =========================================
    ; RET
    ; =========================================
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
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

print_float:
    ; Simple float print (just show integer part for now)
    ; XMM0 contains the float
    cvttss2si eax, xmm0     ; Convert to integer
    push rax
    
    lea rdi, [float_buffer + 10]
    mov byte [rdi], 0
    dec rdi
    
    ; Add ".0" suffix
    mov byte [rdi], '0'
    dec rdi
    mov byte [rdi], '.'
    dec rdi
    
    pop rax
    mov rbx, 10
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
    ret
