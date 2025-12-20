; =============================================================================
; SYNAPSE MNIST Inference Engine v1.2 - With Biases
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Full equation: output = ReLU(input * weights + bias)
; Network: 784 → 128 (ReLU) → 10
; =============================================================================

format PE64 console
entry start

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
GENERIC_READ    = 0x80000000
FILE_SHARE_READ = 0x1
OPEN_EXISTING   = 3
FILE_ATTRIBUTE_NORMAL = 0x80
INVALID_HANDLE  = -1

; Network dimensions (double = 8 bytes)
INPUT_SIZE      = 784
HIDDEN_SIZE     = 128
OUTPUT_SIZE     = 10

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

    banner      db '================================================',13,10
                db '  SYNAPSE MNIST Inference v1.2 (with Biases)',13,10
                db '  output = ReLU(input * weights + bias)',13,10
                db '================================================',13,10,13,10,0
    
    msg_alloc   db '[MEM] Allocating tensors...',13,10,0
    msg_load    db '[IO] Loading network:',13,10,0
    msg_w1      db '  w1.bin (784x128): ',0
    msg_b1      db '  b1.bin (128):     ',0
    msg_w2      db '  w2.bin (128x10):  ',0
    msg_b2      db '  b2.bin (10):      ',0
    msg_img     db '  digit image:      ',0
    msg_ok      db 'OK',13,10,0
    msg_fail    db 'FAILED',13,10,0
    
    msg_exec    db 13,10,'[EXEC] Running inference...',13,10,0
    msg_result  db 13,10,'[OUTPUT] Scores (scaled x100):',13,10,0
    msg_digit   db '  [',0
    msg_close   db '] ',0
    msg_predict db 13,10,'==> PREDICTION: ',0
    
    msg_success db 13,10,'*** MNIST INFERENCE COMPLETE! ***',13,10,0
    newline     db 13,10,0
    space       db ' ',0
    
    path_w1     db 'neural\w1.bin',0
    path_b1     db 'neural\b1.bin',0
    path_w2     db 'neural\w2.bin',0
    path_b2     db 'neural\b2.bin',0
    path_img    db 'neural\digit_0_25.bin',0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    bytes_read      dd ?
    num_buffer      rb 32
    
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; Network tensors (DOUBLE = 8 bytes)
    ptr_input       dq ?        ; 784 doubles
    ptr_w1          dq ?        ; 784 * 128 doubles
    ptr_b1          dq ?        ; 128 doubles (biases!)
    ptr_hidden      dq ?        ; 128 doubles
    ptr_w2          dq ?        ; 128 * 10 doubles
    ptr_b2          dq ?        ; 10 doubles (biases!)
    ptr_output      dq ?        ; 10 doubles

; =============================================================================
; Code
; =============================================================================
section '.text' code readable executable

start:
    sub rsp, 72
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    ; ===========================================
    ; ALLOCATE MEMORY
    ; ===========================================
    lea rcx, [msg_alloc]
    call print_string
    
    call mem_init
    test rax, rax
    jz .exit
    
    ; Input
    mov rcx, INPUT_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_input], rax
    
    ; W1
    mov rcx, INPUT_SIZE * HIDDEN_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_w1], rax
    
    ; B1 (biases for layer 1)
    mov rcx, HIDDEN_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_b1], rax
    
    ; Hidden
    mov rcx, HIDDEN_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_hidden], rax
    
    ; W2
    mov rcx, HIDDEN_SIZE * OUTPUT_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_w2], rax
    
    ; B2 (biases for layer 2)
    mov rcx, OUTPUT_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_b2], rax
    
    ; Output
    mov rcx, OUTPUT_SIZE * 8
    mov rdx, 32
    call mem_alloc_aligned
    mov [ptr_output], rax
    
    ; ===========================================
    ; LOAD FILES
    ; ===========================================
    lea rcx, [msg_load]
    call print_string
    
    ; W1
    lea rcx, [msg_w1]
    call print_string
    lea rcx, [path_w1]
    mov rdx, [ptr_w1]
    mov r8, INPUT_SIZE * HIDDEN_SIZE * 8
    call file_read
    cmp rax, -1
    je .load_fail
    lea rcx, [msg_ok]
    call print_string
    
    ; B1
    lea rcx, [msg_b1]
    call print_string
    lea rcx, [path_b1]
    mov rdx, [ptr_b1]
    mov r8, HIDDEN_SIZE * 8
    call file_read
    cmp rax, -1
    je .load_fail
    lea rcx, [msg_ok]
    call print_string
    
    ; W2
    lea rcx, [msg_w2]
    call print_string
    lea rcx, [path_w2]
    mov rdx, [ptr_w2]
    mov r8, HIDDEN_SIZE * OUTPUT_SIZE * 8
    call file_read
    cmp rax, -1
    je .load_fail
    lea rcx, [msg_ok]
    call print_string
    
    ; B2
    lea rcx, [msg_b2]
    call print_string
    lea rcx, [path_b2]
    mov rdx, [ptr_b2]
    mov r8, OUTPUT_SIZE * 8
    call file_read
    cmp rax, -1
    je .load_fail
    lea rcx, [msg_ok]
    call print_string
    
    ; Image
    lea rcx, [msg_img]
    call print_string
    lea rcx, [path_img]
    mov rdx, [ptr_input]
    mov r8, INPUT_SIZE * 8
    call file_read
    cmp rax, -1
    je .load_fail
    lea rcx, [msg_ok]
    call print_string
    
    ; ===========================================
    ; INFERENCE
    ; ===========================================
    lea rcx, [msg_exec]
    call print_string
    
    call layer1_forward_with_bias
    call layer2_forward_with_bias
    
    ; ===========================================
    ; RESULTS
    ; ===========================================
    lea rcx, [msg_result]
    call print_string
    
    mov rsi, [ptr_output]
    xor r12d, r12d
    xor r13d, r13d
    
    mov rax, 0xFFF0000000000000
    mov [rsp+64], rax
    movsd xmm7, [rsp+64]
    
.show_loop:
    cmp r12d, 10
    jge .show_done
    
    lea rcx, [msg_digit]
    call print_string
    mov rax, r12
    call print_num
    lea rcx, [msg_close]
    call print_string
    
    movsd xmm0, [rsi + r12*8]
    
    ucomisd xmm0, xmm7
    jbe .not_best
    movsd xmm7, xmm0
    mov r13d, r12d
.not_best:
    
    ; Scale by 100 for display
    mov rax, 100
    cvtsi2sd xmm1, rax
    mulsd xmm0, xmm1
    cvttsd2si rax, xmm0
    call print_num_signed
    
    lea rcx, [newline]
    call print_string
    
    inc r12d
    jmp .show_loop

.show_done:
    lea rcx, [msg_predict]
    call print_string
    mov rax, r13
    call print_num
    
    lea rcx, [msg_success]
    call print_string
    jmp .exit

.load_fail:
    lea rcx, [msg_fail]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; Layer 1: 784 -> 128 with BIAS and ReLU
; output = ReLU(input * weights + bias)
; =============================================================================
layer1_forward_with_bias:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    sub rsp, 32
    
    mov r12, [ptr_input]
    mov r13, [ptr_w1]
    mov r14, [ptr_hidden]
    mov r15, [ptr_b1]           ; Bias pointer!
    mov edi, HIDDEN_SIZE
    
.neuron_loop:
    test edi, edi
    jz .done
    
    ; Dot product
    vxorpd ymm0, ymm0, ymm0
    mov rcx, INPUT_SIZE / 4
    mov rsi, r12
    mov rbx, r13
    
.dot_loop:
    vmovupd ymm1, [rsi]
    vmovupd ymm2, [rbx]
    vfmadd231pd ymm0, ymm1, ymm2
    add rsi, 32
    add rbx, 32
    dec rcx
    jnz .dot_loop
    
    ; Horizontal sum
    vextractf128 xmm1, ymm0, 1
    vaddpd xmm0, xmm0, xmm1
    vhaddpd xmm0, xmm0, xmm0
    
    ; ADD BIAS! (xmm0 += bias[i])
    vaddsd xmm0, xmm0, [r15]
    
    ; ReLU
    vxorpd xmm1, xmm1, xmm1
    vmaxsd xmm0, xmm0, xmm1
    
    ; Store
    vmovsd [r14], xmm0
    
    ; Advance pointers
    add r13, INPUT_SIZE * 8
    add r14, 8
    add r15, 8                  ; Next bias!
    dec edi
    jmp .neuron_loop

.done:
    vzeroupper
    add rsp, 32
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; Layer 2: 128 -> 10 with BIAS (no ReLU on output)
; =============================================================================
layer2_forward_with_bias:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    sub rsp, 32
    
    mov r12, [ptr_hidden]
    mov r13, [ptr_w2]
    mov r14, [ptr_output]
    mov r15, [ptr_b2]           ; Bias pointer!
    mov edi, OUTPUT_SIZE
    
.neuron_loop:
    test edi, edi
    jz .done
    
    vxorpd ymm0, ymm0, ymm0
    mov rcx, HIDDEN_SIZE / 4
    mov rsi, r12
    mov rbx, r13
    
.dot_loop:
    vmovupd ymm1, [rsi]
    vmovupd ymm2, [rbx]
    vfmadd231pd ymm0, ymm1, ymm2
    add rsi, 32
    add rbx, 32
    dec rcx
    jnz .dot_loop
    
    vextractf128 xmm1, ymm0, 1
    vaddpd xmm0, xmm0, xmm1
    vhaddpd xmm0, xmm0, xmm0
    
    ; ADD BIAS!
    vaddsd xmm0, xmm0, [r15]
    
    ; No ReLU on output layer
    
    vmovsd [r14], xmm0
    
    add r13, HIDDEN_SIZE * 8
    add r14, 8
    add r15, 8
    dec edi
    jmp .neuron_loop

.done:
    vzeroupper
    add rsp, 32
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; File I/O
; =============================================================================
file_read:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 72
    
    mov rsi, rcx
    mov rdi, rdx
    mov r12, r8
    
    mov rcx, rsi
    mov rdx, GENERIC_READ
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword [rsp+32], OPEN_EXISTING
    mov qword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+48], 0
    call [CreateFileA]
    
    cmp rax, INVALID_HANDLE
    je .error
    mov rbx, rax
    
    mov rcx, rbx
    mov rdx, rdi
    mov r8, r12
    lea r9, [bytes_read]
    mov qword [rsp+32], 0
    call [ReadFile]
    
    test eax, eax
    jz .err_close
    
    mov rcx, rbx
    call [CloseHandle]
    mov eax, [bytes_read]
    jmp .done

.err_close:
    mov rcx, rbx
    call [CloseHandle]
.error:
    mov rax, -1
.done:
    add rsp, 72
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; Memory
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 8*1024*1024
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

print_num:
    push rbx
    push rdi
    lea rdi, [num_buffer + 20]
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

print_num_signed:
    test rax, rax
    jns print_num
    push rax
    mov byte [num_buffer], '-'
    mov byte [num_buffer+1], 0
    lea rcx, [num_buffer]
    call print_string
    pop rax
    neg rax
    jmp print_num
