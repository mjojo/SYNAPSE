; =============================================================================
; SYNAPSE Evolutionary JIT Test (Phase 20) - DARWINIAN ASSEMBLY
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Tests genetic optimization: IMUL vs SHL (multiply by 2)
; Uses RDTSC to measure CPU cycles and select fastest gene
;
; Gene A: IMUL RAX, 2 (heavy)
; Gene B: SHL RAX, 1  (swift)
;
; Natural Selection: The fastest organism survives!
; =============================================================================

format PE64 console
entry start

MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_EXECUTE_RW = 0x40

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
                db '  SYNAPSE Phase 20: Darwinian JIT',13,10
                db '  GENETIC CODE OPTIMIZATION',13,10
                db '  Gene A: IMUL vs Gene B: SHL',13,10
                db '============================================',13,10,13,10,0
    
    alloc_msg   db '[GENESIS] Allocating JIT arena...',13,10,0
    gene_a_msg  db '[EVO] Spawning Organism A (IMUL strategy)...',13,10,0
    gene_b_msg  db '[EVO] Spawning Organism B (SHL strategy)...',13,10,0
    bench_msg   db '        Benchmarking 1,000,000 iterations...',13,10,0
    
    time_a_msg  db '        Time A: ',0
    time_b_msg  db '        Time B: ',0
    cycles_msg  db ' cycles',13,10,0
    
    select_a    db 13,10,'[SELECT] Gene A (IMUL) is faster. Unexpected!',13,10,0
    select_b    db 13,10,'[SELECT] Gene B (SHL) is faster!',13,10
                db '[MUTATION] Evolution successful!',13,10
                db '[DNA] Engine now uses optimized bit-shift.',13,10,0
    
    verify_msg  db 13,10,'[VERIFY] Testing winner: 10 * 2 = ',0
    success_msg db 13,10,'*** NATURAL SELECTION COMPLETE ***',13,10,0

section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    jit_arena       dq ?
    time_a          dq ?
    time_b          dq ?
    winner_addr     dq ?
    num_buffer      rb 32

section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    ; === GENESIS: Allocate JIT Arena ===
    lea rcx, [alloc_msg]
    call print_string
    
    sub rsp, 32
    xor ecx, ecx
    mov edx, 4096
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_RW
    call [VirtualAlloc]
    add rsp, 32
    
    mov [jit_arena], rax
    test rax, rax
    jz .exit
    
    ; =========================================================================
    ; GENE A: IMUL STRATEGY
    ; =========================================================================
    lea rcx, [gene_a_msg]
    call print_string
    
    ; Generate: MOV RAX, RCX; IMUL RAX, RAX, 2; RET
    mov rdi, [jit_arena]
    
    ; MOV RAX, RCX (48 89 C8)
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x89
    mov byte [rdi+2], 0xC8
    add rdi, 3
    
    ; IMUL RAX, RAX, 2 (48 6B C0 02)
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x6B
    mov byte [rdi+2], 0xC0
    mov byte [rdi+3], 0x02
    add rdi, 4
    
    ; RET (C3)
    mov byte [rdi], 0xC3
    
    ; Benchmark A
    lea rcx, [bench_msg]
    call print_string
    
    call run_benchmark
    mov [time_a], rax
    
    ; Print Time A
    lea rcx, [time_a_msg]
    call print_string
    mov rax, [time_a]
    call print_number
    lea rcx, [cycles_msg]
    call print_string
    
    ; =========================================================================
    ; GENE B: SHL STRATEGY (MUTATION)
    ; =========================================================================
    lea rcx, [gene_b_msg]
    call print_string
    
    ; Generate: MOV RAX, RCX; SHL RAX, 1; RET
    mov rdi, [jit_arena]
    
    ; MOV RAX, RCX (48 89 C8)
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x89
    mov byte [rdi+2], 0xC8
    add rdi, 3
    
    ; SHL RAX, 1 (48 D1 E0)
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xD1
    mov byte [rdi+2], 0xE0
    add rdi, 3
    
    ; RET (C3)
    mov byte [rdi], 0xC3
    
    ; Benchmark B
    lea rcx, [bench_msg]
    call print_string
    
    call run_benchmark
    mov [time_b], rax
    
    ; Print Time B
    lea rcx, [time_b_msg]
    call print_string
    mov rax, [time_b]
    call print_number
    lea rcx, [cycles_msg]
    call print_string
    
    ; =========================================================================
    ; NATURAL SELECTION
    ; =========================================================================
    mov rax, [time_a]
    mov rbx, [time_b]
    
    ; Default: Gene B (SHL) is in arena now
    mov rcx, [jit_arena]
    mov [winner_addr], rcx
    
    cmp rbx, rax
    jl .b_wins
    
    ; Gene A wins - need to regenerate it
    lea rcx, [select_a]
    call print_string
    
    ; Regenerate Gene A
    mov rdi, [jit_arena]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x89
    mov byte [rdi+2], 0xC8
    mov byte [rdi+3], 0x48
    mov byte [rdi+4], 0x6B
    mov byte [rdi+5], 0xC0
    mov byte [rdi+6], 0x02
    mov byte [rdi+7], 0xC3
    jmp .verify
    
.b_wins:
    lea rcx, [select_b]
    call print_string
    
.verify:
    ; === VERIFY WINNER ===
    lea rcx, [verify_msg]
    call print_string
    
    ; Call winner with input 10, expect 20
    mov rcx, 10
    call [winner_addr]
    
    ; Print result
    call print_number
    
    lea rcx, [success_msg]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; run_benchmark - Runs JIT code 1,000,000 times, returns cycles in RAX
; =============================================================================
run_benchmark:
    push rbx
    push rsi
    push rdi
    push r12
    
    ; Warmup (10 iterations)
    mov r12, 10
.warmup:
    mov rcx, 42
    call [jit_arena]
    dec r12
    jnz .warmup
    
    ; Start timer (RDTSC)
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov rsi, rax            ; Start time
    
    ; Benchmark loop: 1,000,000 iterations
    mov rbx, 1000000
.loop:
    mov rcx, 42             ; Input value
    call [jit_arena]
    dec rbx
    jnz .loop
    
    ; Stop timer
    rdtsc
    shl rdx, 32
    or rax, rdx
    
    ; Calculate delta
    sub rax, rsi
    
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; print_number - Print RAX as decimal
; =============================================================================
print_number:
    push rbx
    push rcx
    push rdx
    push rdi
    
    lea rdi, [num_buffer + 30]
    mov byte [rdi], 0
    dec rdi
    
    mov rbx, 10
    test rax, rax
    jnz .convert
    
    ; Special case: 0
    mov byte [rdi], '0'
    dec rdi
    jmp .print_it
    
.convert:
    test rax, rax
    jz .print_it
    
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    jmp .convert
    
.print_it:
    inc rdi
    mov rcx, rdi
    call print_string
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

; =============================================================================
; print_string - Print null-terminated string at RCX
; =============================================================================
print_string:
    push rsi
    push rdx
    push r8
    push r9
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
    pop r9
    pop r8
    pop rdx
    pop rsi
    ret
