; =============================================================================
; SYNAPSE SYMBOL TABLE (Phase 7.1)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Maps variable names to Stack Offsets (e.g., "x" -> -8, "y" -> -16)
; Used by the compiler to track local variables in stack frame
; =============================================================================

; Максимум 64 переменные (для начала)
MAX_SYMBOLS = 64
SYM_ENTRY_SIZE = 16 ; 8 bytes (Name Ptr) + 8 bytes (Offset)

section '.data' data readable writeable
    symbols_buffer rb MAX_SYMBOLS * SYM_ENTRY_SIZE
    symbols_count  dq 0
    
    ; Текущее смещение стека относительно RBP.
    ; RBP указывает на начало фрейма.
    ; Первые 8 байт (RBP-8) свободны для первой переменной.
    current_stack_offset dq -8 

section '.text' code readable executable

; -----------------------------------------------------------------------------
; sym_init
; Сброс таблицы (вызывается перед компиляцией новой функции)
; -----------------------------------------------------------------------------
sym_init:
    mov qword [symbols_count], 0
    mov qword [current_stack_offset], -8
    
    ; Очистка памяти (для надежности)
    push rdi
    push rcx
    push rax
    lea rdi, [symbols_buffer]
    mov rcx, MAX_SYMBOLS * SYM_ENTRY_SIZE / 8
    xor rax, rax
    rep stosq
    pop rax
    pop rcx
    pop rdi
    ret

; -----------------------------------------------------------------------------
; sym_add(name_ptr) -> RAX (assigned offset)
; MUTABLE: If variable exists, return existing offset. Else allocate new.
; RCX = Pointer to Name String (null-terminated)
; Returns: RAX = assigned stack offset (negative, e.g., -8)
; -----------------------------------------------------------------------------
sym_add:
    push rbx
    push rdi
    push rcx
    
    ; 1. Check if variable already exists
    call sym_find
    test rax, rax
    jnz .exists                         ; Found - return existing offset
    
    ; 2. Not found - create new entry
    pop rcx                             ; Restore name pointer
    
    mov rbx, [symbols_count]
    shl rbx, 4                          ; * 16 (SYM_ENTRY_SIZE)
    lea rdi, [symbols_buffer]
    add rdi, rbx
    
    ; Save name pointer
    mov [rdi], rcx
    
    ; Allocate offset
    mov rax, [current_stack_offset]
    mov [rdi + 8], rax
    
    ; Move stack boundary for next variable
    sub qword [current_stack_offset], 8
    inc qword [symbols_count]
    
    ; Return offset in RAX
    pop rdi
    pop rbx
    ret

.exists:
    ; Variable exists - return existing offset (already in RAX)
    add rsp, 8                          ; Pop saved RCX without restoring
    pop rdi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; sym_find(name_ptr) -> RAX (offset) OR 0 (not found)
; Ищет переменную по имени
; RCX = Pointer to Name String to search
; Returns: RAX = stack offset if found, 0 if not found
; -----------------------------------------------------------------------------
sym_find:
    push rbx
    push rsi
    push rdi
    push r8
    
    mov r8, rcx                         ; Искомое имя
    mov rcx, [symbols_count]
    test rcx, rcx
    jz .not_found
    
    lea rsi, [symbols_buffer]
    
.loop:
    mov rdi, [rsi]                      ; Имя из таблицы
    
    ; Сравниваем rdi (table name) и r8 (search name)
    push rcx
    push rsi
    mov rsi, r8
    call sym_strcmp
    pop rsi
    pop rcx
    
    test eax, eax
    jz .found                           ; EAX=0 значит равны
    
    add rsi, 16                         ; Next entry
    loop .loop

.not_found:
    xor rax, rax
    jmp .done

.found:
    mov rax, [rsi + 8]                  ; Возвращаем смещение

.done:
    pop r8
    pop rdi
    pop rsi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; sym_strcmp (Internal Helper)
; Compares strings at RDI and RSI
; Returns: EAX = 0 if equal, 1 if different
; -----------------------------------------------------------------------------
sym_strcmp:
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
; sym_get_frame_size() -> RAX (total bytes needed for stack frame)
; Returns the size of stack frame needed for all variables
; -----------------------------------------------------------------------------
sym_get_frame_size:
    mov rax, [symbols_count]
    shl rax, 3                          ; * 8 bytes per variable
    ret
