; =============================================================================
; SYNAPSE CPU Detection - Phase 2.1
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Detects CPU capabilities using CPUID + XGETBV
; Returns: 1=SSE (Legacy), 2=AVX2 (Modern), 3=AVX-512 (Titan Mode)
; =============================================================================

format PE64 console
entry start

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
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
                db '  SYNAPSE CPU Detector - Phase 2.1',13,10
                db '================================================',13,10,13,10,0
    
    msg_detect  db '[CPU] Running CPUID detection...',13,10,0
    msg_tier    db '[CPU] Detected Tier: ',0
    msg_tier1   db 'TIER 1 - SSE (Legacy Mode)',13,10,0
    msg_tier2   db 'TIER 2 - AVX2 (Modern Mode)',13,10,0
    msg_tier3   db 'TIER 3 - AVX-512 (Titan Mode)',13,10,0
    
    msg_vendor  db '[CPU] Vendor: ',0
    msg_newline db 13,10,0
    
    ; Feature flags
    msg_sse     db '  [+] SSE2',13,10,0
    msg_avx     db '  [+] AVX',13,10,0
    msg_avx2    db '  [+] AVX2',13,10,0
    msg_avx512  db '  [+] AVX-512',13,10,0
    msg_fma     db '  [+] FMA3',13,10,0
    msg_noflag  db '  [-] Not supported',13,10,0
    
    msg_osxsave db '[CPU] OS XSAVE support: ',0
    msg_yes     db 'YES',13,10,0
    msg_no      db 'NO',13,10,0
    
    msg_success db 13,10,'[SUCCESS] SYNAPSE can now adapt to your hardware!',13,10,0
    
    ; Storage for CPU tier
    cpu_tier_val    dd 1        ; Default: Tier 1 (SSE)
    
    ; Vendor string (12 chars + null)
    cpu_vendor      rb 16
    
    newline     db 13,10,0

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    num_buffer      rb 32

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
    
    ; Run detection
    lea rcx, [msg_detect]
    call print_string
    
    call detect_cpu_tier
    
    ; Print vendor
    lea rcx, [msg_vendor]
    call print_string
    lea rcx, [cpu_vendor]
    call print_string
    lea rcx, [newline]
    call print_string
    
    ; Print tier result
    lea rcx, [msg_tier]
    call print_string
    
    mov eax, [cpu_tier_val]
    cmp eax, 1
    je .tier1
    cmp eax, 2
    je .tier2
    cmp eax, 3
    je .tier3
    jmp .done

.tier1:
    lea rcx, [msg_tier1]
    call print_string
    jmp .done
    
.tier2:
    lea rcx, [msg_tier2]
    call print_string
    jmp .done
    
.tier3:
    lea rcx, [msg_tier3]
    call print_string

.done:
    lea rcx, [msg_success]
    call print_string
    
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; detect_cpu_tier: Main CPU detection routine
; Output: EAX = tier (1, 2, or 3), also stored in [cpu_tier_val]
; =============================================================================
detect_cpu_tier:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; Default to Tier 1
    mov dword [cpu_tier_val], 1

    ; ===========================================
    ; Get CPU Vendor String (CPUID EAX=0)
    ; ===========================================
    xor eax, eax
    cpuid
    
    ; EBX, EDX, ECX contain vendor string
    lea rdi, [cpu_vendor]
    mov [rdi], ebx
    mov [rdi+4], edx
    mov [rdi+8], ecx
    mov byte [rdi+12], 0
    
    ; Save max standard cpuid level
    mov esi, eax

    ; ===========================================
    ; Check basic features (CPUID EAX=1)
    ; ===========================================
    cmp esi, 1
    jl .legacy_mode
    
    mov eax, 1
    cpuid
    
    ; Check SSE2 (EDX bit 26)
    bt edx, 26
    jnc .legacy_mode
    
    ; Print SSE2 support
    push rcx
    push rdx
    lea rcx, [msg_sse]
    call print_string
    pop rdx
    pop rcx
    
    ; Check AVX support (ECX bit 28)
    bt ecx, 28
    jnc .legacy_mode
    
    ; Print AVX support
    push rcx
    lea rcx, [msg_avx]
    call print_string
    pop rcx
    
    ; Check OSXSAVE (ECX bit 27) - OS must support saving AVX state
    bt ecx, 27
    jnc .legacy_mode
    
    ; Print OSXSAVE status
    push rcx
    push rdx
    lea rcx, [msg_osxsave]
    call print_string
    lea rcx, [msg_yes]
    call print_string
    pop rdx
    pop rcx
    
    ; Check FMA3 (ECX bit 12)
    bt ecx, 12
    jnc .skip_fma
    push rcx
    lea rcx, [msg_fma]
    call print_string
    pop rcx
.skip_fma:

    ; ===========================================
    ; Check XCR0 - OS level AVX support
    ; ===========================================
    xor ecx, ecx        ; XCR0
    xgetbv              ; Result in EDX:EAX
    
    ; Check XMM (bit 1) and YMM (bit 2) are enabled
    and eax, 0x6
    cmp eax, 0x6
    jne .legacy_mode

    ; ===========================================
    ; Check extended features (CPUID EAX=7, ECX=0)
    ; ===========================================
    mov eax, 7
    xor ecx, ecx
    cpuid
    
    ; Check AVX2 (EBX bit 5)
    bt ebx, 5
    jnc .legacy_mode
    
    ; Print AVX2 support
    push rbx
    lea rcx, [msg_avx2]
    call print_string
    pop rbx
    
    ; We have AVX2 - Set Tier 2
    mov dword [cpu_tier_val], 2
    
    ; ===========================================
    ; Check AVX-512 Foundation (EBX bit 16)
    ; ===========================================
    bt ebx, 16
    jnc .done
    
    ; Check if OS supports AVX-512 (XCR0 bits 5,6,7)
    xor ecx, ecx
    xgetbv
    and eax, 0xE0       ; Bits 5,6,7
    cmp eax, 0xE0
    jne .done
    
    ; Print AVX-512 support
    lea rcx, [msg_avx512]
    call print_string
    
    ; We have AVX-512 - Set Tier 3!
    mov dword [cpu_tier_val], 3
    jmp .done

.legacy_mode:
    mov dword [cpu_tier_val], 1

.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    mov eax, [cpu_tier_val]
    ret

; =============================================================================
; Utility functions
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
