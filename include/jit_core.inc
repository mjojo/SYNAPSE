; ============================================================================
; TITAN Language - JIT Compiler Core
; 
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; https://github.com/GLK-Dev
;
; JIT-компилятор: генерация и выполнение x64 машинного кода
; ============================================================================

; ----------------------------------------------------------------------------
; Константы JIT
; ----------------------------------------------------------------------------
JIT_BUFFER_SIZE     = 4096          ; Размер буфера JIT (4KB)
JIT_MAX_CODE_SIZE   = 1024          ; Макс. размер одной компиляции

; VirtualAlloc флаги (Windows)
MEM_COMMIT          = 0x1000
MEM_RESERVE         = 0x2000
MEM_RELEASE         = 0x8000
PAGE_EXECUTE_READWRITE = 0x40

; ----------------------------------------------------------------------------
; x64 Опкоды (основные)
; ----------------------------------------------------------------------------

; MOV
X64_MOV_RAX_IMM64   = 0x48B8        ; mov rax, imm64 (REX.W + B8+rd)
X64_MOV_RCX_IMM64   = 0x48B9        ; mov rcx, imm64
X64_MOV_RDX_IMM64   = 0x48BA        ; mov rdx, imm64
X64_MOV_R8_IMM64    = 0x49B8        ; mov r8, imm64
X64_MOV_R9_IMM64    = 0x49B9        ; mov r9, imm64

X64_MOV_EAX_IMM32   = 0xB8          ; mov eax, imm32
X64_MOV_ECX_IMM32   = 0xB9          ; mov ecx, imm32
X64_MOV_EDX_IMM32   = 0xBA          ; mov edx, imm32
X64_MOV_R8D_IMM32   = 0x41B8        ; mov r8d, imm32

; Арифметика
X64_ADD_RAX_RBX     = 0x4801D8      ; add rax, rbx (REX.W 01 /r)
X64_SUB_RAX_RBX     = 0x4829D8      ; sub rax, rbx
X64_IMUL_RAX_RBX    = 0x480FAFC3    ; imul rax, rbx
X64_XOR_EAX_EAX     = 0x31C0        ; xor eax, eax
X64_XOR_ECX_ECX     = 0x31C9        ; xor ecx, ecx

; Стек
X64_PUSH_RAX        = 0x50
X64_PUSH_RBX        = 0x53
X64_PUSH_RCX        = 0x51
X64_PUSH_RDX        = 0x52
X64_PUSH_RBP        = 0x55
X64_PUSH_RSI        = 0x56
X64_PUSH_RDI        = 0x57
X64_PUSH_0          = 0x6A00        ; push 0

X64_POP_RAX         = 0x58
X64_POP_RBX         = 0x5B
X64_POP_RCX         = 0x59
X64_POP_RDX         = 0x5A
X64_POP_RBP         = 0x5D
X64_POP_RSI         = 0x5E
X64_POP_RDI         = 0x5F

; Вызов и возврат
X64_RET             = 0xC3
X64_CALL_REL32      = 0xE8          ; call rel32
X64_CALL_RAX        = 0xFFD0        ; call rax
X64_CALL_RBX        = 0xFFD3        ; call rbx

; SUB/ADD RSP (для shadow space)
X64_SUB_RSP_IMM8    = 0x4883EC      ; sub rsp, imm8 (REX.W 83 /5 ib)
X64_ADD_RSP_IMM8    = 0x4883C4      ; add rsp, imm8

; LEA
X64_LEA_RCX_RIP     = 0x488D0D      ; lea rcx, [rip+disp32]
X64_LEA_RDX_RIP     = 0x488D15      ; lea rdx, [rip+disp32]
X64_LEA_R8_RIP      = 0x4C8D05      ; lea r8, [rip+disp32]
X64_LEA_R9_RIP      = 0x4C8D0D      ; lea r9, [rip+disp32]

; NOP
X64_NOP             = 0x90

; ----------------------------------------------------------------------------
; Макросы для генерации кода
; ----------------------------------------------------------------------------

; emit_byte: Записывает 1 байт в JIT буфер
; Вход: AL = байт
; Изменяет: RDI (указатель JIT)
macro emit_byte val {
    mov al, val
    stosb
}

; emit_word: Записывает 2 байта (little-endian)
macro emit_word val {
    mov ax, val
    stosw
}

; emit_dword: Записывает 4 байта
macro emit_dword val {
    mov eax, val
    stosd
}

; emit_qword: Записывает 8 байт
macro emit_qword val {
    mov rax, val
    stosq
}
