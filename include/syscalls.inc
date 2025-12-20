; ============================================================================
; TITAN Language - Platform-Independent System Calls Abstraction
; 
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; 
; Абстракция системных вызовов - унифицированный интерфейс для всех платформ
; ============================================================================

; ----------------------------------------------------------------------------
; Выбор платформы
; Определите PLATFORM_WINDOWS или PLATFORM_LINUX перед включением
; По умолчанию: Windows
; ----------------------------------------------------------------------------

if ~ defined PLATFORM_LINUX
    PLATFORM_WINDOWS = 1
end if

; ----------------------------------------------------------------------------
; Подключение платформо-зависимых файлов
; ----------------------------------------------------------------------------

if defined PLATFORM_WINDOWS
    include 'platform_win64.inc'
else if defined PLATFORM_LINUX
    include 'platform_linux64.inc'
end if

; ----------------------------------------------------------------------------
; Унифицированные макросы (платформо-независимые)
; ----------------------------------------------------------------------------

; TITAN_INIT: Инициализация платформы
macro TITAN_INIT {
    if defined PLATFORM_WINDOWS
        win_init
    else if defined PLATFORM_LINUX
        linux_init
    end if
}

; TITAN_EXIT: Выход из программы
macro TITAN_EXIT code {
    if defined PLATFORM_WINDOWS
        sys_exit code
    else if defined PLATFORM_LINUX
        sys_exit_linux code
    end if
}

; TITAN_PRINT: Вывод строки (нужен stdout_handle для Windows)
; Использовать после TITAN_INIT
macro TITAN_PRINT buffer, length {
    if defined PLATFORM_WINDOWS
        mov rcx, [stdout_handle]
        lea rdx, [buffer]
        mov r8d, length
        lea r9, [bytes_written]
        push 0
        sub rsp, 32
        call [WriteConsoleA]
        add rsp, 40
    else if defined PLATFORM_LINUX
        sys_write_linux STDOUT_FILENO, buffer, length
    end if
}

; TITAN_INPUT: Чтение строки (нужен stdin_handle для Windows)
macro TITAN_INPUT buffer, max_length {
    if defined PLATFORM_WINDOWS
        mov rcx, [stdin_handle]
        lea rdx, [buffer]
        mov r8d, max_length
        lea r9, [bytes_read]
        push 0
        sub rsp, 32
        call [ReadConsoleA]
        add rsp, 40
    else if defined PLATFORM_LINUX
        sys_read_linux STDIN_FILENO, buffer, max_length
    end if
}

; TITAN_ALLOC_EXEC: Выделение исполняемой памяти для JIT
; Выход: RAX = адрес памяти
macro TITAN_ALLOC_EXEC size {
    if defined PLATFORM_WINDOWS
        sys_alloc_exec size
    else if defined PLATFORM_LINUX
        sys_alloc_exec_linux size
    end if
}

; TITAN_FREE: Освобождение памяти
macro TITAN_FREE address {
    if defined PLATFORM_WINDOWS
        sys_free address
    else if defined PLATFORM_LINUX
        ; Linux требует размер, но мы его не храним
        ; TODO: добавить tracking размеров аллокаций
        sys_free_linux address, 0
    end if
}

; ----------------------------------------------------------------------------
; Макрос для объявления BSS переменных платформы
; ----------------------------------------------------------------------------

macro TITAN_PLATFORM_BSS {
    if defined PLATFORM_WINDOWS
        win_bss_vars
    else if defined PLATFORM_LINUX
        linux_bss_vars
    end if
}

; ----------------------------------------------------------------------------
; Макрос для таблицы импорта (только Windows)
; ----------------------------------------------------------------------------

macro TITAN_IMPORTS {
    if defined PLATFORM_WINDOWS
        win_import_table
    end if
}
