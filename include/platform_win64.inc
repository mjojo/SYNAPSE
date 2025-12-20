; ============================================================================
; TITAN Language - Windows x64 Platform Layer
; 
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; 
; Платформо-зависимые определения для Windows x64
; ============================================================================

; ----------------------------------------------------------------------------
; Константы Windows
; ----------------------------------------------------------------------------
STD_INPUT_HANDLE  = -10
STD_OUTPUT_HANDLE = -11
STD_ERROR_HANDLE  = -12

; VirtualAlloc флаги
MEM_COMMIT        = 0x1000
MEM_RESERVE       = 0x2000
MEM_RELEASE       = 0x8000

; Права доступа к памяти
PAGE_READONLY          = 0x02
PAGE_READWRITE         = 0x04
PAGE_EXECUTE           = 0x10
PAGE_EXECUTE_READ      = 0x20
PAGE_EXECUTE_READWRITE = 0x40

; ----------------------------------------------------------------------------
; Макросы для Windows API вызовов
; Используют соглашение Microsoft x64 ABI:
; RCX, RDX, R8, R9 = первые 4 аргумента
; Shadow space = 32 байта перед call
; ----------------------------------------------------------------------------

; Макрос: вызов функции с 0-4 аргументами
macro win_call func, [args] {
common
    sub rsp, 32
forward
    if ~ args eq
        ; Загружаем аргументы в регистры
    end if
common
    call [func]
    add rsp, 32
}

; ----------------------------------------------------------------------------
; Макросы системного ввода/вывода
; ----------------------------------------------------------------------------

; sys_write: Вывод строки
; Вход: buffer - адрес буфера, length - длина
; Выход: RAX = количество записанных байт
macro sys_write handle, buffer, length {
    mov rcx, handle
    lea rdx, [buffer]
    mov r8d, length
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
}

; sys_read: Чтение строки
; Вход: buffer - адрес буфера, max_length - макс. длина
; Выход: bytes_read = количество прочитанных байт
macro sys_read handle, buffer, max_length {
    mov rcx, handle
    lea rdx, [buffer]
    mov r8d, max_length
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call [ReadConsoleA]
    add rsp, 40
}

; sys_exit: Завершение программы
; Вход: exit_code - код возврата
macro sys_exit exit_code {
    mov ecx, exit_code
    call [ExitProcess]
}

; sys_alloc_exec: Выделение исполняемой памяти (для JIT)
; Вход: size - размер в байтах
; Выход: RAX = адрес памяти (или 0 при ошибке)
macro sys_alloc_exec size {
    xor ecx, ecx                    ; lpAddress = NULL
    mov edx, size                   ; dwSize
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_READWRITE
    sub rsp, 32
    call [VirtualAlloc]
    add rsp, 32
}

; sys_free: Освобождение памяти
; Вход: address - адрес памяти
macro sys_free address {
    mov rcx, address
    xor edx, edx                    ; dwSize = 0
    mov r8d, MEM_RELEASE
    sub rsp, 32
    call [VirtualFree]
    add rsp, 32
}

; ----------------------------------------------------------------------------
; Структура для импорта Windows API
; ----------------------------------------------------------------------------

macro win_import_table {
section '.idata' import data readable

    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetStdHandle        dq RVA _GetStdHandle
        WriteConsoleA       dq RVA _WriteConsoleA
        ReadConsoleA        dq RVA _ReadConsoleA
        ExitProcess         dq RVA _ExitProcess
        VirtualAlloc        dq RVA _VirtualAlloc
        VirtualFree         dq RVA _VirtualFree
                            dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ReadConsoleA   db 0,0,'ReadConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0
    _VirtualFree    db 0,0,'VirtualFree',0
}

; ----------------------------------------------------------------------------
; Платформо-зависимые переменные
; ----------------------------------------------------------------------------

macro win_bss_vars {
    stdin_handle    dq ?
    stdout_handle   dq ?
    stderr_handle   dq ?
    bytes_written   dd ?
    bytes_read      dd ?
}

; ----------------------------------------------------------------------------
; Инициализация платформы
; ----------------------------------------------------------------------------

macro win_init {
    ; Получаем handle stdout
    mov ecx, STD_OUTPUT_HANDLE
    call [GetStdHandle]
    mov [stdout_handle], rax
    
    ; Получаем handle stdin
    mov ecx, STD_INPUT_HANDLE
    call [GetStdHandle]
    mov [stdin_handle], rax
    
    ; Получаем handle stderr
    mov ecx, STD_ERROR_HANDLE
    call [GetStdHandle]
    mov [stderr_handle], rax
}
