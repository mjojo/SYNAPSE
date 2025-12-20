; ============================================================================
; TITAN Language v0.20.0 - Phase 22: Vision (Neural Eye - CAPTURE)
; JIT-компилируемый язык на чистом Ассемблере x64
; 
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; https://github.com/GLK-Dev
;
; Phase 13: + FFI — вызов функций из DLL (Windows API)
; Платформа: Windows x64 (кроссплатформенная архитектура)
; ============================================================================

format PE64 console
entry start

; ----------------------------------------------------------------------------
; Подключение платформо-независимых констант
; ----------------------------------------------------------------------------
include '..\include\constants.inc'

; ----------------------------------------------------------------------------
; Дополнительные константы (локальные для main)
; ----------------------------------------------------------------------------
; Структура Token
TOKEN_SIZE    = 16
TOKEN_TYPE    = 0
TOKEN_SUBTYPE = 1
TOKEN_LENGTH  = 2
TOKEN_VALUE   = 8

; JIT константы
JIT_BUFFER_SIZE = 4096
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
MEM_RELEASE     = 0x8000
PAGE_EXECUTE_READWRITE = 0x40

; File API константы (Phase 8)
GENERIC_READ    = 0x80000000
GENERIC_WRITE   = 0x40000000
CREATE_ALWAYS   = 2
OPEN_EXISTING   = 3
FILE_ATTRIBUTE_NORMAL = 0x80
INVALID_HANDLE_VALUE = -1

; ----------------------------------------------------------------------------
; Импорт функций Windows API
; ----------------------------------------------------------------------------
section '.idata' import data readable

    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,RVA user32_name,RVA user32_table
    dd 0,0,0,RVA gdi32_name,RVA gdi32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetStdHandle        dq RVA _GetStdHandle
        WriteConsoleA       dq RVA _WriteConsoleA
        ReadConsoleA        dq RVA _ReadConsoleA
        ReadFile            dq RVA _ReadFile
        WriteFile           dq RVA _WriteFile
        CreateFileA         dq RVA _CreateFileA
        CloseHandle         dq RVA _CloseHandle
        ExitProcess         dq RVA _ExitProcess
        VirtualAlloc        dq RVA _VirtualAlloc
        VirtualFree         dq RVA _VirtualFree
        SetUnhandledExceptionFilter dq RVA _SetUnhandledExceptionFilter
        LoadLibraryA        dq RVA _LoadLibraryA
        GetProcAddress      dq RVA _GetProcAddress
        FreeLibrary         dq RVA _FreeLibrary
        GetConsoleWindow    dq RVA _GetConsoleWindow
        GetLastError        dq RVA _GetLastError
        Sleep               dq RVA _Sleep
        GetCommandLineA     dq RVA _GetCommandLineA
                            dq 0

    user32_table:
        MessageBoxA         dq RVA _MessageBoxA
        GetDC               dq RVA _GetDC
        ReleaseDC           dq RVA _ReleaseDC
        GetCursorPos        dq RVA _GetCursorPos
        GetAsyncKeyState    dq RVA _GetAsyncKeyState
        ScreenToClient      dq RVA _ScreenToClient
        ; Phase 21: Window creation
        RegisterClassA      dq RVA _RegisterClassA
        CreateWindowExA     dq RVA _CreateWindowExA
        ShowWindow          dq RVA _ShowWindow
        UpdateWindow        dq RVA _UpdateWindow
        PeekMessageA        dq RVA _PeekMessageA
        TranslateMessage    dq RVA _TranslateMessage
        DispatchMessageA    dq RVA _DispatchMessageA
        DefWindowProcA      dq RVA _DefWindowProcA
        PostQuitMessage     dq RVA _PostQuitMessage
        GetClientRect       dq RVA _GetClientRect
        LoadCursorA         dq RVA _LoadCursorA
        AdjustWindowRect    dq RVA _AdjustWindowRect
                            dq 0
                            
    gdi32_table:
        SetPixel            dq RVA _SetPixel
        LineTo              dq RVA _LineTo
        MoveToEx            dq RVA _MoveToEx
        Rectangle           dq RVA _Rectangle
        Ellipse             dq RVA _Ellipse
        CreatePen           dq RVA _CreatePen
        SelectObject        dq RVA _SelectObject
        DeleteObject        dq RVA _DeleteObject
        ; Phase 21: Fast framebuffer
        SetDIBitsToDevice   dq RVA _SetDIBitsToDevice
        CreateCompatibleDC  dq RVA _CreateCompatibleDC
        CreateDIBSection    dq RVA _CreateDIBSection
                            dq 0

    kernel32_name   db 'kernel32.dll',0
    user32_name     db 'user32.dll',0
    gdi32_name      db 'gdi32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ReadConsoleA   db 0,0,'ReadConsoleA',0
    _ReadFile       db 0,0,'ReadFile',0
    _WriteFile      db 0,0,'WriteFile',0
    _CreateFileA    db 0,0,'CreateFileA',0
    _CloseHandle    db 0,0,'CloseHandle',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0
    _VirtualFree    db 0,0,'VirtualFree',0
    _SetUnhandledExceptionFilter db 0,0,'SetUnhandledExceptionFilter',0
    _LoadLibraryA   db 0,0,'LoadLibraryA',0
    _GetProcAddress db 0,0,'GetProcAddress',0
    _FreeLibrary    db 0,0,'FreeLibrary',0
    _GetConsoleWindow db 0,0,'GetConsoleWindow',0
    _GetLastError   db 0,0,'GetLastError',0
    _Sleep          db 0,0,'Sleep',0
    _GetCommandLineA db 0,0,'GetCommandLineA',0
    _MessageBoxA    db 0,0,'MessageBoxA',0
    _GetDC          db 0,0,'GetDC',0
    _ReleaseDC      db 0,0,'ReleaseDC',0
    _GetCursorPos   db 0,0,'GetCursorPos',0
    _GetAsyncKeyState db 0,0,'GetAsyncKeyState',0
    _ScreenToClient db 0,0,'ScreenToClient',0
    ; Phase 21: Window API names
    _RegisterClassA     db 0,0,'RegisterClassA',0
    _CreateWindowExA    db 0,0,'CreateWindowExA',0
    _ShowWindow         db 0,0,'ShowWindow',0
    _UpdateWindow       db 0,0,'UpdateWindow',0
    _PeekMessageA       db 0,0,'PeekMessageA',0
    _TranslateMessage   db 0,0,'TranslateMessage',0
    _DispatchMessageA   db 0,0,'DispatchMessageA',0
    _DefWindowProcA     db 0,0,'DefWindowProcA',0
    _PostQuitMessage    db 0,0,'PostQuitMessage',0
    _GetClientRect      db 0,0,'GetClientRect',0
    _LoadCursorA        db 0,0,'LoadCursorA',0
    _AdjustWindowRect   db 0,0,'AdjustWindowRect',0
    _SetPixel       db 0,0,'SetPixel',0
    _LineTo         db 0,0,'LineTo',0
    _MoveToEx       db 0,0,'MoveToEx',0
    _Rectangle      db 0,0,'Rectangle',0
    _Ellipse        db 0,0,'Ellipse',0
    _CreatePen      db 0,0,'CreatePen',0
    _SelectObject   db 0,0,'SelectObject',0
    _DeleteObject   db 0,0,'DeleteObject',0
    ; Phase 21: GDI framebuffer names
    _SetDIBitsToDevice  db 0,0,'SetDIBitsToDevice',0
    _CreateCompatibleDC db 0,0,'CreateCompatibleDC',0
    _CreateDIBSection   db 0,0,'CreateDIBSection',0

; ----------------------------------------------------------------------------
; Данные
; ----------------------------------------------------------------------------
section '.data' data readable writeable

    ; Заголовок при старте
    banner      db 'TITAN Language v0.20.0',13,10
                db 'JIT-Compiled TITAN for x64',13,10
                db '(c) 2025 mjojo & GLK-Dev',13,10
                db 'Type EXIT to quit, HELP for commands',13,10,13,10,0
    banner_len  = $ - banner - 1
    
    ; Приглашение ввода
    prompt      db 'TITAN> ',0
    prompt_len  = $ - prompt - 1
    
    ; Сообщение выхода
    bye_msg     db 13,10,'Goodbye!',13,10,0
    bye_len     = $ - bye_msg - 1
    
    newline     db 13,10,0
    
    ; === Phase 13: FFI данные ===
    ffi_test_title   db 'TITAN FFI Test',0
    ffi_test_msg     db 'Hello from TITAN v0.14.0!',13,10
                     db 'FFI is working!',0
    ffi_success_msg  db '  -> FFI: MessageBoxA called successfully!',13,10,0
    msgbox_result_msg db '  -> MSGBOX result: ',0
    msgbox_err_msg   db '  -> Error: MSGBOX "text", "title"',13,10,0
    
    ; DECLARE сообщения
    declare_ok_msg   db '  -> DECLARE: ',0
    declare_ok_msg2  db ' loaded from ',0
    declare_err_msg  db '  -> Error: DECLARE <name> LIB "dll" ALIAS "func"',13,10,0
    declare_err_dll  db '  -> Error: Cannot load DLL: ',0
    declare_err_proc db '  -> Error: Cannot find function: ',0
    
    ; FFI debug сообщения
    ; FFI error messages
    
    ; Сообщения токенов для отладки
    msg_tok_num db '  [NUM: ',0
    msg_tok_str db '  [STR: "',0
    msg_tok_id  db '  [ID: ',0
    msg_tok_kw  db '  [KW: ',0
    msg_tok_op  db '  [OP: ',0
    msg_close   db ']',13,10,0
    msg_quote   db '"]',13,10,0
    
    ; Сообщения об ошибках
    err_jit_alloc   db 'ERROR: Failed to allocate JIT memory',13,10,0
    err_jit_alloc_len = $ - err_jit_alloc - 1
    
    ; Отладочные сообщения
    dbg_jit_exec    db '[JIT: Executing...]',13,10,0
    
    ; Сообщения для DUMP
    dump_header     db '=== JIT Hex Dump ===',13,10,0
    dump_colon      db ': ',0
    dump_space      db ' ',0
    dump_size       db 'Total: ',0
    dump_bytes      db ' bytes',13,10,0
    dump_empty_msg  db 'JIT buffer empty',13,10,0
    hex_chars       db '0123456789ABCDEF'
    
    ; Сообщения для LET/VARS
    let_ok_msg      db 'OK',13,10,0
    let_err_msg     db 'Syntax error in LET',13,10,0
    vars_header     db '=== Variables ===',13,10,0
    vars_prefix     db '  ',0
    vars_eq         db ' = ',0
    
    ; Сообщения для DIM (Phase 16: Arrays)
    dim_ok_msg      db 'Array OK',13,10,0
    dim_err_msg     db 'Syntax error in DIM',13,10,0
    dim_oom_msg     db 'Out of array memory',13,10,0
    arr_bounds_msg  db 'Array index out of bounds',13,10,0
    arr_undef_msg   db 'Array not defined',13,10,0
    
    ; Сообщения для BLOAD/BSAVE (Phase 17: Binary I/O)
    bload_ok_msg    db 'BLOAD OK',13,10,0
    bsave_ok_msg    db 'BSAVE OK',13,10,0
    bload_err_msg   db 'BLOAD error: cannot open file',13,10,0
    bsave_err_msg   db 'BSAVE error: cannot write file',13,10,0
    bio_syntax_msg  db 'Syntax error in BLOAD/BSAVE',13,10,0
    
    ; Сообщения для MATMUL/VRELU (Phase 18: Tensor Ops)
    matmul_ok_msg   db 'MATMUL OK',13,10,0
    matmul_err_msg  db 'Syntax error in MATMUL',13,10,0
    vrelu_ok_msg    db 'VRELU OK',13,10,0
    vrelu_err_msg   db 'Syntax error in VRELU',13,10,0
    arradd_ok_msg   db 'ARRADD OK',13,10,0
    arradd_err_msg  db 'Syntax error in ARRADD',13,10,0
    bytes_suffix    db ' bytes',13,10,0
    
    ; Сообщения для MOUSE/SLEEP (Phase 20: Interactive)
    mouse_ok_msg    db 'MOUSE OK',13,10,0
    mouse_err_msg   db 'Syntax error: MOUSE X, Y',13,10,0
    sleep_err_msg   db 'Syntax error: SLEEP ms',13,10,0
    
    ; === Phase 21: Graphics Window messages ===
    gfx_class_name  db 'TitanGfxWindow',0
    gfx_ok_msg      db 'WINDOW OK',13,10,0
    gfx_err_msg     db 'Syntax error: WINDOW w, h, "title"',13,10,0
    gfx_fail_msg    db 'Window creation failed',13,10,0
    gfx_reg_ok      db '[DEBUG] RegisterClass OK',13,10,0
    gfx_reg_err     db '[DEBUG] RegisterClass FAILED, err=',0
    gfx_create_ok   db '[DEBUG] CreateWindow OK, hwnd=',0
    pset_ok_msg     db 0                 ; No output for PSET (fast loop)
    pset_err_msg    db 'Syntax error: PSET x, y, color',13,10,0
    update_ok_msg   db 0                 ; No output for UPDATE
    wcls_ok_msg     db 0                 ; No output for WCLS
    capture_err_msg db 'Syntax error: CAPTURE arrayname',13,10,0
    downsample_err_msg db 'Syntax error: DOWNSAMPLE x,y,w,h,arr,scale',13,10,0
    gprint_err_msg  db 'Syntax error: GPRINT x, y, "text", color, scale',13,10,0
    
    ; Сообщения для GOTO/IF (Phase 5)
    goto_err_msg    db 'Line not found',13,10,0
    if_err_msg      db 'Syntax error in IF',13,10,0
    
    ; Сообщения для FOR/NEXT (Phase 6)
    for_err_msg     db 'Syntax error in FOR',13,10,0
    next_err_msg    db 'NEXT without FOR',13,10,0
    
    ; Сообщения для GOSUB/RETURN (Phase 10)
    gosub_err_msg   db 'Syntax error in GOSUB',13,10,0
    return_err_msg  db 'RETURN without GOSUB',13,10,0
    
    ; Сообщения для INPUT (Phase 8)
    input_prompt    db '? ',0
    input_err_msg   db 'Syntax error in INPUT',13,10,0
    
    ; Сообщения для SAVE/LOAD (Phase 8)
    save_ok_msg     db 'Program saved',13,10,0
    save_err_msg    db 'Error saving file',13,10,0
    load_ok_msg     db 'Program loaded',13,10,0
    load_err_msg    db 'Error loading file',13,10,0
    
    ; Magic Header для .ttn файлов (Phase 8.1: Rebranding)
    file_magic      db 'TITAN',0            ; 6 байт: "TITAN" + null
    MAGIC_LEN       = 6
    bad_format_msg  db 'Error: Not a valid .ttn file!',13,10,0
    
    ; Сообщения Crash Handler
    crash_header    db 13,10,'!!! TITAN CRASH HANDLER !!!',13,10,0
    crash_access    db 'Access Violation (SIGSEGV)',13,10,0
    crash_divzero   db 'Division by Zero (SIGFPE)',13,10,0
    crash_illegal   db 'Illegal Instruction',13,10,0
    crash_unknown   db 'Unknown Exception: 0x',0
    crash_addr      db 'Address: 0x',0
    crash_continue  db 'Exiting safely...',13,10,13,10,0
    crash_test_msg  db '[Testing crash handler...]',13,10,0
    
    ; Сообщения SIMD (Phase 9)
    simd_avx2_yes   db '[SIMD: AVX2 enabled]',13,10,0
    simd_avx2_no    db '[SIMD: AVX2 not available - scalar mode]',13,10,0
    simd_vdim_msg   db 'Vector declared',13,10,0
    simd_err_msg    db 'SIMD error: AVX2 required',13,10,0
    simd_vset_err   db 'Syntax error in VSET',13,10,0
    simd_vadd_err   db 'Syntax error in VADD',13,10,0
    simd_vsub_err   db 'Syntax error in VSUB',13,10,0
    simd_vmul_err   db 'Syntax error in VMUL',13,10,0
    timer_err_msg   db 'Syntax error in TIMER',13,10,0
    
    ; === Phase 12: Functions ===
    func_enter_msg  db '[FUNC: Frame created]',13,10,0
    func_exit_msg   db '[ENDFUNC: Frame destroyed]',13,10,0
    func_err_msg    db 'Syntax error in FUNC',13,10,0
    endfunc_err_msg db 'ENDFUNC without FUNC',13,10,0
    local_err_msg   db 'LOCAL outside function',13,10,0
    local_decl_msg  db 'Local var declared',13,10,0
    local_write_msg db '[DBG: Local write]',13,10,0
    
    ; Названия ключевых слов для вывода
    kw_names:
        dq kw_print, kw_input, kw_cls, kw_let, kw_dim
        dq kw_goto, kw_if, kw_then, kw_else, kw_gosub
        dq kw_return, kw_end, kw_stop, kw_for, kw_to
        dq kw_step, kw_next, kw_while, kw_wend, kw_data
        dq kw_read, kw_restore, kw_and, kw_or, kw_not
        dq kw_run, kw_list, kw_new, kw_save, kw_load
        dq kw_exit_str, kw_help, kw_dump, kw_vars, kw_regs
        dq kw_rem
    
    kw_print    db 'PRINT',0
    kw_input    db 'INPUT',0
    kw_cls      db 'CLS',0
    kw_let      db 'LET',0
    kw_dim      db 'DIM',0
    kw_goto     db 'GOTO',0
    kw_if       db 'IF',0
    kw_then     db 'THEN',0
    kw_else     db 'ELSE',0
    kw_gosub    db 'GOSUB',0
    kw_return   db 'RETURN',0
    kw_end      db 'END',0
    kw_stop     db 'STOP',0
    kw_for      db 'FOR',0
    kw_to       db 'TO',0
    kw_step     db 'STEP',0
    kw_next     db 'NEXT',0
    kw_while    db 'WHILE',0
    kw_wend     db 'WEND',0
    kw_data     db 'DATA',0
    kw_read     db 'READ',0
    kw_restore  db 'RESTORE',0
    kw_and      db 'AND',0
    kw_or       db 'OR',0
    kw_not      db 'NOT',0
    kw_run      db 'RUN',0
    kw_list     db 'LIST',0
    kw_new      db 'NEW',0
    kw_save     db 'SAVE',0
    kw_load     db 'LOAD',0
    kw_exit_str db 'EXIT',0
    kw_help     db 'HELP',0
    kw_dump     db 'DUMP',0
    kw_vars     db 'VARS',0
    kw_regs     db 'REGS',0
    kw_rem      db 'REM',0
    
    ; Названия операторов
    op_names:
        dq op_plus, op_minus, op_mul, op_div, op_power
        dq op_eq, op_lt, op_gt, op_le, op_ge
        dq op_ne, op_lparen, op_rparen, op_comma, op_semi
        dq op_colon
    
    op_plus     db '+',0
    op_minus    db '-',0
    op_mul      db '*',0
    op_div      db '/',0
    op_power    db '^',0
    op_eq       db '=',0
    op_lt       db '<',0
    op_gt       db '>',0
    op_le       db '<=',0
    op_ge       db '>=',0
    op_ne       db '<>',0
    op_lparen   db '(',0
    op_rparen   db ')',0
    op_comma    db ',',0
    op_semi     db ';',0
    op_colon    db ':',0

    ; Таблица ключевых слов для лексера
    keywords_table:
        db 5, 'PRINT', KW_PRINT
        db 5, 'INPUT', KW_INPUT
        db 3, 'CLS',   KW_CLS
        db 3, 'LET',   KW_LET
        db 3, 'DIM',   KW_DIM
        db 4, 'GOTO',  KW_GOTO
        db 2, 'IF',    KW_IF
        db 4, 'THEN',  KW_THEN
        db 4, 'ELSE',  KW_ELSE
        db 5, 'GOSUB', KW_GOSUB
        db 6, 'RETURN',KW_RETURN
        db 3, 'END',   KW_END
        db 4, 'STOP',  KW_STOP
        db 3, 'FOR',   KW_FOR
        db 2, 'TO',    KW_TO
        db 4, 'STEP',  KW_STEP
        db 4, 'NEXT',  KW_NEXT
        db 5, 'WHILE', KW_WHILE
        db 4, 'WEND',  KW_WEND
        db 4, 'DATA',  KW_DATA
        db 4, 'READ',  KW_READ
        db 7, 'RESTORE', KW_RESTORE
        db 3, 'AND',   KW_AND
        db 2, 'OR',    KW_OR
        db 3, 'NOT',   KW_NOT
        db 3, 'RUN',   KW_RUN
        db 4, 'LIST',  KW_LIST
        db 3, 'NEW',   KW_NEW
        db 4, 'SAVE',  KW_SAVE
        db 4, 'LOAD',  KW_LOAD
        db 4, 'EXIT',  KW_EXIT
        db 4, 'QUIT',  KW_EXIT
        db 3, 'BYE',   KW_EXIT
        db 4, 'HELP',  KW_HELP
        db 4, 'DUMP',  KW_DUMP
        db 4, 'VARS',  KW_VARS
        db 4, 'REGS',  KW_REGS
        db 3, 'REM',   KW_REM
        db 5, 'CRASH', KW_CRASH
        ; === SIMD keywords (Phase 9) ===
        db 4, 'VDIM',  KW_VDIM
        db 4, 'VSET',  KW_VSET
        db 4, 'VADD',  KW_VADD
        db 4, 'VSUB',  KW_VSUB
        db 4, 'VMUL',  KW_VMUL
        db 6, 'VPRINT',KW_VPRINT
        ; === Phase 11: Benchmarks ===
        db 5, 'TIMER', KW_TIMER
        ; === Phase 12: Local Variables ===
        db 4, 'FUNC',    KW_FUNC
        db 7, 'ENDFUNC', KW_ENDFUNC
        db 5, 'LOCAL',   KW_LOCAL
        ; === Phase 13: FFI ===
        db 8, 'TEST_GUI', KW_TEST_GUI
        db 7, 'DECLARE', KW_DECLARE
        db 6, 'MSGBOX', KW_MSGBOX
        db 3, 'LIB', KW_LIB
        db 5, 'ALIAS', KW_ALIAS
        ; === Phase 17: Binary File I/O ===
        db 5, 'BLOAD', KW_BLOAD
        db 5, 'BSAVE', KW_BSAVE
        ; === Phase 18: Tensor Operations ===
        db 6, 'MATMUL', KW_MATMUL
        db 5, 'VRELU', KW_VRELU
        ; === Phase 20: Interactive Input ===
        db 5, 'MOUSE', KW_MOUSE
        db 7, 'KEYDOWN', KW_KEYDOWN
        db 5, 'SLEEP', KW_SLEEP
        ; === Phase 21: Graphics Window ===
        db 6, 'WINDOW', KW_WINDOW
        db 4, 'PSET', KW_PSET
        db 6, 'UPDATE', KW_UPDATE
        db 4, 'WCLS', KW_WCLS
        ; === Phase 22: Vision (Neural Eye) ===
        db 7, 'CAPTURE', KW_CAPTURE
        ; === Phase 23: The Lens ===
        db 10, 'DOWNSAMPLE', KW_DOWNSAMPLE
        ; === Phase 23b: Array Operations ===
        db 6, 'ARRADD', KW_ARRADD
        ; === Phase 24: The Voice (Bitmap Fonts) ===
        db 6, 'GPRINT', KW_GPRINT
        db 0  ; Конец таблицы

; ============================================================================
; Phase 24: 8x8 Bitmap Font (ASCII 32-127)
; Each character is 8 bytes, each byte is one row of 8 pixels
; ============================================================================
    align 8
    font8x8:
    ; Space (32)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ; ! (33)
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00
    ; " (34)
    db 0x6C, 0x6C, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00
    ; # (35)
    db 0x6C, 0x6C, 0xFE, 0x6C, 0xFE, 0x6C, 0x6C, 0x00
    ; $ (36)
    db 0x18, 0x7E, 0xC0, 0x7C, 0x06, 0xFC, 0x18, 0x00
    ; % (37)
    db 0x00, 0xC6, 0xCC, 0x18, 0x30, 0x66, 0xC6, 0x00
    ; & (38)
    db 0x38, 0x6C, 0x38, 0x76, 0xDC, 0xCC, 0x76, 0x00
    ; ' (39)
    db 0x18, 0x18, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00
    ; ( (40)
    db 0x0C, 0x18, 0x30, 0x30, 0x30, 0x18, 0x0C, 0x00
    ; ) (41)
    db 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x18, 0x30, 0x00
    ; * (42)
    db 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00
    ; + (43)
    db 0x00, 0x18, 0x18, 0x7E, 0x18, 0x18, 0x00, 0x00
    ; , (44)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x30
    ; - (45)
    db 0x00, 0x00, 0x00, 0x7E, 0x00, 0x00, 0x00, 0x00
    ; . (46)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00
    ; / (47)
    db 0x06, 0x0C, 0x18, 0x30, 0x60, 0xC0, 0x80, 0x00
    ; 0 (48)
    db 0x7C, 0xC6, 0xCE, 0xDE, 0xF6, 0xE6, 0x7C, 0x00
    ; 1 (49)
    db 0x18, 0x38, 0x78, 0x18, 0x18, 0x18, 0x7E, 0x00
    ; 2 (50)
    db 0x7C, 0xC6, 0x06, 0x1C, 0x30, 0x66, 0xFE, 0x00
    ; 3 (51)
    db 0x7C, 0xC6, 0x06, 0x3C, 0x06, 0xC6, 0x7C, 0x00
    ; 4 (52)
    db 0x1C, 0x3C, 0x6C, 0xCC, 0xFE, 0x0C, 0x1E, 0x00
    ; 5 (53)
    db 0xFE, 0xC0, 0xC0, 0xFC, 0x06, 0xC6, 0x7C, 0x00
    ; 6 (54)
    db 0x38, 0x60, 0xC0, 0xFC, 0xC6, 0xC6, 0x7C, 0x00
    ; 7 (55)
    db 0xFE, 0xC6, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00
    ; 8 (56)
    db 0x7C, 0xC6, 0xC6, 0x7C, 0xC6, 0xC6, 0x7C, 0x00
    ; 9 (57)
    db 0x7C, 0xC6, 0xC6, 0x7E, 0x06, 0x0C, 0x78, 0x00
    ; : (58)
    db 0x00, 0x18, 0x18, 0x00, 0x00, 0x18, 0x18, 0x00
    ; ; (59)
    db 0x00, 0x18, 0x18, 0x00, 0x00, 0x18, 0x18, 0x30
    ; < (60)
    db 0x0C, 0x18, 0x30, 0x60, 0x30, 0x18, 0x0C, 0x00
    ; = (61)
    db 0x00, 0x00, 0x7E, 0x00, 0x00, 0x7E, 0x00, 0x00
    ; > (62)
    db 0x60, 0x30, 0x18, 0x0C, 0x18, 0x30, 0x60, 0x00
    ; ? (63)
    db 0x7C, 0xC6, 0x0C, 0x18, 0x18, 0x00, 0x18, 0x00
    ; @ (64)
    db 0x7C, 0xC6, 0xDE, 0xDE, 0xDE, 0xC0, 0x78, 0x00
    ; A (65)
    db 0x38, 0x6C, 0xC6, 0xC6, 0xFE, 0xC6, 0xC6, 0x00
    ; B (66)
    db 0xFC, 0x66, 0x66, 0x7C, 0x66, 0x66, 0xFC, 0x00
    ; C (67)
    db 0x3C, 0x66, 0xC0, 0xC0, 0xC0, 0x66, 0x3C, 0x00
    ; D (68)
    db 0xF8, 0x6C, 0x66, 0x66, 0x66, 0x6C, 0xF8, 0x00
    ; E (69)
    db 0xFE, 0x62, 0x68, 0x78, 0x68, 0x62, 0xFE, 0x00
    ; F (70)
    db 0xFE, 0x62, 0x68, 0x78, 0x68, 0x60, 0xF0, 0x00
    ; G (71)
    db 0x3C, 0x66, 0xC0, 0xC0, 0xCE, 0x66, 0x3A, 0x00
    ; H (72)
    db 0xC6, 0xC6, 0xC6, 0xFE, 0xC6, 0xC6, 0xC6, 0x00
    ; I (73)
    db 0x3C, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00
    ; J (74)
    db 0x1E, 0x0C, 0x0C, 0x0C, 0xCC, 0xCC, 0x78, 0x00
    ; K (75)
    db 0xE6, 0x66, 0x6C, 0x78, 0x6C, 0x66, 0xE6, 0x00
    ; L (76)
    db 0xF0, 0x60, 0x60, 0x60, 0x62, 0x66, 0xFE, 0x00
    ; M (77)
    db 0xC6, 0xEE, 0xFE, 0xFE, 0xD6, 0xC6, 0xC6, 0x00
    ; N (78)
    db 0xC6, 0xE6, 0xF6, 0xDE, 0xCE, 0xC6, 0xC6, 0x00
    ; O (79)
    db 0x7C, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0x7C, 0x00
    ; P (80)
    db 0xFC, 0x66, 0x66, 0x7C, 0x60, 0x60, 0xF0, 0x00
    ; Q (81)
    db 0x7C, 0xC6, 0xC6, 0xC6, 0xD6, 0xDE, 0x7C, 0x06
    ; R (82)
    db 0xFC, 0x66, 0x66, 0x7C, 0x6C, 0x66, 0xE6, 0x00
    ; S (83)
    db 0x7C, 0xC6, 0x60, 0x38, 0x0C, 0xC6, 0x7C, 0x00
    ; T (84)
    db 0x7E, 0x5A, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00
    ; U (85)
    db 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0x7C, 0x00
    ; V (86)
    db 0xC6, 0xC6, 0xC6, 0xC6, 0x6C, 0x38, 0x10, 0x00
    ; W (87)
    db 0xC6, 0xC6, 0xD6, 0xFE, 0xFE, 0xEE, 0xC6, 0x00
    ; X (88)
    db 0xC6, 0xC6, 0x6C, 0x38, 0x6C, 0xC6, 0xC6, 0x00
    ; Y (89)
    db 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x3C, 0x00
    ; Z (90)
    db 0xFE, 0xC6, 0x8C, 0x18, 0x32, 0x66, 0xFE, 0x00
    ; [ (91)
    db 0x3C, 0x30, 0x30, 0x30, 0x30, 0x30, 0x3C, 0x00
    ; \ (92)
    db 0xC0, 0x60, 0x30, 0x18, 0x0C, 0x06, 0x02, 0x00
    ; ] (93)
    db 0x3C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x3C, 0x00
    ; ^ (94)
    db 0x10, 0x38, 0x6C, 0xC6, 0x00, 0x00, 0x00, 0x00
    ; _ (95)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF
    ; ` (96)
    db 0x30, 0x18, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00
    ; a (97)
    db 0x00, 0x00, 0x78, 0x0C, 0x7C, 0xCC, 0x76, 0x00
    ; b (98)
    db 0xE0, 0x60, 0x7C, 0x66, 0x66, 0x66, 0xDC, 0x00
    ; c (99)
    db 0x00, 0x00, 0x7C, 0xC6, 0xC0, 0xC6, 0x7C, 0x00
    ; d (100)
    db 0x1C, 0x0C, 0x7C, 0xCC, 0xCC, 0xCC, 0x76, 0x00
    ; e (101)
    db 0x00, 0x00, 0x7C, 0xC6, 0xFE, 0xC0, 0x7C, 0x00
    ; f (102)
    db 0x38, 0x6C, 0x60, 0xF8, 0x60, 0x60, 0xF0, 0x00
    ; g (103)
    db 0x00, 0x00, 0x76, 0xCC, 0xCC, 0x7C, 0x0C, 0x78
    ; h (104)
    db 0xE0, 0x60, 0x6C, 0x76, 0x66, 0x66, 0xE6, 0x00
    ; i (105)
    db 0x18, 0x00, 0x38, 0x18, 0x18, 0x18, 0x3C, 0x00
    ; j (106)
    db 0x06, 0x00, 0x0E, 0x06, 0x06, 0x66, 0x66, 0x3C
    ; k (107)
    db 0xE0, 0x60, 0x66, 0x6C, 0x78, 0x6C, 0xE6, 0x00
    ; l (108)
    db 0x38, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00
    ; m (109)
    db 0x00, 0x00, 0xEC, 0xFE, 0xD6, 0xD6, 0xD6, 0x00
    ; n (110)
    db 0x00, 0x00, 0xDC, 0x66, 0x66, 0x66, 0x66, 0x00
    ; o (111)
    db 0x00, 0x00, 0x7C, 0xC6, 0xC6, 0xC6, 0x7C, 0x00
    ; p (112)
    db 0x00, 0x00, 0xDC, 0x66, 0x66, 0x7C, 0x60, 0xF0
    ; q (113)
    db 0x00, 0x00, 0x76, 0xCC, 0xCC, 0x7C, 0x0C, 0x1E
    ; r (114)
    db 0x00, 0x00, 0xDC, 0x76, 0x60, 0x60, 0xF0, 0x00
    ; s (115)
    db 0x00, 0x00, 0x7E, 0xC0, 0x7C, 0x06, 0xFC, 0x00
    ; t (116)
    db 0x30, 0x30, 0xFC, 0x30, 0x30, 0x36, 0x1C, 0x00
    ; u (117)
    db 0x00, 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0x76, 0x00
    ; v (118)
    db 0x00, 0x00, 0xC6, 0xC6, 0xC6, 0x6C, 0x38, 0x00
    ; w (119)
    db 0x00, 0x00, 0xC6, 0xD6, 0xD6, 0xFE, 0x6C, 0x00
    ; x (120)
    db 0x00, 0x00, 0xC6, 0x6C, 0x38, 0x6C, 0xC6, 0x00
    ; y (121)
    db 0x00, 0x00, 0xC6, 0xC6, 0xC6, 0x7E, 0x06, 0x7C
    ; z (122)
    db 0x00, 0x00, 0xFE, 0x8C, 0x18, 0x32, 0xFE, 0x00
    ; { (123)
    db 0x0E, 0x18, 0x18, 0x70, 0x18, 0x18, 0x0E, 0x00
    ; | (124)
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00
    ; } (125)
    db 0x70, 0x18, 0x18, 0x0E, 0x18, 0x18, 0x70, 0x00
    ; ~ (126)
    db 0x76, 0xDC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ; DEL (127) - block
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

; ----------------------------------------------------------------------------
; BSS (неинициализированные данные)
; ----------------------------------------------------------------------------
section '.bss' data readable writeable

    ; Платформо-зависимые переменные
    stdin_handle    dq ?
    stdout_handle   dq ?
    bytes_written   dd ?
    bytes_read      dd ?
    
    ; Временные переменные для BLOAD/BSAVE (Phase 17)
    bload_filename  dq ?
    bload_buffer    dq ?
    bload_size      dd ?
    bload_handle    dq ?
    bsave_filename  dq ?
    bsave_buffer    dq ?
    bsave_size      dd ?
    bsave_handle    dq ?
    
    ; Autorun: буфер для пути к файлу из командной строки
    file_path_buffer rb 512         ; Максимум 512 символов для пути
    
    ; Данные для MOUSE (Phase 20)
    mouse_point     rq 1            ; POINT structure (X, Y as DWORDs)
    
    ; === Phase 21: Graphics Window ===
    gfx_hwnd        dq ?            ; Window handle (HWND)
    gfx_hdc         dq ?            ; Device context (HDC)
    gfx_buffer      dq ?            ; Framebuffer pointer (ARGB pixels)
    gfx_width       dd ?            ; Window width
    gfx_height      dd ?            ; Window height
    gfx_active      db ?            ; 1 if window is active
    
    ; Window title buffer
    gfx_title       rb 128          ; Title string
    
    ; WNDCLASS structure (aligned, 80 bytes for safety)
    align 8
    gfx_wndclass    rb 80           ; WNDCLASSA structure
    
    ; MSG structure for PeekMessage (48 bytes)
    align 8
    gfx_msg         rb 48           ; MSG structure
    
    ; BITMAPINFO structure for SetDIBitsToDevice (44 bytes header + colors)
    align 8
    gfx_bmpinfo     rb 64           ; BITMAPINFO structure
    
    ; RECT structure for AdjustWindowRect
    gfx_rect        rb 16           ; RECT structure (4 DWORDs)
    
    ; Mouse state from window messages
    gfx_mouse_x     dd ?
    gfx_mouse_y     dd ?
    gfx_mouse_btn   dd ?            ; 1=left button down
    
    ; Буферы
    input_buffer    rb INPUT_BUFFER_SIZE
    
    ; Данные лексера
    lexer_pos       dq ?
    lexer_error     db ?
    
    ; Текущий токен
    current_token   rb TOKEN_SIZE
    
    ; Флаг: токен был "отложен" (peek back)
    token_pushed    db ?
    
    ; Флаг: первый токен в строке
    first_token     db ?
    
    ; Буфер для числа
    num_buffer      rb 24
    
    ; Буфер для имени файла (SAVE/LOAD)
    file_buffer     rb 256
    
    ; JIT буфер
    jit_buffer      dq ?            ; Указатель на JIT память
    jit_pos         dq ?            ; Текущая позиция в JIT буфере
    
    ; Временные переменные для JIT
    jit_str_ptr     dq ?            ; Указатель на строку для PRINT
    jit_str_len     dd ?            ; Длина строки для PRINT
    
    ; Переменные A-Z (26 штук по 8 байт = 208 байт)
    variables       rq 26           ; vars[0]=A, vars[1]=B, ... vars[25]=Z
    
    ; === Phase 15: Типы переменных (Float support) ===
    ; Типы переменных A-Z: 0 = INT64, 1 = DOUBLE
    var_types       rb 26           ; 26 байт (по 1 на переменную)
    
    ; Временные переменные для float-арифметики
    float_temp      dq ?            ; Временное хранилище для float
    float_mode      db ?            ; 1 = текущее выражение в режиме float
    
    ; === Phase 5: Управление потоком ===
    ; Таблица строк программы: [номер_строки(4), смещение_в_буфере(4)] × 1000
    ; Максимум 1000 строк, 8 байт на запись = 8000 байт
    line_table      rb 8000
    line_count      dd ?            ; Количество строк в программе
    
    ; Буфер программы: хранит текст строк (64KB)
    program_buffer  rb 65536
    program_pos     dq ?            ; Текущая позиция в буфере программы
    
    ; Режим выполнения: 0 = REPL (интерактив), 1 = RUN (программа)
    run_mode        db ?
    current_line    dd ?            ; Текущая исполняемая строка (при RUN)
    
    ; Autorun: флаг автозапуска при передаче файла через командную строку
    autorun_flag    db ?            ; 1 = нужно автозапустить после загрузки
    
    ; Указатель на текущую строку для выполнения
    exec_ptr        dq ?
    
    ; === Phase 6: Стек циклов FOR/NEXT ===
    ; Формат фрейма (32 байта):
    ;   [0-7]   = Индекс переменной-счётчика (0-25)
    ;   [8-15]  = Значение Limit (TO)
    ;   [16-23] = Индекс строки в line_table для возврата
    ;   [24-31] = Значение Step (STEP)
    loop_stack      rb 512          ; 16 фреймов × 32 байта = 512 байт
    loop_stack_ptr  dq ?            ; Указатель на верхушку стека
    
    ; === Phase 7: String Arena ===
    ; Строковые переменные A$-Z$ (26 штук по 16 байт = 416 байт)
    ; Формат: [PTR (8 байт)][LEN (8 байт)]
    str_vars        rb 416          ; 26 × 16 = 416 байт
    
    ; Арена для хранения строк (64 KB)
    string_heap     rb 65536        ; Linear allocator
    heap_ptr        dq ?            ; Указатель на свободное место
    
    ; === Phase 9: SIMD (AVX2) ===
    cpu_has_avx2    db ?            ; 1 = AVX2 supported, 0 = no
    
    ; Векторные переменные V0-V9 (10 штук по 32 байта = 320 байт)
    ; Должны быть выровнены по 32 байта для AVX
    align 32
    vector_vars     rb 320          ; 10 vectors × 32 bytes (YMM)
    
    ; === Phase 10: Call Stack (GOSUB/RETURN) ===
    ; Стек адресов возврата: [line_index (4 байта)] × 64 уровней
    call_stack      rb 256          ; 64 × 4 байта = 256 байт
    call_stack_ptr  dq ?            ; Указатель на верхушку стека

    ; === Phase 12: Local Variables (Stack Frames) ===
    current_scope   db ?            ; 0 = Global, 1+ = Depth inside Functions
    local_vars_cnt  db ?            ; Количество локальных переменных (0..8)
    ; Таблица локальных переменных: [var_index (1 byte)][offset (1 byte)] × 8
    ; Для MVP: однобуквенные A-Z, offset = -(index+1)*8 от RBP
    local_var_map   rb 16           ; 8 локальных × 2 байта
    func_rbp_saved  dq ?            ; Указатель на текущий фрейм локальных переменных
    
    ; === Phase 12.3: Стек контекстов для рекурсии ===
    ; Каждый контекст: [rbp_saved(8) + local_vars_cnt(1) + local_var_map(16)] = 25 байт → 32 для выравнивания
    func_context_stack  rb 32 * 16  ; Стек на 16 уровней вложенности
    func_stack_ptr      dq ?        ; Указатель на текущую позицию в стеке
    
    ; === Phase 12.4: Статическая память для локальных переменных ===
    ; 16 уровней вложенности × 8 переменных × 8 байт = 1024 байта
    local_vars_storage  rb 64 * 16  ; Хранилище локальных переменных
    
    ; === Phase 13: FFI Table (Foreign Function Interface) ===
    ; Таблица импортированных функций (максимум 32 записи)
    ; Структура записи (32 байта):
    ;   [0-7]   = Name Hash (хеш имени функции в TITAN, например "BEEP")
    ;   [8-15]  = Function Address (адрес от GetProcAddress)
    ;   [16-23] = DLL Handle (HMODULE от LoadLibraryA)
    ;   [24-31] = Arg Count (количество аргументов)
    FFI_ENTRY_SIZE = 32
    FFI_MAX_ENTRIES = 32
    ffi_table       rb FFI_ENTRY_SIZE * FFI_MAX_ENTRIES  ; 32 × 32 = 1024 байта
    ffi_count       dq ?            ; Количество записей в таблице
    
    ; Временные буферы для DECLARE
    dll_name_buf    rb 128          ; Имя DLL (с null-terminator)
    func_name_buf   rb 128          ; Имя функции в DLL
    titan_name_buf  rb 64           ; Имя функции в TITAN
    titan_name_hash dq ?            ; Хеш имени для поиска
    
    ; Буферы для FFI вызовов в parse_factor (Phase 14.1)
    ffi_call_addr   dq ?            ; Адрес вызываемой функции
    ffi_arg_count   dd ?            ; Количество аргументов
    ffi_args        rq 4            ; До 4 аргументов
    factor_var_name dq ?            ; Указатель на имя переменной

    ; === Phase 16: Arrays (Memory Grid) ===
    ; Таблица массивов A()-Z() (26 записей по 16 байт = 416 байт)
    ; Структура записи:
    ;   [0-7]   = Pointer to data (0 = not allocated)
    ;   [8-15]  = Size (number of elements)
    ARRAY_ENTRY_SIZE = 16
    array_table     rb ARRAY_ENTRY_SIZE * 26    ; 26 массивов × 16 байт
    
    ; Heap для данных массивов (1 MB)
    ; Массивы выделяются последовательно из этого блока
    ARRAY_HEAP_SIZE = 1048576       ; 1 MB
    array_heap      rb ARRAY_HEAP_SIZE
    array_heap_ptr  dq ?            ; Указатель на свободное место
    
    ; Временные переменные для работы с массивами
    array_index_var dd ?            ; Индекс переменной массива (0-25)
    array_index_val dq ?            ; Вычисленный индекс элемента

; ----------------------------------------------------------------------------
; Код
; ----------------------------------------------------------------------------
section '.text' code readable executable

start:
    sub rsp, 40
    
    ; === Установка Crash Handler ===
    lea rcx, [crash_handler]
    call [SetUnhandledExceptionFilter]
    ; Старый обработчик в RAX (игнорируем)
    
    ; === Инициализация платформы ===
    mov ecx, STD_OUTPUT_HANDLE
    call [GetStdHandle]
    mov [stdout_handle], rax
    
    mov ecx, STD_INPUT_HANDLE
    call [GetStdHandle]
    mov [stdin_handle], rax
    
    ; === Выделение JIT памяти ===
    xor ecx, ecx                        ; lpAddress = NULL
    mov edx, JIT_BUFFER_SIZE            ; dwSize = 4096
    mov r8d, MEM_COMMIT or MEM_RESERVE  ; flAllocationType
    mov r9d, PAGE_EXECUTE_READWRITE     ; flProtect
    call [VirtualAlloc]
    test rax, rax
    jz .jit_alloc_failed
    mov [jit_buffer], rax
    mov [jit_pos], rax                  ; jit_pos = начало буфера
    jmp .jit_alloc_ok
    
.jit_alloc_failed:
    lea rdx, [err_jit_alloc]
    mov r8d, err_jit_alloc_len
    call print_string
    jmp exit_program
    
.jit_alloc_ok:
    ; === Инициализация String Arena ===
    lea rax, [string_heap]
    mov [heap_ptr], rax
    
    ; === Инициализация Call Stack (Phase 10) ===
    lea rax, [call_stack]
    mov [call_stack_ptr], rax
    
    ; === Инициализация Function Context Stack (Phase 12.3) ===
    lea rax, [func_context_stack]
    mov [func_stack_ptr], rax
    mov byte [current_scope], 0
    mov byte [local_vars_cnt], 0
    
    ; === Инициализация FFI таблицы (Phase 13) ===
    mov qword [ffi_count], 0
    
    ; === Инициализация Array Heap (Phase 16) ===
    lea rax, [array_heap]
    mov [array_heap_ptr], rax
    ; Обнуляем таблицу массивов (все указатели = 0)
    lea rdi, [array_table]
    xor eax, eax
    mov ecx, ARRAY_ENTRY_SIZE * 26 / 8  ; 416 / 8 = 52 qwords
    rep stosq
    
    ; === Проверка поддержки AVX2 (Phase 9) ===
    call check_cpu_features
    mov [cpu_has_avx2], al
    
    ; Выводим баннер
    lea rdx, [banner]
    mov r8d, banner_len
    call print_string
    
    ; Выводим статус SIMD
    cmp byte [cpu_has_avx2], 1
    jne .no_avx2_msg
    lea rdx, [simd_avx2_yes]
    call print_cstring
    jmp .simd_msg_done
.no_avx2_msg:
    lea rdx, [simd_avx2_no]
    call print_cstring
.simd_msg_done:

    ; Прыжок к repl_loop
    jmp repl_loop

; ============================================================================
; Phase 21: Graphics Window System - WindowProc Callback
; ПРИМЕЧАНИЕ: Эта функция находится ВНЕ repl_loop чтобы не ломать scope
; ============================================================================

; ----------------------------------------------------------------------------
; WindowProc - Callback для обработки сообщений окна
; Параметры: rcx=hwnd, rdx=uMsg, r8=wParam, r9=lParam
; ----------------------------------------------------------------------------
WindowProc:
    push rbp
    mov rbp, rsp
    sub rsp, 64                     ; Shadow space + locals
    
    ; Сохраняем параметры
    mov [rbp-8], rcx                ; hwnd
    mov [rbp-16], rdx               ; uMsg
    mov [rbp-24], r8                ; wParam
    mov [rbp-32], r9                ; lParam
    
    ; WM_CLOSE = 0x10
    cmp edx, 0x10
    je .wndproc_close
    
    ; WM_MOUSEMOVE = 0x200
    cmp edx, 0x200
    je .wndproc_mousemove
    
    ; WM_LBUTTONDOWN = 0x201
    cmp edx, 0x201
    je .wndproc_lbuttondown
    
    ; WM_LBUTTONUP = 0x202
    cmp edx, 0x202
    je .wndproc_lbuttonup
    
    ; WM_DESTROY = 0x02
    cmp edx, 0x02
    je .wndproc_destroy
    
    ; Default: вызываем DefWindowProcA
    mov rcx, [rbp-8]
    mov rdx, [rbp-16]
    mov r8, [rbp-24]
    mov r9, [rbp-32]
    call [DefWindowProcA]
    jmp .wndproc_return

.wndproc_close:
    ; Закрываем окно
    mov byte [gfx_active], 0
    xor ecx, ecx
    call [PostQuitMessage]
    xor eax, eax
    jmp .wndproc_return

.wndproc_destroy:
    xor ecx, ecx
    call [PostQuitMessage]
    xor eax, eax
    jmp .wndproc_return

.wndproc_mousemove:
    ; lParam содержит координаты: LOWORD=X, HIWORD=Y
    mov rax, [rbp-32]               ; lParam
    movzx ecx, ax                   ; X = LOWORD
    mov [gfx_mouse_x], ecx
    shr eax, 16
    mov [gfx_mouse_y], eax          ; Y = HIWORD
    xor eax, eax
    jmp .wndproc_return

.wndproc_lbuttondown:
    mov dword [gfx_mouse_btn], 1
    ; Также обновляем координаты
    mov rax, [rbp-32]
    movzx ecx, ax
    mov [gfx_mouse_x], ecx
    shr eax, 16
    mov [gfx_mouse_y], eax
    xor eax, eax
    jmp .wndproc_return

.wndproc_lbuttonup:
    mov dword [gfx_mouse_btn], 0
    xor eax, eax
    jmp .wndproc_return

.wndproc_return:
    add rsp, 64
    pop rbp
    ret

; ----------------------------------------------------------------------------
; Главный цикл REPL
; ----------------------------------------------------------------------------
repl_loop:
    ; Выводим prompt
    lea rdx, [prompt]
    mov r8d, prompt_len
    call print_string
    
    ; === Читаем строку побайтово до CR/LF (для корректной работы с pipe) ===
    lea rdi, [input_buffer]
    xor r12d, r12d                  ; r12 = счётчик символов
    
.read_char_loop:
    ; ReadFile(stdin, &char, 1, &bytes_read, NULL)
    mov rcx, [stdin_handle]
    lea rdx, [rdi + r12]            ; Позиция в буфере
    mov r8d, 1                      ; Читаем 1 байт
    lea r9, [bytes_read]
    push 0                          ; lpOverlapped = NULL
    sub rsp, 32
    call [ReadFile]
    add rsp, 40
    
    ; Проверяем на EOF
    mov eax, [bytes_read]
    test eax, eax
    jz .read_eof
    
    ; Проверяем символ
    movzx eax, byte [rdi + r12]
    cmp al, 10                      ; LF?
    je .read_line_done
    cmp al, 13                      ; CR?
    je .read_skip_cr
    
    ; Обычный символ — добавляем
    inc r12d
    cmp r12d, INPUT_BUFFER_SIZE - 2
    jl .read_char_loop
    jmp .read_line_done             ; Буфер полон
    
.read_skip_cr:
    ; Пропускаем CR, ждём LF
    jmp .read_char_loop
    
.read_eof:
    ; EOF — если ничего не прочитали, выходим
    test r12d, r12d
    jz exit_program
    ; Иначе обрабатываем то что есть
    
.read_line_done:
    ; Завершаем строку нулём
    mov byte [rdi + r12], 0
    
    ; Если строка пустая — читаем следующую
    test r12d, r12d
    jz repl_loop
    
    ; Инициализируем лексер
    lea rsi, [input_buffer]
    mov [lexer_pos], rsi
    mov byte [lexer_error], 0
    mov byte [token_pushed], 0      ; Сбрасываем флаг отката токена
    mov byte [first_token], 1       ; Первый токен в строке
    
    ; Читаем и выводим все токены
.tokenize_loop:
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Проверяем тип токена
    cmp al, TOKEN_EOL
    jne .not_eol
    jmp .tokenize_done
.not_eol:
    cmp al, 0
    jne .not_zero
    jmp .tokenize_done
.not_zero:
    
    ; Обрабатываем токен
    cmp al, TOKEN_KEYWORD
    jne .not_keyword
    jmp .handle_keyword
.not_keyword:
    cmp al, TOKEN_NUMBER
    jne .not_number
    jmp .check_line_number
.not_number:
    cmp al, TOKEN_STRING
    jne .not_string
    jmp .handle_string
.not_string:
    cmp al, TOKEN_IDENTIFIER
    jne .not_ident
    jmp .handle_identifier
.not_ident:
    cmp al, TOKEN_OPERATOR
    jne .tokenize_next
    jmp .handle_operator

; Если первый токен - число, это номер строки программы
.check_line_number:
    cmp byte [first_token], 1
    jne .handle_number              ; Не первый токен - обычное число
    
    ; Это номер строки - добавляем в программу
    jmp .add_program_line
    
.tokenize_next:
    mov byte [first_token], 0       ; Больше не первый токен
    jmp .tokenize_loop

.handle_keyword:
    mov byte [first_token], 0       ; Сбрасываем флаг
    ; Проверяем на EXIT
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_EXIT
    je exit_program
    
    ; Проверяем на PRINT
    cmp al, KW_PRINT
    je .jit_print
    
    ; Проверяем на DUMP
    cmp al, KW_DUMP
    je .cmd_dump
    
    ; Проверяем на LET
    cmp al, KW_LET
    je .cmd_let
    
    ; Проверяем на DIM (Phase 16: Arrays)
    cmp al, KW_DIM
    je .cmd_dim
    
    ; Проверяем на VARS
    cmp al, KW_VARS
    je .cmd_vars
    
    ; Проверяем на RUN
    cmp al, KW_RUN
    je .cmd_run
    
    ; Проверяем на LIST
    cmp al, KW_LIST
    je .cmd_list
    
    ; Проверяем на NEW
    cmp al, KW_NEW
    je .cmd_new
    
    ; Проверяем на GOTO
    cmp al, KW_GOTO
    je .cmd_goto
    
    ; Проверяем на IF
    cmp al, KW_IF
    je .cmd_if
    
    ; Проверяем на CRASH (тест crash handler)
    cmp al, KW_CRASH
    je .cmd_crash
    
    ; Проверяем на FOR
    cmp al, KW_FOR
    je .cmd_for
    
    ; Проверяем на NEXT
    cmp al, KW_NEXT
    je .cmd_next
    
    ; Проверяем на INPUT
    cmp al, KW_INPUT
    je .cmd_input
    
    ; Проверяем на SAVE
    cmp al, KW_SAVE
    je .cmd_save
    
    ; Проверяем на LOAD
    cmp al, KW_LOAD
    je .cmd_load
    
    ; === SIMD команды (Phase 9) ===
    cmp al, KW_VDIM
    je .cmd_vdim
    
    cmp al, KW_VSET
    je .cmd_vset
    
    cmp al, KW_VADD
    je .cmd_vadd
    
    cmp al, KW_VSUB
    je .cmd_vsub
    
    cmp al, KW_VMUL
    je .cmd_vmul
    
    cmp al, KW_VPRINT
    je .cmd_vprint
    
    ; Проверяем на REM
    cmp al, KW_REM
    je .cmd_rem

    ; === Phase 11: Benchmarks ===
    cmp al, KW_TIMER
    je .cmd_timer
    
    ; === Phase 12: Local Variables (Stack Frames) ===
    cmp al, KW_FUNC
    je .cmd_func
    
    cmp al, KW_ENDFUNC
    je .cmd_endfunc
    
    cmp al, KW_LOCAL
    je .cmd_local

    ; === Phase 13: FFI ===
    cmp al, KW_TEST_GUI
    je .cmd_test_gui
    
    cmp al, KW_DECLARE
    je .cmd_declare
    
    cmp al, KW_MSGBOX
    je .cmd_msgbox

    ; === Phase 17: Binary File I/O ===
    cmp al, KW_BLOAD
    je .cmd_bload
    
    cmp al, KW_BSAVE
    je .cmd_bsave

    ; === Phase 18: Tensor Operations ===
    cmp al, KW_MATMUL
    je .cmd_matmul
    
    cmp al, KW_VRELU
    je .cmd_vrelu

    ; === Phase 20: Interactive Input ===
    cmp al, KW_MOUSE
    je .cmd_mouse
    
    cmp al, KW_SLEEP
    je .cmd_sleep

    ; === Phase 21: Graphics Window ===
    cmp al, KW_WINDOW
    je .cmd_window
    
    cmp al, KW_PSET
    je .cmd_pset
    
    cmp al, KW_UPDATE
    je .cmd_update
    
    cmp al, KW_WCLS
    je .cmd_wcls
    
    cmp al, KW_CAPTURE
    je .cmd_capture
    
    cmp al, KW_DOWNSAMPLE
    je .cmd_downsample
    
    cmp al, KW_ARRADD
    je .cmd_arradd
    
    cmp al, KW_GPRINT
    je .cmd_gprint

    ; === Phase 10: END/STOP/GOSUB/RETURN ===
    cmp al, KW_END
    je .cmd_end
    
    cmp al, KW_STOP
    je .cmd_end               ; STOP = END в нашей реализации
    
    cmp al, KW_GOSUB
    je .cmd_gosub
    
    cmp al, KW_RETURN
    je .cmd_return
    
    ; Остальные ключевые слова - отладочный вывод
    jmp .print_keyword_debug
    
; ============================================================================
; JIT-компиляция PRINT
; ============================================================================
.jit_print:
    ; Сбрасываем JIT указатель на начало буфера
    mov rax, [jit_buffer]
    mov [jit_pos], rax
    
    ; Получаем следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Проверяем тип токена
    lea rbx, [current_token]
    movzx eax, byte [rbx + TOKEN_TYPE]
    
    cmp al, TOKEN_STRING
    je .print_string
    cmp al, TOKEN_STRING_VAR
    je .print_string_var
    ; Phase 16: Используем parse_expression для чисел, переменных и массивов
    cmp al, TOKEN_IDENTIFIER
    je .print_expression
    cmp al, TOKEN_NUMBER
    je .print_expression
    cmp al, TOKEN_FLOAT
    je .print_expression
    jmp .print_keyword_debug      ; Неизвестный тип

; Phase 16: PRINT через parse_expression (поддержка массивов и выражений)
.print_expression:
    ; Откатываем токен чтобы parse_expression его прочитал
    mov byte [token_pushed], 1
    call parse_expression
    test rcx, rcx
    jz .tokenize_loop             ; Ошибка парсинга
    
    ; Проверяем режим float
    cmp byte [float_mode], 1
    je .print_expr_float
    
    ; Integer output
    call print_number
    call print_maybe_newline
    jmp .tokenize_loop

.print_expr_float:
    ; Float output - RAX содержит битовый паттерн double
    call print_float
    call print_maybe_newline
    jmp .tokenize_loop

; --- PRINT строковой переменной A$ ---
.print_string_var:
    ; Получаем индекс переменной
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx eax, byte [rax]
    cmp al, 'a'
    jl .print_strvar_upper
    sub al, 32
.print_strvar_upper:
    sub al, 'A'
    cmp al, 25
    ja .print_keyword_debug
    
    ; Получаем PTR и LEN из str_vars
    movzx eax, al
    shl eax, 4                      ; * 16
    lea rbx, [str_vars]
    mov rdx, qword [rbx + rax]      ; PTR
    mov r8, qword [rbx + rax + 8]   ; LEN
    
    ; Выводим строку
    test rdx, rdx
    jz .print_strvar_empty
    test r8, r8
    jz .print_strvar_empty
    
    call print_string
    call print_maybe_newline
    jmp .tokenize_loop
    
.print_strvar_empty:
    ; Пустая строка - просто проверяем ; и newline
    call print_maybe_newline
    jmp .tokenize_loop

; --- PRINT числовой переменной ---
.print_variable:
    ; Получаем имя переменной
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx eax, byte [rax]
    cmp al, 'a'
    jl .print_var_upper
    sub al, 32
.print_var_upper:
    sub al, 'A'
    cmp al, 25
    ja .print_keyword_debug
    
    ; === Phase 12.2: Проверяем — локальная или глобальная переменная ===
    movzx r12d, al                  ; R12 = индекс переменной
    call lookup_variable            ; CF=1 локальная (AL=offset), CF=0 глобальная
    jnc .print_var_global
    
    ; --- Локальная переменная ---
    movzx eax, al                   ; Zero-extend offset
    mov rbx, [func_rbp_saved]
    mov rax, qword [rbx + rax]      ; Читаем локальную
    jmp .print_var_output
    
.print_var_global:
    ; --- Глобальная переменная ---
    movzx eax, r12b
    
    ; === Phase 15: Проверяем тип переменной ===
    lea rbx, [var_types]
    cmp byte [rbx + rax], VAR_TYPE_FLOAT
    je .print_var_float
    
    ; Integer variable
    lea rbx, [variables]
    mov rax, qword [rbx + rax*8]
    
.print_var_output:
    call print_number
    call print_maybe_newline
    jmp .tokenize_loop

; Phase 15: Float variable output
.print_var_float:
    lea rbx, [variables]
    mov rax, qword [rbx + rax*8]    ; 64-bit pattern of double
    call print_float
    call print_maybe_newline
    jmp .tokenize_loop

; --- PRINT числа ---
.print_immediate:
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    call print_number
    call print_maybe_newline
    jmp .tokenize_loop

; --- PRINT строки (простой вызов) ---
.print_string:
    ; Получаем указатель на строку и её длину
    mov rdx, qword [rbx + TOKEN_VALUE]
    movzx r8d, word [rbx + TOKEN_LENGTH]
    call print_string
    call print_maybe_newline
    jmp .tokenize_loop

; ============================================================================
; Команда DUMP - вывод JIT байт-кода
; ============================================================================
.cmd_dump:
    ; Выводим заголовок
    lea rdx, [dump_header]
    call print_cstring
    
    ; Получаем начало и конец JIT буфера
    mov rsi, [jit_buffer]
    test rsi, rsi
    jz .dump_empty
    
    mov rdi, [jit_pos]
    cmp rsi, rdi
    jge .dump_empty
    
    ; Счётчик байт в строке
    xor r12d, r12d          ; r12 = позиция в строке (0-15)
    xor r13d, r13d          ; r13 = общий счётчик байт
    
.dump_loop:
    cmp rsi, rdi
    jge .dump_done
    
    ; Выводим смещение в начале строки
    test r12d, r12d
    jnz .dump_byte
    
    ; Выводим смещение (4 hex цифры)
    mov eax, r13d
    call print_hex_word
    lea rdx, [dump_colon]
    call print_cstring
    
.dump_byte:
    ; Читаем байт
    movzx eax, byte [rsi]
    call print_hex_byte
    
    ; Пробел после байта
    lea rdx, [dump_space]
    call print_cstring
    
    inc rsi
    inc r13d
    inc r12d
    
    ; Новая строка после 16 байт
    cmp r12d, 16
    jl .dump_loop
    
    ; Перевод строки
    lea rdx, [newline]
    call print_cstring
    xor r12d, r12d
    jmp .dump_loop
    
.dump_done:
    ; Если строка не закончена - перевод строки
    test r12d, r12d
    jz .dump_footer
    lea rdx, [newline]
    call print_cstring
    
.dump_footer:
    ; Выводим размер
    lea rdx, [dump_size]
    call print_cstring
    mov eax, r13d
    call print_number
    lea rdx, [dump_bytes]
    call print_cstring
    jmp .tokenize_loop
    
.dump_empty:
    lea rdx, [dump_empty_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда LET - присваивание переменной
; Синтаксис: LET A = 100  или  LET X = Y + 5  или  LET Z = A * B
;            LET A$ = "Hello"  или  LET C$ = A$ + B$
; Phase 7: Поддержка строковых переменных
; ============================================================================
.cmd_let:
    ; Получаем следующий токен (имя переменной)
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Проверяем тип переменной
    cmp al, TOKEN_STRING_VAR
    je .let_string_var
    
    ; Должен быть идентификатор (числовая переменная)
    cmp al, TOKEN_IDENTIFIER
    jne .let_error
    
    ; === Числовая переменная ===
    ; Получаем имя переменной (первый символ)
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]          ; r12 = первый символ имени
    
    ; Преобразуем в верхний регистр и индекс
    cmp r12b, 'a'
    jl .let_check_upper
    sub r12b, 32                    ; a-z -> A-Z
.let_check_upper:
    sub r12b, 'A'                   ; A=0, B=1, ... Z=25
    cmp r12b, 25
    ja .let_error                   ; Не A-Z
    
    ; === Phase 16: Проверяем — это массив A(I) или переменная A? ===
    push r12
    lea rdi, [current_token]
    call lexer_next_token
    pop r12
    
    cmp al, TOKEN_OPERATOR
    jne .let_not_array
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    je .let_array_element           ; Это массив!
    cmp al, OP_EQ
    je .let_have_eq                 ; Это '=' — обычная переменная
    jmp .let_error
    
.let_not_array:
    ; Откладываем токен — это должен быть '='
    mov byte [token_pushed], 1
    
    ; Сохраняем индекс целевой переменной
    push r12
    
    ; Получаем следующий токен (должен быть =)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .let_error_pop
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    jne .let_error_pop
    jmp .let_parse_value
    
.let_have_eq:
    ; Уже прочитали '='
    push r12
    
.let_parse_value:
    ; Вызываем парсер выражения — результат в RAX
    call parse_expression
    
    test rcx, rcx                   ; RCX = 0 если ошибка
    jz .let_error_pop
    
    ; RAX содержит результат выражения
    pop r12                         ; Восстанавливаем индекс целевой
    
    ; === Phase 12.2: Проверяем — локальная или глобальная переменная ===
    push rax                        ; Сохраняем значение
    call lookup_variable            ; CF=1 локальная, AL=offset; CF=0 глобальная
    pop rcx                         ; RCX = значение для записи
    jnc .let_global_var             ; CF=0 → глобальная
    
    ; --- Локальная переменная: записываем через func_rbp_saved ---
    movzx eax, al                   ; Zero-extend offset (0, 8, 16, ...) СРАЗУ!
    mov rbx, [func_rbp_saved]       ; Базовый указатель фрейма функции
    mov qword [rbx + rax], rcx      ; Записываем по [base + offset]
    jmp .let_done
    
.let_global_var:
    ; --- Глобальная переменная: классический путь ---
    movzx r12d, r12b
    lea rbx, [variables]
    mov qword [rbx + r12*8], rcx
    
    ; === Phase 15: Сохраняем тип переменной ===
    lea rbx, [var_types]
    movzx eax, byte [float_mode]    ; 0 = int, 1 = float
    mov byte [rbx + r12], al
    jmp .let_done

; === Phase 16: LET A(I) = value — запись в массив ===
.let_array_element:
    ; r12 = индекс массива (0-25)
    ; Мы уже прочитали '('
    
    ; Сохраняем индекс массива на стек (не в глобальную переменную!)
    push r12
    
    ; Парсим индекс (выражение)
    call parse_expression
    test rcx, rcx
    jz .let_arr_error_pop1
    
    ; RAX = индекс элемента
    push rax                        ; Сохраняем индекс на стек
    
    ; Проверяем закрывающую скобку
    cmp byte [token_pushed], 0
    jne .let_arr_use_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .let_arr_check_rparen
.let_arr_use_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.let_arr_check_rparen:
    cmp al, TOKEN_OPERATOR
    jne .let_arr_error_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .let_arr_error_pop2
    
    ; Ожидаем '='
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .let_arr_error_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    jne .let_arr_error_pop2
    
    ; Парсим значение
    call parse_expression
    test rcx, rcx
    jz .let_arr_error_pop2
    
    ; RAX = значение для записи
    mov r13, rax                    ; r13 = value
    
    ; Восстанавливаем индекс и индекс массива со стека
    pop rcx                         ; rcx = element index
    pop r12                         ; r12 = array index (0-25)
    
    ; Получаем информацию о массиве
    movzx eax, r12b
    shl eax, 4                      ; index * 16
    lea rbx, [array_table]
    mov rdi, qword [rbx + rax]      ; rdi = pointer to data
    mov r14, qword [rbx + rax + 8]  ; r14 = size
    
    ; Проверяем что массив выделен
    test rdi, rdi
    jz .let_arr_undef
    
    ; Проверяем границы
    test rcx, rcx
    js .let_arr_bounds              ; index < 0
    cmp rcx, r14
    jge .let_arr_bounds             ; index >= size
    
    ; Записываем элемент: [rdi + rcx * 8] = r13
    ; Phase 16: Массивы хранят float, конвертируем если нужно
    cmp byte [float_mode], 1
    je .let_arr_store_float
    
    ; Значение - целое, конвертируем в float
    cvtsi2sd xmm0, r13
    movq r13, xmm0
    
.let_arr_store_float:
    mov qword [rdi + rcx*8], r13
    jmp .let_done

.let_arr_error_pop2:
    pop rax
.let_arr_error_pop1:
    pop r12
    jmp .let_error

.let_arr_undef:
    lea rdx, [arr_undef_msg]
    call print_cstring
    jmp .tokenize_loop

.let_arr_bounds:
    lea rdx, [arr_bounds_msg]
    call print_cstring
    jmp .tokenize_loop

.let_done:
    
    ; Выводим подтверждение (только в интерактивном режиме)
    cmp byte [run_mode], 1
    je .tokenize_loop
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_loop

; === Строковая переменная (LET A$ = ...) ===
.let_string_var:
    ; Получаем имя переменной (первый символ)
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]          ; r12 = первый символ (A, B, ...)
    
    ; Преобразуем в индекс
    cmp r12b, 'a'
    jl .let_str_upper
    sub r12b, 32
.let_str_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .let_error
    
    ; r12 = индекс строковой переменной (0-25)
    push r12
    
    ; Получаем '='
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .let_error_pop
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    jne .let_error_pop
    
    ; Парсим строковое выражение
    call parse_string_expr
    test rcx, rcx
    jz .let_error_pop
    
    ; RAX = указатель на строку в heap
    ; RDX = длина строки
    pop r12
    
    ; Сохраняем в str_vars[r12]
    ; Формат: [PTR (8 байт)][LEN (8 байт)]
    movzx r12d, r12b
    lea rbx, [str_vars]
    shl r12, 4                      ; r12 * 16
    mov qword [rbx + r12], rax      ; PTR
    mov qword [rbx + r12 + 8], rdx  ; LEN
    
    cmp byte [run_mode], 1
    je .tokenize_loop
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_loop
    
.let_error_pop:
    pop r12
.let_error:
    lea rdx, [let_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда DIM - выделение массива (Phase 16)
; Синтаксис: DIM A(1000) — выделить массив A на 1000 элементов
; ============================================================================
.cmd_dim:
    ; Получаем имя массива (должен быть идентификатор A-Z)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .dim_error
    
    ; Получаем индекс массива (первая буква имени)
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]          ; r12 = первый символ
    
    cmp r12b, 'a'
    jl .dim_check_upper
    sub r12b, 32                    ; a-z -> A-Z
.dim_check_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .dim_error
    
    ; r12 = индекс массива (0-25)
    
    ; Ожидаем открывающую скобку
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .dim_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    jne .dim_error
    
    ; Парсим размер (выражение)
    call parse_expression
    test rcx, rcx
    jz .dim_error
    
    ; RAX = размер массива (количество элементов)
    mov r13, rax                    ; r13 = size
    
    ; Проверяем что размер > 0
    test r13, r13
    jle .dim_error
    
    ; Ожидаем закрывающую скобку
    cmp byte [token_pushed], 0
    jne .dim_use_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .dim_check_rparen
.dim_use_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.dim_check_rparen:
    cmp al, TOKEN_OPERATOR
    jne .dim_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .dim_error
    
    ; Вычисляем размер в байтах: size * 8
    mov rax, r13
    shl rax, 3                      ; rax = size * 8 bytes
    mov r14, rax                    ; r14 = bytes needed
    
    ; Проверяем что хватает места в heap
    mov rdi, [array_heap_ptr]
    lea rbx, [array_heap]
    add rbx, ARRAY_HEAP_SIZE        ; rbx = конец heap
    lea rax, [rdi + r14]            ; rax = новый указатель
    cmp rax, rbx
    ja .dim_out_of_memory
    
    ; Выделяем память
    ; Записываем в array_table[r12]: [pointer][size]
    movzx eax, r12b
    shl eax, 4                      ; eax = index * 16 (ARRAY_ENTRY_SIZE)
    lea rbx, [array_table]
    mov qword [rbx + rax], rdi      ; Pointer to data
    mov qword [rbx + rax + 8], r13  ; Size (elements)
    
    ; Обнуляем память массива
    push rdi
    push r14
    mov rcx, r14
    shr rcx, 3                      ; rcx = count of qwords
    xor eax, eax
    rep stosq
    pop r14
    pop rdi
    
    ; Обновляем array_heap_ptr
    add rdi, r14
    mov [array_heap_ptr], rdi
    
    ; Сообщение OK (только в интерактивном режиме)
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    ; Выводим "Array X(N) OK"
    lea rdx, [dim_ok_msg]
    call print_cstring
    jmp .tokenize_loop

.dim_out_of_memory:
    lea rdx, [dim_oom_msg]
    call print_cstring
    jmp .tokenize_loop

.dim_error:
    lea rdx, [dim_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда VARS - вывод всех переменных
; ============================================================================
.cmd_vars:
    lea rdx, [vars_header]
    call print_cstring
    
    xor r12d, r12d                  ; r12 = индекс (0-25)
    lea r13, [variables]            ; r13 = база массива
    
.vars_loop:
    ; Получаем значение
    mov rax, qword [r13 + r12*8]
    
    ; Пропускаем нулевые переменные
    test rax, rax
    jz .vars_next
    
    ; Выводим имя: "  X = "
    lea rdx, [vars_prefix]
    call print_cstring
    
    ; Выводим букву
    mov al, r12b
    add al, 'A'
    mov [num_buffer], al
    lea rdx, [num_buffer]
    mov r8d, 1
    call print_string
    
    lea rdx, [vars_eq]
    call print_cstring
    
    ; Выводим значение
    mov rax, qword [r13 + r12*8]
    call print_number
    
    lea rdx, [newline]
    call print_cstring
    
.vars_next:
    inc r12d
    cmp r12d, 26
    jl .vars_loop
    
    jmp .tokenize_loop

; ============================================================================
; Команда CRASH - тест crash handler (Phase X.2)
; ============================================================================
.cmd_crash:
    ; Отладочное сообщение
    lea rdx, [crash_test_msg]
    call print_cstring
    
    ; Генерируем JIT-код с Access Violation (надёжнее перехватывается)
    mov rax, [jit_buffer]
    mov [jit_pos], rax
    
    ; Записываем: xor rax, rax (rax = 0)
    mov byte [rax], 0x48            ; REX.W
    mov byte [rax+1], 0x31          ; xor r/m64, r64
    mov byte [rax+2], 0xC0          ; ModRM: rax, rax
    
    ; mov qword [rax], 0x12345678 - запись по нулевому адресу = Access Violation!
    mov byte [rax+3], 0x48          ; REX.W
    mov byte [rax+4], 0xC7          ; mov [r/m64], imm32
    mov byte [rax+5], 0x00          ; ModRM: [rax]
    mov dword [rax+6], 0x12345678   ; imm32
    
    ; ret (на случай если как-то выживем)
    mov byte [rax+10], 0xC3
    
    ; Вызываем JIT-код (вызовет crash!)
    mov rax, [jit_buffer]
    call rax
    
    ; Сюда не дойдём - crash handler перехватит
    jmp .tokenize_loop

; ============================================================================
; Команда TEST_GUI - тест FFI (Phase 13)
; Показывает MessageBox напрямую через Windows API
; ============================================================================
.cmd_test_gui:
    ; Windows x64 Calling Convention:
    ; RCX = arg1 (hWnd = 0)
    ; RDX = arg2 (lpText = message)
    ; R8  = arg3 (lpCaption = title)
    ; R9  = arg4 (uType = MB_OK = 0)
    ; + Shadow Space (32 bytes)
    
    ; Сохраняем callee-saved регистры
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    
    ; Выравниваем стек на 16 байт и резервируем shadow space
    and rsp, -16
    sub rsp, 32                     ; Shadow space
    
    xor ecx, ecx                    ; hWnd = NULL
    lea rdx, [ffi_test_msg]         ; lpText
    lea r8, [ffi_test_title]        ; lpCaption
    xor r9d, r9d                    ; uType = MB_OK (0)
    
    call [MessageBoxA]
    
    ; Восстанавливаем стек
    mov rsp, rbp
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    ; Выводим сообщение об успехе
    lea rdx, [ffi_success_msg]
    call print_cstring
    
    jmp .tokenize_loop

; ============================================================================
; Команда DECLARE - объявление внешней функции (Phase 13.3)
; Синтаксис: DECLARE <NAME> LIB "<dll>" ALIAS "<func>"
; Пример: DECLARE BEEP LIB "kernel32.dll" ALIAS "Beep"
; ============================================================================
.cmd_declare:
    ; Сохраняем callee-saved регистры
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; === 1. Читаем имя функции в TITAN (например, BEEP) ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .declare_error
    
    ; Копируем имя в titan_name_buf и вычисляем хеш
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]   ; Указатель на имя
    movzx rcx, word [rbx + TOKEN_LENGTH] ; Длина
    
    ; Сохраняем для хеширования
    push rsi
    push rcx
    
    ; Копируем имя
    lea rdi, [titan_name_buf]
    rep movsb
    mov byte [rdi], 0                    ; Null-terminator
    
    ; Вычисляем хеш через ffi_hash_string
    pop rcx                              ; Восстанавливаем длину
    pop rsi                              ; Восстанавливаем указатель
    call ffi_hash_string
    mov [titan_name_hash], rax
    mov r13, rax                         ; r13 = hash
    
    ; === 2. Ожидаем LIB ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_KEYWORD
    jne .declare_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_LIB
    jne .declare_error
    
    ; === 3. Читаем имя DLL (строковый литерал) ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_STRING
    jne .declare_error
    
    ; Копируем имя DLL в dll_name_buf
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx rcx, word [rbx + TOKEN_LENGTH]
    lea rdi, [dll_name_buf]
    push rcx
    rep movsb
    mov byte [rdi], 0                    ; Null-terminator
    pop rcx
    
    ; === 4. Загружаем DLL через LoadLibraryA ===
    sub rsp, 40                          ; Shadow space + alignment
    lea rcx, [dll_name_buf]
    call [LoadLibraryA]
    add rsp, 40
    
    test rax, rax
    jz .declare_error_dll
    mov r14, rax                         ; r14 = DLL Handle
    
    ; === 5. Ожидаем ALIAS ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_KEYWORD
    jne .declare_error_free_dll
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_ALIAS
    jne .declare_error_free_dll
    
    ; === 6. Читаем имя функции в DLL ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_STRING
    jne .declare_error_free_dll
    
    ; Копируем имя функции в func_name_buf
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx rcx, word [rbx + TOKEN_LENGTH]
    lea rdi, [func_name_buf]
    rep movsb
    mov byte [rdi], 0                    ; Null-terminator
    
    ; === 7. Получаем адрес функции через GetProcAddress ===
    sub rsp, 40
    mov rcx, r14                         ; HMODULE
    lea rdx, [func_name_buf]
    call [GetProcAddress]
    add rsp, 40
    
    test rax, rax
    jz .declare_error_proc
    mov r15, rax                         ; r15 = Function Address
    
    ; === 8. Сохраняем в FFI Table ===
    mov rax, [ffi_count]
    cmp rax, FFI_MAX_ENTRIES
    jge .declare_error_full
    
    ; Вычисляем смещение в таблице: offset = count * 32
    shl rax, 5                           ; × 32
    lea rbx, [ffi_table]
    add rbx, rax                         ; rbx = &ffi_table[count]
    
    ; Записываем структуру
    mov qword [rbx + 0], r13             ; Hash
    mov qword [rbx + 8], r15             ; Function Address
    mov qword [rbx + 16], r14            ; DLL Handle
    mov qword [rbx + 24], 0              ; Arg Count (TODO: автоопределение)
    
    ; Увеличиваем счётчик
    inc qword [ffi_count]
    
    ; === 9. Выводим сообщение об успехе ===
    cmp byte [run_mode], 1
    je .declare_done
    
    lea rdx, [declare_ok_msg]
    call print_cstring
    lea rdx, [titan_name_buf]
    call print_cstring
    lea rdx, [declare_ok_msg2]
    call print_cstring
    lea rdx, [dll_name_buf]
    call print_cstring
    lea rdx, [newline]
    call print_cstring
    
.declare_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    jmp .tokenize_loop

.declare_error_full:
    ; FFI table is full
.declare_error_proc:
    ; Не удалось найти функцию
    lea rdx, [declare_err_proc]
    call print_cstring
    lea rdx, [func_name_buf]
    call print_cstring
    lea rdx, [newline]
    call print_cstring
    jmp .declare_cleanup

.declare_error_free_dll:
    ; Нужно освободить загруженную DLL
.declare_error_dll:
    lea rdx, [declare_err_dll]
    call print_cstring
    lea rdx, [dll_name_buf]
    call print_cstring
    lea rdx, [newline]
    call print_cstring
    jmp .declare_cleanup

.declare_error:
    lea rdx, [declare_err_msg]
    call print_cstring
    
.declare_cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    jmp .tokenize_loop

; ============================================================================
; Команда MSGBOX - показать MessageBox (Phase 13.1)
; Синтаксис: MSGBOX "Text", "Title"  или  MSGBOX A$ + B$, "Title"
; ============================================================================
.cmd_msgbox:
    ; Парсим первый аргумент (текст сообщения) - поддержка конкатенации!
    call parse_string_expr
    test rcx, rcx
    jz .msgbox_error
    
    ; RAX = указатель на строку (null-terminated в heap)
    ; RDX = длина строки
    push rax                        ; Сохраняем указатель на текст
    
    ; Ожидаем запятую (токен уже может быть считан parse_string_expr)
    cmp byte [token_pushed], 0
    jne .msgbox_use_current
    lea rdi, [current_token]
    call lexer_next_token
    jmp .msgbox_check_comma
.msgbox_use_current:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.msgbox_check_comma:
    cmp al, TOKEN_OPERATOR
    jne .msgbox_error_pop1
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .msgbox_error_pop1
    
    ; Парсим второй аргумент (заголовок) - тоже с конкатенацией
    call parse_string_expr
    test rcx, rcx
    jz .msgbox_error_pop1
    
    ; RAX = указатель на заголовок
    mov r8, rax                     ; R8 = lpCaption
    pop rdx                         ; RDX = lpText
    
    ; Вызываем MessageBoxA
    ; Windows x64 ABI: RCX, RDX, R8, R9 + Shadow Space
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    
    and rsp, -16                    ; Выравнивание на 16 байт
    sub rsp, 32                     ; Shadow space
    
    xor ecx, ecx                    ; hWnd = NULL
    ; RDX уже содержит lpText
    ; R8 уже содержит lpCaption
    xor r9d, r9d                    ; uType = MB_OK
    
    call [MessageBoxA]
    
    mov rsp, rbp
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    ; Выводим результат (номер нажатой кнопки)
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    push rax
    lea rdx, [msgbox_result_msg]
    call print_cstring
    pop rax
    call print_number
    lea rdx, [newline]
    call print_cstring
    
    jmp .tokenize_loop

.msgbox_error_pop1:
    pop rax
.msgbox_error:
    lea rdx, [msgbox_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда BLOAD - загрузить бинарный файл в массив (Phase 17)
; Синтаксис: BLOAD "filename.bin", A
; ============================================================================
.cmd_bload:
    ; Парсим имя файла (строковое выражение)
    call parse_string_expr
    test rcx, rcx
    jz .bload_error
    
    ; RAX = указатель на имя файла (null-terminated в heap)
    mov [bload_filename], rax
    
    ; Ожидаем запятую
    ; Проверяем, не был ли токен уже прочитан parse_string_expr
    cmp byte [token_pushed], 0
    jne .bload_use_current_comma
    lea rdi, [current_token]
    call lexer_next_token
    jmp .bload_check_comma
.bload_use_current_comma:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.bload_check_comma:
    cmp al, TOKEN_OPERATOR
    jne .bload_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .bload_error
    
    ; Парсим имя массива (одна буква)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .bload_error
    
    ; Получаем индекс массива (0-25)
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF                   ; Uppercase
    sub eax, 'A'
    cmp eax, 25
    ja .bload_error
    
    ; Получаем указатель и размер массива
    shl eax, 4                      ; * 16 (ARRAY_ENTRY_SIZE)
    lea r10, [array_table]
    add r10, rax
    
    mov rax, [r10]                  ; Pointer to data
    test rax, rax
    jz .bload_error                 ; Массив не выделен
    mov [bload_buffer], rax
    
    mov rax, [r10 + 8]              ; Size in elements (qword)
    shl rax, 3                      ; * 8 (sizeof double)
    mov [bload_size], eax           ; Store as dword (max 4GB file)
    
    ; === Вызываем CreateFileA ===
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    
    mov rcx, [bload_filename]       ; lpFileName
    mov edx, 0x80000000             ; GENERIC_READ
    xor r8d, r8d                    ; dwShareMode = 0
    xor r9d, r9d                    ; lpSecurityAttributes = NULL
    mov dword [rsp + 32], 3         ; OPEN_EXISTING
    mov dword [rsp + 40], 0x80      ; FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0         ; hTemplateFile = NULL
    
    call [CreateFileA]
    
    mov rsp, rbp
    pop rbp
    
    cmp rax, -1                     ; INVALID_HANDLE_VALUE
    je .bload_error
    
    mov [bload_handle], rax
    
    ; === Вызываем ReadFile ===
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 48
    
    mov rcx, [bload_handle]         ; hFile
    mov rdx, [bload_buffer]         ; lpBuffer
    mov r8d, [bload_size]           ; nNumberOfBytesToRead
    lea r9, [bytes_read]            ; lpNumberOfBytesRead
    mov qword [rsp + 32], 0         ; lpOverlapped = NULL
    
    call [ReadFile]
    
    mov rsp, rbp
    pop rbp
    
    ; Save bytes_read before any print calls overwrite it
    mov r12d, [bytes_read]
    
    test eax, eax
    jz .bload_close_error
    
    ; === Закрываем файл ===
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    mov rcx, [bload_handle]
    call [CloseHandle]
    mov rsp, rbp
    pop rbp
    
    ; Успех!
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    lea rdx, [bload_ok_msg]
    call print_cstring
    mov eax, r12d                   ; Use saved bytes_read
    call print_number
    lea rdx, [bytes_suffix]
    call print_cstring
    
    jmp .tokenize_loop

.bload_close_error:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    mov rcx, [bload_handle]
    call [CloseHandle]
    mov rsp, rbp
    pop rbp
    
.bload_error:
    lea rdx, [bload_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда BSAVE - сохранить массив в бинарный файл (Phase 17)
; Синтаксис: BSAVE "filename.bin", A
; ============================================================================
.cmd_bsave:
    ; Парсим имя файла (строковое выражение)
    call parse_string_expr
    test rcx, rcx
    jz .bsave_error
    
    ; RAX = указатель на имя файла (null-terminated в heap)
    mov [bsave_filename], rax
    
    ; Ожидаем запятую - проверяем token_pushed
    cmp byte [token_pushed], 0
    jne .bsave_use_current_comma
    lea rdi, [current_token]
    call lexer_next_token
    jmp .bsave_check_comma
.bsave_use_current_comma:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.bsave_check_comma:
    cmp al, TOKEN_OPERATOR
    jne .bsave_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .bsave_error
    
    ; Парсим имя массива (одна буква)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .bsave_error
    
    ; Получаем индекс массива (0-25)
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF                   ; Uppercase
    sub eax, 'A'
    cmp eax, 25
    ja .bsave_error
    
    ; Получаем указатель и размер массива
    shl eax, 4                      ; * 16 (ARRAY_ENTRY_SIZE)
    lea r10, [array_table]
    add r10, rax
    
    mov rax, [r10]                  ; Pointer to data
    test rax, rax
    jz .bsave_error                 ; Массив не выделен
    mov [bsave_buffer], rax
    
    mov rax, [r10 + 8]              ; Size in elements (qword)
    shl rax, 3                      ; * 8 (sizeof double)
    mov [bsave_size], eax           ; Store as dword (max 4GB file)
    
    ; === Вызываем CreateFileA ===
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    
    mov rcx, [bsave_filename]       ; lpFileName
    mov edx, 0x40000000             ; GENERIC_WRITE
    xor r8d, r8d                    ; dwShareMode = 0
    xor r9d, r9d                    ; lpSecurityAttributes = NULL
    mov dword [rsp + 32], 2         ; CREATE_ALWAYS
    mov dword [rsp + 40], 0x80      ; FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0         ; hTemplateFile = NULL
    
    call [CreateFileA]
    
    mov rsp, rbp
    pop rbp
    
    cmp rax, -1                     ; INVALID_HANDLE_VALUE
    je .bsave_error
    
    mov [bsave_handle], rax
    
    ; === Вызываем WriteFile ===
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 48
    
    mov rcx, [bsave_handle]         ; hFile
    mov rdx, [bsave_buffer]         ; lpBuffer
    mov r8d, [bsave_size]           ; nNumberOfBytesToWrite
    lea r9, [bytes_written]         ; lpNumberOfBytesWritten
    mov qword [rsp + 32], 0         ; lpOverlapped = NULL
    
    call [WriteFile]
    
    mov rsp, rbp
    pop rbp
    
    ; Save bytes_written before any print calls overwrite it
    mov r12d, [bytes_written]
    
    test eax, eax
    jz .bsave_close_error
    
    ; === Закрываем файл ===
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    mov rcx, [bsave_handle]
    call [CloseHandle]
    mov rsp, rbp
    pop rbp
    
    ; Успех!
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    lea rdx, [bsave_ok_msg]
    call print_cstring
    mov eax, r12d                   ; Use saved bytes_written (r12 is callee-saved)
    call print_number
    lea rdx, [bytes_suffix]
    call print_cstring
    
    jmp .tokenize_loop

.bsave_close_error:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    mov rcx, [bsave_handle]
    call [CloseHandle]
    mov rsp, rbp
    pop rbp
    
.bsave_error:
    lea rdx, [bsave_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда MATMUL - умножение матриц с AVX2/FMA (Phase 18)
; Синтаксис: MATMUL C, A, B, M, N, K
; C[M,K] = A[M,N] * B[N,K]
; ============================================================================
.cmd_matmul:
    ; Парсим 6 аргументов: C, A, B, M, N, K
    
    ; === Массив C (результат) ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .matmul_error
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .matmul_error
    push rax                        ; [rsp+40] = index C
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .matmul_err_pop1
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .matmul_err_pop1
    
    ; === Массив A ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .matmul_err_pop1
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .matmul_err_pop1
    push rax                        ; [rsp+32] = index A
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .matmul_err_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .matmul_err_pop2
    
    ; === Массив B ===
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .matmul_err_pop2
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .matmul_err_pop2
    push rax                        ; [rsp+24] = index B
    
    ; Запятая - проверяем token_pushed после lexer
    cmp byte [token_pushed], 0
    jne .matmul_use_comma1
    lea rdi, [current_token]
    call lexer_next_token
    jmp .matmul_check_comma1
.matmul_use_comma1:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.matmul_check_comma1:
    cmp al, TOKEN_OPERATOR
    jne .matmul_err_pop3
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .matmul_err_pop3
    
    ; === Размер M ===
    call parse_expression
    push rax                        ; [rsp+16] = M
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .matmul_use_comma2
    lea rdi, [current_token]
    call lexer_next_token
    jmp .matmul_check_comma2
.matmul_use_comma2:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.matmul_check_comma2:
    cmp al, TOKEN_OPERATOR
    jne .matmul_err_pop4
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .matmul_err_pop4
    
    ; === Размер N ===
    call parse_expression
    push rax                        ; [rsp+8] = N
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .matmul_use_comma3
    lea rdi, [current_token]
    call lexer_next_token
    jmp .matmul_check_comma3
.matmul_use_comma3:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.matmul_check_comma3:
    cmp al, TOKEN_OPERATOR
    jne .matmul_err_pop5
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .matmul_err_pop5
    
    ; === Размер K ===
    call parse_expression
    push rax                        ; [rsp+0] = K
    
    ; Теперь стек: [K, N, M, idxB, idxA, idxC]
    ; Получаем указатели на массивы
    lea r15, [array_table]
    
    ; C
    mov eax, [rsp + 40]
    imul eax, ARRAY_ENTRY_SIZE
    mov r8, [r15 + rax ]  ; R8 = ptr C
    test r8, r8
    jz .matmul_err_pop6
    
    ; A
    mov eax, [rsp + 32]
    imul eax, ARRAY_ENTRY_SIZE
    mov r9, [r15 + rax ]  ; R9 = ptr A
    test r9, r9
    jz .matmul_err_pop6
    
    ; B
    mov eax, [rsp + 24]
    imul eax, ARRAY_ENTRY_SIZE
    mov r10, [r15 + rax ] ; R10 = ptr B
    test r10, r10
    jz .matmul_err_pop6
    
    ; Размеры
    mov r11d, [rsp + 16]            ; R11 = M
    mov r12d, [rsp + 8]             ; R12 = N
    mov r13d, [rsp + 0]             ; R13 = K
    
    ; Чистим стек
    add rsp, 48
    
    ; === Тройной цикл с FMA ===
    ; C[i,k] = sum(j=0..N-1) A[i,j] * B[j,k]
    ; Индексация: C[i*K + k], A[i*N + j], B[j*K + k]
    
    xor ecx, ecx                    ; i = 0
.matmul_loop_i:
    cmp ecx, r11d
    jge .matmul_done
    push rcx                        ; Сохраняем i
    
    xor edx, edx                    ; k = 0
.matmul_loop_k:
    cmp edx, r13d
    jge .matmul_next_i
    push rdx                        ; Сохраняем k
    
    ; C[i*K + k] = 0
    mov eax, ecx                    ; i
    imul eax, r13d                  ; i*K
    add eax, edx                    ; i*K + k
    xorpd xmm0, xmm0
    
    xor ebx, ebx                    ; j = 0
.matmul_loop_j:
    cmp ebx, r12d
    jge .matmul_store_c
    
    ; xmm0 += A[i*N + j] * B[j*K + k]
    mov eax, [rsp + 8]              ; i
    imul eax, r12d                  ; i*N
    add eax, ebx                    ; i*N + j
    movsd xmm1, [r9 + rax*8]        ; A[i*N + j]
    
    mov eax, ebx                    ; j
    imul eax, r13d                  ; j*K
    add eax, [rsp]                  ; j*K + k
    movsd xmm2, [r10 + rax*8]       ; B[j*K + k]
    
    ; FMA: xmm0 += xmm1 * xmm2
    vfmadd231sd xmm0, xmm1, xmm2
    
    inc ebx
    jmp .matmul_loop_j
    
.matmul_store_c:
    ; Сохраняем результат в C[i*K + k]
    mov eax, [rsp + 8]              ; i
    imul eax, r13d                  ; i*K
    add eax, [rsp]                  ; i*K + k
    movsd [r8 + rax*8], xmm0
    
    pop rdx                         ; Восстанавливаем k
    inc edx
    mov ecx, [rsp]                  ; Восстанавливаем i (не pop!)
    jmp .matmul_loop_k
    
.matmul_next_i:
    pop rcx                         ; Восстанавливаем i
    inc ecx
    jmp .matmul_loop_i
    
.matmul_done:
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    lea rdx, [matmul_ok_msg]
    call print_cstring
    jmp .tokenize_loop

.matmul_err_pop6:
    add rsp, 48
    jmp .matmul_error
.matmul_err_pop5:
    add rsp, 8
.matmul_err_pop4:
    add rsp, 8
.matmul_err_pop3:
    add rsp, 8
.matmul_err_pop2:
    add rsp, 8
.matmul_err_pop1:
    add rsp, 8
.matmul_error:
    lea rdx, [matmul_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда VRELU - векторизованная ReLU активация (Phase 18)
; Синтаксис: VRELU A, N
; A[i] = max(0, A[i]) для i = 0..N-1
; ============================================================================
.cmd_vrelu:
    ; Парсим массив
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vrelu_error
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .vrelu_error
    push rax                        ; Индекс массива
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .vrelu_err_pop1
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .vrelu_err_pop1
    
    ; Размер N
    call parse_expression
    mov r12, rax                    ; R12 = N
    
    ; Получаем указатель на массив
    pop rax
    lea r10, [array_table]
    imul eax, ARRAY_ENTRY_SIZE
    add r10, rax
    
    mov r11, [r10 ]      ; R11 = указатель на данные
    test r11, r11
    jz .vrelu_error
    
    ; === Векторизованный ReLU с AVX ===
    ; Обрабатываем по 4 double за раз (256 бит = 4 * 64)
    vxorpd ymm1, ymm1, ymm1         ; ymm1 = [0.0, 0.0, 0.0, 0.0]
    
    mov rcx, r12
    shr rcx, 2                      ; Количество итераций по 4
    xor eax, eax                    ; Индекс
    
.vrelu_vec_loop:
    test rcx, rcx
    jz .vrelu_scalar
    
    vmovupd ymm0, [r11 + rax*8]     ; Загружаем 4 double
    vmaxpd ymm0, ymm0, ymm1         ; max(x, 0)
    vmovupd [r11 + rax*8], ymm0     ; Сохраняем
    
    add eax, 4
    dec rcx
    jmp .vrelu_vec_loop
    
.vrelu_scalar:
    ; Обрабатываем остаток (0-3 элемента)
    cmp eax, r12d
    jge .vrelu_done
    
    movsd xmm0, [r11 + rax*8]
    xorpd xmm2, xmm2
    maxsd xmm0, xmm2
    movsd [r11 + rax*8], xmm0
    
    inc eax
    jmp .vrelu_scalar
    
.vrelu_done:
    ; Обязательно очищаем верхнюю часть YMM регистров
    vzeroupper
    
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    lea rdx, [vrelu_ok_msg]
    call print_cstring
    jmp .tokenize_loop

.vrelu_err_pop1:
    pop rax
.vrelu_error:
    lea rdx, [vrelu_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда ARRADD - сложение массивов float64 с AVX (Phase 23b)
; Синтаксис: ARRADD C, A, B, N
; C[i] = A[i] + B[i] для i = 0..N-1
; ============================================================================
.cmd_arradd:
    ; Парсим массив C (результат)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .arradd_error
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .arradd_error
    push rax                        ; [rsp+16] = index C
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .arradd_err_pop1
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .arradd_err_pop1
    
    ; Парсим массив A
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .arradd_err_pop1
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .arradd_err_pop1
    push rax                        ; [rsp+8] = index A
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .arradd_err_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .arradd_err_pop2
    
    ; Парсим массив B
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .arradd_err_pop2
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx eax, byte [rsi]
    and eax, 0xDF
    sub eax, 'A'
    cmp eax, 25
    ja .arradd_err_pop2
    push rax                        ; [rsp+0] = index B
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .arradd_err_pop3
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .arradd_err_pop3
    
    ; Парсим размер N
    call parse_expression
    test rcx, rcx
    jz .arradd_err_pop3
    cmp byte [float_mode], 1
    jne .arradd_n_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.arradd_n_int:
    mov r15, rax                    ; r15 = N
    
    ; Получаем указатели на массивы
    lea r14, [array_table]
    
    ; C
    pop rbx                         ; rbx = index B
    pop r12                         ; r12 = index A  
    pop r13                         ; r13 = index C
    
    ; Адрес C
    mov eax, r13d
    shl eax, 4                      ; * 16 (ARRAY_ENTRY_SIZE)
    mov rdi, [r14 + rax]            ; rdi = C data pointer
    
    ; Адрес A
    mov eax, r12d
    shl eax, 4
    mov rsi, [r14 + rax]            ; rsi = A data pointer
    
    ; Адрес B
    mov eax, ebx
    shl eax, 4
    mov rdx, [r14 + rax]            ; rdx = B data pointer
    
    ; Цикл сложения с AVX: 4 double за раз
    xor ecx, ecx                    ; ecx = i
    
.arradd_vec_loop:
    mov eax, r15d
    sub eax, ecx
    cmp eax, 4
    jl .arradd_scalar               ; Меньше 4 элементов - скалярный цикл
    
    ; Загружаем 4 double из A и B
    vmovupd ymm0, [rsi + rcx*8]     ; A[i..i+3]
    vmovupd ymm1, [rdx + rcx*8]     ; B[i..i+3]
    vaddpd ymm0, ymm0, ymm1         ; A + B
    vmovupd [rdi + rcx*8], ymm0     ; C[i..i+3] = result
    
    add ecx, 4
    jmp .arradd_vec_loop
    
.arradd_scalar:
    cmp ecx, r15d
    jge .arradd_done
    
    movsd xmm0, [rsi + rcx*8]       ; A[i]
    addsd xmm0, [rdx + rcx*8]       ; + B[i]
    movsd [rdi + rcx*8], xmm0       ; C[i] = result
    
    inc ecx
    jmp .arradd_scalar
    
.arradd_done:
    vzeroupper
    
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    lea rdx, [arradd_ok_msg]
    call print_cstring
    jmp .tokenize_loop

.arradd_err_pop3:
    pop rax
.arradd_err_pop2:
    pop rax
.arradd_err_pop1:
    pop rax
.arradd_error:
    lea rdx, [arradd_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда GPRINT - вывод текста в графическое окно (Phase 24: The Voice)
; Синтаксис: GPRINT x, y, "text", color, scale
; Рисует текст шрифтом 8x8 с масштабированием
; ============================================================================
.cmd_gprint:
    ; Проверяем что окно создано
    cmp byte [gfx_active], 1
    jne .gprint_done
    
    ; Парсим X
    call parse_expression
    test rcx, rcx
    jz .gprint_error
    cmp byte [float_mode], 1
    jne .gprint_x_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.gprint_x_int:
    push rax                        ; [rsp+32] = X
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .gprint_use_comma1
    lea rdi, [current_token]
    call lexer_next_token
    jmp .gprint_check_comma1
.gprint_use_comma1:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.gprint_check_comma1:
    cmp al, TOKEN_OPERATOR
    jne .gprint_err_pop1
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .gprint_err_pop1
    
    ; Парсим Y
    call parse_expression
    test rcx, rcx
    jz .gprint_err_pop1
    cmp byte [float_mode], 1
    jne .gprint_y_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.gprint_y_int:
    push rax                        ; [rsp+24] = Y
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .gprint_use_comma2
    lea rdi, [current_token]
    call lexer_next_token
    jmp .gprint_check_comma2
.gprint_use_comma2:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.gprint_check_comma2:
    cmp al, TOKEN_OPERATOR
    jne .gprint_err_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .gprint_err_pop2
    
    ; Парсим строку или переменную
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_STRING
    jne .gprint_err_pop2
    
    ; Сохраняем указатель на строку и длину
    mov rsi, qword [current_token + TOKEN_VALUE]
    push rsi                        ; [rsp+16] = string ptr
    movzx eax, word [current_token + TOKEN_LENGTH]
    push rax                        ; [rsp+8] = string len
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .gprint_err_pop4
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .gprint_err_pop4
    
    ; Парсим color
    call parse_expression
    test rcx, rcx
    jz .gprint_err_pop4
    cmp byte [float_mode], 1
    jne .gprint_color_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.gprint_color_int:
    push rax                        ; [rsp+0] = color
    
    ; Запятая и scale (опционально, по умолчанию 1)
    mov r15d, 1                     ; Default scale = 1
    cmp byte [token_pushed], 0
    jne .gprint_use_comma4
    lea rdi, [current_token]
    call lexer_next_token
    jmp .gprint_check_comma4
.gprint_use_comma4:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.gprint_check_comma4:
    cmp al, TOKEN_OPERATOR
    jne .gprint_no_scale
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .gprint_no_scale
    
    ; Парсим scale
    call parse_expression
    test rcx, rcx
    jz .gprint_no_scale
    cmp byte [float_mode], 1
    jne .gprint_scale_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.gprint_scale_int:
    mov r15d, eax                   ; r15 = scale
    jmp .gprint_render
    
.gprint_no_scale:
    mov byte [token_pushed], 1
    
.gprint_render:
    ; Стек: [color, len, str, Y, X]
    ; r15 = scale
    pop r14                         ; r14 = color
    pop rcx                         ; rcx = string len
    pop rsi                         ; rsi = string ptr
    pop r13                         ; r13 = Y
    pop r12                         ; r12 = X (текущая позиция)
    
    ; Рисуем каждый символ
    test rcx, rcx
    jz .gprint_done
    
.gprint_char_loop:
    push rcx
    push rsi
    
    ; Получаем символ
    movzx eax, byte [rsi]
    
    ; Проверяем диапазон 32-127
    cmp al, 32
    jl .gprint_next_char
    cmp al, 127
    jg .gprint_next_char
    
    ; Вычисляем адрес глифа: font8x8 + (char - 32) * 8
    sub eax, 32
    shl eax, 3                      ; * 8
    lea rbx, [font8x8]
    add rbx, rax                    ; rbx = pointer to glyph (8 bytes)
    
    ; Рисуем глиф 8x8 с масштабированием
    xor r8d, r8d                    ; r8 = row (0-7)
    
.gprint_row_loop:
    cmp r8d, 8
    jge .gprint_next_char
    
    movzx r9d, byte [rbx + r8]      ; r9 = row bitmap
    xor r10d, r10d                  ; r10 = col (0-7)
    
.gprint_col_loop:
    cmp r10d, 8
    jge .gprint_row_next
    
    ; Проверяем бит (7-col)
    mov eax, 7
    sub eax, r10d
    mov ecx, 1
    shl ecx, cl                     ; cl = bit position
    mov eax, 7
    sub eax, r10d
    mov ecx, eax
    mov eax, 1
    shl eax, cl
    test r9d, eax
    jz .gprint_col_next
    
    ; Бит установлен - рисуем квадрат scale*scale
    ; pixel_x = X + col * scale
    ; pixel_y = Y + row * scale
    mov eax, r10d
    imul eax, r15d
    add eax, r12d                   ; eax = pixel_x base
    
    mov r11d, r8d
    imul r11d, r15d
    add r11d, r13d                  ; r11 = pixel_y base
    
    ; Рисуем квадрат scale*scale
    push r8
    push r9
    push r10
    
    xor ecx, ecx                    ; sy = 0
.gprint_scale_y:
    cmp ecx, r15d
    jge .gprint_scale_done
    
    push rcx
    xor edx, edx                    ; sx = 0
.gprint_scale_x:
    cmp edx, r15d
    jge .gprint_scale_x_done
    
    ; Вычисляем координаты пикселя
    push rdx
    push rcx
    
    mov edi, eax                    ; pixel_x base
    add edi, edx                    ; + sx
    mov esi, r11d                   ; pixel_y base
    pop rcx
    add esi, ecx                    ; + sy
    
    ; Проверяем границы
    test edi, edi
    js .gprint_skip_pixel
    test esi, esi
    js .gprint_skip_pixel
    cmp edi, [gfx_width]
    jge .gprint_skip_pixel
    cmp esi, [gfx_height]
    jge .gprint_skip_pixel
    
    ; Вычисляем смещение: offset = (y * width + x) * 4
    push rax
    mov eax, esi
    imul eax, [gfx_width]
    add eax, edi
    shl eax, 2
    
    ; Записываем пиксель
    mov rdi, [gfx_buffer]
    mov ecx, r14d                   ; color
    mov [rdi + rax], ecx
    pop rax
    
.gprint_skip_pixel:
    pop rdx
    inc edx
    jmp .gprint_scale_x
    
.gprint_scale_x_done:
    pop rcx
    inc ecx
    jmp .gprint_scale_y
    
.gprint_scale_done:
    pop r10
    pop r9
    pop r8
    
.gprint_col_next:
    inc r10d
    jmp .gprint_col_loop
    
.gprint_row_next:
    inc r8d
    jmp .gprint_row_loop
    
.gprint_next_char:
    pop rsi
    pop rcx
    
    ; Следующий символ: X += 8 * scale
    mov eax, r15d
    shl eax, 3                      ; * 8
    add r12d, eax
    
    inc rsi
    dec rcx
    jnz .gprint_char_loop
    
.gprint_done:
    jmp .tokenize_loop

.gprint_err_pop4:
    pop rax
    pop rax
.gprint_err_pop2:
    pop rax
.gprint_err_pop1:
    pop rax
.gprint_error:
    lea rdx, [gprint_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда MOUSE - получить координаты мыши (Phase 20)
; Синтаксис: MOUSE X, Y
; Записывает координаты мыши в переменные X и Y
; ============================================================================
.cmd_mouse:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32                     ; Shadow space (держим выровненным)
    
    ; Парсим первую переменную (X)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .mouse_error
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx r12d, byte [rsi]
    and r12d, 0xDF
    sub r12d, 'A'
    cmp r12d, 25
    ja .mouse_error
    
    ; Запятая
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .mouse_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .mouse_error
    
    ; Парсим вторую переменную (Y)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .mouse_error
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx r13d, byte [rsi]
    and r13d, 0xDF
    sub r13d, 'A'
    cmp r13d, 25
    ja .mouse_error
    
    ; Проверяем есть ли третий аргумент (кнопка) - опционально
    xor r14d, r14d                  ; r14 = -1 означает нет третьего аргумента
    dec r14d                        ; r14 = -1
    
    ; Пробуем прочитать ещё запятую
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .mouse_no_btn
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .mouse_no_btn
    
    ; Есть третий аргумент!
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .mouse_error
    mov rsi, qword [current_token + TOKEN_VALUE]
    movzx r14d, byte [rsi]
    and r14d, 0xDF
    sub r14d, 'A'
    cmp r14d, 25
    ja .mouse_error
    jmp .mouse_get_coords
    
.mouse_no_btn:
    ; Откатываем токен (если не запятая)
    mov byte [token_pushed], 1
    
.mouse_get_coords:
    ; Если есть графическое окно - берём координаты из него
    cmp byte [gfx_active], 1
    jne .mouse_use_global
    
    ; Используем координаты из графического окна
    mov eax, [gfx_mouse_x]
    cdqe
    lea rbx, [variables]
    mov qword [rbx + r12*8], rax
    lea rbx, [var_types]
    mov byte [rbx + r12], 0
    
    mov eax, [gfx_mouse_y]
    cdqe
    lea rbx, [variables]
    mov qword [rbx + r13*8], rax
    lea rbx, [var_types]
    mov byte [rbx + r13], 0
    
    ; Записываем состояние кнопки если есть третий аргумент
    cmp r14d, -1
    je .mouse_done
    mov eax, [gfx_mouse_btn]
    cdqe
    lea rbx, [variables]
    mov qword [rbx + r14*8], rax
    lea rbx, [var_types]
    mov byte [rbx + r14], 0
    jmp .mouse_done
    
.mouse_use_global:
    ; Вызываем GetCursorPos(&POINT)
    lea rcx, [mouse_point]
    call [GetCursorPos]
    
    ; Записываем X
    mov eax, dword [mouse_point]
    cdqe
    lea rbx, [variables]
    mov qword [rbx + r12*8], rax
    lea rbx, [var_types]
    mov byte [rbx + r12], 0
    
    ; Записываем Y
    mov eax, dword [mouse_point + 4]
    cdqe
    lea rbx, [variables]
    mov qword [rbx + r13*8], rax
    lea rbx, [var_types]
    mov byte [rbx + r13], 0
    
    ; Кнопку для глобального режима не поддерживаем (пока)
    
.mouse_done:
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    
    cmp byte [run_mode], 1
    je .tokenize_loop
    
    lea rdx, [mouse_ok_msg]
    call print_cstring
    jmp .tokenize_loop
    
.mouse_error:
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    lea rdx, [mouse_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда SLEEP - пауза в миллисекундах (Phase 20)
; Синтаксис: SLEEP <ms>
; ============================================================================
.cmd_sleep:
    ; Парсим количество миллисекунд
    call parse_expression
    test rcx, rcx
    jz .sleep_error
    
    ; Phase 15: если float, конвертируем
    cmp byte [float_mode], 1
    jne .sleep_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.sleep_int:
    
    ; Вызываем Sleep(ms)
    mov rcx, rax
    sub rsp, 32
    call [Sleep]
    add rsp, 32
    
    jmp .tokenize_loop

.sleep_error:
    lea rdx, [sleep_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ----------------------------------------------------------------------------
; Команда WINDOW - создать графическое окно (Phase 21)
; Синтаксис: WINDOW width, height, "title"
; ----------------------------------------------------------------------------
.cmd_window:
    ; Парсим width
    call parse_expression
    test rcx, rcx
    jz .window_error
    
    cmp byte [float_mode], 1
    jne .window_w_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.window_w_int:
    mov r12d, eax                   ; r12 = width
    mov [gfx_width], eax
    
    ; Ожидаем запятую (может быть в token_pushed)
    cmp byte [token_pushed], 0
    jne .window_comma1_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .window_check_comma1
.window_comma1_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.window_check_comma1:
    cmp al, TOKEN_OPERATOR
    jne .window_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .window_error
    
    ; Парсим height
    call parse_expression
    test rcx, rcx
    jz .window_error
    
    cmp byte [float_mode], 1
    jne .window_h_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.window_h_int:
    mov r13d, eax                   ; r13 = height
    mov [gfx_height], eax
    
    ; Ожидаем запятую (может быть в token_pushed)
    cmp byte [token_pushed], 0
    jne .window_comma2_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .window_check_comma2
.window_comma2_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.window_check_comma2:
    cmp al, TOKEN_OPERATOR
    jne .window_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .window_error
    
    ; Ожидаем строку заголовка
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_STRING
    jne .window_error
    
    ; Получаем указатель на строку заголовка и копируем в gfx_title
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]   ; rsi = title string source
    lea rdi, [gfx_title]
.copy_title:
    lodsb
    stosb
    test al, al
    jnz .copy_title
    
    ; ---- Регистрируем класс окна ----
    ; Очистим структуру WNDCLASS
    lea rdi, [gfx_wndclass]
    xor eax, eax
    mov ecx, 80
    rep stosb
    
    ; Заполняем WNDCLASSA structure (смещения для 64-bit):
    ; 0: style (DWORD)
    ; 8: lpfnWndProc (QWORD)
    ; 16: cbClsExtra (DWORD)
    ; 20: cbWndExtra (DWORD)
    ; 24: hInstance (QWORD)
    ; 32: hIcon (QWORD)
    ; 40: hCursor (QWORD)
    ; 48: hbrBackground (QWORD)
    ; 56: lpszMenuName (QWORD)
    ; 64: lpszClassName (QWORD)
    
    lea rdi, [gfx_wndclass]
    mov dword [rdi], 0x0003         ; CS_HREDRAW | CS_VREDRAW
    lea rax, [WindowProc]
    mov [rdi+8], rax                ; lpfnWndProc
    
    ; hInstance = GetModuleHandle(NULL) - но используем 0
    xor eax, eax
    mov [rdi+24], rax
    
    ; LoadCursor(NULL, IDC_ARROW = 32512)
    xor ecx, ecx
    mov edx, 32512
    sub rsp, 32
    call [LoadCursorA]
    add rsp, 32
    lea rdi, [gfx_wndclass]
    mov [rdi+40], rax               ; hCursor
    
    ; hbrBackground = COLOR_WINDOW+1 = 6
    mov qword [rdi+48], 6
    
    ; lpszClassName
    lea rax, [gfx_class_name]
    mov [rdi+64], rax
    
    ; RegisterClassA(&wndclass)
    lea rcx, [gfx_wndclass]
    sub rsp, 32
    call [RegisterClassA]
    add rsp, 32
    
    ; Debug: проверяем результат RegisterClassA
    test ax, ax
    jnz .reg_ok
    ; RegisterClassA failed, check GetLastError
    sub rsp, 32
    call [GetLastError]
    add rsp, 32
    push rax
    lea rdx, [gfx_reg_err]
    call print_cstring
    pop rcx
    call print_number
    ; Продолжаем всё равно
.reg_ok:
    
    ; ---- AdjustWindowRect для правильного размера ----
    lea rdi, [gfx_rect]
    mov dword [rdi], 0              ; left
    mov dword [rdi+4], 0            ; top
    mov eax, r12d
    mov [rdi+8], eax                ; right = width
    mov eax, r13d
    mov [rdi+12], eax               ; bottom = height
    
    lea rcx, [gfx_rect]
    mov edx, 0x00CF0000             ; WS_OVERLAPPEDWINDOW
    xor r8d, r8d                    ; no menu
    sub rsp, 32
    call [AdjustWindowRect]
    add rsp, 32
    
    ; Вычисляем реальные размеры
    lea rdi, [gfx_rect]
    mov eax, [rdi+8]                ; right
    sub eax, [rdi]                  ; - left
    mov r15d, eax                   ; r15 = adjusted width
    
    mov eax, [rdi+12]               ; bottom
    sub eax, [rdi+4]                ; - top
    mov r14d, eax                   ; r14 = adjusted height (title уже не нужен)
    
    ; ---- CreateWindowExA ----
    ; CreateWindowExA(exStyle, className, title, style, x, y, w, h, parent, menu, instance, param)
    sub rsp, 96                     ; 12 params * 8 bytes
    
    xor ecx, ecx                    ; dwExStyle = 0
    lea rdx, [gfx_class_name]       ; lpClassName
    lea r8, [gfx_title]             ; lpWindowName (title)
    mov r9d, 0x10CF0000             ; WS_VISIBLE | WS_OVERLAPPEDWINDOW
    
    ; Используем фиксированные координаты
    mov qword [rsp+32], 100         ; X = 100 (qword!)
    mov qword [rsp+40], 100         ; Y = 100 (qword!)
    mov rax, r15
    mov [rsp+48], rax               ; nWidth (qword)
    mov rax, r14
    mov [rsp+56], rax               ; nHeight (qword)
    mov qword [rsp+64], 0           ; hWndParent
    mov qword [rsp+72], 0           ; hMenu
    mov qword [rsp+80], 0           ; hInstance
    mov qword [rsp+88], 0           ; lpParam
    
    call [CreateWindowExA]
    add rsp, 96
    
    test rax, rax
    jz .window_fail
    
    mov [gfx_hwnd], rax
    
    ; ShowWindow(hwnd, SW_SHOW) - явно показываем окно!
    mov rcx, rax
    mov edx, 5                      ; SW_SHOW = 5
    sub rsp, 32
    call [ShowWindow]
    add rsp, 32
    
    ; UpdateWindow(hwnd) - перерисовываем
    mov rcx, [gfx_hwnd]
    sub rsp, 32
    call [UpdateWindow]
    add rsp, 32
    
    ; GetDC(hwnd)
    mov rcx, [gfx_hwnd]
    sub rsp, 32
    call [GetDC]
    add rsp, 32
    mov [gfx_hdc], rax
    
    ; ---- Выделяем framebuffer ----
    ; width * height * 4 (ARGB)
    mov eax, [gfx_width]
    imul eax, [gfx_height]
    shl eax, 2                      ; * 4 bytes per pixel
    
    ; VirtualAlloc(NULL, size, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)
    xor ecx, ecx
    mov edx, eax
    mov r8d, 0x3000                 ; MEM_COMMIT | MEM_RESERVE
    mov r9d, 0x04                   ; PAGE_READWRITE
    sub rsp, 32
    call [VirtualAlloc]
    add rsp, 32
    mov [gfx_buffer], rax
    
    ; Очистим буфер (чёрный цвет)
    mov rdi, rax
    mov eax, [gfx_width]
    imul eax, [gfx_height]
    mov ecx, eax
    xor eax, eax                    ; Чёрный = 0
    rep stosd
    
    ; ---- Настраиваем BITMAPINFO ----
    lea rdi, [gfx_bmpinfo]
    xor eax, eax
    mov ecx, 64
    rep stosb
    
    lea rdi, [gfx_bmpinfo]
    mov dword [rdi], 40             ; biSize = sizeof(BITMAPINFOHEADER)
    mov eax, [gfx_width]
    mov [rdi+4], eax                ; biWidth
    mov eax, [gfx_height]
    neg eax                         ; МИНУС! Чтобы (0,0) было сверху-слева
    mov [rdi+8], eax                ; biHeight (negative = top-down)
    mov word [rdi+12], 1            ; biPlanes
    mov word [rdi+14], 32           ; biBitCount = 32 (ARGB)
    mov dword [rdi+16], 0           ; biCompression = BI_RGB
    
    mov byte [gfx_active], 1
    
    ; Успех!
    lea rdx, [gfx_ok_msg]
    call print_cstring
    jmp .tokenize_loop

.window_error:
    lea rdx, [gfx_err_msg]
    call print_cstring
    jmp .tokenize_loop

.window_fail:
    lea rdx, [gfx_fail_msg]
    call print_cstring
    jmp .tokenize_loop

; ----------------------------------------------------------------------------
; Команда PSET - установить пиксель (Phase 21)
; Синтаксис: PSET x, y, color
; ----------------------------------------------------------------------------
.cmd_pset:
    ; Проверяем что окно создано
    cmp byte [gfx_active], 1
    jne .pset_error
    
    ; Парсим X
    call parse_expression
    test rcx, rcx
    jz .pset_error
    
    cmp byte [float_mode], 1
    jne .pset_x_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.pset_x_int:
    mov r12d, eax                   ; r12 = x
    
    ; Запятая (может быть в token_pushed)
    cmp byte [token_pushed], 0
    jne .pset_comma1_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .pset_check_comma1
.pset_comma1_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.pset_check_comma1:
    cmp al, TOKEN_OPERATOR
    jne .pset_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .pset_error
    
    ; Парсим Y
    call parse_expression
    test rcx, rcx
    jz .pset_error
    
    cmp byte [float_mode], 1
    jne .pset_y_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.pset_y_int:
    mov r13d, eax                   ; r13 = y
    
    ; Запятая (может быть в token_pushed)
    cmp byte [token_pushed], 0
    jne .pset_comma2_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .pset_check_comma2
.pset_comma2_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.pset_check_comma2:
    cmp al, TOKEN_OPERATOR
    jne .pset_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .pset_error
    
    ; Парсим Color
    call parse_expression
    test rcx, rcx
    jz .pset_error
    
    cmp byte [float_mode], 1
    jne .pset_c_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.pset_c_int:
    mov r14d, eax                   ; r14 = color
    
    ; Проверяем границы
    cmp r12d, 0
    jl .pset_done
    cmp r13d, 0
    jl .pset_done
    mov eax, [gfx_width]
    cmp r12d, eax
    jge .pset_done
    mov eax, [gfx_height]
    cmp r13d, eax
    jge .pset_done
    
    ; Вычисляем смещение: offset = (y * width + x) * 4
    mov eax, r13d
    imul eax, [gfx_width]
    add eax, r12d
    shl eax, 2
    
    ; Записываем пиксель
    mov rdi, [gfx_buffer]
    mov [rdi + rax], r14d

.pset_done:
    jmp .tokenize_loop

.pset_error:
    lea rdx, [pset_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ----------------------------------------------------------------------------
; Команда UPDATE - обновить экран (Phase 21)
; Синтаксис: UPDATE
; ----------------------------------------------------------------------------
.cmd_update:
    ; Проверяем что окно создано
    cmp byte [gfx_active], 1
    jne .update_done
    
    ; Обрабатываем сообщения Windows (чтобы окно не зависло)
.update_msg_loop:
    ; PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE)
    lea rcx, [gfx_msg]
    xor edx, edx                    ; hwnd = NULL (все окна)
    xor r8d, r8d                    ; wMsgFilterMin = 0
    xor r9d, r9d                    ; wMsgFilterMax = 0
    sub rsp, 40
    mov dword [rsp+32], 1           ; PM_REMOVE = 1
    call [PeekMessageA]
    add rsp, 40
    
    test eax, eax
    jz .update_blit                 ; Нет сообщений - идём рисовать
    
    ; TranslateMessage(&msg)
    lea rcx, [gfx_msg]
    sub rsp, 32
    call [TranslateMessage]
    add rsp, 32
    
    ; DispatchMessageA(&msg)
    lea rcx, [gfx_msg]
    sub rsp, 32
    call [DispatchMessageA]
    add rsp, 32
    
    jmp .update_msg_loop

.update_blit:
    ; SetDIBitsToDevice(hdc, 0, 0, w, h, 0, 0, 0, h, buffer, bmpinfo, DIB_RGB_COLORS)
    sub rsp, 96
    
    mov rcx, [gfx_hdc]              ; hdc
    xor edx, edx                    ; xDest = 0
    xor r8d, r8d                    ; yDest = 0
    mov r9d, [gfx_width]            ; dwWidth
    
    mov eax, [gfx_height]
    mov [rsp+32], eax               ; dwHeight
    mov dword [rsp+40], 0           ; xSrc = 0
    mov dword [rsp+48], 0           ; ySrc = 0
    mov dword [rsp+56], 0           ; uStartScan = 0
    mov eax, [gfx_height]
    mov [rsp+64], eax               ; cScanLines = height
    mov rax, [gfx_buffer]
    mov [rsp+72], rax               ; lpvBits
    lea rax, [gfx_bmpinfo]
    mov [rsp+80], rax               ; lpbmi
    mov dword [rsp+88], 0           ; fuColorUse = DIB_RGB_COLORS
    
    call [SetDIBitsToDevice]
    add rsp, 96

.update_done:
    jmp .tokenize_loop

; ----------------------------------------------------------------------------
; Команда WCLS - очистить графическое окно (Phase 21)
; Синтаксис: WCLS [color]
; ----------------------------------------------------------------------------
.cmd_wcls:
    ; Проверяем что окно создано
    cmp byte [gfx_active], 1
    jne .wcls_done
    
    ; По умолчанию чёрный цвет
    xor r12d, r12d
    
    ; Пробуем парсить цвет (опционально)
    push rbx
    mov rbx, [lexer_pos]            ; Сохраняем позицию лексера
    call parse_expression
    test rcx, rcx
    jz .wcls_use_default
    
    cmp byte [float_mode], 1
    jne .wcls_c_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.wcls_c_int:
    mov r12d, eax
    pop rbx
    jmp .wcls_fill
    
.wcls_use_default:
    pop rbx
    ; Восстанавливаем позицию если не было аргумента
    ; (не нужно для цвета 0)
    
.wcls_fill:
    ; Заполняем весь буфер цветом r12d
    mov rdi, [gfx_buffer]
    mov eax, [gfx_width]
    imul eax, [gfx_height]
    mov ecx, eax
    mov eax, r12d
    rep stosd

.wcls_done:
    jmp .tokenize_loop

; ============================================================================
; Команда CAPTURE - захват 28x28 пикселей в float массив (Phase 22: Vision)
; Синтаксис: CAPTURE arrayname
; ============================================================================
.cmd_capture:
    ; Проверяем что окно создано
    cmp byte [gfx_active], 1
    jne .capture_done
    
    ; Получаем имя массива
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .capture_error
    
    ; Получаем индекс массива (первая буква имени = индекс A=0, B=1...)
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]
    cmp r12b, 'a'
    jl .capture_upper
    sub r12b, 32
.capture_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .capture_error
    
    ; r12 = индекс массива (0-25)
    ; Вычисляем адрес в array_table
    movzx eax, r12b
    shl eax, 4                           ; * 16 (ARRAY_ENTRY_SIZE)
    lea rdi, [array_table]
    add rdi, rax
    
    ; Получаем указатель на данные массива
    mov r13, qword [rdi]                 ; data pointer (offset 0 in entry)
    
    ; Теперь проходим по 28x28 пикселям framebuffer
    mov rsi, [gfx_buffer]                ; rsi = framebuffer
    mov rdi, r13                         ; rdi = output array (float64)
    
    xor r14d, r14d                       ; r14 = y
.capture_y_loop:
    cmp r14d, 28
    jge .capture_done
    
    xor r15d, r15d                       ; r15 = x
.capture_x_loop:
    cmp r15d, 28
    jge .capture_y_next
    
    ; Вычисляем offset в framebuffer: (y * width + x) * 4
    mov eax, r14d
    imul eax, [gfx_width]
    add eax, r15d
    
    ; Читаем пиксель (ARGB)
    mov ecx, [rsi + rax*4]
    and ecx, 0x00FFFFFF                  ; Маска RGB
    
    ; Если не чёрный -> 1.0, иначе 0.0
    test ecx, ecx
    jz .capture_black
    
    ; Белый (или любой не-чёрный) -> 1.0
    mov rax, 0x3FF0000000000000          ; 1.0 в double
    jmp .capture_store
    
.capture_black:
    xor rax, rax                         ; 0.0 (64-bit!)
    
.capture_store:
    mov [rdi], rax
    add rdi, 8                           ; next float64
    
    inc r15d
    jmp .capture_x_loop
    
.capture_y_next:
    inc r14d
    jmp .capture_y_loop

.capture_error:
    lea rdx, [capture_err_msg]
    call print_cstring
    
.capture_done:
    jmp .tokenize_loop

; ============================================================================
; Команда DOWNSAMPLE - сжатие области экрана в массив (Phase 23: The Lens)
; Синтаксис: DOWNSAMPLE x, y, w, h, array, scale
; Сжимает область (x,y,w,h) с коэффициентом scale в float массив
; ============================================================================
.cmd_downsample:
    ; Проверяем что окно создано
    cmp byte [gfx_active], 1
    jne .downsample_done
    
    ; Парсим x
    call parse_expression
    test rcx, rcx
    jz .downsample_error
    cmp byte [float_mode], 1
    jne .ds_x_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.ds_x_int:
    push rax                        ; [rsp+40] = x
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .ds_comma1_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ds_check_comma1
.ds_comma1_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.ds_check_comma1:
    cmp al, TOKEN_OPERATOR
    jne .downsample_err_pop1
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .downsample_err_pop1
    
    ; Парсим y
    call parse_expression
    test rcx, rcx
    jz .downsample_err_pop1
    cmp byte [float_mode], 1
    jne .ds_y_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.ds_y_int:
    push rax                        ; [rsp+32] = y
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .ds_comma2_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ds_check_comma2
.ds_comma2_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.ds_check_comma2:
    cmp al, TOKEN_OPERATOR
    jne .downsample_err_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .downsample_err_pop2
    
    ; Парсим w
    call parse_expression
    test rcx, rcx
    jz .downsample_err_pop2
    cmp byte [float_mode], 1
    jne .ds_w_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.ds_w_int:
    push rax                        ; [rsp+24] = w
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .ds_comma3_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ds_check_comma3
.ds_comma3_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.ds_check_comma3:
    cmp al, TOKEN_OPERATOR
    jne .downsample_err_pop3
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .downsample_err_pop3
    
    ; Парсим h
    call parse_expression
    test rcx, rcx
    jz .downsample_err_pop3
    cmp byte [float_mode], 1
    jne .ds_h_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.ds_h_int:
    push rax                        ; [rsp+16] = h
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .ds_comma4_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ds_check_comma4
.ds_comma4_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.ds_check_comma4:
    cmp al, TOKEN_OPERATOR
    jne .downsample_err_pop4
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .downsample_err_pop4
    
    ; Парсим имя массива
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .downsample_err_pop4
    
    ; Получаем индекс массива
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]
    cmp r12b, 'a'
    jl .ds_arr_upper
    sub r12b, 32
.ds_arr_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .downsample_err_pop4
    
    ; Получаем указатель на данные массива
    movzx eax, r12b
    shl eax, 4
    lea rdi, [array_table]
    mov r13, qword [rdi + rax]      ; r13 = array data pointer
    
    ; Запятая
    cmp byte [token_pushed], 0
    jne .ds_comma5_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ds_check_comma5
.ds_comma5_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.ds_check_comma5:
    cmp al, TOKEN_OPERATOR
    jne .downsample_err_pop4
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .downsample_err_pop4
    
    ; Парсим scale
    call parse_expression
    test rcx, rcx
    jz .downsample_err_pop4
    cmp byte [float_mode], 1
    jne .ds_scale_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.ds_scale_int:
    push rax                        ; [rsp] = scale
    
    ; Стек: [scale, h, w, y, x] (rsp -> scale)
    ; Восстанавливаем параметры
    mov r8d, [rsp]                  ; scale
    mov r9d, [rsp+8]                ; h
    mov r10d, [rsp+16]              ; w
    mov r11d, [rsp+24]              ; y
    mov r14d, [rsp+32]              ; x
    
    ; r13 = output array pointer
    ; Framebuffer pointer
    mov rsi, [gfx_buffer]
    mov rdi, r13                    ; output array
    
    ; Внешний цикл по y (выходного изображения)
    xor ebx, ebx                    ; out_y = 0
.ds_loop_y:
    mov eax, ebx
    imul eax, r8d                   ; out_y * scale
    cmp eax, r9d                    ; сравниваем с h
    jge .ds_done_y                  ; если out_y * scale >= h, выходим
    
    ; Внутренний цикл по x
    xor r15d, r15d                  ; out_x = 0
.ds_loop_x:
    mov eax, r15d
    imul eax, r8d                   ; out_x * scale
    cmp eax, r10d                   ; сравниваем с w
    jge .ds_next_y                  ; если out_x * scale >= w, следующий y
    
    ; Считаем сумму пикселей в блоке scale x scale
    xorpd xmm0, xmm0                ; sum = 0.0
    
    xor ecx, ecx                    ; dy = 0
.ds_block_y:
    cmp ecx, r8d
    jge .ds_block_done
    
    xor edx, edx                    ; dx = 0
.ds_block_x:
    cmp edx, r8d
    jge .ds_block_next_y
    
    ; Вычисляем координаты пикселя
    ; pixel_x = base_x + out_x * scale + dx
    mov eax, r15d
    imul eax, r8d
    add eax, edx
    add eax, r14d                   ; eax = pixel_x
    
    ; Сохраняем dx и pixel_x
    push rdx
    push rax
    
    ; pixel_y = base_y + out_y * scale + dy  
    mov eax, ebx
    imul eax, r8d
    add eax, ecx
    add eax, r11d                   ; eax = pixel_y
    
    ; offset = pixel_y * gfx_width + pixel_x
    imul eax, [gfx_width]           ; eax = pixel_y * width
    pop rdx                         ; rdx = pixel_x
    add eax, edx                    ; eax = offset
    
    pop rdx                         ; восстанавливаем dx
    
    ; Читаем пиксель
    mov eax, [rsi + rax*4]
    and eax, 0x00FFFFFF
    
    ; Если не чёрный - добавляем 1.0
    test eax, eax
    jz .ds_pixel_black
    
    mov rax, 0x3FF0000000000000     ; 1.0
    movq xmm1, rax
    addsd xmm0, xmm1
    
.ds_pixel_black:
    inc edx
    jmp .ds_block_x
    
.ds_block_next_y:
    inc ecx
    jmp .ds_block_y
    
.ds_block_done:
    ; Делим сумму на scale*scale чтобы получить среднее
    mov eax, r8d
    imul eax, r8d                   ; scale * scale
    cvtsi2sd xmm1, eax
    divsd xmm0, xmm1                ; avg = sum / (scale*scale)
    
    ; Если avg > 0.1 -> 1.0, иначе 0.0 (бинаризация)
    mov rax, 0x3FB999999999999A     ; 0.1 в double
    movq xmm1, rax
    comisd xmm0, xmm1
    jbe .ds_store_zero
    
    mov rax, 0x3FF0000000000000     ; 1.0
    jmp .ds_store_pixel
    
.ds_store_zero:
    xor rax, rax                    ; 0.0
    
.ds_store_pixel:
    mov [rdi], rax
    add rdi, 8
    
    inc r15d
    jmp .ds_loop_x
    
.ds_next_y:
    inc ebx
    jmp .ds_loop_y
    
.ds_done_y:
    add rsp, 40                     ; Очищаем стек (5 параметров)
    jmp .downsample_done

.downsample_err_pop4:
    add rsp, 8
.downsample_err_pop3:
    add rsp, 8
.downsample_err_pop2:
    add rsp, 8
.downsample_err_pop1:
    add rsp, 8
.downsample_error:
    lea rdx, [downsample_err_msg]
    call print_cstring
    
.downsample_done:
    jmp .tokenize_loop

; ============================================================================
; Команда FOR - начало цикла (Phase 6)
; Синтаксис: FOR <VAR> = <START> TO <END> [STEP <STEP>]
; ============================================================================
.cmd_for:
    ; Инициализируем loop_stack_ptr если первый раз
    mov rax, [loop_stack_ptr]
    test rax, rax
    jnz .for_stack_ok
    lea rax, [loop_stack]
    mov [loop_stack_ptr], rax
.for_stack_ok:
    
    ; Получаем имя переменной
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .for_error
    
    ; Сохраняем индекс переменной (0-25)
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]          ; r12 = первый символ имени
    cmp r12b, 'a'
    jl .for_check_upper
    sub r12b, 32
.for_check_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .for_error
    
    ; r12 = индекс переменной (0-25)
    
    ; Получаем '='
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .for_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    jne .for_error
    
    ; Парсим начальное значение (START)
    call parse_factor
    test rcx, rcx
    jz .for_error
    mov r13, rax                    ; r13 = START
    
    ; Ожидаем TO
    cmp byte [token_pushed], 0
    jne .for_use_current_to
    lea rdi, [current_token]
    call lexer_next_token
    jmp .for_check_to
.for_use_current_to:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.for_check_to:
    cmp al, TOKEN_KEYWORD
    jne .for_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_TO
    jne .for_error
    
    ; Парсим конечное значение (END/LIMIT)
    call parse_factor
    test rcx, rcx
    jz .for_error
    mov r14, rax                    ; r14 = LIMIT
    
    ; Проверяем есть ли STEP
    mov r15, 1                      ; r15 = STEP (по умолчанию 1)
    
    cmp byte [token_pushed], 0
    jne .for_use_current_step
    lea rdi, [current_token]
    call lexer_next_token
    jmp .for_check_step
.for_use_current_step:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.for_check_step:
    cmp al, TOKEN_KEYWORD
    jne .for_no_step
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_STEP
    jne .for_no_step
    
    ; Парсим STEP
    call parse_factor
    test rcx, rcx
    jz .for_error
    mov r15, rax                    ; r15 = STEP
    jmp .for_setup
    
.for_no_step:
    ; Откладываем токен (не STEP, может быть EOL или что-то другое)
    mov byte [token_pushed], 1

.for_setup:
    ; Присваиваем начальное значение переменной
    movzx eax, r12b
    lea rbx, [variables]
    mov qword [rbx + rax*8], r13    ; VAR = START
    
    ; Записываем фрейм в loop_stack
    ; Формат: [var_idx:8][limit:8][step:8][return_line_idx:8]
    mov rdi, [loop_stack_ptr]
    
    ; [0-7] = индекс переменной
    movzx rax, r12b
    mov qword [rdi], rax
    
    ; [8-15] = LIMIT
    mov qword [rdi + 8], r14
    
    ; [16-23] = текущий индекс строки (для возврата с NEXT)
    mov eax, [current_line]
    mov qword [rdi + 16], rax
    
    ; [24-31] = STEP
    mov qword [rdi + 24], r15
    
    ; Продвигаем указатель стека
    add qword [loop_stack_ptr], 32
    
    ; Сообщение OK (только в интерактивном режиме)
    cmp byte [run_mode], 1
    je .tokenize_loop
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_loop
    
.for_error:
    lea rdx, [for_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда NEXT - конец цикла (Phase 6)
; Синтаксис: NEXT [<VAR>]
; ============================================================================
.cmd_next:
    ; Проверяем есть ли что-то в стеке
    mov rdi, [loop_stack_ptr]
    lea rax, [loop_stack]
    cmp rdi, rax
    jle .next_error                 ; Стек пуст
    
    ; Получаем верхний фрейм (без извлечения пока)
    sub rdi, 32                     ; Указатель на текущий фрейм
    
    ; Опционально: проверяем имя переменной
    lea rbx, [current_token]
    push rdi
    lea rdi, [current_token]
    call lexer_next_token
    pop rdi
    
    cmp al, TOKEN_IDENTIFIER
    jne .next_skip_var_check        ; Нет переменной - пропускаем проверку
    
    ; Есть переменная - проверяем совпадение
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx eax, byte [rax]
    cmp al, 'a'
    jl .next_var_upper
    sub al, 32
.next_var_upper:
    sub al, 'A'
    movzx eax, al
    
    ; Сравниваем с переменной из стека
    cmp rax, qword [rdi]
    jne .next_error                 ; Несовпадение переменных!
    jmp .next_do_loop
    
.next_skip_var_check:
    ; Откладываем токен если это не переменная
    cmp al, TOKEN_EOL
    je .next_do_loop
    mov byte [token_pushed], 1
    
.next_do_loop:
    ; Получаем данные из фрейма
    ; rdi уже указывает на фрейм
    mov r12, qword [rdi]            ; r12 = индекс переменной
    mov r13, qword [rdi + 8]        ; r13 = LIMIT
    mov r14, qword [rdi + 16]       ; r14 = return_line_idx
    mov r15, qword [rdi + 24]       ; r15 = STEP
    
    ; Увеличиваем счётчик на STEP
    lea rbx, [variables]
    mov rax, qword [rbx + r12*8]    ; Текущее значение
    add rax, r15                    ; + STEP
    mov qword [rbx + r12*8], rax    ; Сохраняем обратно
    
    ; Сравниваем с LIMIT
    ; Если STEP > 0: продолжаем если VAR <= LIMIT
    ; Если STEP < 0: продолжаем если VAR >= LIMIT
    test r15, r15
    js .next_negative_step
    
    ; Положительный шаг
    cmp rax, r13
    jg .next_done                   ; VAR > LIMIT - выходим
    jmp .next_loop_back
    
.next_negative_step:
    ; Отрицательный шаг
    cmp rax, r13
    jl .next_done                   ; VAR < LIMIT - выходим
    
.next_loop_back:
    ; Возвращаемся к строке после FOR
    mov eax, r14d
    mov [current_line], eax
    jmp .run_next_line
    
.next_done:
    ; Цикл завершён - извлекаем фрейм из стека
    sub qword [loop_stack_ptr], 32
    jmp .tokenize_loop
    
.next_error:
    lea rdx, [next_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда INPUT - ввод от пользователя (Phase 8)
; Синтаксис: INPUT A (число) или INPUT A$ (строка)
; ============================================================================
.cmd_input:
    ; Получаем имя переменной
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Проверяем тип
    cmp al, TOKEN_STRING_VAR
    je .input_string
    cmp al, TOKEN_IDENTIFIER
    je .input_number
    jmp .input_error
    
; --- INPUT числа ---
.input_number:
    ; Получаем индекс переменной
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]
    cmp r12b, 'a'
    jl .input_num_upper
    sub r12b, 32
.input_num_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .input_error
    
    ; r12 = индекс переменной (0-25)
    push r12
    
    ; Выводим промпт "? "
    lea rdx, [input_prompt]
    call print_cstring
    
    ; Читаем строку от пользователя
    mov rcx, [stdin_handle]
    lea rdx, [input_buffer]
    mov r8d, INPUT_BUFFER_SIZE - 1
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call [ReadFile]
    add rsp, 40
    
    ; Парсим число из input_buffer
    lea rsi, [input_buffer]
    xor rax, rax
    xor rbx, rbx
    
.input_parse_num:
    mov bl, [rsi]
    cmp bl, '0'
    jl .input_num_done
    cmp bl, '9'
    jg .input_num_done
    imul rax, 10
    sub bl, '0'
    add rax, rbx
    inc rsi
    jmp .input_parse_num
    
.input_num_done:
    ; Сохраняем в переменную
    pop r12
    movzx r12d, r12b
    lea rbx, [variables]
    mov qword [rbx + r12*8], rax
    jmp .tokenize_done
    
; --- INPUT строки ---
.input_string:
    ; Получаем индекс строковой переменной
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]
    cmp r12b, 'a'
    jl .input_str_upper
    sub r12b, 32
.input_str_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .input_error
    
    ; r12 = индекс переменной
    push r12
    
    ; Выводим промпт "? "
    lea rdx, [input_prompt]
    call print_cstring
    
    ; Читаем строку
    mov rcx, [stdin_handle]
    lea rdx, [input_buffer]
    mov r8d, INPUT_BUFFER_SIZE - 1
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call [ReadFile]
    add rsp, 40
    
    ; Вычисляем длину (без CR/LF)
    mov ecx, [bytes_read]
    test ecx, ecx
    jz .input_str_empty
    
    ; Убираем CR/LF с конца
    lea rsi, [input_buffer]
    mov r13, rsi                    ; r13 = начало буфера
    add rsi, rcx
    dec rsi
.input_strip_crlf:
    cmp rsi, r13
    jl .input_str_empty
    mov al, [rsi]
    cmp al, 13
    je .input_strip_next
    cmp al, 10
    je .input_strip_next
    jmp .input_str_len_done
.input_strip_next:
    dec rsi
    jmp .input_strip_crlf
    
.input_str_len_done:
    ; rsi указывает на последний символ
    sub rsi, r13
    inc rsi                         ; rsi = длина строки
    mov r14, rsi                    ; r14 = длина
    
    ; Копируем в String Arena
    mov rdi, [heap_ptr]
    mov r15, rdi                    ; r15 = начало строки в heap
    lea rsi, [input_buffer]
    mov rcx, r14
    rep movsb
    
    ; Добавляем null-terminator для FFI
    mov byte [rdi], 0
    inc rdi
    
    ; Обновляем heap_ptr
    mov [heap_ptr], rdi
    
    ; Сохраняем в str_vars
    pop r12
    movzx r12d, r12b
    shl r12, 4                      ; * 16
    lea rbx, [str_vars]
    mov qword [rbx + r12], r15      ; PTR
    mov qword [rbx + r12 + 8], r14  ; LEN
    jmp .tokenize_done
    
.input_str_empty:
    pop r12
    jmp .tokenize_done
    
.input_error:
    lea rdx, [input_err_msg]
    call print_cstring
    jmp .tokenize_done

; ============================================================================
; Команда SAVE - сохранить программу в файл (Phase 8)
; Синтаксис: SAVE "filename.bas"
; ============================================================================
.cmd_save:
    ; Получаем имя файла
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_STRING
    jne .save_error
    
    ; Копируем имя файла в file_buffer (с нуль-терминатором)
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx ecx, word [rbx + TOKEN_LENGTH]
    lea rdi, [file_buffer]
    rep movsb
    mov byte [rdi], 0               ; Нуль-терминатор
    
    ; CreateFileA(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
    lea rcx, [file_buffer]          ; lpFileName
    mov edx, GENERIC_WRITE          ; dwDesiredAccess
    xor r8d, r8d                    ; dwShareMode = 0
    xor r9d, r9d                    ; lpSecurityAttributes = NULL
    push 0                          ; hTemplateFile = NULL
    push FILE_ATTRIBUTE_NORMAL      ; dwFlagsAndAttributes
    push CREATE_ALWAYS              ; dwCreationDisposition
    sub rsp, 32
    call [CreateFileA]
    add rsp, 56
    
    cmp rax, INVALID_HANDLE_VALUE
    je .save_error
    mov r12, rax                    ; r12 = file handle
    
    ; ШАГ 1: Записываем Magic Header "TITAN\0" (Phase 8.1)
    mov rcx, r12                    ; hFile
    lea rdx, [file_magic]           ; lpBuffer = "TITAN\0"
    mov r8d, MAGIC_LEN              ; 6 байт
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteFile]
    add rsp, 40
    
    ; ШАГ 2: Записываем каждую строку программы
    mov r13d, [line_count]
    test r13d, r13d
    jz .save_close                  ; Нет строк
    
    xor r14d, r14d                  ; Индекс строки
    lea r15, [line_table]
    
.save_loop:
    ; Получаем номер строки
    mov eax, [r15 + r14*8]
    push r14
    push r15
    call print_number_to_buffer     ; Число в num_buffer
    pop r15
    pop r14
    
    ; Записываем номер строки
    mov rcx, r12                    ; hFile
    lea rdx, [num_buffer]           ; lpBuffer
    mov r8d, eax                    ; nNumberOfBytesToWrite (длина числа)
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteFile]
    add rsp, 40
    
    ; Записываем пробел
    mov rcx, r12
    lea rdx, [dump_space]
    mov r8d, 1
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteFile]
    add rsp, 40
    
    ; Получаем текст строки
    mov eax, [r15 + r14*8 + 4]      ; Смещение в program_buffer
    lea rsi, [program_buffer]
    add rsi, rax                    ; RSI = указатель на текст
    
    ; Вычисляем длину строки
    xor ecx, ecx
.save_strlen:
    cmp byte [rsi + rcx], 0
    je .save_write_line
    inc ecx
    jmp .save_strlen
    
.save_write_line:
    ; Записываем текст строки
    mov r8d, ecx                    ; nNumberOfBytesToWrite
    push rcx
    push rsi                        ; Сохраняем указатель на текст
    mov rcx, r12                    ; hFile
    mov rdx, rsi                    ; lpBuffer = указатель на текст
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteFile]
    add rsp, 40
    pop rsi                         ; Восстанавливаем (не используется)
    pop rcx                         ; Восстанавливаем (не используется)
    
    ; Записываем CRLF
    mov rcx, r12
    lea rdx, [newline]
    mov r8d, 2
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteFile]
    add rsp, 40
    
    ; Следующая строка
    inc r14d
    cmp r14d, r13d
    jl .save_loop
    
.save_close:
    ; CloseHandle
    mov rcx, r12
    call [CloseHandle]
    
    lea rdx, [save_ok_msg]
    call print_cstring
    jmp .tokenize_done
    
.save_error:
    lea rdx, [save_err_msg]
    call print_cstring
    jmp .tokenize_done

; ============================================================================
; Команда LOAD - загрузить программу из файла (Phase 8)
; Синтаксис: LOAD "filename.bas"
; ============================================================================
.cmd_load:
    ; Получаем имя файла
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_STRING
    jne .load_error
    
    ; Копируем имя файла
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx ecx, word [rbx + TOKEN_LENGTH]
    lea rdi, [file_buffer]
    rep movsb
    mov byte [rdi], 0
    
    ; Сначала очищаем программу (как NEW)
    mov dword [line_count], 0
    lea rax, [program_buffer]
    mov [program_pos], rax
    
    ; CreateFileA(filename, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
    lea rcx, [file_buffer]
    mov edx, GENERIC_READ
    xor r8d, r8d
    xor r9d, r9d
    push 0
    push FILE_ATTRIBUTE_NORMAL
    push OPEN_EXISTING
    sub rsp, 32
    call [CreateFileA]
    add rsp, 56
    
    cmp rax, INVALID_HANDLE_VALUE
    je .load_error
    mov r12, rax                    ; r12 = file handle
    
    ; Читаем весь файл в string_heap (временный буфер)
    mov rcx, r12
    lea rdx, [string_heap]
    mov r8d, 32768                  ; Читаем до 32KB
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call [ReadFile]
    add rsp, 40
    
    ; Закрываем файл
    mov rcx, r12
    call [CloseHandle]
    
    ; ШАГ 1: Проверяем Magic Header "TITAN\0" (Phase 8.1)
    mov ecx, [bytes_read]
    cmp ecx, MAGIC_LEN
    jl .load_bad_format             ; Файл слишком короткий
    
    ; Сравниваем первые 6 байт с "TITAN\0"
    lea rsi, [string_heap]
    lea rdi, [file_magic]
    mov ecx, MAGIC_LEN
.load_check_magic:
    mov al, [rsi]
    cmp al, [rdi]
    jne .load_bad_format
    inc rsi
    inc rdi
    dec ecx
    jnz .load_check_magic
    
    ; Magic OK! RSI теперь указывает на данные после заголовка
    ; ШАГ 2: Парсим файл построчно
    mov ecx, [bytes_read]
    sub ecx, MAGIC_LEN              ; Вычитаем длину заголовка
    test ecx, ecx
    jz .load_done
    
    add rcx, rsi                    ; rcx = конец данных
    mov r13, rcx                    ; r13 = конец
    
.load_parse_loop:
    cmp rsi, r13
    jge .load_done
    
    ; Пропускаем пустые строки
    mov al, [rsi]
    cmp al, 13
    je .load_skip_char
    cmp al, 10
    je .load_skip_char
    cmp al, 0
    je .load_done
    
    ; Копируем строку в input_buffer
    lea rdi, [input_buffer]
    xor ecx, ecx
.load_copy_line:
    cmp rsi, r13
    jge .load_line_done
    mov al, [rsi]
    cmp al, 13
    je .load_line_done
    cmp al, 10
    je .load_line_done
    mov [rdi + rcx], al
    inc ecx
    inc rsi
    jmp .load_copy_line
    
.load_line_done:
    mov byte [rdi + rcx], 0         ; Нуль-терминатор
    
    ; Инициализируем лексер
    push rsi
    push r13
    lea rsi, [input_buffer]
    mov [lexer_pos], rsi
    mov byte [lexer_error], 0
    mov byte [token_pushed], 0
    mov byte [first_token], 1
    
    ; Читаем первый токен (номер строки)
    lea rdi, [current_token]
    call lexer_next_token
    
    cmp al, TOKEN_NUMBER
    jne .load_skip_line
    
    ; Добавляем строку в программу
    call .add_program_line_internal
    
.load_skip_line:
    pop r13
    pop rsi
    jmp .load_parse_loop
    
.load_skip_char:
    inc rsi
    jmp .load_parse_loop
    
.load_done:
    lea rdx, [load_ok_msg]
    call print_cstring
    jmp .tokenize_done

.load_bad_format:
    ; Ошибка: неверный формат файла (нет Magic Header)
    lea rdx, [bad_format_msg]
    call print_cstring
    jmp .tokenize_done
    
.load_error:
    lea rdx, [load_err_msg]
    call print_cstring
    jmp .tokenize_done

; ============================================================================
; SIMD команды (Phase 9)
; ============================================================================

; --- VDIM Vn — объявить векторную переменную ---
.cmd_vdim:
    ; Проверяем поддержку AVX2
    cmp byte [cpu_has_avx2], 1
    jne .simd_no_avx2
    
    ; Получаем имя вектора (V0-V9)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vdim_error
    
    ; Проверяем что это V + цифра
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vdim_error
    mov al, [rsi + 1]
    cmp al, '0'
    jl .vdim_error
    cmp al, '9'
    jg .vdim_error
    
    ; Получаем индекс (0-9)
    sub al, '0'
    movzx ecx, al                   ; ECX = индекс вектора (0-9)
    
    ; Инициализируем вектор нулями (256 бит = 32 байта)
    ; Используем AVX: vpxor ymm0, ymm0, ymm0 затем vmovdqa
    lea rdi, [vector_vars]
    shl ecx, 5                      ; ecx * 32 = смещение
    add rdi, rcx
    
    ; Обнуляем вектор с помощью AVX
    vpxor ymm0, ymm0, ymm0
    vmovdqa [rdi], ymm0
    
    lea rdx, [simd_vdim_msg]
    call print_cstring
    jmp .tokenize_done

.vdim_error:
    lea rdx, [simd_err_msg]
    call print_cstring
    jmp .tokenize_done

; --- VSET Vn = n1,n2,n3,n4,n5,n6,n7,n8 ---
.cmd_vset:
    cmp byte [cpu_has_avx2], 1
    jne .simd_no_avx2
    
    ; Получаем имя вектора
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vset_error
    
    ; Проверяем V + цифра
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vset_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vset_error
    movzx r12d, al                  ; r12 = индекс вектора
    
    ; Пропускаем '='
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .vset_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    jne .vset_error
    
    ; Читаем 8 чисел через запятую
    xor r13d, r13d                  ; r13 = счётчик чисел (0-7)
    
.vset_read_loop:
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_NUMBER
    jne .vset_error
    
    ; Сохраняем число в num_buffer (временно как массив)
    lea rbx, [current_token]
    mov eax, dword [rbx + TOKEN_VALUE]
    lea rdi, [num_buffer]
    mov [rdi + r13*4], eax          ; num_buffer используем как temp array
    
    inc r13d
    cmp r13d, 8
    jge .vset_load_vector
    
    ; Проверяем запятую
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .vset_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    jne .vset_error
    jmp .vset_read_loop

.vset_load_vector:
    ; Загружаем данные в вектор AVX
    lea rsi, [num_buffer]
    vmovdqu ymm0, [rsi]             ; Загружаем 8 int32 в ymm0
    
    ; Сохраняем в vector_vars[r12]
    lea rdi, [vector_vars]
    mov eax, r12d
    shl eax, 5                      ; * 32
    add rdi, rax
    vmovdqa [rdi], ymm0
    
    ; Выводим OK (только в интерактивном режиме)
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_done

.vset_error:
    lea rdx, [simd_vset_err]
    call print_cstring
    jmp .tokenize_done

; --- VADD Vn Vm — V[n] = V[n] + V[m] ---
.cmd_vadd:
    cmp byte [cpu_has_avx2], 1
    jne .simd_no_avx2
    
    ; Получаем первый вектор (destination)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vadd_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vadd_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vadd_error
    movzx r12d, al                  ; r12 = индекс первого вектора
    
    ; Получаем второй вектор (source)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vadd_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vadd_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vadd_error
    movzx r13d, al                  ; r13 = индекс второго вектора
    
    ; Загружаем оба вектора
    lea rsi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    vmovdqa ymm0, [rsi + rax]       ; ymm0 = V[r12]
    
    mov eax, r13d
    shl eax, 5
    vmovdqa ymm1, [rsi + rax]       ; ymm1 = V[r13]
    
    ; Параллельное сложение 8 int32 одной инструкцией!
    vpaddd ymm0, ymm0, ymm1         ; ymm0 = ymm0 + ymm1
    
    ; Сохраняем результат в V[r12]
    lea rdi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    vmovdqa [rdi + rax], ymm0
    
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_done

.vadd_error:
    lea rdx, [simd_vadd_err]
    call print_cstring
    jmp .tokenize_done

; --- VSUB V1 V2 — параллельное вычитание 8 int32 ---
.cmd_vsub:
    cmp byte [cpu_has_avx2], 1
    jne .simd_no_avx2
    
    ; Получаем первый вектор (destination)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vsub_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vsub_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vsub_error
    movzx r12d, al                  ; r12 = индекс первого вектора
    
    ; Получаем второй вектор (source)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vsub_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vsub_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vsub_error
    movzx r13d, al                  ; r13 = индекс второго вектора
    
    ; Загружаем оба вектора
    lea rsi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    vmovdqa ymm0, [rsi + rax]       ; ymm0 = V[r12]
    
    mov eax, r13d
    shl eax, 5
    vmovdqa ymm1, [rsi + rax]       ; ymm1 = V[r13]
    
    ; Параллельное вычитание 8 int32 одной инструкцией!
    vpsubd ymm0, ymm0, ymm1         ; ymm0 = ymm0 - ymm1
    
    ; Сохраняем результат в V[r12]
    lea rdi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    vmovdqa [rdi + rax], ymm0
    
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_done

.vsub_error:
    lea rdx, [simd_vsub_err]
    call print_cstring
    jmp .tokenize_done

; --- VMUL V1 V2 — параллельное умножение 8 int32 (Phase 11) ---
.cmd_vmul:
    cmp byte [cpu_has_avx2], 1
    jne .simd_no_avx2
    
    ; Получаем первый вектор (destination)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vmul_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vmul_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vmul_error
    movzx r12d, al                  ; r12 = индекс первого вектора
    
    ; Получаем второй вектор (source)
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vmul_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vmul_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vmul_error
    movzx r13d, al                  ; r13 = индекс второго вектора
    
    ; Загружаем оба вектора
    lea rsi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    vmovdqa ymm0, [rsi + rax]       ; ymm0 = V[r12]
    
    mov eax, r13d
    shl eax, 5
    vmovdqa ymm1, [rsi + rax]       ; ymm1 = V[r13]
    
    ; Параллельное умножение 8 int32 одной инструкцией!
    ; vpmulld = Vector Packed Multiply Low Dword
    vpmulld ymm0, ymm0, ymm1        ; ymm0 = ymm0 * ymm1
    
    ; Сохраняем результат в V[r12]
    lea rdi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    vmovdqa [rdi + rax], ymm0
    
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [let_ok_msg]
    call print_cstring
    jmp .tokenize_done

.vmul_error:
    lea rdx, [simd_vmul_err]
    call print_cstring
    jmp .tokenize_done

; --- VPRINT Vn — вывести все 8 элементов вектора ---
.cmd_vprint:
    cmp byte [cpu_has_avx2], 1
    jne .simd_no_avx2
    
    ; Получаем имя вектора
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .vprint_error
    
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    mov al, [rsi]
    cmp al, 'V'
    jne .vprint_error
    mov al, [rsi + 1]
    sub al, '0'
    cmp al, 9
    ja .vprint_error
    movzx r12d, al                  ; r12 = индекс вектора
    
    ; Получаем адрес вектора
    lea rsi, [vector_vars]
    mov eax, r12d
    shl eax, 5
    add rsi, rax
    
    ; Выводим 8 чисел
    xor r13d, r13d                  ; счётчик
.vprint_loop:
    mov eax, [rsi + r13*4]          ; Загружаем элемент
    push rsi
    push r13
    call print_number               ; Выводим число
    pop r13
    pop rsi
    
    ; Выводим пробел (кроме последнего)
    inc r13d
    cmp r13d, 8
    jge .vprint_newline
    
    push rsi
    push r13
    lea rdx, [dump_space]
    call print_cstring
    pop r13
    pop rsi
    jmp .vprint_loop

.vprint_newline:
    lea rdx, [newline]
    call print_cstring
    jmp .tokenize_done

.vprint_error:
    lea rdx, [simd_err_msg]
    call print_cstring
    jmp .tokenize_done

; --- Общая ошибка: AVX2 не поддерживается ---
.simd_no_avx2:
    lea rdx, [simd_err_msg]
    call print_cstring
    jmp .tokenize_done

; ============================================================================
; TIMER (Phase 11) — высокоточный таймер через RDTSC
; ============================================================================

; --- TIMER <var> — сохранить текущее значение тактов процессора ---
.cmd_timer:
    ; Получаем имя переменной
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .timer_error
    
    ; Получаем указатель на строку имени
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    
    ; Вычисляем индекс переменной (первая буква - 'A')
    movzx eax, byte [rsi]
    cmp al, 'a'
    jl .timer_upper
    sub al, 32                      ; Приводим к верхнему регистру
.timer_upper:
    sub al, 'A'
    cmp al, 25
    ja .timer_error
    movzx r12d, al                  ; r12 = индекс переменной
    
    ; Выполняем RDTSC — читаем счётчик тактов процессора
    ; Результат: EDX:EAX (64-бит значение)
    rdtsc
    
    ; Объединяем EDX:EAX в RAX
    shl rdx, 32
    or rax, rdx
    
    ; Сохраняем в переменную
    lea rdi, [variables]
    mov [rdi + r12*8], rax
    
    jmp .tokenize_done

.timer_error:
    lea rdx, [timer_err_msg]
    call print_cstring
    jmp .tokenize_done

; ============================================================================
; FUNC/ENDFUNC/LOCAL (Phase 12) — Локальные переменные и стековые фреймы
; ============================================================================

; --- FUNC [Name] — начало функции, создание стекового фрейма ---
; Генерирует пролог: push rbp / mov rbp, rsp / sub rsp, 64
.cmd_func:
    ; === Phase 12.3: Поддержка рекурсии — сохраняем текущий контекст ===
    
    ; Проверяем глубину вложенности (макс 16)
    cmp byte [current_scope], 16
    jge .func_too_deep
    
    ; Если мы уже внутри функции — сохраняем контекст в стек
    cmp byte [current_scope], 0
    je .func_first_level
    
    ; --- Сохраняем текущий контекст (выровненный) ---
    mov rdi, [func_stack_ptr]
    
    ; Сохраняем func_rbp_saved [0-7] (8 байт)
    mov rax, [func_rbp_saved]
    mov [rdi], rax
    
    ; Сохраняем local_vars_cnt [8] (1 байт, padding до 16) 
    movzx eax, byte [local_vars_cnt]
    mov [rdi + 8], al
    
    ; Сохраняем local_var_map [16-31] (16 байт, выровнено)
    lea rsi, [local_var_map]
    mov rax, [rsi]
    mov [rdi + 16], rax
    mov rax, [rsi + 8]
    mov [rdi + 24], rax
    
    ; Сдвигаем указатель стека контекстов
    add qword [func_stack_ptr], 32
    
.func_first_level:
    ; Увеличиваем глубину вложенности
    inc byte [current_scope]
    
    ; Очищаем таблицу локальных переменных для НОВОГО контекста
    mov byte [local_vars_cnt], 0
    lea rdi, [local_var_map]
    xor eax, eax
    mov ecx, 2                      ; 2 qwords = 16 байт (НЕ 4!)
    rep stosq
    
    ; === Phase 12.4: Вычисляем указатель на фрейм в статическом хранилище ===
    ; func_rbp_saved = local_vars_storage + (current_scope - 1) * 64
    movzx eax, byte [current_scope]
    dec eax                         ; 0-based индекс уровня
    shl eax, 6                      ; × 64 байта на уровень
    lea rbx, [local_vars_storage]
    add rbx, rax
    mov [func_rbp_saved], rbx       ; Сохраняем указатель на фрейм
    
    ; Инициализируем локальные переменные нулями
    mov rdi, rbx
    xor eax, eax
    mov ecx, 8
    rep stosq
    
    ; Выводим сообщение (только в интерактивном режиме)
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [func_enter_msg]
    call print_cstring
    jmp .tokenize_done

.func_too_deep:
    lea rdx, [func_err_msg]
    call print_cstring
    jmp .tokenize_done

.func_nested_error:
    lea rdx, [func_err_msg]
    call print_cstring
    jmp .tokenize_done

; --- ENDFUNC — конец функции, восстановление контекста ---
.cmd_endfunc:
    ; Проверяем что мы внутри функции
    cmp byte [current_scope], 0
    je .endfunc_no_func
    
    ; === Phase 12.4: Статическая память — не нужно освобождать стек ===
    
    ; Уменьшаем глубину вложенности
    dec byte [current_scope]
    
    ; Если вернулись на глобальный уровень — просто выходим
    cmp byte [current_scope], 0
    je .endfunc_global
    
    ; --- Восстанавливаем предыдущий контекст из стека (выровненный) ---
    sub qword [func_stack_ptr], 32
    mov rdi, [func_stack_ptr]
    
    ; Восстанавливаем func_rbp_saved [0-7]
    mov rax, [rdi]
    mov [func_rbp_saved], rax
    
    ; Восстанавливаем local_vars_cnt [8]
    movzx eax, byte [rdi + 8]
    mov [local_vars_cnt], al
    
    ; Восстанавливаем local_var_map [16-31] (выровнено)
    lea rsi, [local_var_map]
    mov rax, [rdi + 16]
    mov [rsi], rax
    mov rax, [rdi + 24]
    mov [rsi + 8], rax
    
    jmp .endfunc_done
    
.endfunc_global:
    ; Очищаем всё
    mov byte [local_vars_cnt], 0
    
.endfunc_done:
    ; Выводим сообщение
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [func_exit_msg]
    call print_cstring
    jmp .tokenize_done

.endfunc_no_func:
    lea rdx, [endfunc_err_msg]
    call print_cstring
    jmp .tokenize_done

; --- LOCAL <var> — объявление локальной переменной ---
.cmd_local:
    ; Проверяем что мы внутри функции (current_scope > 0)
    cmp byte [current_scope], 0
    je .local_not_in_func
    
    ; Получаем имя переменной
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .local_error
    
    ; Получаем первую букву имени
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx eax, byte [rsi]
    
    ; Приводим к верхнему регистру
    cmp al, 'a'
    jl .local_upper
    sub al, 32
.local_upper:
    sub al, 'A'
    cmp al, 25
    ja .local_error
    
    ; Добавляем в таблицу локальных переменных
    movzx ecx, byte [local_vars_cnt]
    cmp cl, 8
    jge .local_too_many
    
    ; Записываем: [var_index, offset]
    lea rdi, [local_var_map]
    mov byte [rdi + rcx*2], al           ; Индекс переменной (0-25)
    inc cl
    mov byte [rdi + rcx*2 - 1], cl       ; Offset = номер × 8 (1-8)
    mov [local_vars_cnt], cl
    
    ; Выводим сообщение
    cmp byte [run_mode], 1
    je .tokenize_done
    lea rdx, [local_decl_msg]
    call print_cstring
    jmp .tokenize_done

.local_not_in_func:
    lea rdx, [local_err_msg]
    call print_cstring
    jmp .tokenize_done

.local_too_many:
.local_error:
    lea rdx, [local_err_msg]
    call print_cstring
    jmp .tokenize_done

; ============================================================================
; END/STOP/GOSUB/RETURN (Phase 10)
; ============================================================================

; --- REM — комментарий ---
.cmd_rem:
    jmp .tokenize_done

; --- END/STOP — завершение программы ---
.cmd_end:
    ; Прекращаем выполнение, возвращаемся в REPL
    mov byte [run_mode], 0          ; Выключаем режим выполнения
    jmp repl_loop

; --- GOSUB <line> — вызов подпрограммы ---
.cmd_gosub:
    ; Получаем номер строки
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_NUMBER
    jne .gosub_error
    
    ; Сохраняем целевую строку
    lea rbx, [current_token]
    mov r12d, dword [rbx + TOKEN_VALUE]     ; r12 = target line number
    
    ; Сохраняем текущую позицию (current_line) в call_stack
    mov rdi, [call_stack_ptr]
    mov eax, [current_line]
    mov [rdi], eax                          ; Сохраняем индекс текущей строки
    add qword [call_stack_ptr], 4           ; Двигаем указатель стека
    
    ; Ищем целевую строку в line_table
    lea rsi, [line_table]
    mov ecx, [line_count]
    xor ebx, ebx
.gosub_find_loop:
    cmp ebx, ecx
    jge .gosub_not_found
    mov eax, [rsi + rbx*8]
    cmp eax, r12d
    je .gosub_found
    inc ebx
    jmp .gosub_find_loop

.gosub_found:
    ; Переходим к найденной строке
    mov [current_line], ebx
    jmp .run_next_line

.gosub_not_found:
    lea rdx, [goto_err_msg]
    call print_cstring
    jmp .tokenize_done

.gosub_error:
    lea rdx, [gosub_err_msg]
    call print_cstring
    jmp .tokenize_done

; --- RETURN — возврат из подпрограммы ---
.cmd_return:
    ; Проверяем что стек не пуст
    mov rdi, [call_stack_ptr]
    lea rax, [call_stack]
    cmp rdi, rax
    jbe .return_error               ; Стек пуст (указатель <= база)
    
    ; Достаём адрес возврата
    sub qword [call_stack_ptr], 4
    mov rdi, [call_stack_ptr]
    mov eax, [rdi]                  ; eax = индекс строки где был GOSUB
    
    ; Возвращаемся к следующей строке после GOSUB
    ; current_line уже указывает на следующую строку (inc был в .run_next_line)
    mov [current_line], eax
    jmp .run_next_line

.return_error:
    lea rdx, [return_err_msg]
    call print_cstring
    jmp .tokenize_done

; --- Вспомогательная функция: добавить строку (вызывается из LOAD) ---
.add_program_line_internal:
    ; current_token содержит номер строки
    lea rbx, [current_token]
    mov r12d, dword [rbx + TOKEN_VALUE]
    mov r15, [lexer_pos]
    
    ; Добавляем в конец (упрощённо)
    mov ecx, [line_count]
    lea rdi, [line_table]
    mov [rdi + rcx*8], r12d
    
    mov rax, [program_pos]
    test rax, rax
    jnz .load_has_pos
    lea rax, [program_buffer]
    mov [program_pos], rax
.load_has_pos:
    lea rbx, [program_buffer]
    mov rdx, [program_pos]
    sub rdx, rbx
    mov [rdi + rcx*8 + 4], edx
    
    ; Копируем текст
    mov rsi, r15
    mov rdi, [program_pos]
.load_copy_text:
    lodsb
    stosb
    test al, al
    jnz .load_copy_text
    mov [program_pos], rdi
    
    inc dword [line_count]
    ret

; ============================================================================
; Добавление строки в программу (Phase 5)
; ============================================================================
.add_program_line:
    ; current_token содержит номер строки
    lea rbx, [current_token]
    mov r12d, dword [rbx + TOKEN_VALUE]  ; r12 = номер строки
    
    ; Получаем остаток строки (после номера)
    mov r15, [lexer_pos]            ; r15 = Указатель на остаток (сохраняем!)
    
    ; Ищем или создаём запись в line_table
    ; Формат: [line_num:4][offset:4] × line_count
    lea rdi, [line_table]
    mov ecx, [line_count]
    test ecx, ecx
    jz .add_new_line                ; Пустая таблица
    
    xor ebx, ebx                    ; Индекс
.find_line_loop:
    mov eax, [rdi + rbx*8]          ; Номер строки
    cmp eax, r12d
    je .replace_line                ; Найдена - заменяем
    jg .insert_line                 ; Нашли место для вставки
    inc ebx
    cmp ebx, ecx
    jl .find_line_loop
    
    ; Добавляем в конец
    jmp .add_new_line
    
.insert_line:
    ; Для MVP: просто добавляем в конец (игнорируем порядок)
    ; TODO: реализовать вставку с сортировкой
    
.add_new_line:
    ; Добавляем новую запись
    mov ecx, [line_count]
    lea rdi, [line_table]
    
    ; Записываем номер строки
    mov [rdi + rcx*8], r12d
    
    ; Инициализируем program_pos если нужно
    mov rax, [program_pos]
    test rax, rax
    jnz .has_program_pos
    lea rax, [program_buffer]
    mov [program_pos], rax
.has_program_pos:
    
    ; Записываем смещение
    lea rbx, [program_buffer]
    mov rdx, [program_pos]
    sub rdx, rbx                    ; Смещение от начала буфера
    mov [rdi + rcx*8 + 4], edx
    
    ; Копируем текст строки из r15
    mov rsi, r15                    ; RSI = указатель на текст
    mov rdi, [program_pos]
.copy_line:
    lodsb
    stosb
    test al, al
    jnz .copy_line
    mov [program_pos], rdi
    
    ; Увеличиваем счётчик строк
    inc dword [line_count]
    
    jmp repl_loop
    
.replace_line:
    ; Для простоты: пока не поддерживаем замену
    ; TODO: реализовать замену строки
    jmp .add_new_line

; ============================================================================
; Команда RUN - выполнить программу
; ============================================================================
.cmd_run:
    mov dword [current_line], 0     ; Начинаем с первой строки в таблице
    mov byte [run_mode], 1          ; Режим выполнения программы
    
    ; === Phase 12.3: Сброс стека контекстов при запуске ===
    mov byte [current_scope], 0
    mov byte [local_vars_cnt], 0
    lea rax, [func_context_stack]
    mov [func_stack_ptr], rax
    
    ; Инициализируем стеки циклов  
    lea rax, [loop_stack]
    mov [loop_stack_ptr], rax
    
.run_next_line:
    ; Проверяем есть ли ещё строки
    mov eax, [current_line]
    cmp eax, [line_count]
    jge .run_done
    
    ; Получаем указатель на текст строки
    lea rbx, [line_table]
    mov ecx, [current_line]
    mov edx, [rbx + rcx*8 + 4]      ; Смещение в program_buffer
    lea rsi, [program_buffer]
    add rsi, rdx                    ; RSI = указатель на текст
    
    ; Копируем в input_buffer для лексера
    lea rdi, [input_buffer]
.copy_to_input:
    lodsb
    stosb
    test al, al
    jnz .copy_to_input
    
    ; Инициализируем лексер
    lea rsi, [input_buffer]
    mov [lexer_pos], rsi
    mov byte [lexer_error], 0
    mov byte [token_pushed], 0
    
    ; Переходим к следующей строке (если не будет GOTO)
    inc dword [current_line]
    
    ; Выполняем команды
    jmp .tokenize_loop

.run_done:
    mov byte [run_mode], 0
    jmp .tokenize_done

; ============================================================================
; Команда LIST - вывести программу
; ============================================================================
.cmd_list:
    mov ecx, [line_count]
    test ecx, ecx
    jz .list_empty
    
    xor r12d, r12d                  ; Индекс
    lea r13, [line_table]
    
.list_loop:
    ; Выводим номер строки
    mov eax, [r13 + r12*8]
    call print_number
    
    ; Пробел
    lea rdx, [dump_space]
    call print_cstring
    
    ; Выводим текст строки
    mov eax, [r13 + r12*8 + 4]      ; Смещение
    lea rdx, [program_buffer]
    add rdx, rax                    ; RDX = program_buffer + смещение
    call print_cstring
    
    ; Новая строка
    lea rdx, [newline]
    call print_cstring
    
    inc r12d
    cmp r12d, [line_count]
    jl .list_loop
    
    jmp .tokenize_loop
    
.list_empty:
    jmp .tokenize_loop

; ============================================================================
; Команда NEW - очистить программу
; ============================================================================
.cmd_new:
    mov dword [line_count], 0
    lea rax, [program_buffer]
    mov [program_pos], rax
    
    ; === Phase 12.3: Сброс стека контекстов функций ===
    mov byte [current_scope], 0
    mov byte [local_vars_cnt], 0
    lea rax, [func_context_stack]
    mov [func_stack_ptr], rax
    
    jmp .tokenize_loop

; ============================================================================
; Команда GOTO - переход к строке
; ============================================================================
.cmd_goto:
    ; Получаем номер строки
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_NUMBER
    jne .goto_error
    
    lea rbx, [current_token]
    mov r12d, dword [rbx + TOKEN_VALUE]  ; Целевой номер строки
    
    ; Ищем строку в таблице
    lea rdi, [line_table]
    mov ecx, [line_count]
    test ecx, ecx
    jz .goto_error
    
    xor ebx, ebx
.goto_find:
    mov eax, [rdi + rbx*8]
    cmp eax, r12d
    je .goto_found
    inc ebx
    cmp ebx, ecx
    jl .goto_find
    
    ; Строка не найдена
    jmp .goto_error
    
.goto_found:
    ; Устанавливаем current_line на найденный индекс
    mov [current_line], ebx
    
    ; Если в режиме RUN - продолжаем выполнение
    cmp byte [run_mode], 1
    je .run_next_line
    
    ; Иначе просто выходим (GOTO в REPL ничего не делает)
    jmp .tokenize_loop
    
.goto_error:
    lea rdx, [goto_err_msg]
    call print_cstring
    jmp .tokenize_loop

; ============================================================================
; Команда IF - условный переход
; Синтаксис: IF <value> <op> <value> THEN <command>
; Для MVP: только простые сравнения (переменная или число)
; ============================================================================
.cmd_if:
    ; Парсим левое значение (переменная или число)
    call parse_factor
    test rcx, rcx
    jz .if_error
    mov r12, rax                    ; r12 = левое значение
    
    ; Получаем оператор сравнения
    cmp byte [token_pushed], 0
    jne .if_use_current
    lea rdi, [current_token]
    call lexer_next_token
    jmp .if_check_op
.if_use_current:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.if_check_op:
    cmp al, TOKEN_OPERATOR
    jne .if_error
    
    movzx r14d, byte [current_token + TOKEN_SUBTYPE]  ; r14 = оператор
    
    ; Парсим правое значение
    call parse_factor
    test rcx, rcx
    jz .if_error
    mov r13, rax                    ; r13 = правое значение
    
    ; Получаем следующий токен (должен быть THEN)
    lea rdi, [current_token]
    call lexer_next_token
    
    cmp al, TOKEN_KEYWORD
    jne .if_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, KW_THEN
    jne .if_error
    
    ; Выполняем сравнение
    cmp r14d, OP_EQ
    je .if_eq
    cmp r14d, OP_LT
    je .if_lt
    cmp r14d, OP_GT
    je .if_gt
    cmp r14d, OP_LE
    je .if_le
    cmp r14d, OP_GE
    je .if_ge
    cmp r14d, OP_NE
    je .if_ne
    jmp .if_error
    
.if_eq:
    cmp r12, r13
    jne .if_false
    jmp .if_true
    
.if_lt:
    cmp r12, r13
    jge .if_false
    jmp .if_true
    
.if_gt:
    cmp r12, r13
    jle .if_false
    jmp .if_true
    
.if_le:
    cmp r12, r13
    jg .if_false
    jmp .if_true
    
.if_ge:
    cmp r12, r13
    jl .if_false
    jmp .if_true
    
.if_ne:
    cmp r12, r13
    je .if_false
    jmp .if_true
    
.if_true:
    ; Условие истинно - продолжаем выполнение (следующий токен после THEN)
    jmp .tokenize_loop
    
.if_false:
    ; Условие ложно - пропускаем остаток строки, идём к следующей
    jmp .tokenize_done
    
.if_error:
    lea rdx, [if_err_msg]
    call print_cstring
    jmp .tokenize_loop

; Неизвестное ключевое слово - игнорируем
.print_keyword_debug:
    jmp .tokenize_loop

.handle_number:
    ; Число вне контекста - игнорируем
    jmp .tokenize_loop

.handle_string:
    ; Строка вне контекста - игнорируем
    jmp .tokenize_loop

.handle_identifier:
    ; Phase 17: Проверяем на неявный LET (A=5 или A(0)=5)
    ; Сначала сохраняем информацию о текущем идентификаторе
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rsi]          ; r12 = первая буква имени
    
    ; Смотрим следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Если '(' - это массив или вызов функции
    cmp al, TOKEN_OPERATOR
    jne .ident_check_ffi
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    je .ident_implicit_let          ; A = value (простая переменная)
    cmp al, OP_LPAREN
    je .ident_array_or_func
    
.ident_check_ffi:
    ; Не присваивание - проверяем FFI
    ; Вычисляем хеш имени идентификатора (нужно заново получить имя)
    mov byte [token_pushed], 1      ; Откатываем токен
    lea rbx, [current_token]
    ; Нужно восстановить имя... на самом деле проще всего перейти к старому коду
    jmp .ident_check_ffi_old

.ident_implicit_let:
    ; A = value — неявный LET для простой переменной
    ; r12 = первая буква
    cmp r12b, 'a'
    jl .ident_implicit_let_upper
    sub r12b, 32
.ident_implicit_let_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .tokenize_loop
    
    ; Парсим значение
    call parse_expression
    test rcx, rcx
    jz .tokenize_loop
    
    mov r13, rax                    ; r13 = value from parse_expression
    
    ; Сохраняем значение
    movzx eax, r12b
    lea rbx, [variables]
    mov qword [rbx + rax*8], r13    ; Store value (r13)
    
    ; Сохраняем тип
    lea rbx, [var_types]
    movzx ecx, byte [float_mode]
    mov byte [rbx + rax], cl
    
    jmp .tokenize_loop

.ident_array_or_func:
    ; A(...) - это массив A(index) или вызов функции
    ; Смотрим что дальше после скобок
    ; Для простоты: если следующий токен после ')' это '=', то это присваивание массива
    
    ; Сохраняем индекс массива
    cmp r12b, 'a'
    jl .ident_arr_upper
    sub r12b, 32
.ident_arr_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .tokenize_loop
    
    push r12                        ; Сохраняем индекс массива
    
    ; Парсим индекс элемента
    call parse_expression
    test rcx, rcx
    jz .ident_arr_error_pop1
    
    push rax                        ; Сохраняем индекс элемента
    
    ; Ожидаем ')'
    cmp byte [token_pushed], 0
    jne .ident_arr_use_pushed_rparen
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ident_arr_check_rparen
.ident_arr_use_pushed_rparen:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.ident_arr_check_rparen:
    cmp al, TOKEN_OPERATOR
    jne .ident_arr_error_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .ident_arr_error_pop2
    
    ; Смотрим следующий токен - должен быть '='
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .ident_arr_error_pop2
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_EQ
    jne .ident_arr_error_pop2
    
    ; Парсим значение
    call parse_expression
    test rcx, rcx
    jz .ident_arr_error_pop2
    
    mov r13, rax                    ; r13 = value
    
    ; Восстанавливаем индексы
    pop rcx                         ; rcx = element index
    pop r12                         ; r12 = array index
    
    ; Получаем информацию о массиве
    movzx eax, r12b
    shl eax, 4
    lea rbx, [array_table]
    mov rdi, qword [rbx + rax]
    mov r14, qword [rbx + rax + 8]
    
    test rdi, rdi
    jz .let_arr_undef
    
    test rcx, rcx
    js .let_arr_bounds
    cmp rcx, r14
    jge .let_arr_bounds
    
    ; Конвертируем и сохраняем
    cmp byte [float_mode], 1
    je .ident_arr_store_float
    cvtsi2sd xmm0, r13
    movq r13, xmm0
.ident_arr_store_float:
    mov qword [rdi + rcx*8], r13
    jmp .tokenize_loop

.ident_arr_error_pop2:
    pop rax
.ident_arr_error_pop1:
    pop r12
    jmp .tokenize_loop

.ident_check_ffi_old:
    ; Старый код для FFI (без изменений)
    ; Проверяем: это может быть FFI функция?
    ; Вычисляем хеш имени идентификатора
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx rcx, word [rbx + TOKEN_LENGTH]
    call ffi_hash_string
    
    ; Ищем в FFI таблице
    call ffi_lookup
    test rax, rax
    jnz .call_ffi_function
    
    ; Не найдено в FFI - игнорируем
    jmp .tokenize_loop

; ============================================================================
; Вызов FFI функции с аргументами
; RAX = адрес функции
; ============================================================================
.call_ffi_function:
    push rax                        ; Сохраняем адрес функции
    
    ; Парсим аргументы (до 4)
    ; Аргументы разделяются запятыми
    xor r12d, r12d                  ; r12 = счётчик аргументов
    
    ; Резервируем место для 4 аргументов на стеке
    sub rsp, 32
    
.ffi_parse_args:
    cmp r12d, 4
    jge .ffi_call_ready
    
    ; Смотрим следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    
    cmp al, TOKEN_EOL
    je .ffi_call_ready
    
    ; Проверяем на двоеточие (конец команды)
    cmp al, TOKEN_OPERATOR
    jne .ffi_not_colon
    movzx ebx, byte [current_token + TOKEN_SUBTYPE]
    cmp bl, OP_COLON
    je .ffi_pushback_and_call
.ffi_not_colon:
    
    ; Это число?
    cmp al, TOKEN_NUMBER
    je .ffi_arg_number
    
    ; Это идентификатор (переменная)?
    cmp al, TOKEN_IDENTIFIER
    je .ffi_arg_variable
    
    ; Это оператор (запятая)?
    cmp al, TOKEN_OPERATOR
    jne .ffi_call_ready
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_COMMA
    je .ffi_parse_args              ; Пропускаем запятую
    jmp .ffi_call_ready

.ffi_arg_number:
    ; Получаем значение числа
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    mov qword [rsp + r12*8], rax    ; Сохраняем аргумент
    inc r12d
    jmp .ffi_parse_args

.ffi_arg_variable:
    ; Получаем значение переменной
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx eax, byte [rax]           ; Первый символ имени
    cmp al, 'a'
    jl .ffi_var_upper
    sub al, 32
.ffi_var_upper:
    sub al, 'A'
    cmp al, 25
    ja .ffi_parse_args              ; Неверная переменная - пропускаем
    
    movzx eax, al
    lea rbx, [variables]
    mov rax, qword [rbx + rax*8]    ; Значение переменной
    mov qword [rsp + r12*8], rax
    inc r12d
    jmp .ffi_parse_args

.ffi_pushback_and_call:
    mov byte [token_pushed], 1
    
.ffi_call_ready:
    ; Загружаем аргументы в регистры Windows x64
    mov rcx, qword [rsp + 0]        ; arg1 -> RCX
    mov rdx, qword [rsp + 8]        ; arg2 -> RDX
    mov r8, qword [rsp + 16]        ; arg3 -> R8
    mov r9, qword [rsp + 24]        ; arg4 -> R9
    
    add rsp, 32                     ; Освобождаем временный буфер
    pop rax                         ; Восстанавливаем адрес функции
    
    ; Сохраняем callee-saved регистры
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    
    ; Выравниваем стек и резервируем shadow space
    and rsp, -16
    sub rsp, 32
    
    ; Вызываем FFI функцию
    call rax
    
    ; Восстанавливаем
    mov rsp, rbp
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    ; Сохраняем результат в переменную R (для удобства)
    lea rbx, [variables]
    mov qword [rbx + 17*8], rax     ; R = 17-я буква (0-based: 'R'-'A' = 17)
    
    jmp .tokenize_loop

.handle_operator:
    ; Оператор обработан, продолжаем
    jmp .tokenize_loop

.tokenize_done:
    ; Если в режиме RUN — продолжаем выполнение программы
    cmp byte [run_mode], 1
    je .run_next_line
    jmp repl_loop

; ----------------------------------------------------------------------------
; Выход из программы
; ----------------------------------------------------------------------------
exit_program:
    lea rdx, [bye_msg]
    mov r8d, bye_len
    call print_string
    
    xor ecx, ecx
    call [ExitProcess]

; ============================================================================
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
; ============================================================================

; --- Проверка точки с запятой для PRINT (Phase 14.2) ---
; Если следующий токен ";" - НЕ печатаем newline
; Если нет - печатаем newline
print_maybe_newline:
    push rbx
    
    ; Проверяем есть ли уже прочитанный токен
    cmp byte [token_pushed], 0
    jne .pmn_check_token
    
    ; Читаем следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    
.pmn_check_token:
    lea rbx, [current_token]
    movzx eax, byte [rbx + TOKEN_TYPE]
    cmp al, TOKEN_OPERATOR
    jne .pmn_need_newline
    
    ; Проверяем точку с запятой
    movzx eax, byte [rbx + TOKEN_SUBTYPE]
    cmp al, OP_SEMICOLON
    jne .pmn_need_newline
    
    ; Точка с запятой - не печатаем newline, токен поглощён
    mov byte [token_pushed], 0
    pop rbx
    ret

.pmn_need_newline:
    ; Печатаем newline, токен нужно вернуть
    mov byte [token_pushed], 1
    lea rdx, [newline]
    call print_cstring
    pop rbx
    ret

; --- Поиск переменной: локальная или глобальная? (Phase 12.2) ---
; Вход: R12B = индекс переменной (0='A', 1='B', ... 25='Z')
; Выход: 
;   CF = 1: Локальная переменная, AL = смещение от RBP (отрицательное, например -8)
;   CF = 0: Глобальная переменная
; Сохраняет: R12, RBX
lookup_variable:
    ; Если мы не внутри функции — всегда глобальная
    cmp byte [current_scope], 0
    je .lookup_global
    
    ; Ищем в таблице локальных переменных
    push rcx
    push rsi
    push r12                        ; Сохраняем R12
    
    lea rsi, [local_var_map]
    movzx ecx, byte [local_vars_cnt]
    test ecx, ecx
    jz .lookup_global_pop           ; Нет локальных переменных
    
.lookup_loop:
    movzx eax, byte [rsi]           ; Индекс переменной в таблице
    cmp al, r12b                    ; Совпадает с искомой?
    je .lookup_found_local
    
    add rsi, 2                      ; Следующий слот
    dec ecx
    jnz .lookup_loop
    
    ; Не нашли в локальных — глобальная
.lookup_global_pop:
    pop r12
    pop rsi
    pop rcx
.lookup_global:
    clc                             ; CF = 0: глобальная
    ret

.lookup_found_local:
    movzx eax, byte [rsi + 1]       ; Offset (1, 2, 3... = номер переменной)
    dec al                          ; 1→0, 2→1, 3→2...
    shl al, 3                       ; Умножаем на 8 (0→0, 1→8, 2→16...)
    ; AL теперь ПОЛОЖИТЕЛЬНОЕ смещение от func_rbp_saved
    pop r12
    pop rsi
    pop rcx
    stc                             ; CF = 1: локальная
    ret

; --- Проверка поддержки AVX2 (Phase 9) ---
; Выход: AL = 1 если AVX2 поддерживается, 0 если нет
check_cpu_features:
    push rbx
    push rcx
    push rdx
    
    ; Сначала проверим, поддерживает ли CPU расширенные функции CPUID
    mov eax, 0
    cpuid
    cmp eax, 7                      ; Нужен как минимум CPUID leaf 7
    jl .no_avx2
    
    ; Проверяем AVX2 (CPUID leaf 7, EBX bit 5)
    mov eax, 7
    xor ecx, ecx
    cpuid
    
    test ebx, 0x20                  ; Бит 5 = AVX2
    jz .no_avx2
    
    ; AVX2 поддерживается!
    mov al, 1
    jmp .check_done
    
.no_avx2:
    xor al, al
    
.check_done:
    pop rdx
    pop rcx
    pop rbx
    ret

; --- Преобразование числа в строку ---
; Вход: EAX = число
; Выход: num_buffer содержит строку, EAX = длина
print_number_to_buffer:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    lea rdi, [num_buffer + 20]
    mov byte [rdi], 0
    mov rbx, 10
    mov ecx, eax
    
.pntb_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test eax, eax
    jnz .pntb_loop
    
    ; Копируем в начало num_buffer
    lea rsi, [num_buffer + 20]
    sub rsi, rdi
    mov eax, esi                    ; Длина
    
    push rax
    lea rsi, [rdi]
    lea rdi, [num_buffer]
    mov rcx, rax
    rep movsb
    pop rax
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ============================================================================
; ЛЕКСЕР
; ============================================================================

lexer_next_token:
    push rbx
    push rcx
    push rdx
    push rsi
    push r8
    push r9
    
    mov rsi, [lexer_pos]
    mov r8, rdi

    xor eax, eax
    mov [rdi + TOKEN_TYPE], al
    mov [rdi + TOKEN_SUBTYPE], al
    mov word [rdi + TOKEN_LENGTH], ax
    mov qword [rdi + TOKEN_VALUE], rax

.skip_whitespace:
    mov al, [rsi]
    cmp al, ' '
    je .next_ws
    cmp al, 9
    je .next_ws
    jmp .check_end
.next_ws:
    inc rsi
    jmp .skip_whitespace

.check_end:
    cmp al, 0
    je .token_eol
    cmp al, 13
    je .token_eol
    cmp al, 10
    je .token_eol
    cmp al, "'"
    je .token_comment
    cmp al, '"'
    je .token_string
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .token_number
.check_alpha:
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .token_identifier
.check_lower:
    cmp al, 'a'
    jl .token_operator
    cmp al, 'z'
    jle .token_identifier
    jmp .token_operator

.token_eol:
    mov byte [r8 + TOKEN_TYPE], TOKEN_EOL
    mov [lexer_pos], rsi
    mov al, TOKEN_EOL
    jmp .done

.token_comment:
.comment_skip:
    inc rsi
    mov al, [rsi]
    cmp al, 0
    je .token_eol
    cmp al, 13
    je .token_eol
    cmp al, 10
    je .token_eol
    jmp .comment_skip

.token_string:
    mov byte [r8 + TOKEN_TYPE], TOKEN_STRING
    inc rsi
    mov [r8 + TOKEN_VALUE], rsi
    xor ecx, ecx
.string_loop:
    mov al, [rsi]
    cmp al, '"'
    je .string_end
    cmp al, 0
    je .string_error
    cmp al, 13
    je .string_error
    inc ecx
    inc rsi
    jmp .string_loop
.string_end:
    mov word [r8 + TOKEN_LENGTH], cx
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_STRING
    jmp .done
.string_error:
    mov byte [lexer_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.token_number:
    ; Phase 15: Парсинг чисел с плавающей точкой
    mov byte [r8 + TOKEN_TYPE], TOKEN_NUMBER
    xor rax, rax
    xor rbx, rbx
    xor r9d, r9d                    ; r9 = флаг "видели точку"
    xor r10, r10                    ; r10 = дробная часть
    mov r11, 1                      ; r11 = делитель (степень 10)
    
.number_loop:
    mov bl, [rsi]
    
    ; Проверяем на точку
    cmp bl, '.'
    jne .number_not_dot
    
    ; Это точка - переключаемся в режим float
    test r9d, r9d
    jnz .number_done                ; Вторая точка = конец числа
    mov r9d, 1                      ; Отмечаем что видели точку
    inc rsi
    jmp .number_loop
    
.number_not_dot:
    cmp bl, '0'
    jl .number_done
    cmp bl, '9'
    jg .number_done
    
    ; Это цифра
    test r9d, r9d
    jnz .number_frac_digit          ; После точки - дробная часть
    
    ; Целая часть
    imul rax, 10
    sub bl, '0'
    add rax, rbx
    inc rsi
    jmp .number_loop
    
.number_frac_digit:
    ; Дробная часть - накапливаем в r10, считаем делитель в r11
    imul r10, 10
    sub bl, '0'
    movzx ebx, bl
    add r10, rbx
    imul r11, 10
    inc rsi
    jmp .number_loop
    
.number_done:
    ; Проверяем: это float или int?
    test r9d, r9d
    jz .number_is_int
    
    ; === FLOAT ===
    mov byte [r8 + TOKEN_TYPE], TOKEN_FLOAT
    
    ; Конвертируем в double: result = integer_part + frac_part / divisor
    ; Сохраняем целую часть
    push rax
    push r10
    push r11
    
    ; Конвертируем целую часть в double
    cvtsi2sd xmm0, rax              ; xmm0 = (double)integer_part
    
    ; Конвертируем дробную часть
    cvtsi2sd xmm1, r10              ; xmm1 = (double)frac_part
    cvtsi2sd xmm2, r11              ; xmm2 = (double)divisor
    divsd xmm1, xmm2                ; xmm1 = frac_part / divisor
    
    ; Складываем
    addsd xmm0, xmm1                ; xmm0 = integer + fraction
    
    ; Сохраняем double в TOKEN_VALUE (как 64-bit pattern)
    movq rax, xmm0
    mov [r8 + TOKEN_VALUE], rax
    
    pop r11
    pop r10
    pop rax
    
    mov [lexer_pos], rsi
    mov al, TOKEN_FLOAT
    jmp .done
    
.number_is_int:
    ; === INTEGER ===
    mov [r8 + TOKEN_VALUE], rax
    mov [lexer_pos], rsi
    mov al, TOKEN_NUMBER
    jmp .done

.token_identifier:
    mov byte [r8 + TOKEN_TYPE], TOKEN_IDENTIFIER
    mov [r8 + TOKEN_VALUE], rsi
    xor ecx, ecx
.ident_loop:
    mov al, [rsi]
    cmp al, 'A'
    jl .ident_check_lower
    cmp al, 'Z'
    jle .ident_cont
.ident_check_lower:
    cmp al, 'a'
    jl .ident_check_digit
    cmp al, 'z'
    jle .ident_cont
.ident_check_digit:
    cmp al, '0'
    jl .ident_check_special
    cmp al, '9'
    jle .ident_cont
.ident_check_special:
    cmp al, '_'
    je .ident_cont
    cmp al, '$'
    je .ident_dollar
    jmp .ident_end
.ident_cont:
    inc ecx
    inc rsi
    jmp .ident_loop
.ident_dollar:
    ; Строковая переменная (A$, B$, ...)
    inc ecx
    inc rsi
    ; Устанавливаем тип как STRING_VAR
    mov word [r8 + TOKEN_LENGTH], cx
    mov [lexer_pos], rsi
    mov byte [r8 + TOKEN_TYPE], TOKEN_STRING_VAR
    mov al, TOKEN_STRING_VAR
    jmp .done
    
.ident_end:
    mov word [r8 + TOKEN_LENGTH], cx
    mov [lexer_pos], rsi
    
    push rsi
    mov rsi, [r8 + TOKEN_VALUE]
    mov edx, ecx
    call check_keyword
    pop rsi
    
    test eax, eax
    jz .ident_not_kw
    mov byte [r8 + TOKEN_TYPE], TOKEN_KEYWORD
    mov byte [r8 + TOKEN_SUBTYPE], al
    mov al, TOKEN_KEYWORD
    jmp .done
.ident_not_kw:
    mov al, TOKEN_IDENTIFIER
    jmp .done

.token_operator:
    mov byte [r8 + TOKEN_TYPE], TOKEN_OPERATOR
    mov al, [rsi]
    
    cmp al, '+'
    je .op_plus
    cmp al, '-'
    je .op_minus
    cmp al, '*'
    je .op_mul
    cmp al, '/'
    je .op_div
    cmp al, '^'
    je .op_power
    cmp al, '='
    je .op_eq
    cmp al, '<'
    je .op_less
    cmp al, '>'
    je .op_greater
    cmp al, '('
    je .op_lparen
    cmp al, ')'
    je .op_rparen
    cmp al, ','
    je .op_comma
    cmp al, ';'
    je .op_semi
    cmp al, ':'
    je .op_colon
    
    mov byte [lexer_error], ERR_SYNTAX
    xor eax, eax
    jmp .done

.op_plus:
    mov byte [r8 + TOKEN_SUBTYPE], OP_PLUS
    jmp .op_single
.op_minus:
    mov byte [r8 + TOKEN_SUBTYPE], OP_MINUS
    jmp .op_single
.op_mul:
    mov byte [r8 + TOKEN_SUBTYPE], OP_MUL
    jmp .op_single
.op_div:
    mov byte [r8 + TOKEN_SUBTYPE], OP_DIV
    jmp .op_single
.op_power:
    mov byte [r8 + TOKEN_SUBTYPE], OP_POWER
    jmp .op_single
.op_eq:
    mov byte [r8 + TOKEN_SUBTYPE], OP_EQ
    jmp .op_single
.op_lparen:
    mov byte [r8 + TOKEN_SUBTYPE], OP_LPAREN
    jmp .op_single
.op_rparen:
    mov byte [r8 + TOKEN_SUBTYPE], OP_RPAREN
    jmp .op_single
.op_comma:
    mov byte [r8 + TOKEN_SUBTYPE], OP_COMMA
    jmp .op_single
.op_semi:
    mov byte [r8 + TOKEN_SUBTYPE], OP_SEMICOLON
    jmp .op_single
.op_colon:
    mov byte [r8 + TOKEN_SUBTYPE], OP_COLON
    jmp .op_single

.op_less:
    inc rsi
    mov al, [rsi]
    cmp al, '='
    je .op_le
    cmp al, '>'
    je .op_ne
    mov byte [r8 + TOKEN_SUBTYPE], OP_LT
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done
.op_le:
    mov byte [r8 + TOKEN_SUBTYPE], OP_LE
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done
.op_ne:
    mov byte [r8 + TOKEN_SUBTYPE], OP_NE
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done

.op_greater:
    inc rsi
    mov al, [rsi]
    cmp al, '='
    je .op_ge
    mov byte [r8 + TOKEN_SUBTYPE], OP_GT
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done
.op_ge:
    mov byte [r8 + TOKEN_SUBTYPE], OP_GE
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done

.op_single:
    inc rsi
    mov [lexer_pos], rsi
    mov al, TOKEN_OPERATOR
    jmp .done

.done:
    pop r9
    pop r8
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; check_keyword
; ----------------------------------------------------------------------------
check_keyword:
    push rbx
    push rcx
    push rdi
    push r10
    
    lea rdi, [keywords_table]

.kw_loop:
    movzx ecx, byte [rdi]
    test ecx, ecx
    jz .kw_not_found
    
    cmp ecx, edx
    jne .kw_next
    
    push rsi
    push rdi
    inc rdi
    mov r10d, ecx
    
.kw_compare:
    mov al, [rsi]
    mov bl, [rdi]
    
    cmp al, 'a'
    jl .kw_no_upper
    cmp al, 'z'
    jg .kw_no_upper
    sub al, 32
.kw_no_upper:
    
    cmp al, bl
    jne .kw_mismatch
    
    inc rsi
    inc rdi
    dec r10d
    jnz .kw_compare
    
    pop rdi
    pop rsi
    movzx rcx, byte [keywords_table]
    add rdi, rdx
    inc rdi
    movzx eax, byte [rdi]
    jmp .kw_done

.kw_mismatch:
    pop rdi
    pop rsi

.kw_next:
    movzx ecx, byte [rdi]
    add rdi, rcx
    add rdi, 2
    jmp .kw_loop

.kw_not_found:
    xor eax, eax

.kw_done:
    pop r10
    pop rdi
    pop rcx
    pop rbx
    ret

; ============================================================================
; ПАРСЕР ВЫРАЖЕНИЙ (Phase 4 - Арифметика)
; ============================================================================
; parse_expression - парсит арифметическое выражение
; Возвращает: RAX = результат, RCX = 1 (успех) или 0 (ошибка)
; Поддерживает: числа, переменные, операции + - * /
; Приоритеты: * / выполняются перед + -
; ============================================================================

parse_expression:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40                     ; Shadow space + alignment
    
    ; Phase 15: Сбрасываем float_mode в начале выражения
    mov byte [float_mode], 0
    
    ; Парсим первый терм (с учётом приоритета * /)
    call parse_term
    test rcx, rcx
    jz .expr_error
    
    ; Phase 15: Проверяем режим float
    cmp byte [float_mode], 1
    je .expr_float_mode
    
    ; === INTEGER MODE ===
    mov r14, rax                    ; r14 = аккумулятор (результат)
    
.expr_loop:
    ; Проверяем, был ли токен "отложен"
    cmp byte [token_pushed], 0
    jne .expr_use_current
    
    ; Смотрим следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    jmp .expr_check_token
    
.expr_use_current:
    ; Используем уже прочитанный токен
    mov byte [token_pushed], 0      ; Сбрасываем флаг
    movzx eax, byte [current_token + TOKEN_TYPE]
    
.expr_check_token:
    ; Если EOL или не оператор — конец выражения
    cmp al, TOKEN_EOL
    je .expr_done
    cmp al, TOKEN_OPERATOR
    jne .expr_done
    
    ; Проверяем какой оператор
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    
    cmp al, OP_PLUS
    je .expr_add
    cmp al, OP_MINUS
    je .expr_sub
    
    ; Не + или - — конец выражения (может быть ) или другой символ)
    jmp .expr_done
    
.expr_add:
    ; Парсим следующий терм
    call parse_term
    test rcx, rcx
    jz .expr_error
    
    ; Phase 15: Проверяем — не стал ли операнд float?
    cmp byte [float_mode], 1
    je .expr_switch_to_float_add
    
    add r14, rax
    jmp .expr_loop
    
.expr_switch_to_float_add:
    ; Конвертируем r14 в float и переходим в float mode
    cvtsi2sd xmm0, r14              ; xmm0 = (double)r14
    movq xmm1, rax                  ; xmm1 = новый float операнд
    addsd xmm0, xmm1
    jmp .expr_float_loop
    
.expr_sub:
    call parse_term
    test rcx, rcx
    jz .expr_error
    
    ; Phase 15: Проверяем — не стал ли операнд float?
    cmp byte [float_mode], 1
    je .expr_switch_to_float_sub
    
    sub r14, rax
    jmp .expr_loop
    
.expr_switch_to_float_sub:
    ; Конвертируем r14 в float и переходим в float mode
    cvtsi2sd xmm0, r14
    movq xmm1, rax
    subsd xmm0, xmm1
    jmp .expr_float_loop
    
.expr_done:
    ; Откатываем токен, который не был оператором + или -
    mov byte [token_pushed], 1
    mov rax, r14                    ; Результат
    mov rcx, 1                      ; Успех
    jmp .expr_ret
    
; === FLOAT MODE ===
.expr_float_mode:
    ; RAX содержит 64-bit pattern of double
    movq xmm0, rax                  ; xmm0 = аккумулятор float
    
.expr_float_loop:
    ; Проверяем, был ли токен "отложен"
    cmp byte [token_pushed], 0
    jne .expr_float_use_current
    
    ; Сохраняем xmm0 перед вызовом
    sub rsp, 16
    movsd [rsp], xmm0
    
    lea rdi, [current_token]
    call lexer_next_token
    
    ; Восстанавливаем xmm0
    movsd xmm0, [rsp]
    add rsp, 16
    jmp .expr_float_check_token
    
.expr_float_use_current:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
    
.expr_float_check_token:
    cmp al, TOKEN_EOL
    je .expr_float_done
    cmp al, TOKEN_OPERATOR
    jne .expr_float_done
    
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    
    cmp al, OP_PLUS
    je .expr_float_add
    cmp al, OP_MINUS
    je .expr_float_sub
    
    jmp .expr_float_done
    
.expr_float_add:
    ; Сохраняем xmm0
    sub rsp, 16
    movsd [rsp], xmm0
    
    call parse_term
    
    ; Восстанавливаем xmm0
    movsd xmm0, [rsp]
    add rsp, 16
    
    test rcx, rcx
    jz .expr_error
    
    ; RAX = новый операнд (может быть int или float)
    cmp byte [float_mode], 1
    je .expr_float_add_float
    
    ; Операнд - int, конвертируем
    cvtsi2sd xmm1, rax
    jmp .expr_float_add_do
    
.expr_float_add_float:
    movq xmm1, rax
    
.expr_float_add_do:
    addsd xmm0, xmm1
    mov byte [float_mode], 1        ; Остаёмся в float mode
    jmp .expr_float_loop
    
.expr_float_sub:
    sub rsp, 16
    movsd [rsp], xmm0
    
    call parse_term
    
    movsd xmm0, [rsp]
    add rsp, 16
    
    test rcx, rcx
    jz .expr_error
    
    cmp byte [float_mode], 1
    je .expr_float_sub_float
    
    cvtsi2sd xmm1, rax
    jmp .expr_float_sub_do
    
.expr_float_sub_float:
    movq xmm1, rax
    
.expr_float_sub_do:
    subsd xmm0, xmm1
    mov byte [float_mode], 1
    jmp .expr_float_loop
    
.expr_float_done:
    mov byte [token_pushed], 1
    movq rax, xmm0                  ; Результат как 64-bit pattern
    mov byte [float_mode], 1        ; Устанавливаем float_mode для LET
    mov rcx, 1
    jmp .expr_ret
    
.expr_error:
    xor eax, eax
    xor ecx, ecx                    ; Ошибка
    
.expr_ret:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ----------------------------------------------------------------------------
; parse_term - парсит терм (множители/делители)
; Обрабатывает * и / которые имеют больший приоритет
; ----------------------------------------------------------------------------
parse_term:
    push rbx
    push r12
    push r13
    sub rsp, 40
    
    ; Парсим первый фактор
    call parse_factor
    test rcx, rcx
    jz .term_error
    
    ; Phase 15: Проверяем режим float
    cmp byte [float_mode], 1
    je .term_float_mode
    
    ; === INTEGER MODE ===
    mov r12, rax                    ; r12 = аккумулятор терма
    
.term_loop:
    ; Проверяем, был ли токен "отложен"
    cmp byte [token_pushed], 0
    jne .term_use_current
    
    ; Смотрим следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    jmp .term_check_token
    
.term_use_current:
    ; Используем уже прочитанный токен
    mov byte [token_pushed], 0      ; Сбрасываем флаг
    movzx eax, byte [current_token + TOKEN_TYPE]
    
.term_check_token:
    cmp al, TOKEN_EOL
    je .term_done
    cmp al, TOKEN_OPERATOR
    jne .term_pushback
    
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    
    cmp al, OP_MUL
    je .term_mul
    cmp al, OP_DIV
    je .term_div
    
    ; Не * или / — откатываем токен и выходим
    jmp .term_pushback
    
.term_mul:
    call parse_factor
    test rcx, rcx
    jz .term_error
    
    ; Phase 15: Проверяем — не стал ли операнд float?
    cmp byte [float_mode], 1
    je .term_switch_to_float_mul
    
    imul r12, rax
    jmp .term_loop
    
.term_switch_to_float_mul:
    cvtsi2sd xmm0, r12              ; Конвертируем r12 в float
    movq xmm1, rax                  ; Новый операнд уже float
    mulsd xmm0, xmm1
    jmp .term_float_loop
    
.term_div:
    call parse_factor
    test rcx, rcx
    jz .term_error
    
    ; Phase 15: Проверяем — не стал ли операнд float?
    cmp byte [float_mode], 1
    je .term_switch_to_float_div
    
    ; Проверка деления на ноль
    test rax, rax
    jz .term_error                  ; Деление на 0 = ошибка
    mov r13, rax                    ; Сохраняем делитель
    mov rax, r12                    ; Делимое
    cqo                             ; Расширяем RAX в RDX:RAX
    idiv r13                        ; RAX = RAX / R13
    mov r12, rax
    jmp .term_loop
    
.term_switch_to_float_div:
    cvtsi2sd xmm0, r12
    movq xmm1, rax
    divsd xmm0, xmm1
    jmp .term_float_loop
    
.term_pushback:
    ; "Откат" токена: устанавливаем флаг token_pushed
    mov byte [token_pushed], 1
    
.term_done:
    mov rax, r12
    mov rcx, 1
    jmp .term_ret

; === FLOAT MODE for parse_term ===
.term_float_mode:
    movq xmm0, rax                  ; xmm0 = аккумулятор float
    
.term_float_loop:
    ; Проверяем, был ли токен "отложен"
    cmp byte [token_pushed], 0
    jne .term_float_use_current
    
    ; Сохраняем xmm0 перед вызовом
    sub rsp, 16
    movsd [rsp], xmm0
    
    lea rdi, [current_token]
    call lexer_next_token
    
    movsd xmm0, [rsp]
    add rsp, 16
    jmp .term_float_check_token
    
.term_float_use_current:
    mov byte [token_pushed], 0      ; Сбрасываем флаг
    movzx eax, byte [current_token + TOKEN_TYPE]
    
.term_float_check_token:
    cmp al, TOKEN_EOL
    je .term_float_done
    cmp al, TOKEN_OPERATOR
    jne .term_float_pushback
    
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    
    cmp al, OP_MUL
    je .term_float_mul
    cmp al, OP_DIV
    je .term_float_div
    
    jmp .term_float_pushback
    
.term_float_mul:
    sub rsp, 16
    movsd [rsp], xmm0
    
    call parse_factor
    
    movsd xmm0, [rsp]
    add rsp, 16
    
    test rcx, rcx
    jz .term_error
    
    cmp byte [float_mode], 1
    je .term_float_mul_float
    
    ; Операнд - int
    cvtsi2sd xmm1, rax
    jmp .term_float_mul_do
    
.term_float_mul_float:
    movq xmm1, rax
    
.term_float_mul_do:
    mulsd xmm0, xmm1
    mov byte [float_mode], 1
    jmp .term_float_loop
    
.term_float_div:
    sub rsp, 16
    movsd [rsp], xmm0
    
    call parse_factor
    
    movsd xmm0, [rsp]
    add rsp, 16
    
    test rcx, rcx
    jz .term_error
    
    cmp byte [float_mode], 1
    je .term_float_div_float
    
    cvtsi2sd xmm1, rax
    jmp .term_float_div_do
    
.term_float_div_float:
    movq xmm1, rax
    
.term_float_div_do:
    divsd xmm0, xmm1
    mov byte [float_mode], 1
    jmp .term_float_loop
    
.term_float_pushback:
    mov byte [token_pushed], 1
    
.term_float_done:
    movq rax, xmm0
    mov byte [float_mode], 1
    mov rcx, 1
    jmp .term_ret
    
.term_error:
    xor eax, eax
    xor ecx, ecx
    
.term_ret:
    add rsp, 40
    pop r13
    pop r12
    pop rbx
    ret

; ----------------------------------------------------------------------------
; parse_factor - парсит фактор (число, переменная или FFI-вызов)
; Phase 14.1: Добавлена поддержка FFI-вызовов как выражений
; ----------------------------------------------------------------------------
parse_factor:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56                     ; Больше места для FFI аргументов
    
    ; Проверяем, был ли токен "отложен"
    cmp byte [token_pushed], 0
    jne .factor_use_current
    
    ; Получаем следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    jmp .factor_check_type
    
.factor_use_current:
    ; Используем уже прочитанный токен
    mov byte [token_pushed], 0      ; Сбрасываем флаг
    movzx eax, byte [current_token + TOKEN_TYPE]
    
.factor_check_type:
    cmp al, TOKEN_NUMBER
    je .factor_number
    cmp al, TOKEN_FLOAT
    je .factor_float                ; Phase 15: Float literal
    cmp al, TOKEN_IDENTIFIER
    je .factor_check_ffi
    cmp al, TOKEN_OPERATOR
    je .factor_check_paren          ; Проверяем на открывающую скобку
    
    ; Ошибка: неожиданный токен
    xor eax, eax
    xor ecx, ecx
    jmp .factor_ret

.factor_check_paren:
    ; Проверяем: это открывающая скобка?
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    jne .factor_error
    
    ; Да - парсим вложенное выражение
    call parse_expression
    test rcx, rcx
    jz .factor_error
    
    mov r12, rax                    ; Сохраняем результат
    
    ; Ожидаем закрывающую скобку
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .factor_paren_err
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .factor_paren_err
    
    mov rax, r12
    mov rcx, 1
    jmp .factor_ret
    
.factor_paren_err:
    ; Отложим токен - возможно это не ошибка
    mov byte [token_pushed], 1
    mov rax, r12
    mov rcx, 1
    jmp .factor_ret

.factor_check_ffi:
    ; === Phase 22: Проверяем встроенные функции KEY() и MAXIDX() ===
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]
    movzx rcx, word [rbx + TOKEN_LENGTH]
    
    ; Сохраняем имя для возможного использования как переменной
    mov [factor_var_name], rsi      ; Сохраняем в память
    
    ; Проверяем KEY
    cmp ecx, 3
    jne .factor_not_key
    mov eax, [rsi]
    and eax, 0xFFFFFF               ; Только 3 символа
    or eax, 0x202020                ; to lowercase
    cmp eax, 'key'
    je .factor_builtin_key
    
.factor_not_key:
    ; Проверяем MAXIDX
    cmp ecx, 6
    jne .factor_not_maxidx
    push rsi
    ; Сравниваем "MAXIDX"
    mov al, [rsi]
    or al, 0x20
    cmp al, 'm'
    jne .factor_not_maxidx_pop
    mov al, [rsi+1]
    or al, 0x20
    cmp al, 'a'
    jne .factor_not_maxidx_pop
    mov al, [rsi+2]
    or al, 0x20
    cmp al, 'x'
    jne .factor_not_maxidx_pop
    mov al, [rsi+3]
    or al, 0x20
    cmp al, 'i'
    jne .factor_not_maxidx_pop
    mov al, [rsi+4]
    or al, 0x20
    cmp al, 'd'
    jne .factor_not_maxidx_pop
    mov al, [rsi+5]
    or al, 0x20
    cmp al, 'x'
    jne .factor_not_maxidx_pop
    pop rsi
    jmp .factor_builtin_maxidx
    
.factor_not_maxidx_pop:
    pop rsi
    
.factor_not_maxidx:
    ; === Обычная FFI проверка ===
    call ffi_hash_string
    ; RAX = hash, передаём его в ffi_lookup (RAX уже содержит хеш!)
    call ffi_lookup
    
    test rax, rax
    jnz .factor_ffi_call            ; Найдена! RAX = адрес функции
    
    ; НЕ найдено - идём к переменной
    jmp .factor_var

.factor_ffi_call:
    ; RAX = адрес функции, вызываем с аргументами в скобках
    mov [ffi_call_addr], rax        ; Сохраняем адрес функции в памяти
    
    ; Смотрим следующий токен - должна быть скобка (
    lea rdi, [current_token]
    call lexer_next_token
    
    cmp al, TOKEN_OPERATOR
    jne .ffi_no_args
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    jne .ffi_no_args
    
    ; Парсим аргументы - используем буфер в памяти
    mov dword [ffi_arg_count], 0
    
.ffi_factor_parse_args:
    cmp dword [ffi_arg_count], 4
    jge .ffi_factor_call_ready
    
    ; Проверяем, был ли токен "отложен"
    cmp byte [token_pushed], 0
    jne .ffi_factor_use_current
    
    ; Получаем следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    jmp .ffi_factor_check_close
    
.ffi_factor_use_current:
    ; Используем уже прочитанный токен
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
    
.ffi_factor_check_close:
    cmp al, TOKEN_OPERATOR
    jne .ffi_factor_not_close
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    je .ffi_factor_call_ready       ; Конец аргументов
    cmp al, OP_COMMA
    je .ffi_factor_parse_args       ; Пропускаем запятую
    jmp .ffi_factor_not_close
    
.ffi_factor_not_close:
    ; Откатываем токен и парсим выражение
    mov byte [token_pushed], 1
    
    ; Сохраняем ffi_call_addr на стек перед рекурсией
    push qword [ffi_call_addr]
    push qword [ffi_arg_count]
    
    ; Рекурсивный вызов parse_expression для аргумента
    call parse_expression
    
    ; Восстанавливаем после рекурсии
    pop qword [ffi_arg_count]
    pop qword [ffi_call_addr]
    
    test rcx, rcx
    jz .factor_error
    
    ; Сохраняем аргумент в буфер
    mov ecx, [ffi_arg_count]
    lea rbx, [ffi_args]
    mov qword [rbx + rcx*8], rax
    inc dword [ffi_arg_count]
    jmp .ffi_factor_parse_args
    
.ffi_no_args:
    ; Откатываем токен, вызываем без аргументов
    mov byte [token_pushed], 1
    mov dword [ffi_arg_count], 0
    
.ffi_factor_call_ready:
    ; Загружаем аргументы в регистры Windows x64
    lea rbx, [ffi_args]
    mov rcx, qword [rbx + 0]        ; arg1 -> RCX
    mov rdx, qword [rbx + 8]        ; arg2 -> RDX
    mov r8, qword [rbx + 16]        ; arg3 -> R8
    mov r9, qword [rbx + 24]        ; arg4 -> R9
    
    ; Вызываем FFI функцию
    mov rax, [ffi_call_addr]        ; Восстанавливаем адрес функции
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32                     ; Shadow space
    
    call rax                        ; Вызов функции
    
    mov rsp, rbp
    pop rbp
    
    ; RAX = результат функции
    mov rcx, 1                      ; Успех
    jmp .factor_ret

.factor_number:
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    mov byte [float_mode], 0        ; Phase 15: This is an integer
    mov rcx, 1
    jmp .factor_ret

; Phase 15: Float literal
.factor_float:
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]  ; 64-bit pattern of double
    mov byte [float_mode], 1        ; Phase 15: This is a float
    mov rcx, 1
    jmp .factor_ret
    
.factor_var:
    ; Используем сохранённый указатель на имя переменной
    mov rsi, [factor_var_name]      ; Восстанавливаем указатель на имя
    movzx eax, byte [rsi]           ; Первый символ
    cmp al, 'a'
    jl .factor_var_upper
    sub al, 32
.factor_var_upper:
    sub al, 'A'
    cmp al, 25
    ja .factor_var_error
    
    movzx r12d, al                  ; R12 = индекс переменной
    
    ; === Phase 16: Проверяем — это массив A(I) или обычная переменная A? ===
    ; Смотрим следующий токен
    push r12
    lea rdi, [current_token]
    call lexer_next_token
    pop r12
    
    cmp al, TOKEN_OPERATOR
    jne .factor_not_array
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    jne .factor_not_array
    
    ; === Это массив! ===
    jmp .factor_array_access
    
.factor_not_array:
    ; Откатываем токен — это обычная переменная
    mov byte [token_pushed], 1
    
    ; === Phase 12.2: Проверяем — локальная или глобальная переменная ===
    call lookup_variable            ; CF=1 локальная (AL=offset), CF=0 глобальная
    jnc .factor_global_var
    
    ; --- Локальная переменная: читаем через func_rbp_saved ---
    movzx eax, al                   ; Zero-extend offset (0, 8, 16, ...)
    mov rbx, [func_rbp_saved]       ; Базовый указатель фрейма
    mov rax, qword [rbx + rax]      ; Читаем [base + offset]
    mov rcx, 1
    jmp .factor_ret
    
.factor_global_var:
    ; --- Глобальная переменная ---
    movzx eax, r12b
    
    ; === Phase 15: Проверяем тип переменной и устанавливаем float_mode ===
    push rax
    lea rbx, [var_types]
    mov cl, byte [rbx + rax]        ; Тип переменной
    mov byte [float_mode], cl       ; Устанавливаем float_mode
    pop rax
    
    lea rbx, [variables]
    mov rax, qword [rbx + rax*8]
    mov rcx, 1
    jmp .factor_ret

; === Phase 16: Array access A(I) ===
.factor_array_access:
    ; r12 = индекс массива (0-25)
    ; Мы уже прочитали '('
    
    ; Сохраняем индекс массива
    mov [array_index_var], r12d
    
    ; Парсим индекс (выражение)
    call parse_expression
    test rcx, rcx
    jz .factor_error
    
    ; RAX = индекс элемента
    ; Phase 16: Если индекс - float, конвертируем в int
    cmp byte [float_mode], 1
    jne .factor_arr_int_index
    ; Конвертируем float в int
    movq xmm0, rax
    cvttsd2si rax, xmm0             ; Truncate to integer
.factor_arr_int_index:
    mov r13, rax                    ; r13 = index (int)
    
    ; Проверяем закрывающую скобку
    cmp byte [token_pushed], 0
    jne .factor_arr_use_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .factor_arr_check_rparen
.factor_arr_use_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.factor_arr_check_rparen:
    cmp al, TOKEN_OPERATOR
    jne .factor_arr_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .factor_arr_error
    
    ; Получаем информацию о массиве из array_table
    mov eax, [array_index_var]
    shl eax, 4                      ; index * 16
    lea rbx, [array_table]
    mov rdi, qword [rbx + rax]      ; rdi = pointer to data
    mov r14, qword [rbx + rax + 8]  ; r14 = size
    
    ; Проверяем что массив выделен
    test rdi, rdi
    jz .factor_arr_undef
    
    ; Проверяем границы: 0 <= index < size
    test r13, r13
    js .factor_arr_bounds           ; index < 0
    cmp r13, r14
    jge .factor_arr_bounds          ; index >= size
    
    ; Читаем элемент: rax = [rdi + r13 * 8]
    mov rax, qword [rdi + r13*8]
    
    ; Phase 16: Массивы по умолчанию float (для нейросетей)
    mov byte [float_mode], 1
    
    mov rcx, 1
    jmp .factor_ret

.factor_arr_undef:
    ; Массив не определён - выводим ошибку и возвращаем 0
    push rcx
    lea rdx, [arr_undef_msg]
    call print_cstring
    pop rcx
    xor eax, eax
    xor ecx, ecx
    jmp .factor_ret

.factor_arr_bounds:
    ; Индекс за пределами - выводим ошибку и возвращаем 0
    push rcx
    lea rdx, [arr_bounds_msg]
    call print_cstring
    pop rcx
    xor eax, eax
    xor ecx, ecx
    jmp .factor_ret

; === Phase 22: Встроенная функция KEY(keycode) ===
.factor_builtin_key:
    ; Ожидаем (
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .factor_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    jne .factor_error
    
    ; Парсим keycode
    call parse_expression
    test rcx, rcx
    jz .factor_error
    
    ; Преобразуем в int если float
    cmp byte [float_mode], 1
    jne .key_int
    movq xmm0, rax
    cvttsd2si rax, xmm0
.key_int:
    mov r12, rax                    ; r12 = keycode
    
    ; Ожидаем )
    cmp byte [token_pushed], 0
    jne .key_use_pushed
    lea rdi, [current_token]
    call lexer_next_token
    jmp .key_check_rparen
.key_use_pushed:
    mov byte [token_pushed], 0
    movzx eax, byte [current_token + TOKEN_TYPE]
.key_check_rparen:
    cmp al, TOKEN_OPERATOR
    jne .key_skip_rparen
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .key_skip_rparen
    jmp .key_call
.key_skip_rparen:
    mov byte [token_pushed], 1
    
.key_call:
    ; GetAsyncKeyState(keycode)
    mov ecx, r12d
    sub rsp, 32
    call [GetAsyncKeyState]
    add rsp, 32
    
    ; Результат: старший бит = нажата
    test ax, 0x8000
    jz .key_not_pressed
    mov eax, 1
    jmp .key_done
.key_not_pressed:
    xor eax, eax
.key_done:
    mov byte [float_mode], 0
    mov rcx, 1
    jmp .factor_ret

; === Phase 22: Встроенная функция MAXIDX(array) ===
.factor_builtin_maxidx:
    ; Ожидаем (
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .factor_error
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_LPAREN
    jne .factor_error
    
    ; Ожидаем имя массива
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_IDENTIFIER
    jne .factor_error
    
    ; Получаем индекс массива (первая буква имени = индекс A=0, B=1...)
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx r12d, byte [rax]
    cmp r12b, 'a'
    jl .maxidx_upper
    sub r12b, 32
.maxidx_upper:
    sub r12b, 'A'
    cmp r12b, 25
    ja .factor_error
    
    ; r12 = индекс массива (0-25)
    ; Вычисляем адрес в array_table
    movzx eax, r12b
    shl eax, 4                      ; * 16 (ARRAY_ENTRY_SIZE)
    lea rdi, [array_table]
    add rdi, rax
    
    ; Получаем данные массива
    mov r13, qword [rdi]            ; data pointer (offset 0)
    mov r14, qword [rdi + 8]        ; size in elements (offset 8)
    
    ; Ожидаем )
    lea rdi, [current_token]
    call lexer_next_token
    cmp al, TOKEN_OPERATOR
    jne .maxidx_skip_rparen
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_RPAREN
    jne .maxidx_skip_rparen
    jmp .maxidx_compute
.maxidx_skip_rparen:
    mov byte [token_pushed], 1
    
.maxidx_compute:
    ; Ищем индекс максимального элемента в float64 массиве
    ; r13 = data, r14 = count
    xor r15d, r15d                  ; r15 = max_index
    movsd xmm0, [r13]               ; xmm0 = max_value
    mov ecx, 1                      ; ecx = current index
    
.maxidx_loop:
    cmp ecx, r14d
    jge .maxidx_done
    
    movsd xmm1, [r13 + rcx*8]       ; xmm1 = current value
    comisd xmm1, xmm0
    jbe .maxidx_not_greater
    
    ; Новый максимум
    movsd xmm0, xmm1
    mov r15d, ecx
    
.maxidx_not_greater:
    inc ecx
    jmp .maxidx_loop
    
.maxidx_done:
    mov eax, r15d
    mov byte [float_mode], 0
    mov rcx, 1
    jmp .factor_ret

.factor_arr_error:
    jmp .factor_error
    
.factor_var_error:
.factor_error:
    xor eax, eax
    xor ecx, ecx
    
.factor_ret:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ============================================================================
; ПАРСЕР СТРОКОВЫХ ВЫРАЖЕНИЙ (Phase 7)
; ============================================================================
; parse_string_expr - парсит строковое выражение
; Возвращает: RAX = указатель на строку в heap, RDX = длина, RCX = 1 (успех)
; Поддерживает: литералы "...", строковые переменные A$, конкатенацию +
; ============================================================================

parse_string_expr:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    ; Получаем первый элемент
    call parse_string_factor
    test rcx, rcx
    jz .strexpr_error
    
    ; RAX = ptr, RDX = len
    mov r12, rax                    ; r12 = текущий ptr
    mov r13, rdx                    ; r13 = текущая длина
    
.strexpr_loop:
    ; Смотрим следующий токен
    lea rdi, [current_token]
    call lexer_next_token
    
    cmp al, TOKEN_EOL
    je .strexpr_done
    cmp al, TOKEN_OPERATOR
    jne .strexpr_pushback
    
    movzx eax, byte [current_token + TOKEN_SUBTYPE]
    cmp al, OP_PLUS
    jne .strexpr_pushback
    
    ; Конкатенация: нужно получить второй операнд
    call parse_string_factor
    test rcx, rcx
    jz .strexpr_error
    
    ; RAX = ptr2, RDX = len2
    ; Нужно объединить: скопировать оба в heap
    mov r14, rax                    ; r14 = ptr2
    mov r15, rdx                    ; r15 = len2
    
    ; Сохраняем начальную позицию в heap
    mov rdi, [heap_ptr]
    push rdi                        ; Запоминаем начало результата
    
    ; Копируем первую строку
    mov rsi, r12
    mov rcx, r13
    rep movsb
    
    ; Копируем вторую строку
    mov rsi, r14
    mov rcx, r15
    rep movsb
    
    ; Добавляем null-terminator для FFI
    mov byte [rdi], 0
    inc rdi
    
    ; Обновляем heap_ptr
    mov [heap_ptr], rdi
    
    ; Вычисляем результат
    pop rax                         ; RAX = начало новой строки
    mov rdx, r13
    add rdx, r15                    ; Общая длина
    
    ; Обновляем текущие значения для следующей итерации
    mov r12, rax
    mov r13, rdx
    
    jmp .strexpr_loop
    
.strexpr_pushback:
    mov byte [token_pushed], 1
    
.strexpr_done:
    mov rax, r12
    mov rdx, r13
    mov rcx, 1
    jmp .strexpr_ret
    
.strexpr_error:
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    
.strexpr_ret:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ----------------------------------------------------------------------------
; parse_string_factor - парсит строковый литерал или переменную
; Возвращает: RAX = ptr, RDX = len, RCX = 1 (успех)
; ----------------------------------------------------------------------------
parse_string_factor:
    push rbx
    sub rsp, 32
    
    ; Получаем токен
    lea rdi, [current_token]
    call lexer_next_token
    
    cmp al, TOKEN_STRING
    je .strfact_literal
    cmp al, TOKEN_STRING_VAR
    je .strfact_var
    
    ; Ошибка
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    jmp .strfact_ret
    
.strfact_literal:
    ; Строковый литерал "..."
    ; Копируем в heap с null-terminator (для FFI)
    lea rbx, [current_token]
    mov rsi, qword [rbx + TOKEN_VALUE]   ; Указатель на строку
    movzx r8d, word [rbx + TOKEN_LENGTH] ; Длина
    
    ; Выделяем место в heap
    mov rdi, [heap_ptr]
    mov rax, rdi                    ; Запоминаем начало
    
    ; Копируем
    mov rcx, r8
    push rax
    rep movsb
    
    ; Добавляем null-terminator для совместимости с C-строками
    mov byte [rdi], 0
    inc rdi
    pop rax
    
    ; Обновляем heap_ptr
    mov [heap_ptr], rdi
    
    mov rdx, r8                     ; Длина (без null)
    mov rcx, 1                      ; Успех
    jmp .strfact_ret
    
.strfact_var:
    ; Строковая переменная A$
    lea rbx, [current_token]
    mov rax, qword [rbx + TOKEN_VALUE]
    movzx eax, byte [rax]           ; Первый символ
    cmp al, 'a'
    jl .strfact_var_upper
    sub al, 32
.strfact_var_upper:
    sub al, 'A'
    cmp al, 25
    ja .strfact_var_error
    
    ; Получаем из str_vars
    ; Формат: [PTR (8)][LEN (8)] - каждая запись 16 байт
    movzx eax, al
    shl eax, 4                      ; * 16 (индекс в байтах)
    lea rbx, [str_vars]
    add rbx, rax                    ; rbx = &str_vars[index]
    mov rax, qword [rbx]            ; PTR
    mov rdx, qword [rbx + 8]        ; LEN
    
    mov rcx, 1
    jmp .strfact_ret
    
.strfact_var_error:
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    
.strfact_ret:
    add rsp, 32
    pop rbx
    ret

; ============================================================================
; УТИЛИТЫ ВЫВОДА
; ============================================================================

print_string:
    push rcx
    mov rcx, [stdout_handle]
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    pop rcx
    ret

print_cstring:
    push rcx
    push r8
    push rsi
    
    mov rsi, rdx
    xor r8d, r8d
.count:
    cmp byte [rsi + r8], 0
    je .print
    inc r8d
    jmp .count
.print:
    mov rcx, [stdout_handle]
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    
    pop rsi
    pop r8
    pop rcx
    ret

print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push r8
    
    ; Проверяем на отрицательное число (signed)
    test rax, rax
    jns .positive
    
    ; Отрицательное - выводим минус и инвертируем
    push rax
    mov byte [num_buffer], '-'
    lea rdx, [num_buffer]
    mov r8d, 1
    call print_string
    pop rax
    neg rax
    
.positive:
    lea rcx, [num_buffer + 20]
    mov byte [rcx], 0
    mov rbx, 10
    
.conv_loop:
    xor edx, edx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .conv_loop
    
    lea rsi, [num_buffer + 20]
    sub rsi, rcx
    
    mov rdx, rcx
    mov r8d, esi
    call print_string
    
    pop r8
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; print_float - выводит число с плавающей точкой
; Phase 15: Floating Point Support
; Вход: RAX = 64-bit pattern of double (IEEE 754)
; Алгоритм: ftoa с фиксированной точностью (6 знаков после запятой)
; ----------------------------------------------------------------------------
print_float:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r12
    push r13
    push r14
    sub rsp, 40
    
    ; Загружаем double из RAX
    movq xmm0, rax
    
    ; Проверяем на отрицательное число
    xorpd xmm1, xmm1                ; xmm1 = 0.0
    ucomisd xmm0, xmm1
    jae .pf_positive
    
    ; Отрицательное - выводим минус
    push rax
    mov byte [num_buffer], '-'
    lea rdx, [num_buffer]
    mov r8d, 1
    call print_string
    pop rax
    
    ; Инвертируем знак: xmm0 = -xmm0
    movq xmm0, rax
    mov rax, 0x8000000000000000     ; Sign bit mask
    movq xmm1, rax
    xorpd xmm0, xmm1                ; Flip sign bit
    
.pf_positive:
    ; xmm0 = |value|
    
    ; Извлекаем целую часть
    cvttsd2si rax, xmm0             ; rax = (int64)xmm0 (truncate)
    mov r12, rax                    ; r12 = целая часть
    
    ; Вычисляем дробную часть: frac = xmm0 - (double)r12
    cvtsi2sd xmm1, r12              ; xmm1 = (double)целая_часть
    subsd xmm0, xmm1                ; xmm0 = дробная часть (0.0 <= x < 1.0)
    
    ; Умножаем дробную часть на 1000000 (6 знаков точности)
    mov rax, 1000000
    cvtsi2sd xmm1, rax
    mulsd xmm0, xmm1                ; xmm0 = frac * 1000000
    
    ; Округляем до целого
    cvtsd2si r13, xmm0              ; r13 = дробная часть как int (0-999999)
    
    ; Выводим целую часть
    mov rax, r12
    call print_number
    
    ; Выводим точку
    mov byte [num_buffer], '.'
    lea rdx, [num_buffer]
    mov r8d, 1
    call print_string
    
    ; Выводим дробную часть с ведущими нулями (6 цифр)
    mov rax, r13
    lea rdi, [num_buffer + 6]       ; Конец буфера
    mov byte [rdi], 0
    mov rcx, 6                      ; 6 цифр
    mov rbx, 10
    
.pf_frac_loop:
    xor edx, edx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    dec rcx
    jnz .pf_frac_loop
    
    ; Удаляем trailing zeros (но оставляем хотя бы 1 цифру)
    lea rsi, [num_buffer + 5]       ; Последняя цифра
    mov rcx, 5                      ; Максимум удалить 5 нулей
.pf_trim_zeros:
    cmp byte [rsi], '0'
    jne .pf_print_frac
    mov byte [rsi], 0               ; Убираем ноль
    dec rsi
    dec rcx
    jnz .pf_trim_zeros
    
.pf_print_frac:
    ; Выводим дробную часть
    lea rdx, [num_buffer]
    ; Считаем длину
    lea rsi, [num_buffer]
    xor r8d, r8d
.pf_len_loop:
    cmp byte [rsi], 0
    je .pf_print_now
    inc rsi
    inc r8d
    jmp .pf_len_loop
    
.pf_print_now:
    test r8d, r8d
    jz .pf_done
    call print_string
    
.pf_done:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ----------------------------------------------------------------------------
; print_hex_byte - выводит байт в hex (AL)
; Вход: AL = байт
; ----------------------------------------------------------------------------
print_hex_byte:
    push rax
    push rbx
    push rcx
    push rdx
    
    mov bl, al              ; Сохраняем байт
    lea rcx, [hex_chars]
    
    ; Старший nibble
    mov al, bl
    shr al, 4
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    mov [num_buffer], al
    
    ; Младший nibble
    mov al, bl
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    mov [num_buffer + 1], al
    
    ; Выводим 2 символа
    lea rdx, [num_buffer]
    mov r8d, 2
    call print_string
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ----------------------------------------------------------------------------
; print_hex_word - выводит word в hex (AX, 4 цифры)
; Вход: AX = word
; ----------------------------------------------------------------------------
print_hex_word:
    push rax
    push rbx
    push rcx
    push rdx
    
    mov bx, ax              ; Сохраняем word
    lea rcx, [hex_chars]
    
    ; Nibble 3 (старший)
    mov al, bh
    shr al, 4
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    mov [num_buffer], al
    
    ; Nibble 2
    mov al, bh
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    mov [num_buffer + 1], al
    
    ; Nibble 1
    mov al, bl
    shr al, 4
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    mov [num_buffer + 2], al
    
    ; Nibble 0 (младший)
    mov al, bl
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    mov [num_buffer + 3], al
    
    ; Выводим 4 символа
    lea rdx, [num_buffer]
    mov r8d, 4
    call print_string
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; CRASH HANDLER - Перехват исключений (Phase X.2)
; ============================================================================
; Вызывается Windows при необработанном исключении
; Вход: RCX = EXCEPTION_POINTERS (указатель на EXCEPTION_RECORD и CONTEXT)
; Выход: EAX = EXCEPTION_CONTINUE_EXECUTION (-1) или EXCEPTION_EXECUTE_HANDLER (1)
; ============================================================================

; Константы исключений Windows
EXCEPTION_ACCESS_VIOLATION    = 0xC0000005
EXCEPTION_INT_DIVIDE_BY_ZERO  = 0xC0000094
EXCEPTION_ILLEGAL_INSTRUCTION = 0xC000001D
EXCEPTION_CONTINUE_EXECUTION  = -1

crash_handler:
    ; Прямой вывод через WriteConsoleA (обходим обёртки)
    push rbp
    mov rbp, rsp
    sub rsp, 96                     ; Shadow space + locals
    
    ; Сохраняем EXCEPTION_POINTERS
    mov [rbp - 8], rcx
    
    ; Получаем stdout заново (на случай если handle испортился)
    mov ecx, STD_OUTPUT_HANDLE
    call [GetStdHandle]
    mov [rbp - 16], rax             ; Сохраняем stdout
    
    ; Получаем ExceptionCode
    mov rcx, [rbp - 8]              ; EXCEPTION_POINTERS
    mov rax, [rcx]                  ; ExceptionRecord*
    mov ebx, [rax]                  ; ExceptionCode
    
    ; Выводим заголовок
    mov rcx, [rbp - 16]             ; stdout
    lea rdx, [crash_header]         
    mov r8d, 30                     ; Длина "!!! TITAN CRASH HANDLER !!!\r\n"
    lea r9, [bytes_written]
    push qword 0                    ; lpReserved
    sub rsp, 32                     ; shadow space
    call [WriteConsoleA]
    add rsp, 40
    
    ; Определяем тип
    cmp ebx, EXCEPTION_ACCESS_VIOLATION
    je .crash_access
    cmp ebx, EXCEPTION_INT_DIVIDE_BY_ZERO
    je .crash_divzero
    jmp .crash_other
    
.crash_access:
    mov rcx, [rbp - 16]
    lea rdx, [crash_access]
    mov r8d, 28                     ; "Access Violation (SIGSEGV)\r\n"
    lea r9, [bytes_written]
    push qword 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    jmp .crash_exit
    
.crash_divzero:
    mov rcx, [rbp - 16]
    lea rdx, [crash_divzero]
    mov r8d, 27                     ; "Division by Zero (SIGFPE)\r\n"
    lea r9, [bytes_written]
    push qword 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    jmp .crash_exit
    
.crash_other:
    mov rcx, [rbp - 16]
    lea rdx, [crash_illegal]
    mov r8d, 21                     ; "Illegal Instruction\r\n"
    lea r9, [bytes_written]
    push qword 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    
.crash_exit:
    ; Выводим сообщение о выходе
    mov rcx, [rbp - 16]
    lea rdx, [crash_continue]
    mov r8d, 20                     ; "Exiting safely...\r\n\r\n"
    lea r9, [bytes_written]
    push qword 0
    sub rsp, 32
    call [WriteConsoleA]
    add rsp, 40
    
    ; Безопасный выход
    add rsp, 96
    pop rbp
    xor ecx, ecx
    call [ExitProcess]
    
    ; Fallback
    mov eax, 1
    ret

; ----------------------------------------------------------------------------
; print_hex_dword - выводит DWORD в hex (EAX, 8 цифр)
; Вход: EAX = dword
; ----------------------------------------------------------------------------
print_hex_dword:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov ebx, eax                    ; Сохраняем dword
    lea rdi, [num_buffer]
    lea rcx, [hex_chars]
    
    ; 8 nibbles, от старшего к младшему
    mov eax, ebx
    shr eax, 28
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    shr eax, 24
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    shr eax, 20
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    shr eax, 16
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    shr eax, 12
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    shr eax, 8
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    shr eax, 4
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    mov eax, ebx
    and eax, 0Fh
    movzx eax, byte [rcx + rax]
    stosb
    
    ; Выводим 8 символов
    lea rdx, [num_buffer]
    mov r8d, 8
    call print_string
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; FFI: Поиск функции в таблице по хешу имени
; Вход: RAX = хеш имени
; Выход: RAX = адрес функции (или 0 если не найдена)
;        RDX = DLL Handle
; ============================================================================
ffi_lookup:
    push rbx
    push rcx
    push r8
    
    mov r8, rax                     ; r8 = искомый хеш
    mov rcx, [ffi_count]            ; rcx = количество записей
    test rcx, rcx
    jz .ffi_not_found
    
    lea rbx, [ffi_table]            ; rbx = начало таблицы
    
.ffi_search_loop:
    cmp qword [rbx], r8             ; Сравниваем хеш
    je .ffi_found
    add rbx, FFI_ENTRY_SIZE         ; Следующая запись
    dec rcx
    jnz .ffi_search_loop
    
.ffi_not_found:
    xor eax, eax
    xor edx, edx
    jmp .ffi_lookup_ret

.ffi_found:
    mov rax, qword [rbx + 8]        ; Function Address
    mov rdx, qword [rbx + 16]       ; DLL Handle
    
.ffi_lookup_ret:
    pop r8
    pop rcx
    pop rbx
    ret

; ============================================================================
; FFI: Вычисление хеша строки (DJB2)
; Вход: RSI = указатель на строку, RCX = длина
; Выход: RAX = хеш
; ============================================================================
ffi_hash_string:
    push rbx
    push rcx
    push rsi
    
    mov rax, 5381                   ; DJB2 initial value
    
.ffi_hash_loop:
    test rcx, rcx
    jz .ffi_hash_done
    
    movzx ebx, byte [rsi]
    ; Приводим к верхнему регистру
    cmp bl, 'a'
    jl .ffi_hash_upper
    cmp bl, 'z'
    jg .ffi_hash_upper
    sub bl, 32
.ffi_hash_upper:
    imul rax, 33
    add rax, rbx
    inc rsi
    dec rcx
    jmp .ffi_hash_loop
    
.ffi_hash_done:
    pop rsi
    pop rcx
    pop rbx
    ret

; ============================================================================
; FFI: Вызов функции с аргументами (до 4)
; Вход: 
;   RAX = адрес функции
;   Stack: [arg4] [arg3] [arg2] [arg1] (сверху вниз, arg1 на вершине)
;   RCX = количество аргументов (0-4)
; Выход: RAX = результат функции
; ============================================================================
ffi_call_function:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    
    mov r15, rax                    ; r15 = адрес функции
    
    ; Загружаем аргументы из стека в регистры Windows x64 ABI
    ; Аргументы лежат в стеке: [rbp+48]=arg1, [rbp+56]=arg2, etc.
    ; (учитывая 6 push по 8 байт = 48 байт)
    
    xor ecx, ecx                    ; arg1 = 0 по умолчанию
    xor edx, edx                    ; arg2 = 0
    xor r8d, r8d                    ; arg3 = 0
    xor r9d, r9d                    ; arg4 = 0
    
    ; TODO: загрузка аргументов из стека вызывающей стороны
    
    ; Выравниваем стек и резервируем shadow space
    and rsp, -16
    sub rsp, 32
    
    ; Вызываем функцию
    call r15
    
    ; Восстанавливаем стек
    mov rsp, rbp
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
