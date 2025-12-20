; =============================================================================
; SYNAPSE Neural Layer Test - Phase 2.4
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Test: MATMUL + ReLU (4 neurons, 8 inputs each)
; Input: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
; Weights:
;   Row 0: [0.5, ...] -> Dot = 4.0  -> ReLU = 4.0
;   Row 1: [1.0, ...] -> Dot = 8.0  -> ReLU = 8.0
;   Row 2: [-1.0,...] -> Dot = -8.0 -> ReLU = 0.0 (!)
;   Row 3: [2.0, ...] -> Dot = 16.0 -> ReLU = 16.0
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
                db '  SYNAPSE Neural Layer Test - Phase 2.4',13,10
                db '  MATMUL + ReLU Activation',13,10
                db '================================================',13,10,13,10,0
    
    msg_alloc   db '[MEM] Allocating layer data...',13,10,0
    msg_init    db '[INIT] Setting up 4-neuron layer:',13,10,0
    msg_row0    db '  Neuron 0: weights=[0.5...] -> expect 4.0',13,10,0
    msg_row1    db '  Neuron 1: weights=[1.0...] -> expect 8.0',13,10,0
    msg_row2    db '  Neuron 2: weights=[-1.0..] -> expect 0.0 (ReLU!)',13,10,0
    msg_row3    db '  Neuron 3: weights=[2.0...] -> expect 16.0',13,10,0
    
    msg_jit     db 13,10,'[JIT] Generating MATMUL loop with ReLU...',13,10,0
    msg_exec    db '[EXEC] Running neural layer...',13,10,0
    
    msg_check   db 13,10,'[RESULT] Checking outputs:',13,10,0
    msg_n0_ok   db '  Neuron 0: 4.0  [OK]',13,10,0
    msg_n1_ok   db '  Neuron 1: 8.0  [OK]',13,10,0
    msg_n2_ok   db '  Neuron 2: 0.0  [OK] (ReLU worked!)',13,10,0
    msg_n3_ok   db '  Neuron 3: 16.0 [OK]',13,10,0
    
    msg_success db 13,10,'*** SUCCESS! NEURAL LAYER WORKS! ***',13,10
                db '    SYNAPSE is ready for MNIST!',13,10,0
    msg_fail    db 13,10,'[FAILED]',13,10,0
    
    newline     db 13,10,0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    
    ; Heap
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; Layer data
    ptr_input       dq ?    ; 8 floats
    ptr_weights     dq ?    ; 4 rows x 8 floats = 32 floats
    ptr_output      dq ?    ; 4 floats
    
    ; JIT
    jit_buffer      dq ?
    jit_cursor      dq ?
    loop_start_addr dq ?

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
    ; STEP 1: Allocate memory
    ; ===========================================
    lea rcx, [msg_alloc]
    call print_string
    
    call mem_init
    test rax, rax
    jz .failed
    
    ; Input: 8 floats = 32 bytes
    mov rcx, 32
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_input], rax
    
    ; Weights: 4 rows x 8 floats = 128 bytes
    mov rcx, 128
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_weights], rax
    
    ; Output: 4 floats = 16 bytes
    mov rcx, 16
    mov rdx, 16
    call mem_alloc_aligned
    mov [ptr_output], rax
    
    ; ===========================================
    ; STEP 2: Initialize data
    ; ===========================================
    lea rcx, [msg_init]
    call print_string
    lea rcx, [msg_row0]
    call print_string
    lea rcx, [msg_row1]
    call print_string
    lea rcx, [msg_row2]
    call print_string
    lea rcx, [msg_row3]
    call print_string
    
    ; Fill input with 1.0
    mov rdi, [ptr_input]
    mov eax, 0x3F800000     ; 1.0
    mov ecx, 8
.fill_input:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_input
    
    ; Fill weights
    mov rdi, [ptr_weights]
    
    ; Row 0: 0.5 (8 times)
    mov eax, 0x3F000000     ; 0.5
    mov ecx, 8
.fill_r0:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_r0
    
    ; Row 1: 1.0 (8 times)
    mov eax, 0x3F800000     ; 1.0
    mov ecx, 8
.fill_r1:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_r1
    
    ; Row 2: -1.0 (8 times) - ReLU TEST!
    mov eax, 0xBF800000     ; -1.0
    mov ecx, 8
.fill_r2:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_r2
    
    ; Row 3: 2.0 (8 times)
    mov eax, 0x40000000     ; 2.0
    mov ecx, 8
.fill_r3:
    mov [rdi], eax
    add rdi, 4
    dec ecx
    jnz .fill_r3
    
    ; Clear output
    mov rdi, [ptr_output]
    xor eax, eax
    mov [rdi], rax
    mov [rdi+8], rax
    
    ; ===========================================
    ; STEP 3: Generate JIT code
    ; ===========================================
    lea rcx, [msg_jit]
    call print_string
    
    call jit_init
    test rax, rax
    jz .failed
    
    ; Generate the neural layer function
    ; Function: layer(rax=input, rbx=weights, rcx=output, r8=count)
    call emit_neural_layer
    
    ; ===========================================
    ; STEP 4: Execute
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    ; Setup registers for call
    mov rax, [ptr_input]
    mov rbx, [ptr_weights]
    mov rcx, [ptr_output]
    mov r8, 4               ; 4 neurons
    
    ; Call JIT!
    push rbx
    mov rdx, [jit_buffer]
    call rdx
    pop rbx
    
    ; ===========================================
    ; STEP 5: Verify results
    ; ===========================================
    lea rcx, [msg_check]
    call print_string
    
    mov rsi, [ptr_output]
    
    ; Neuron 0: expect 4.0 (0x40800000)
    mov eax, [rsi]
    cmp eax, 0x40800000
    jne .failed
    lea rcx, [msg_n0_ok]
    call print_string
    
    ; Neuron 1: expect 8.0 (0x41000000)
    mov eax, [rsi+4]
    cmp eax, 0x41000000
    jne .failed
    lea rcx, [msg_n1_ok]
    call print_string
    
    ; Neuron 2: expect 0.0 (ReLU converted -8.0 to 0.0)
    mov eax, [rsi+8]
    test eax, eax           ; 0.0 = all zeros
    jnz .failed
    lea rcx, [msg_n2_ok]
    call print_string
    
    ; Neuron 3: expect 16.0 (0x41800000)
    mov eax, [rsi+12]
    cmp eax, 0x41800000
    jne .failed
    lea rcx, [msg_n3_ok]
    call print_string
    
    ; SUCCESS!
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
; emit_neural_layer: Generate complete neural layer with loop + ReLU
; =============================================================================
emit_neural_layer:
    push rdi
    push rbx
    push r12
    
    mov rdi, [jit_cursor]
    
    ; =========================================
    ; SAVE LOOP START ADDRESS
    ; =========================================
    mov [loop_start_addr], rdi
    
    ; =========================================
    ; DOT PRODUCT INLINE (no store, no ret)
    ; YMM0 = load [rax]
    ; YMM1 = load [rbx]
    ; YMM0 = YMM0 * YMM1
    ; Horizontal sum -> scalar in XMM0
    ; =========================================
    
    ; VMOVAPS ymm0, [rax]
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC
    mov byte [rdi + 2], 0x28
    mov byte [rdi + 3], 0x00
    add rdi, 4
    
    ; VMOVAPS ymm1, [rbx]
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC
    mov byte [rdi + 2], 0x28
    mov byte [rdi + 3], 0x0B
    add rdi, 4
    
    ; VMULPS ymm0, ymm0, ymm1
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFC
    mov byte [rdi + 2], 0x59
    mov byte [rdi + 3], 0xC1
    add rdi, 4
    
    ; VEXTRACTF128 xmm1, ymm0, 1
    mov byte [rdi + 0], 0xC4
    mov byte [rdi + 1], 0xE3
    mov byte [rdi + 2], 0x7D
    mov byte [rdi + 3], 0x19
    mov byte [rdi + 4], 0xC1
    mov byte [rdi + 5], 0x01
    add rdi, 6
    
    ; VADDPS xmm0, xmm0, xmm1
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xF8
    mov byte [rdi + 2], 0x58
    mov byte [rdi + 3], 0xC1
    add rdi, 4
    
    ; VHADDPS xmm0, xmm0, xmm0
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFB
    mov byte [rdi + 2], 0x7C
    mov byte [rdi + 3], 0xC0
    add rdi, 4
    
    ; VHADDPS xmm0, xmm0, xmm0
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFB
    mov byte [rdi + 2], 0x7C
    mov byte [rdi + 3], 0xC0
    add rdi, 4
    
    ; =========================================
    ; RELU: xmm0 = max(0, xmm0)
    ; VXORPS xmm1, xmm1, xmm1  (zero)
    ; VMAXSS xmm0, xmm0, xmm1
    ; =========================================
    
    ; VXORPS xmm1, xmm1, xmm1
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xF0
    mov byte [rdi + 2], 0x57
    mov byte [rdi + 3], 0xC9
    add rdi, 4
    
    ; VMAXSS xmm0, xmm0, xmm1
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFA
    mov byte [rdi + 2], 0x5F
    mov byte [rdi + 3], 0xC1
    add rdi, 4
    
    ; =========================================
    ; STORE RESULT: [rcx] = xmm0
    ; VMOVSS [rcx], xmm0
    ; C5 FA 11 01
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xFA
    mov byte [rdi + 2], 0x11
    mov byte [rdi + 3], 0x01
    add rdi, 4
    
    ; =========================================
    ; POINTER ARITHMETIC
    ; add rbx, 32 (next weight row)
    ; add rcx, 4 (next output slot)
    ; =========================================
    
    ; add rbx, 32
    mov byte [rdi + 0], 0x48
    mov byte [rdi + 1], 0x83
    mov byte [rdi + 2], 0xC3
    mov byte [rdi + 3], 0x20
    add rdi, 4
    
    ; add rcx, 4
    mov byte [rdi + 0], 0x48
    mov byte [rdi + 1], 0x83
    mov byte [rdi + 2], 0xC1
    mov byte [rdi + 3], 0x04
    add rdi, 4
    
    ; =========================================
    ; LOOP: dec r8; jnz loop_start
    ; =========================================
    
    ; dec r8 (49 FF C8)
    mov byte [rdi + 0], 0x49
    mov byte [rdi + 1], 0xFF
    mov byte [rdi + 2], 0xC8
    add rdi, 3
    
    ; jnz loop_start
    ; Calculate relative offset
    mov byte [rdi + 0], 0x0F
    mov byte [rdi + 1], 0x85      ; JNZ near
    
    mov rax, [loop_start_addr]
    sub rax, rdi
    sub rax, 6                    ; Offset from end of this instruction
    mov dword [rdi + 2], eax
    add rdi, 6
    
    ; =========================================
    ; VZEROUPPER + RET
    ; =========================================
    mov byte [rdi + 0], 0xC5
    mov byte [rdi + 1], 0xF8
    mov byte [rdi + 2], 0x77
    add rdi, 3
    
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    pop r12
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
