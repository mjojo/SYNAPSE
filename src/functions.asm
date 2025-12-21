; =============================================================================
; SYNAPSE FUNCTION TABLE (Phase 8.1)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Maps function names ("main", "train") to JIT Memory Addresses
; Used by the compiler for CALL instruction generation
; =============================================================================

MAX_FUNCS = 64
FUNC_ENTRY_SIZE = 16 ; 8 bytes (Name Ptr) + 8 bytes (Address)

section '.data' data readable writeable
    funcs_buffer rb MAX_FUNCS * FUNC_ENTRY_SIZE
    funcs_count  dq 0

section '.text' code readable executable

; -----------------------------------------------------------------------------
; func_init
; Clears the function table (call before compiling a new module)
; -----------------------------------------------------------------------------
func_init:
    push rdi
    push rcx
    push rax
    
    mov qword [funcs_count], 0
    lea rdi, [funcs_buffer]
    mov rcx, MAX_FUNCS * FUNC_ENTRY_SIZE / 8
    xor rax, rax
    rep stosq
    
    pop rax
    pop rcx
    pop rdi
    ret

; -----------------------------------------------------------------------------
; func_add(name_ptr, jit_address)
; Registers a new function with its JIT code address
; RCX = Name Ptr (null-terminated string)
; RDX = JIT Address (pointer to compiled code)
; -----------------------------------------------------------------------------
func_add:
    push rdi
    push rbx
    
    ; 1. Calculate new entry position
    mov rbx, [funcs_count]
    shl rbx, 4                          ; * 16 (FUNC_ENTRY_SIZE)
    lea rdi, [funcs_buffer]
    add rdi, rbx
    
    ; 2. Store name and address
    mov [rdi], rcx                      ; Name pointer
    mov [rdi + 8], rdx                  ; JIT address
    
    inc qword [funcs_count]
    
    pop rbx
    pop rdi
    ret

; -----------------------------------------------------------------------------
; func_find(name_ptr) -> RAX (Address) OR 0 (Not found)
; Looks up a function by name
; RCX = Name Ptr to search for
; Returns: RAX = JIT address if found, 0 if not found
; -----------------------------------------------------------------------------
func_find:
    push rbx
    push rsi
    push rdi
    push r8
    
    mov r8, rcx                         ; Save search name
    mov rcx, [funcs_count]
    test rcx, rcx
    jz .not_found
    
    lea rsi, [funcs_buffer]
    
.loop:
    mov rdi, [rsi]                      ; Name from table
    
    ; Compare rdi (table name) vs r8 (search name)
    push rcx
    push rsi
    mov rsi, r8
    call func_strcmp
    pop rsi
    pop rcx
    
    test eax, eax
    jz .found                           ; EAX=0 means equal
    
    add rsi, 16                         ; Next entry
    loop .loop

.not_found:
    xor rax, rax
    jmp .done

.found:
    mov rax, [rsi + 8]                  ; Return JIT address

.done:
    pop r8
    pop rdi
    pop rsi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; func_strcmp (Internal Helper)
; Compares strings at RDI and RSI
; Returns: EAX = 0 if equal, 1 if different
; -----------------------------------------------------------------------------
func_strcmp:
    push rbx
.lp:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .diff
    test al, al
    jz .eq
    inc rdi
    inc rsi
    jmp .lp
.diff:
    mov eax, 1
    jmp .end
.eq:
    xor eax, eax
.end:
    pop rbx
    ret

; -----------------------------------------------------------------------------
; func_get_count() -> RAX (number of registered functions)
; -----------------------------------------------------------------------------
func_get_count:
    mov rax, [funcs_count]
    ret
