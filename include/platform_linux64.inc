; ============================================================================
; TITAN Language - Linux x64 Platform Layer
; 
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; 
; Платформо-зависимые определения для Linux x64 (ELF64)
; STUB - будет реализовано позже
; ============================================================================

; ----------------------------------------------------------------------------
; Константы Linux
; ----------------------------------------------------------------------------
STDIN_FILENO  = 0
STDOUT_FILENO = 1
STDERR_FILENO = 2

; Номера системных вызовов x86_64
SYS_READ      = 0
SYS_WRITE     = 1
SYS_OPEN      = 2
SYS_CLOSE     = 3
SYS_MMAP      = 9
SYS_MPROTECT  = 10
SYS_MUNMAP    = 11
SYS_EXIT      = 60

; mmap флаги
MAP_PRIVATE   = 0x02
MAP_ANONYMOUS = 0x20

; mmap права доступа
PROT_NONE     = 0x0
PROT_READ     = 0x1
PROT_WRITE    = 0x2
PROT_EXEC     = 0x4

; ----------------------------------------------------------------------------
; Макросы для Linux syscall
; Соглашение Linux x64 ABI:
; RAX = номер syscall
; RDI, RSI, RDX, R10, R8, R9 = аргументы 1-6
; Результат в RAX
; ----------------------------------------------------------------------------

; sys_write: Вывод строки
; Вход: fd - дескриптор, buffer - адрес, length - длина
; Выход: RAX = количество записанных байт
macro sys_write_linux fd, buffer, length {
    mov eax, SYS_WRITE
    mov edi, fd
    lea rsi, [buffer]
    mov edx, length
    syscall
}

; sys_read: Чтение строки
; Вход: fd - дескриптор, buffer - адрес, max_length - макс. длина
; Выход: RAX = количество прочитанных байт
macro sys_read_linux fd, buffer, max_length {
    mov eax, SYS_READ
    mov edi, fd
    lea rsi, [buffer]
    mov edx, max_length
    syscall
}

; sys_exit: Завершение программы
; Вход: exit_code - код возврата
macro sys_exit_linux exit_code {
    mov eax, SYS_EXIT
    mov edi, exit_code
    syscall
}

; sys_mmap: Выделение исполняемой памяти (для JIT)
; Вход: size - размер в байтах
; Выход: RAX = адрес памяти (или -1 при ошибке)
macro sys_alloc_exec_linux size {
    mov eax, SYS_MMAP
    xor edi, edi                    ; addr = NULL
    mov esi, size                   ; length
    mov edx, PROT_READ or PROT_WRITE or PROT_EXEC
    mov r10d, MAP_PRIVATE or MAP_ANONYMOUS
    mov r8d, -1                     ; fd = -1
    xor r9d, r9d                    ; offset = 0
    syscall
}

; sys_munmap: Освобождение памяти
; Вход: address - адрес, size - размер
macro sys_free_linux address, size {
    mov eax, SYS_MUNMAP
    mov rdi, address
    mov esi, size
    syscall
}

; ----------------------------------------------------------------------------
; Платформо-зависимые переменные (Linux не требует handles)
; ----------------------------------------------------------------------------

macro linux_bss_vars {
    bytes_read      dq ?
}

; ----------------------------------------------------------------------------
; Инициализация платформы (Linux - ничего не нужно)
; ----------------------------------------------------------------------------

macro linux_init {
    ; Linux не требует инициализации stdin/stdout
    ; Они уже доступны как fd 0, 1, 2
}

; ----------------------------------------------------------------------------
; TODO: Структура ELF64 для Linux-сборки
; ----------------------------------------------------------------------------

; Для Linux-сборки использовать:
; format ELF64 executable
; entry start
; segment readable executable
; segment readable writeable
