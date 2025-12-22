; =============================================================================
; SYNAPSE CLI Compiler v2.3 - FULL IMPLEMENTATION
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Complete pipeline: File → Lexer → Parser → AST → JIT → Execute
; Usage: synapse.exe [filename.syn]
; =============================================================================

format PE64 console
entry start

MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_RW = 0x40
GENERIC_READ    = 0x80000000
OPEN_EXISTING   = 3
FILE_ATTRIBUTE_NORMAL = 0x80
INVALID_HANDLE_VALUE = -1

include '..\include\ast.inc'

section '.idata' import data readable
    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetStdHandle    dq RVA _GetStdHandle
        WriteConsoleA   dq RVA _WriteConsoleA
        ReadConsoleA    dq RVA _ReadConsoleA
        ExitProcess     dq RVA _ExitProcess
        VirtualAlloc    dq RVA _VirtualAlloc
        CreateFileA     dq RVA _CreateFileA
        ReadFile        dq RVA _ReadFile
        GetFileSize     dq RVA _GetFileSize
        CloseHandle     dq RVA _CloseHandle
        GetCommandLineA dq RVA _GetCommandLineA
                        dq 0

    kernel32_name   db 'KERNEL32.DLL',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ReadConsoleA   db 0,0,'ReadConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0
    _CreateFileA    db 0,0,'CreateFileA',0
    _ReadFile       db 0,0,'ReadFile',0
    _GetFileSize    db 0,0,'GetFileSize',0
    _CloseHandle    db 0,0,'CloseHandle',0
    _GetCommandLineA db 0,0,'GetCommandLineA',0

section '.data' data readable writeable

    banner      db '============================================',13,10
                db '  SYNAPSE v2.5 Compiler',13,10
                db '  Full Pipeline: Lex -> Parse -> JIT -> Run',13,10
                db '============================================',13,10,13,10,0
    
    load_msg    db '[LOAD] Reading source file...',13,10,0
    lex_msg     db '[LEX] Tokenizing...',13,10,0
    parse_msg   db '[PARSE] Building AST...',13,10,0
    jit_msg     db '[JIT] Generating machine code...',13,10,0
    exec_msg    db '[EXEC] Running...',13,10,0
    done_msg    db 13,10,'--------------------------------',13,10,0
    result_msg  db 'Exit Code: ',0
    newline     db 13,10,0
    
    err_file    db '[ERROR] Cannot open file: ',0
    err_lex     db '[ERROR] Lexer failed',13,10,0
    err_parse   db '[ERROR] Parser failed',13,10,0
    err_jit     db '[ERROR] JIT failed',13,10,0
    err_no_main db '[ERROR] Function main() not found',13,10,0
    
    dbg_func_count db '[DEBUG] Functions compiled: ',0
    dbg_main_addr  db '[DEBUG] main() address: ',0
    dbg_calling    db '[DEBUG] Calling main()...',13,10,0
    dbg_jit_size   db '[DEBUG] JIT code size: ',0
    dbg_factorial  db '[DEBUG] factorial() address: ',0
    dbg_jit_dump   db '[DEBUG] main() JIT bytes: ',0
    dbg_adding_func db '[DEBUG] Adding function: ',0
    dbg_found_fn db '[DEBUG] Found fn keyword',13,10,0
    dbg_parsing_fn db '[DEBUG] Parsing fn: ',0
    dbg_sym_add db '[DEBUG] sym_add: ',0
    dbg_if_token db '[IF] Type: ',0
    dbg_if_val db ' Val: ',0
    dbg_sym_offset db '[DEBUG]   offset: ',0
    dbg_term_type db '[TERM] type=',0
    dbg_term_value db ' value=',0
    dbg_tok_lexed db '[LEX] type=',0
    dbg_tok_val_str db ' val=',0
    dbg_check_char db '[CHR] ',0
    dbg_if_enter db '[IF] Entering compile_if',13,10,0
    dbg_if_body db '[IF] Body token type=',0
    dbg_if_loop db '[IF-LOOP] type=',0
    dbg_kw_check db '[KW] Checking keyword value=',0
    dbg_if_return db '[IF] Matched RETURN!',13,10,0
    dbg_ret_enter db '[RET] Entering compile_return',13,10,0
    dbg_ret_done db '[RET] compile_expr done',13,10,0
    dbg_expr_start db '[EXPR] Starting',13,10,0
    dbg_expr_tok db '[EXPR] After next_token: type=',0
    hex_chars      db '0123456789ABCDEF',0
    
    ; Intrinsics strings
    str_print      db 'print',0
    str_time       db 'time',0
    str_alloc      db 'alloc',0
    str_arg        db 'arg',0
    print_prefix   db '> ',0
    dbg_print_enter db '[PRINT] Entering intrinsic_print',13,10,0
    dbg_print_addr  db '[PRINT] global_sym_find returned: ',0
    
    default_file db 'examples\neuron.syn',0
    
    ; Token types for internal use
    TOK_EOF     = 0
    TOK_NUMBER  = 1
    TOK_IDENT   = 2
    TOK_KEYWORD = 3
    TOK_OP      = 4
    TOK_NEWLINE = 5
    
    ; Keywords
    KW_FN       = 1
    KW_LET      = 2
    KW_WHILE    = 3
    KW_IF       = 4
    KW_RETURN   = 5
    KW_ELSE     = 6
    
    ; Operators
    OP_PLUS     = 1
    OP_MINUS    = 2
    OP_MUL      = 3
    OP_LT       = 4
    OP_GT       = 5
    OP_EQ       = 6
    OP_LPAREN   = 7
    OP_RPAREN   = 8
    OP_LBRACE   = 9
    OP_RBRACE   = 10
    OP_ASSIGN   = 11
    OP_COMMA    = 12
    OP_LBRACKET = 13
    OP_RBRACKET = 14
    
    ; Keyword table
    kw_fn       db 'fn',0
    kw_let      db 'let',0
    kw_while    db 'while',0
    kw_if       db 'if',0
    kw_return   db 'return',0
    kw_else     db 'else',0
    str_factorial db 'factorial',0

section '.bss' data readable writeable

    stdout          dq ?
    stdin           dq ?
    bytes_written   dd ?
    bytes_read      dd ?
    
    ; File handling
    file_handle     dq ?
    file_size       dq ?
    file_buffer     dq ?
    
    ; Memory pools
    heap_base       dq ?
    heap_ptr        dq ?
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ; Lexer state
    lex_pos         dq ?
    lex_end         dq ?
    lex_line        dd ?
    
    ; Current token
    cur_tok_type    dd ?
    cur_tok_value   dq ?
    cur_tok_len     dd ?
    
    ; Peeked token (saved by peek_token)
    peek_tok_type   dd ?
    peek_tok_value  dq ?
    
    tok_buffer      rb 256
    func_call_name  rb 64       ; Buffer for function call name
    var_name_buf    rb 64       ; Buffer for variable name in let
    
    ; Symbol table (simple: name_ptr, offset pairs) - LOCAL to each function
    sym_table       rb 2048     ; 64 entries * 32 bytes (24 name + 8 offset)
    sym_count       dd ?
    sym_offset      dd ?        ; Next local variable offset (negative, grows down)
    param_offset    dd ?        ; Next parameter offset (positive, +16, +24...)
    
    ; GLOBAL symbol table - shared across functions
    ; Format: name (24 bytes) + address in global_vars (8 bytes) = 32 bytes per entry
    global_sym_table rb 2048    ; 64 entries * 32 bytes
    global_sym_count dd ?
    global_vars      rb 512     ; 64 global variables * 8 bytes each
    global_vars_ptr  dq ?
    
    ; Fixed intrinsic argument location (for print, etc.)
    intrinsic_arg    dq 0       ; Value passed to intrinsics like print()
    
    ; Param parsing temp storage (for reverse registration)
    param_names      rb 512     ; 16 params * 32 bytes each (name strings)
    param_count      dd ?       ; Number of parameters found
    
    ; Function table (name hash -> jit address)
    func_table      rb 2048     ; 64 entries * 32 bytes (name_ptr, jit_addr, arg_count)
    func_count      dd ?
    cur_func_name   rb 64       ; Current function name being compiled
    main_addr       dq ?        ; Address of main() for execution
    
    ; AST buffer
    ast_buffer      rb 65536    ; 64KB for AST nodes
    ast_ptr         dq ?
    
    ; Result
    exec_result     dq ?
    num_buffer      rb 32

section '.text' code readable executable

start:
    sub rsp, 56
    
    ; Get handles
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    mov ecx, -10
    call [GetStdHandle]
    mov [stdin], rax
    
    ; Banner
    lea rcx, [banner]
    call print_string
    
    ; Init memory
    call mem_init
    call jit_init
    call sym_init
    call global_sym_init
    call func_table_init
    call init_intrinsics        ; Register built-in functions (print, time)
    call ast_init
    
    ; =========================================================================
    ; PHASE 1: LOAD SOURCE FILE
    ; =========================================================================
    lea rcx, [load_msg]
    call print_string
    
    lea rcx, [default_file]
    call load_file
    test rax, rax
    jz .err_file
    
    mov [file_buffer], rax
    mov [lex_pos], rax
    add rax, [file_size]
    mov [lex_end], rax
    mov dword [lex_line], 1
    
    ; =========================================================================
    ; PHASE 2: LEXER + PARSER + CODEGEN (Single Pass)
    ; =========================================================================
    lea rcx, [lex_msg]
    call print_string
    
    lea rcx, [parse_msg]
    call print_string
    
    lea rcx, [jit_msg]
    call print_string
    
    ; Parse and compile all functions
    call compile_program
    test eax, eax
    jz .err_parse
    
    ; DEBUG: Show function count
    lea rcx, [dbg_func_count]
    call print_string
    mov eax, [func_count]
    call print_number
    lea rcx, [newline]
    call print_string
    
    ; DEBUG: Show main address
    lea rcx, [dbg_main_addr]
    call print_string
    mov rax, [main_addr]
    call print_number
    lea rcx, [newline]
    call print_string
    
    ; DEBUG: Show JIT code size
    lea rcx, [dbg_jit_size]
    call print_string
    mov rax, [jit_cursor]
    sub rax, [jit_buffer]
    call print_number
    lea rcx, [newline]
    call print_string
    
    ; DEBUG: Dump first 220 bytes of main() JIT code (full function)
    lea rcx, [dbg_jit_dump]
    call print_string
    mov rsi, [main_addr]
    mov rcx, 220
    call dump_hex
    lea rcx, [newline]
    call print_string
    
    ; DEBUG: Find and show factorial address
    lea rcx, [str_factorial]
    call func_find
    push rax
    lea rcx, [dbg_factorial]
    call print_string
    pop rax
    call print_number
    lea rcx, [newline]
    call print_string
    
    ; =========================================================================
    ; PHASE 3: EXECUTE main()
    ; =========================================================================
    lea rcx, [exec_msg]
    call print_string
    
    ; Check if main was found
    mov rax, [main_addr]
    test rax, rax
    jz .no_main
    
    ; Execute main() - it has its own prologue/epilogue now
    call rax
    
    mov [exec_result], rax
    
    ; =========================================================================
    ; OUTPUT RESULT
    ; =========================================================================
    lea rcx, [done_msg]
    call print_string
    
    lea rcx, [result_msg]
    call print_string
    
    mov rax, [exec_result]
    call print_number
    
    lea rcx, [newline]
    call print_string
    
    jmp .exit

.err_file:
    lea rcx, [err_file]
    call print_string
    lea rcx, [default_file]
    call print_string
    lea rcx, [newline]
    call print_string
    jmp .exit

.err_parse:
    lea rcx, [err_parse]
    call print_string
    jmp .exit

.no_main:
    lea rcx, [err_no_main]
    call print_string
    jmp .exit

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; compile_program - Parse and JIT compile the source
; Returns: EAX = 1 success, 0 error
; =============================================================================
compile_program:
    push rbx
    push r12
    push r13
    push r14
    push r15
    
.main_loop:
    call next_token
    
    cmp dword [cur_tok_type], TOK_EOF
    je .success
    
    cmp dword [cur_tok_type], TOK_NEWLINE
    je .main_loop
    
    cmp dword [cur_tok_type], TOK_KEYWORD
    jne .main_loop
    
    cmp qword [cur_tok_value], KW_FN
    je .parse_fn
    
    jmp .main_loop

.parse_fn:
    ; Skip 'fn'
    call next_token
    
    ; Expect identifier (function name)
    cmp dword [cur_tok_type], TOK_IDENT
    jne .error
    
    ; Save function name
    lea rsi, [tok_buffer]
    lea rdi, [cur_func_name]
    mov rcx, 60
.copy_fname:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .fname_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_fname
.fname_done:
    
    ; Save JIT address for this function
    mov r14, [jit_cursor]       ; Save function start address
    
    ; Generate function prologue: PUSH RBP; MOV RBP, RSP; SUB RSP, 256
    mov rdi, [jit_cursor]
    
    ; PUSH RBP (0x55)
    mov byte [rdi], 0x55
    inc rdi
    
    ; MOV RBP, RSP (48 89 E5) - 3 bytes
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x89
    mov byte [rdi+2], 0xE5
    add rdi, 3
    
    ; SUB RSP, 256 (48 81 EC 00 01 00 00) - 7 bytes
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x81
    mov byte [rdi+2], 0xEC
    mov dword [rdi+3], 256      ; 00 01 00 00 in little-endian
    add rdi, 7
    
    mov [jit_cursor], rdi
    
    ; Reset symbol table for this function's locals
    call sym_init
    
    ; Skip function name (already saved)
    call next_token
    
    ; Expect '('
    cmp dword [cur_tok_type], TOK_OP
    jne .error
    cmp qword [cur_tok_value], OP_LPAREN
    jne .error
    
    call next_token
    
    ; =========================================================================
    ; PARSE FUNCTION PARAMETERS: fn name(a, b, c)
    ; Parameters get POSITIVE offsets: +16, +24, +32...
    ; BUT: Arguments are pushed L-to-R, so last arg is at lowest offset!
    ; We collect params first, then register in REVERSE order.
    ; =========================================================================
    mov dword [param_count], 0  ; Reset param counter
    
.parse_params:
    ; If immediately ')', no parameters
    cmp dword [cur_tok_type], TOK_OP
    jne .check_param_ident
    cmp qword [cur_tok_value], OP_RPAREN
    je .register_params_reverse
    
.check_param_ident:
    ; Expect identifier (parameter name)
    cmp dword [cur_tok_type], TOK_IDENT
    jne .register_params_reverse ; Not an identifier, assume end
    
    ; Copy param name to param_names buffer
    ; Destination = param_names + param_count * 32
    mov eax, [param_count]
    shl eax, 5                  ; * 32
    lea rdi, [param_names]
    add rdi, rax
    lea rsi, [tok_buffer]
    
    ; Copy name string
    mov rcx, 31
.copy_pname:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_pname_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_pname
.copy_pname_done:
    mov byte [rdi], 0
    
    inc dword [param_count]
    
    ; Advance past parameter name
    call next_token
    
    ; Check for comma (more parameters) or ')' (end)
    cmp dword [cur_tok_type], TOK_OP
    jne .register_params_reverse
    
    cmp qword [cur_tok_value], OP_COMMA
    jne .check_rparen
    
    ; Skip comma and continue parsing params
    call next_token
    jmp .parse_params
    
.check_rparen:
    cmp qword [cur_tok_value], OP_RPAREN
    jne .register_params_reverse
    
.register_params_reverse:
    ; Now we have param_count params in param_names buffer
    ; Register in REVERSE order: last param gets +16, second-to-last +24, etc.
    
    mov dword [param_offset], 16
    mov eax, [param_count]
    test eax, eax
    jz .params_done
    
    dec eax                     ; Start from last param (index = count - 1)
    
.reg_param_loop:
    cmp eax, 0
    jl .params_done
    
    ; Get pointer to param name: param_names + eax * 32
    push rax
    shl eax, 5                  ; * 32
    lea rcx, [param_names]
    add rcx, rax
    
    call sym_add_param          ; Register with current offset (+16, +24, ...)
    
    pop rax
    dec eax                     ; Move to previous param
    jmp .reg_param_loop
    
.params_done:
    ; Current token should be ')'
    cmp dword [cur_tok_type], TOK_OP
    jne .error
    cmp qword [cur_tok_value], OP_RPAREN
    jne .error
    
    call next_token
    
    ; Expect '{'
    cmp dword [cur_tok_type], TOK_OP
    jne .skip_to_brace
    cmp qword [cur_tok_value], OP_LBRACE
    je .parse_body
    
.skip_to_brace:
    cmp dword [cur_tok_type], TOK_EOF
    je .error
    cmp dword [cur_tok_type], TOK_OP
    jne .next_skip
    cmp qword [cur_tok_value], OP_LBRACE
    je .parse_body
.next_skip:
    call next_token
    jmp .skip_to_brace

.parse_body:
    ; CRITICAL: Register function BEFORE parsing body!
    ; This enables recursion (self-calls)
    lea rcx, [cur_func_name]
    mov rdx, r14                ; Function start address (saved earlier)
    call func_add
    
    call parse_block
    
    ; Generate function epilogue: ADD RSP, 256; POP RBP; RET
    mov rdi, [jit_cursor]
    
    ; ADD RSP, 256 (48 81 C4 00 01 00 00) - 7 bytes
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x81
    mov byte [rdi+2], 0xC4
    mov dword [rdi+3], 256
    add rdi, 7
    
    ; POP RBP (0x5D)
    mov byte [rdi], 0x5D
    inc rdi
    
    ; RET (0xC3)
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    ; Function was already registered before parse_block for recursion support
    
    jmp .main_loop

.success:
    mov eax, 1
    jmp .done

.error:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; parse_block - Parse statements inside { }
; =============================================================================
parse_block:
    push rbx
    
.stmt_loop:
    call next_token
    
    cmp dword [cur_tok_type], TOK_EOF
    je .done
    
    cmp dword [cur_tok_type], TOK_OP
    jne .check_keyword
    cmp qword [cur_tok_value], OP_RBRACE
    je .done
    
.check_keyword:
    cmp dword [cur_tok_type], TOK_NEWLINE
    je .stmt_loop
    
    ; Check for function call as statement (identifier followed by '(')
    cmp dword [cur_tok_type], TOK_IDENT
    je .maybe_func_call
    
    cmp dword [cur_tok_type], TOK_KEYWORD
    jne .stmt_loop
    
    mov rax, [cur_tok_value]
    
    cmp rax, KW_LET
    je .parse_let
    
    cmp rax, KW_WHILE
    je .parse_while
    
    cmp rax, KW_IF
    je .parse_if
    
    cmp rax, KW_RETURN
    je .parse_return
    
    jmp .stmt_loop

.maybe_func_call:
    ; This could be a function call like print()
    ; Save identifier name
    lea rsi, [tok_buffer]
    lea rdi, [func_call_name]
    mov rcx, 60
.copy_stmt_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_stmt_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_stmt_name
.copy_stmt_done:
    
    ; Check if next token is '('
    call next_token
    cmp dword [cur_tok_type], TOK_OP
    jne .stmt_loop
    cmp qword [cur_tok_value], OP_LPAREN
    je .is_func_call
    cmp qword [cur_tok_value], OP_LBRACKET
    je .is_array_assign
    cmp qword [cur_tok_value], OP_ASSIGN
    je .is_var_assign
    jmp .stmt_loop

.is_var_assign:
    ; Handle: var = expr
    ; func_call_name contains the variable name
    ; Current token is '='
    
    ; Find variable - check local first
    lea rcx, [func_call_name]
    call sym_find
    test rax, rax
    jz .var_try_global_only
    mov r13b, al            ; R13 = local offset (signed byte)
    
    ; Also find global address
    lea rcx, [func_call_name]
    call global_sym_find
    mov r14, rax            ; R14 = global address (may be 0)
    mov r15d, 1             ; R15 = 1 means we have local
    jmp .var_compile_value
    
.var_try_global_only:
    lea rcx, [func_call_name]
    call global_sym_find
    test rax, rax
    jz .stmt_loop           ; Not found - skip
    mov r14, rax            ; R14 = global address
    xor r15d, r15d          ; R15 = 0 means global only
    
.var_compile_value:
    ; Save R13/R14/R15 before compile_expr
    push r13
    push r14
    push r15
    
    ; Compile right-hand side expression
    call compile_expr
    
    ; Restore R13/R14/R15
    pop r15
    pop r14
    pop r13
    
    ; RAX = value, generate store(s)
    mov rdi, [jit_cursor]
    
    test r15d, r15d
    jz .var_global_only
    
    ; We have local - write to local first
    mov dword [rdi], 0x458948   ; MOV [RBP + disp8], RAX
    mov [rdi+3], r13b
    add rdi, 4
    mov [jit_cursor], rdi
    
    ; Also write to global if we have it
    test r14, r14
    jz .stmt_loop
    
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB948      ; MOV RCX, imm64
    mov [rdi+2], r14
    add rdi, 10
    mov dword [rdi], 0x018948   ; MOV [RCX], RAX
    add rdi, 3
    mov [jit_cursor], rdi
    jmp .stmt_loop
    
.var_global_only:
    ; Global only - write to global
    mov word [rdi], 0xB948      ; MOV RCX, imm64
    mov [rdi+2], r14
    add rdi, 10
    mov dword [rdi], 0x018948   ; MOV [RCX], RAX
    add rdi, 3
    mov [jit_cursor], rdi
    jmp .stmt_loop
    jmp .stmt_loop

.is_array_assign:
    ; Handle: ptr[index] = value
    ; func_call_name contains the variable name (ptr)
    ; Current token is '['
    
    ; First, get the base pointer from local variable
    lea rcx, [func_call_name]
    call sym_find
    test rax, rax
    jz .arr_try_global
    mov r13b, al            ; R13 = local offset
    mov r14d, 1             ; R14 = 1 means local
    jmp .arr_parse_index
    
.arr_try_global:
    lea rcx, [func_call_name]
    call global_sym_find
    test rax, rax
    jz .stmt_loop           ; Not found - skip
    mov r13, rax            ; R13 = global address
    xor r14d, r14d          ; R14 = 0 means global
    
.arr_parse_index:
    ; Save R13/R14 before compile_expr (they may be clobbered)
    push r13
    push r14
    
    ; Compile index expression (next_token will skip '[')
    call compile_expr
    
    ; After compile_expr, need to advance to get ']'
    call next_token
    
    ; RAX now has index value
    ; Generate: PUSH RAX (save index)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50    ; PUSH RAX
    inc qword [jit_cursor]
    
    ; Skip ']' - current token should be ']'
    cmp dword [cur_tok_type], TOK_OP
    jne .arr_skip_eq
    cmp qword [cur_tok_value], OP_RBRACKET
    jne .arr_skip_eq
    call next_token         ; Now on '='
.arr_skip_eq:
    
    ; Current token should be '=' - compile_expr will skip it
    ; Compile value expression
    call compile_expr
    
    ; Restore R13/R14
    pop r14
    pop r13
    
    ; RAX = value to store
    ; Stack has: index
    
    ; Generate: POP RCX (index into RCX)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59    ; POP RCX
    inc qword [jit_cursor]
    
    ; Generate: Load base pointer into RDX
    mov rdi, [jit_cursor]
    test r14d, r14d
    jz .arr_gen_global
    
    ; Local: MOV RDX, [RBP + offset]
    mov dword [rdi], 0x558B48   ; MOV RDX, [RBP + disp8]
    mov [rdi+3], r13b
    add qword [jit_cursor], 4
    jmp .arr_gen_store
    
.arr_gen_global:
    ; Global: MOV RDX, [global_addr]
    mov word [rdi], 0xBA48      ; MOV RDX, imm64
    mov [rdi+2], r13
    add rdi, 10
    mov dword [rdi], 0x128B48   ; MOV RDX, [RDX] (load pointer value)
    add rdi, 3
    mov [jit_cursor], rdi
    
.arr_gen_store:
    ; Generate: MOV [RDX + RCX*8], RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xCA048948 ; MOV [RDX + RCX*8], RAX (48 89 04 CA)
    add qword [jit_cursor], 4
    
    jmp .stmt_loop

.is_func_call:
    ; DON'T skip '(' - compile_expr will read first token itself!
    ; The current token is '('
    
    ; Find function first (save address)
    lea rcx, [func_call_name]
    call func_find
    mov r12, rax                ; R12 = function address
    
    test r12, r12
    jz .skip_call               ; Function not found
    
    ; === Parse ALL arguments (like in compile_term) ===
    xor r14d, r14d              ; R14 = argument counter
    
.stmt_parse_arg_loop:
    ; Parse argument expression
    ; compile_expr will call next_token to skip '(' or ',' and read argument
    push r12                    ; Save func address
    push r14                    ; Save arg counter
    call compile_expr
    pop r14                     ; Restore arg counter
    pop r12                     ; Restore func address
    
    ; Generate: PUSH RAX (push argument onto stack)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50        ; PUSH RAX
    inc qword [jit_cursor]
    
    inc r14d                    ; Count argument
    
    ; Check for ',' (more arguments) or ')' (end)
    cmp dword [cur_tok_type], TOK_OP
    jne .stmt_args_done
    cmp qword [cur_tok_value], OP_COMMA
    jne .stmt_check_rparen
    ; Found ',' - skip it then continue (compile_expr calls next_token internally)
    call next_token             ; Skip ','
    jmp .stmt_parse_arg_loop
    
.stmt_check_rparen:
    cmp qword [cur_tok_value], OP_RPAREN
    je .stmt_args_done
    jmp .stmt_parse_arg_loop    ; Try parsing more
    
.stmt_args_done:
    ; Skip ')' if present
    cmp dword [cur_tok_type], TOK_OP
    jne .skip_paren
    cmp qword [cur_tok_value], OP_RPAREN
    jne .skip_paren
    call next_token             ; Consume ')'
.skip_paren:
    
    ; Generate function call
    mov rdi, [jit_cursor]
    
    ; MOV RAX, func_addr (48 B8 + 8 bytes)
    mov word [rdi], 0xB848
    mov [rdi+2], r12
    add rdi, 10
    
    ; CALL RAX (FF D0)
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    ; Cleanup ALL arguments: ADD RSP, arg_count * 8
    ; R14 = number of arguments
    mov eax, r14d
    shl eax, 3                  ; * 8
    
    ; ADD RSP, imm8 (48 83 C4 xx)
    mov dword [rdi], 0x00C48348
    mov [rdi+3], al
    add rdi, 4
    
    mov [jit_cursor], rdi
    jmp .stmt_loop
    
.skip_call:
    ; Skip to ')'
    cmp dword [cur_tok_type], TOK_OP
    jne .stmt_loop
    cmp qword [cur_tok_value], OP_RPAREN
    jne .stmt_loop
    call next_token
    jmp .stmt_loop

.parse_let:
    call compile_let
    jmp .stmt_loop

.parse_while:
    call compile_while
    jmp .stmt_loop

.parse_if:
    call compile_if
    jmp .check_keyword      ; Don't call next_token - compile_if already positioned

.parse_return:
    call compile_return
    jmp .done

.done:
    pop rbx
    ret

; =============================================================================
; compile_let - Compile: let var = expr
; Stores in local symbol table AND global symbol table for cross-function access
; =============================================================================
compile_let:
    push rbx
    push r12
    push r13
    
    ; Skip 'let'
    call next_token
    
    ; Get variable name
    cmp dword [cur_tok_type], TOK_IDENT
    jne .let_done
    
    ; Save variable name for global registration
    lea rsi, [tok_buffer]
    lea rdi, [var_name_buf]
    mov rcx, 60
.copy_var_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_var_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_var_name
.copy_var_done:
    
    ; Add to LOCAL symbol table
    lea rcx, [tok_buffer]
    call sym_add
    mov r12, rax            ; Save LOCAL offset (negative from RBP)
    
    ; Also add to GLOBAL symbol table
    lea rcx, [var_name_buf]
    call global_sym_add
    mov r13, rax            ; Save GLOBAL address
    
    ; Skip '='
    call next_token
    cmp dword [cur_tok_type], TOK_OP
    jne .let_done
    cmp qword [cur_tok_value], OP_ASSIGN
    jne .let_done
    
    ; Compile expression
    call compile_expr
    
    ; Generate: MOV [RBP + offset], RAX (local copy)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458948      ; MOV [RBP + disp8], RAX
    mov rax, r12
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    
    ; Generate: MOV [global_addr], RAX (global copy)
    ; MOV RCX, imm64; MOV [RCX], RAX
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB948          ; MOV RCX, imm64
    mov [rdi + 2], r13
    add rdi, 10
    mov dword [rdi], 0x018948       ; MOV [RCX], RAX (48 89 01)
    add rdi, 3
    mov [jit_cursor], rdi

.let_done:
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; compile_while - Compile: while (cond) { body }
; =============================================================================
compile_while:
    push rbx
    push r12
    push r13
    push r14
    
    ; Skip 'while' (reads '(', lex_pos now at first token of condition)
    call next_token
    
    ; DON'T skip '(' here! compile_expr's first next_token will read the first 
    ; token of condition. The '(' is now in cur_tok but we ignore it.
    ; compile_expr will call next_token first which reads 'i' (first term)
    
    ; === LOOP START: Save address here so condition is re-evaluated each iteration ===
    mov r12, [jit_cursor]
    
    ; Compile condition (e.g., i < 6)
    ; After: cur_tok = last token of expr, lex_pos at ')'
    call compile_expr
    
    ; Skip ')' - already consumed by compile_expr or it's next
    call peek_token
    cmp dword [cur_tok_type], TOK_OP
    jne .skip_paren_done
    cmp qword [cur_tok_value], OP_RPAREN
    jne .skip_paren_done
    call next_token
.skip_paren_done:
    
    ; Generate: TEST RAX, RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    ; Generate: JZ (skip body) - placeholder
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F
    add qword [jit_cursor], 2
    mov r13, [jit_cursor]       ; Save JZ offset location for backpatching
    mov dword [rdi+2], 0
    add qword [jit_cursor], 4
    
    ; Skip to '{' if not already there
.find_brace:
    call next_token
    cmp dword [cur_tok_type], TOK_EOF
    je .body_done
    cmp dword [cur_tok_type], TOK_OP
    jne .find_brace
    cmp qword [cur_tok_value], OP_LBRACE
    jne .find_brace
    
    ; Now inside body - compile all statements until '}'
.body_loop:
    call peek_token
    
    ; Check for end of body
    cmp dword [cur_tok_type], TOK_EOF
    je .body_done
    
    cmp dword [cur_tok_type], TOK_OP
    jne .not_rbrace
    cmp qword [cur_tok_value], OP_RBRACE
    je .consume_rbrace
.not_rbrace:
    
    ; Skip newlines
    cmp dword [cur_tok_type], TOK_NEWLINE
    jne .check_keyword
    call next_token
    jmp .body_loop
    
.check_keyword:
    ; Check for function call (identifier followed by '(')
    cmp dword [cur_tok_type], TOK_IDENT
    je .while_func_call
    
    cmp dword [cur_tok_type], TOK_KEYWORD
    jne .skip_unknown
    
    mov rax, [cur_tok_value]
    
    ; Handle LET
    cmp rax, KW_LET
    je .while_let
    
    ; Handle RETURN
    cmp rax, KW_RETURN
    je .while_return
    
    ; Handle IF (nested if inside while)
    cmp rax, KW_IF
    je .while_if
    
    jmp .skip_unknown

.while_let:
    call next_token         ; Consume 'let'
    call compile_let
    jmp .body_loop

.while_return:
    call next_token         ; Consume 'return'
    call compile_return
    jmp .body_loop

.while_if:
    ; compile_if expects 'if' as current token from peek
    call compile_if
    jmp .body_loop

.while_func_call:
    ; Consume the identifier (it was only peeked)
    call next_token
    
    ; Save function name
    lea rsi, [tok_buffer]
    lea rdi, [func_call_name]
    mov rcx, 60
.copy_while_fname:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_while_fdone
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_while_fname
.copy_while_fdone:
    
    ; Check for '(' or '=' or '['
    call next_token
    cmp dword [cur_tok_type], TOK_OP
    jne .body_loop
    cmp qword [cur_tok_value], OP_LPAREN
    je .while_do_call
    cmp qword [cur_tok_value], OP_ASSIGN
    je .while_var_assign
    cmp qword [cur_tok_value], OP_LBRACKET
    je .while_array_assign
    jmp .body_loop

.while_var_assign:
    ; Handle: var = expr inside while loop
    ; func_call_name contains the variable name
    ; Current token is '='
    
    ; Find variable - check local first
    lea rcx, [func_call_name]
    call sym_find
    test rax, rax
    jz .while_var_try_global
    mov r15b, al            ; R15 = local offset (signed byte)
    
    ; Also find global address
    push r15
    lea rcx, [func_call_name]
    call global_sym_find
    mov r14, rax            ; R14 = global address (may be 0)
    pop r15
    
    ; Compile right-hand side expression
    push r14
    push r15
    call compile_expr
    pop r15
    pop r14
    
    ; Generate: MOV [RBP + offset], RAX (local copy)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458948      ; MOV [RBP + disp8], RAX
    mov [rdi + 3], r15b
    add rdi, 4
    mov [jit_cursor], rdi
    
    ; Also write to global if we have it
    test r14, r14
    jz .body_loop
    
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB948          ; MOV RCX, imm64
    mov [rdi + 2], r14
    add rdi, 10
    mov dword [rdi], 0x018948       ; MOV [RCX], RAX
    add rdi, 3
    mov [jit_cursor], rdi
    jmp .body_loop
    
.while_var_try_global:
    lea rcx, [func_call_name]
    call global_sym_find
    test rax, rax
    jz .body_loop           ; Not found - skip
    mov r14, rax            ; R14 = global address
    
    ; Compile right-hand side expression
    push r14
    call compile_expr
    pop r14
    
    ; Global only - write to global
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB948          ; MOV RCX, imm64
    mov [rdi + 2], r14
    add rdi, 10
    mov dword [rdi], 0x018948       ; MOV [RCX], RAX
    add rdi, 3
    mov [jit_cursor], rdi
    jmp .body_loop

.while_array_assign:
    ; Handle: ptr[index] = value inside while loop
    ; func_call_name contains the variable name (ptr)
    ; Current token is '['
    
    ; Get base pointer from local variable
    lea rcx, [func_call_name]
    call sym_find
    test rax, rax
    jz .body_loop           ; Variable not found
    mov r15b, al            ; R15b = local offset
    
    ; Save R15 across compile_expr
    push r15
    
    ; Compile index expression
    call compile_expr       ; RAX = index
    
    ; Restore R15
    pop r15
    
    ; --- SAFE TOKEN CONSUMPTION ---
    ; We need to skip ']' and '='. 
    ; Preserve RAX (index) across next_token calls
    push rax
    call next_token         ; Consume ']'
    call next_token         ; Consume '='
    pop rax
    ; ------------------------------
    
    ; Generate: MOV RCX, RAX (Move index to RCX)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC18948       ; MOV RCX, RAX (48 89 C1)
    add rdi, 3
    mov [jit_cursor], rdi
    
    ; Generate: PUSH RCX (Save INDEX on stack)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x51            ; PUSH RCX
    inc rdi
    mov [jit_cursor], rdi
    
    ; Generate: MOV R8, [RBP + offset] (Load BASE POINTER to R8)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458B4C       ; MOV R8, [RBP + disp8]
    mov [rdi + 3], r15b             ; Write offset byte
    add rdi, 4
    mov [jit_cursor], rdi
    
    ; Generate: PUSH R8 (Save BASE on stack)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x41
    mov byte [rdi+1], 0x50          ; PUSH R8
    add rdi, 2
    mov [jit_cursor], rdi
    
    ; Compile value expression (RHS)
    ; This will result in RAX = Value
    call compile_expr
    
    ; Generate: POP R8 (Restore BASE)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x41
    mov byte [rdi+1], 0x58          ; POP R8
    add rdi, 2
    mov [jit_cursor], rdi
    
    ; Generate: POP RCX (Restore INDEX)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59            ; POP RCX
    inc rdi
    mov [jit_cursor], rdi
    
    ; Generate: MOV [R8 + RCX*8], RAX (Write Value to Memory)
    ; 49 89 04 C8 -> MOV [R8 + RCX*8], RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC8048949
    add rdi, 4
    mov [jit_cursor], rdi
    
    jmp .body_loop

.while_do_call:
    
    ; DON'T skip '(' - compile_expr will read first token!
    
    ; Find function (save address in R14)
    lea rcx, [func_call_name]
    call func_find
    mov r14, rax                ; R14 = function address
    
    test r14, r14
    jz .while_skip_call
    
    ; Always parse argument expression
    call compile_expr
    
    ; Generate: PUSH RAX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    ; Expect ')'
    cmp dword [cur_tok_type], TOK_OP
    jne .while_skip_paren
    cmp qword [cur_tok_value], OP_RPAREN
    jne .while_skip_paren
    call next_token
.while_skip_paren:
    
    ; Generate CALL
    mov rdi, [jit_cursor]
    
    ; MOV RAX, func_addr
    mov word [rdi], 0xB848
    mov [rdi+2], r14
    add rdi, 10
    
    ; CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    ; ADD RSP, 8
    mov dword [rdi], 0x08C48348
    add rdi, 4
    
    mov [jit_cursor], rdi
    jmp .body_loop
    
.while_skip_call:
    cmp dword [cur_tok_type], TOK_OP
    jne .body_loop
    cmp qword [cur_tok_value], OP_RPAREN
    jne .body_loop
    call next_token
    jmp .body_loop

.skip_unknown:
    call next_token
    jmp .body_loop

.consume_rbrace:
    call next_token         ; Consume '}'

.body_done:
    ; Generate: JMP (back to loop start - condition)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE9
    inc qword [jit_cursor]
    
    mov rax, r12
    sub rax, [jit_cursor]
    sub rax, 4
    mov rdi, [jit_cursor]
    mov [rdi], eax
    add qword [jit_cursor], 4
    
    ; Backpatch JZ (jump here when condition is false)
    mov rax, [jit_cursor]
    sub rax, r13
    sub rax, 4
    mov [r13], eax
    
    pop r14
    pop r13
    pop r12
    pop rbx
    ret


; =============================================================================
; compile_if - Compile: if (cond) { body } [else { body }]
; 
; JIT Layout:
;   1. TEST RAX, RAX (condition result)
;   2. JZ .else_or_end (if false, jump to else or end)
;   3. [IF BODY CODE]
;   4. JMP .end (skip else block) - only if else exists
;   5. .else_label: [ELSE BODY CODE] - only if else exists
;   6. .end_label:
; =============================================================================
compile_if:
    push rbx
    push r12
    push r13
    push r14
    
    ; Skip 'if' - cur_tok becomes '('
    call next_token
    
    ; Compile condition
    call compile_expr
    
    ; Skip ')' - compile_expr leaves us at ')'
    call next_token
    
    ; Generate: TEST RAX, RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC08548
    add qword [jit_cursor], 3
    
    ; Generate: JZ rel32 (skip to else/end if false)
    mov rdi, [jit_cursor]
    mov word [rdi], 0x840F          ; JZ opcode
    add qword [jit_cursor], 2
    mov r12, [jit_cursor]           ; R12 = address for JZ backpatch
    mov dword [rdi+2], 0            ; placeholder
    add qword [jit_cursor], 4
    
    ; Find and skip '{'
.find_lbrace:
    cmp dword [cur_tok_type], TOK_OP
    jne .skip_to_lbrace
    cmp qword [cur_tok_value], OP_LBRACE
    je .found_lbrace
.skip_to_lbrace:
    call next_token
    jmp .find_lbrace
.found_lbrace:
    call next_token                 ; Skip '{'
    
    ; === Compile IF body ===
.if_body:
    cmp dword [cur_tok_type], TOK_OP
    jne .check_if_stmt
    cmp qword [cur_tok_value], OP_RBRACE
    je .if_body_done
    
.check_if_stmt:
    cmp dword [cur_tok_type], TOK_EOF
    je .if_body_done
    cmp dword [cur_tok_type], TOK_NEWLINE
    je .if_skip_newline
    cmp dword [cur_tok_type], TOK_KEYWORD
    jne .if_skip_unknown
    
    mov rax, [cur_tok_value]
    cmp rax, KW_LET
    je .if_let
    cmp rax, KW_RETURN
    je .if_return
    cmp rax, KW_IF
    je .if_nested_if
    jmp .if_skip_unknown
    
.if_skip_newline:
    call next_token
    jmp .if_body
    
.if_skip_unknown:
    call next_token
    jmp .if_body
    
.if_let:
    call next_token
    call compile_let
    jmp .if_body
    
.if_return:
    call compile_return
    jmp .if_body

.if_nested_if:
    call compile_if
    call next_token                 ; Skip '}' of nested if
    jmp .if_body

.if_body_done:
    ; Skip '}' of if block
    call next_token
    
    ; === Check for ELSE ===
    ; Skip newlines before checking for else
.skip_before_else:
    cmp dword [cur_tok_type], TOK_NEWLINE
    jne .check_else
    call next_token
    jmp .skip_before_else
    
.check_else:
    cmp dword [cur_tok_type], TOK_KEYWORD
    jne .no_else
    cmp qword [cur_tok_value], KW_ELSE
    jne .no_else
    
    ; === FOUND ELSE ===
    
    ; Generate: JMP rel32 (skip else block after if body)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xE9            ; JMP opcode
    add qword [jit_cursor], 1
    mov r13, [jit_cursor]           ; R13 = address for JMP backpatch
    mov dword [rdi+1], 0            ; placeholder
    add qword [jit_cursor], 4
    
    ; Backpatch JZ to HERE (start of else block)
    mov rax, [jit_cursor]
    sub rax, r12
    sub rax, 4
    mov [r12], eax
    
    ; Skip 'else'
    call next_token
    
    ; Find and skip '{' of else block
.find_else_lbrace:
    cmp dword [cur_tok_type], TOK_OP
    jne .skip_to_else_lbrace
    cmp qword [cur_tok_value], OP_LBRACE
    je .found_else_lbrace
.skip_to_else_lbrace:
    call next_token
    jmp .find_else_lbrace
.found_else_lbrace:
    call next_token                 ; Skip '{'
    
    ; === Compile ELSE body ===
.else_body:
    cmp dword [cur_tok_type], TOK_OP
    jne .check_else_stmt
    cmp qword [cur_tok_value], OP_RBRACE
    je .else_body_done
    
.check_else_stmt:
    cmp dword [cur_tok_type], TOK_EOF
    je .else_body_done
    cmp dword [cur_tok_type], TOK_NEWLINE
    je .else_skip_newline
    cmp dword [cur_tok_type], TOK_KEYWORD
    jne .else_skip_unknown
    
    mov rax, [cur_tok_value]
    cmp rax, KW_LET
    je .else_let
    cmp rax, KW_RETURN
    je .else_return
    cmp rax, KW_IF
    je .else_nested_if
    jmp .else_skip_unknown
    
.else_skip_newline:
    call next_token
    jmp .else_body
    
.else_skip_unknown:
    call next_token
    jmp .else_body
    
.else_let:
    call next_token
    call compile_let
    jmp .else_body
    
.else_return:
    call compile_return
    jmp .else_body

.else_nested_if:
    call compile_if
    call next_token                 ; Skip '}' of nested if
    jmp .else_body

.else_body_done:
    ; Backpatch JMP to HERE (after else block)
    mov rax, [jit_cursor]
    sub rax, r13
    sub rax, 4
    mov [r13], eax
    
    jmp .compile_if_exit

.no_else:
    ; No else - just backpatch JZ to HERE
    mov rax, [jit_cursor]
    sub rax, r12
    sub rax, 4
    mov [r12], eax

.compile_if_exit:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; compile_return - Compile: return expr
; Generates: expression + epilogue + RET
; =============================================================================
compile_return:
    push rbx
    
    call compile_expr
    ; Result already in RAX
    
    ; Generate function epilogue and RET
    mov rdi, [jit_cursor]
    
    ; ADD RSP, 256 (48 81 C4 00 01 00 00) - 7 bytes
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x81
    mov byte [rdi+2], 0xC4
    mov dword [rdi+3], 256
    add rdi, 7
    
    ; POP RBP (0x5D)
    mov byte [rdi], 0x5D
    inc rdi
    
    ; RET (0xC3)
    mov byte [rdi], 0xC3
    inc rdi
    
    mov [jit_cursor], rdi
    
    pop rbx
    ret

; =============================================================================
; compile_expr - Compile expression, result in RAX
; =============================================================================
compile_expr:
    push rbx
    push r12
    
    ; Get first term
    call next_token
    call compile_term
    
.expr_loop:
    ; Check for operator
    call peek_token
    
    cmp dword [cur_tok_type], TOK_OP
    jne .expr_done
    
    mov rax, [cur_tok_value]
    
    ; Check for closing paren - means end of expression
    cmp rax, OP_RPAREN
    je .expr_done
    
    cmp rax, OP_PLUS
    je .do_add
    cmp rax, OP_MINUS
    je .do_sub
    cmp rax, OP_MUL
    je .do_mul
    cmp rax, OP_LT
    je .do_lt
    cmp rax, OP_GT
    je .do_gt
    
    jmp .expr_done

.do_add:
    call next_token     ; Skip operator
    
    ; PUSH RAX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    call next_token
    call compile_term
    
    ; POP RCX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; ADD RAX, RCX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC80148
    add qword [jit_cursor], 3
    
    jmp .expr_loop

.do_sub:
    call next_token
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    call next_token
    call compile_term
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; SUB RCX, RAX; MOV RAX, RCX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC12948
    add qword [jit_cursor], 3
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC88948
    add qword [jit_cursor], 3
    
    jmp .expr_loop

.do_mul:
    call next_token
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    call next_token
    call compile_term
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; IMUL RAX, RCX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC1AF0F48
    add qword [jit_cursor], 4
    
    jmp .expr_loop

.do_lt:
    call next_token
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    call next_token
    call compile_term
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; CMP RCX, RAX
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948
    add qword [jit_cursor], 3
    
    ; SETL AL
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC09C0F
    add qword [jit_cursor], 3
    
    ; MOVZX RAX, AL
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48
    add qword [jit_cursor], 4
    
    jmp .expr_loop

.do_gt:
    call next_token
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    call next_token
    call compile_term
    
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x59
    inc qword [jit_cursor]
    
    ; CMP RCX, RAX (compare left > right means left - right > 0)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC13948        ; CMP RCX, RAX
    add qword [jit_cursor], 3
    
    ; SETG AL (set if greater - signed)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC09F0F        ; SETG AL (0F 9F C0)
    add qword [jit_cursor], 3
    
    ; MOVZX RAX, AL
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC0B60F48
    add qword [jit_cursor], 4
    
    jmp .expr_loop

.expr_done:
    pop r12
    pop rbx
    ret

; =============================================================================
; compile_term - Compile single term (number or variable)
; REWRITTEN: Uses peek_token instead of manual lexer manipulation
; =============================================================================
compile_term:
    cmp dword [cur_tok_type], TOK_NUMBER
    je .number
    
    cmp dword [cur_tok_type], TOK_IDENT
    je .variable
    
    ; Default: return 0
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov qword [rdi+2], 0
    add qword [jit_cursor], 10
    ret

.number:
    ; MOV RAX, imm64
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov rax, [cur_tok_value]
    mov [rdi+2], rax
    add qword [jit_cursor], 10
    ret

.variable:
    ; Save current identifier name
    push rbx
    lea rsi, [tok_buffer]
    lea rdi, [func_call_name]
    mov rcx, 60
.copy_call_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_call_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_call_name
.copy_call_done:
    pop rbx
    
    ; --- NEW LOGIC: Use peek_token to check ahead ---
    call peek_token
    
    ; Check if next token is '(' (Function Call) or '[' (Array)
    cmp dword [peek_tok_type], TOK_OP
    jne .not_func_call
    
    cmp qword [peek_tok_value], OP_LPAREN
    je .is_func_call
    
    cmp qword [peek_tok_value], OP_LBRACKET
    je .is_array_get
    
    jmp .not_func_call

.is_array_get:
    ; Consume the IDENT (current) so we can proceed to '['
    call next_token     ; Current becomes '['
    
    ; This is array access: ptr[index]
    ; func_call_name has variable name, current token is '['
    
    ; Find the base pointer variable
    lea rcx, [func_call_name]
    call sym_find
    test rax, rax
    jz .arr_get_try_global
    mov r13b, al            ; R13 = local offset
    mov r14d, 1             ; R14 = 1 means local
    jmp .arr_get_parse_index
    
.arr_get_try_global:
    lea rcx, [func_call_name]
    call global_sym_find
    test rax, rax
    jz .arr_get_fail
    mov r13, rax            ; R13 = global address
    xor r14d, r14d          ; R14 = 0 means global
    
.arr_get_parse_index:
    ; Save R13/R14 before compile_expr
    push r13
    push r14
    
    ; Compile index expression (next_token will skip '[')
    call compile_expr       ; RAX = index value
    
    ; --- SAFE TOKEN SKIP ---
    push rax
    call next_token     ; Skip ']'
    pop rax
    ; -----------------------
    
    ; Restore R13/R14
    pop r14
    pop r13
    
    ; RAX = index
    ; Generate: MOV RCX, RAX (save index)
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xC18948   ; MOV RCX, RAX
    add qword [jit_cursor], 3
    
.arr_get_gen:
    ; Generate: Load base pointer into RDX
    mov rdi, [jit_cursor]
    test r14d, r14d
    jz .arr_get_global
    
    ; Local: MOV RDX, [RBP + offset]
    mov dword [rdi], 0x558B48   ; MOV RDX, [RBP + disp8]
    mov [rdi+3], r13b
    add qword [jit_cursor], 4
    jmp .arr_get_load
    
.arr_get_global:
    ; Global: MOV RDX, imm64; MOV RDX, [RDX]
    mov word [rdi], 0xBA48      ; MOV RDX, imm64
    mov [rdi+2], r13
    add rdi, 10
    mov dword [rdi], 0x128B48   ; MOV RDX, [RDX]
    add rdi, 3
    mov [jit_cursor], rdi
    
.arr_get_load:
    ; Generate: MOV RAX, [RDX + RCX*8]
    mov rdi, [jit_cursor]
    mov dword [rdi], 0xCA048B48 ; MOV RAX, [RDX + RCX*8]
    add qword [jit_cursor], 4
    ret
    
.arr_get_fail:
    ; Return 0 on failure
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov qword [rdi+2], 0
    add qword [jit_cursor], 10
    ret

.is_func_call:
    ; Consume the IDENT so we move to '('
    call next_token     ; Current becomes '('
    
    ; Find the function
    lea rcx, [func_call_name]
    call func_find
    
    test rax, rax
    jz .func_not_found
    
    ; Save function address
    mov r15, rax
    
    ; === Parse ALL arguments ===
    xor r14d, r14d              ; R14 = argument counter
    
.parse_arg_loop:
    ; Parse argument expression
    push r15
    push r14
    call compile_expr
    pop r14
    pop r15
    
    ; Generate: PUSH RAX
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x50
    inc qword [jit_cursor]
    
    inc r14d
    
    ; Check for ',' or ')'
    cmp dword [cur_tok_type], TOK_OP
    jne .args_done
    cmp qword [cur_tok_value], OP_COMMA
    jne .check_rparen
    
    ; Found ','
    call next_token
    jmp .parse_arg_loop
    
.check_rparen:
    cmp qword [cur_tok_value], OP_RPAREN
    je .args_done
    jmp .parse_arg_loop
    
.args_done:
    ; Skip ')'
    cmp dword [cur_tok_type], TOK_OP
    jne .skip_call_paren
    cmp qword [cur_tok_value], OP_RPAREN
    jne .skip_call_paren
    call next_token
.skip_call_paren:
    
    ; Generate CALL
    mov rdi, [jit_cursor]
    
    ; MOV RAX, func_addr
    mov word [rdi], 0xB848
    mov [rdi+2], r15
    add rdi, 10
    
    ; CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    ; ADD RSP, N*8
    mov eax, r14d
    shl eax, 3
    
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x81
    mov byte [rdi+2], 0xC4
    mov [rdi+3], eax
    add rdi, 7
    
    mov [jit_cursor], rdi
    ret
    
.func_not_found:
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB848
    mov qword [rdi+2], 0
    add qword [jit_cursor], 10
    ret

.not_func_call:
    ; It's a variable access
    ; NOTE: We do NOT need to restore lex_pos because peek_token 
    ; didn't consume anything permanently, and next_token hasn't been called.
    ; cur_tok is still the IDENT.
    
    ; First try LOCAL symbol table
    lea rcx, [func_call_name]
    call sym_find
    
    test rax, rax
    jz .try_global
    
    ; Found in local - MOV RAX, [RBP + offset]
    mov rdi, [jit_cursor]
    mov dword [rdi], 0x458B48
    mov [rdi + 3], al
    add qword [jit_cursor], 4
    ret

.try_global:
    lea rcx, [func_call_name]
    call global_sym_find
    
    test rax, rax
    jz .var_not_found
    
    ; Found in global - MOV RCX, addr; MOV RAX, [RCX]
    mov rbx, rax
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB948
    mov [rdi + 2], rbx
    add rdi, 10
    mov dword [rdi], 0x018B48
    add rdi, 3
    mov [jit_cursor], rdi
    ret

.var_not_found:
    ; Auto-register global
    lea rcx, [func_call_name]
    call global_sym_add
    
    mov rbx, rax
    mov rdi, [jit_cursor]
    mov word [rdi], 0xB948
    mov [rdi + 2], rbx
    add rdi, 10
    mov dword [rdi], 0x018B48
    add rdi, 3
    mov [jit_cursor], rdi
    ret

; =============================================================================
; LEXER
; =============================================================================
next_token:
    push rbx
    push rsi
    push rdi
    
    mov rsi, [lex_pos]
    
.skip_space:
    cmp rsi, [lex_end]
    jge .eof
    
    mov al, [rsi]
    cmp al, ' '
    je .skip_one
    cmp al, 9
    je .skip_one
    cmp al, 13
    je .skip_one
    jmp .check_char
    
.skip_one:
    inc rsi
    jmp .skip_space

.check_char:
    cmp rsi, [lex_end]
    jge .eof
    
    mov al, [rsi]
    
    ; Newline
    cmp al, 10
    je .newline
    
    ; Comment
    cmp al, '/'
    je .maybe_comment
    
    ; Number
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .number
    
.check_alpha:
    cmp al, 'a'
    jl .check_upper
    cmp al, 'z'
    jle .identifier
    
.check_upper:
    cmp al, 'A'
    jl .check_under
    cmp al, 'Z'
    jle .identifier

.check_under:
    cmp al, '_'
    je .identifier
    
    ; Operators
    jmp .operator

.eof:
    mov dword [cur_tok_type], TOK_EOF
    jmp .done

.newline:
    inc rsi
    mov [lex_pos], rsi
    inc dword [lex_line]
    mov dword [cur_tok_type], TOK_NEWLINE
    jmp .done

.maybe_comment:
    cmp byte [rsi+1], '/'
    jne .operator
    
    ; Skip to end of line
.skip_comment:
    inc rsi
    cmp rsi, [lex_end]
    jge .eof
    cmp byte [rsi], 10
    jne .skip_comment
    jmp .newline

.number:
    xor rbx, rbx
.num_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_done
    cmp al, '9'
    jg .num_done
    
    imul rbx, 10
    movzx eax, al
    sub eax, '0'
    add rbx, rax
    inc rsi
    jmp .num_loop
    
.num_done:
    mov [lex_pos], rsi
    mov dword [cur_tok_type], TOK_NUMBER
    mov [cur_tok_value], rbx
    jmp .done

.identifier:
    lea rdi, [tok_buffer]
    xor ecx, ecx
.ident_loop:
    mov al, [rsi]
    cmp al, 'a'
    jl .ident_check_upper
    cmp al, 'z'
    jle .ident_copy
.ident_check_upper:
    cmp al, 'A'
    jl .ident_check_digit
    cmp al, 'Z'
    jle .ident_copy
.ident_check_digit:
    cmp al, '0'
    jl .ident_check_under
    cmp al, '9'
    jle .ident_copy
.ident_check_under:
    cmp al, '_'
    jne .ident_done
.ident_copy:
    mov [rdi + rcx], al
    inc rcx
    inc rsi
    jmp .ident_loop
    
.ident_done:
    mov byte [rdi + rcx], 0
    mov [cur_tok_len], ecx
    mov [lex_pos], rsi
    
    ; Check if keyword
    call check_keyword
    test eax, eax
    jnz .is_keyword
    
    mov dword [cur_tok_type], TOK_IDENT
    jmp .done
    
.is_keyword:
    mov dword [cur_tok_type], TOK_KEYWORD
    ; eax contains keyword code, zero-extend and store
    mov dword [cur_tok_value], eax
    mov dword [cur_tok_value + 4], 0     ; Zero upper 32 bits
    jmp .done

.operator:
    mov al, [rsi]
    inc rsi
    mov [lex_pos], rsi
    mov dword [cur_tok_type], TOK_OP
    
    cmp al, '+'
    je .op_plus
    cmp al, '-'
    je .op_minus
    cmp al, '*'
    je .op_mul
    cmp al, '<'
    je .op_lt
    cmp al, '>'
    je .op_gt
    cmp al, '='
    je .op_eq
    cmp al, '('
    je .op_lparen
    cmp al, ')'
    je .op_rparen
    cmp al, '{'
    je .op_lbrace
    cmp al, '}'
    je .op_rbrace
    cmp al, ','
    je .op_comma
    cmp al, '['
    je .op_lbracket
    cmp al, ']'
    je .op_rbracket
    
    ; Unknown - skip
    jmp next_token

.op_plus:
    mov qword [cur_tok_value], OP_PLUS
    jmp .done
.op_minus:
    mov qword [cur_tok_value], OP_MINUS
    jmp .done
.op_mul:
    mov qword [cur_tok_value], OP_MUL
    jmp .done
.op_lt:
    mov qword [cur_tok_value], OP_LT
    jmp .done
.op_gt:
    mov qword [cur_tok_value], OP_GT
    jmp .done
.op_eq:
    mov qword [cur_tok_value], OP_ASSIGN
    jmp .done
.op_lparen:
    mov qword [cur_tok_value], OP_LPAREN
    jmp .done
.op_rparen:
    mov qword [cur_tok_value], OP_RPAREN
    jmp .done
.op_lbrace:
    mov qword [cur_tok_value], OP_LBRACE
    jmp .done
.op_rbrace:
    mov qword [cur_tok_value], OP_RBRACE
    jmp .done
.op_comma:
    mov qword [cur_tok_value], OP_COMMA
    jmp .done
.op_lbracket:
    mov qword [cur_tok_value], OP_LBRACKET
    jmp .done
.op_rbracket:
    mov qword [cur_tok_value], OP_RBRACKET
    jmp .done

.done:
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; peek_token - Look at next token without consuming
; Reads next token and puts result in cur_tok_type/value AND peek_tok_type/value
; Restores lexer position so next_token will re-read the same token
; NOTE: cur_tok_type/value WILL BE MODIFIED to show peeked token!
; =============================================================================
peek_token:
    push rax
    push rbx
    
    ; Save lexer position
    mov rax, [lex_pos]
    push rax
    mov eax, [lex_line]
    push rax
    
    ; Read next token (modifies cur_tok_type/value)
    call next_token
    
    ; Copy to peek_tok_*
    mov eax, [cur_tok_type]
    mov [peek_tok_type], eax
    mov rax, [cur_tok_value]
    mov [peek_tok_value], rax
    
    ; Restore lexer position
    pop rax
    mov [lex_line], eax
    pop rax
    mov [lex_pos], rax
    
    pop rbx
    pop rax
    ret

; =============================================================================
; check_keyword - Check if tok_buffer is a keyword
; Returns: EAX = keyword code or 0
; =============================================================================
check_keyword:
    push rbx
    push rsi
    push rdi
    
    lea rsi, [tok_buffer]
    
    ; Check 'fn'
    lea rdi, [kw_fn]
    call str_eq
    test eax, eax
    jnz .is_fn
    
    ; Check 'let'
    lea rdi, [kw_let]
    call str_eq
    test eax, eax
    jnz .is_let
    
    ; Check 'while'
    lea rdi, [kw_while]
    call str_eq
    test eax, eax
    jnz .is_while
    
    ; Check 'if'
    lea rdi, [kw_if]
    call str_eq
    test eax, eax
    jnz .is_if
    
    ; Check 'return'
    lea rdi, [kw_return]
    call str_eq
    test eax, eax
    jnz .is_return
    
    ; Check 'else'
    lea rdi, [kw_else]
    call str_eq
    test eax, eax
    jnz .is_else
    
    xor eax, eax
    jmp .ck_done

.is_fn:
    mov eax, KW_FN
    jmp .ck_done
.is_let:
    mov eax, KW_LET
    jmp .ck_done
.is_while:
    mov eax, KW_WHILE
    jmp .ck_done
.is_if:
    mov eax, KW_IF
    jmp .ck_done
.is_return:
    mov eax, KW_RETURN
    jmp .ck_done
.is_else:
    mov eax, KW_ELSE

.ck_done:
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; str_eq - Compare RSI and RDI strings
; Returns: EAX = 1 if equal
; =============================================================================
str_eq:
    push rcx
.cmp_loop:
    mov al, [rsi]
    mov cl, [rdi]
    cmp al, cl
    jne .not_eq
    test al, al
    jz .eq
    inc rsi
    inc rdi
    jmp .cmp_loop
.eq:
    mov eax, 1
    pop rcx
    ret
.not_eq:
    xor eax, eax
    pop rcx
    ret

; =============================================================================
; SYMBOL TABLE (LOCAL - per function)
; =============================================================================
sym_init:
    mov dword [sym_count], 0
    mov dword [sym_offset], -8
    mov dword [param_offset], 16    ; First param at [RBP+16]
    ret

; =============================================================================
; GLOBAL SYMBOL TABLE - shared across all functions
; =============================================================================
global_sym_init:
    mov dword [global_sym_count], 0
    lea rax, [global_vars]
    mov [global_vars_ptr], rax
    ret

global_sym_add:
    ; RCX = name pointer
    ; Adds a global variable, returns address in global_vars
    push rbx
    push rsi
    push rdi
    push r12
    
    mov r12, rcx                ; Save name pointer in r12
    
    ; Check if already exists (rcx still has name)
    call global_sym_find
    test rax, rax
    jnz .gs_exists
    
    ; Add new entry
    mov eax, [global_sym_count]
    shl eax, 5                  ; * 32
    lea rdi, [global_sym_table]
    add rdi, rax
    
    ; Copy name (up to 24 chars)
    mov rsi, r12                ; Source = saved name pointer
    push rdi
    mov rcx, 24
.gs_copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .gs_copy_done
    inc rsi
    inc rdi
    dec rcx
    jnz .gs_copy
.gs_copy_done:
    mov byte [rdi], 0
    pop rdi
    
    ; Calculate address in global_vars (8 bytes per var)
    mov eax, [global_sym_count]
    shl eax, 3                  ; * 8
    lea rbx, [global_vars]
    add rbx, rax
    mov [rdi + 24], rbx         ; Store address at offset 24
    
    inc dword [global_sym_count]
    mov rax, rbx
    jmp .gs_done

.gs_exists:
    ; RAX already has the address

.gs_done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

global_sym_find:
    ; RCX = name to find
    ; Returns: RAX = address in global_vars or 0
    push rbx
    push rsi
    push rdi
    push r12
    
    mov r12, rcx
    
    xor ebx, ebx
    mov ecx, [global_sym_count]
    test ecx, ecx
    jz .gsf_not_found
    
.gsf_loop:
    mov eax, ebx
    shl eax, 5                  ; * 32
    lea rdi, [global_sym_table]
    add rdi, rax
    
    mov rsi, r12
    push rdi
    call str_eq
    pop rdi
    
    test eax, eax
    jnz .gsf_found
    
    inc ebx
    cmp ebx, [global_sym_count]
    jl .gsf_loop

.gsf_not_found:
    xor eax, eax
    xor rax, rax
    jmp .gsf_done

.gsf_found:
    mov rax, [rdi + 24]         ; Return the address

.gsf_done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; FUNCTION TABLE - Maps function names to JIT addresses
; =============================================================================
func_table_init:
    mov dword [func_count], 0
    mov qword [main_addr], 0
    ret

; =============================================================================
; INTRINSICS - Built-in functions registered at startup
; =============================================================================
init_intrinsics:
    push rbx
    
    ; Register 'print' intrinsic
    lea rcx, [str_print]
    lea rdx, [intrinsic_print]
    call func_add
    
    ; Register 'time' intrinsic (returns CPU timestamp)
    lea rcx, [str_time]
    lea rdx, [intrinsic_time]
    call func_add
    
    ; Register 'alloc' intrinsic (dynamic memory allocation)
    lea rcx, [str_alloc]
    lea rdx, [intrinsic_alloc]
    call func_add
    
    pop rbx
    ret

; -----------------------------------------------------------------------------
; intrinsic_print - Prints argument passed via stack
; Usage in SYNAPSE:
;    print(42)           // literal
;    print(x)            // variable
;    print(x * 10 + 5)   // expression
;
; Stack Layout at entry:
;   [RSP]      = Return Address (8 bytes) - from CALL
;   [RSP + 8]  = Argument 1 (pushed by caller before CALL)
;
; After our pushes:
;   [RSP]      = saved RDI
;   [RSP + 8]  = saved RSI  
;   [RSP + 16] = saved RBX
;   [RSP + 24] = Return Address
;   [RSP + 32] = ARGUMENT!
; -----------------------------------------------------------------------------
intrinsic_print:
    push rbx
    push rsi
    push rdi
    sub rsp, 32                 ; Shadow space for Windows x64
    
    ; Read argument from stack and save it
    ; +32 (shadow) +8 (rdi) +8 (rsi) +8 (rbx) +8 (ret) = 64, then arg
    mov rbx, [rsp + 64]         ; Save argument in RBX
    
    ; Print prefix "> "
    lea rcx, [print_prefix]
    call print_string
    
    ; Print the number
    mov rax, rbx                ; Restore from RBX
    call print_number
    
    ; Print newline
    lea rcx, [newline]
    call print_string
    
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; intrinsic_time - Returns CPU timestamp (RDTSC) in RAX
; Usage: let t = time()
; -----------------------------------------------------------------------------
intrinsic_time:
    rdtsc
    shl rdx, 32
    or rax, rdx
    ret

; -----------------------------------------------------------------------------
; intrinsic_alloc(size) - Allocate dynamic memory
; Usage: let arr = alloc(10)   // allocates 10 qwords (80 bytes)
; Returns: pointer to allocated memory in RAX
;
; Stack layout after pushes:
;   [RSP+24] = Return address
;   [RSP+32] = Size argument (number of qwords)
; -----------------------------------------------------------------------------
intrinsic_alloc:
    push rbx
    push rsi
    
    ; Read 'size' argument from stack
    mov rcx, [rsp + 24]         ; Size in qwords
    
    ; Convert to bytes (size * 8)
    shl rcx, 3
    
    ; Simple bump allocator from heap_ptr
    mov rax, [heap_ptr]
    add [heap_ptr], rcx         ; Advance heap pointer
    
    ; RAX = pointer to allocated memory
    pop rsi
    pop rbx
    ret

func_add:
    ; RCX = name pointer, RDX = JIT address
    push rbx
    push rsi
    push rdi
    
    mov rsi, rcx
    mov rbx, rdx
    
    ; Get current count
    mov eax, [func_count]
    shl eax, 5                  ; * 32
    lea rdi, [func_table]
    add rdi, rax
    
    ; Copy name (up to 24 chars)
    push rdi
    mov rcx, 24
.copy_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_name
.copy_done:
    mov byte [rdi], 0           ; Ensure null-term
    pop rdi
    
    ; Store JIT address at offset 24
    mov [rdi + 24], rbx
    
    ; Check if this is 'main'
    push rdi
    lea rsi, [rdi]
    lea rdi, [str_main]
    call str_eq
    pop rdi
    test eax, eax
    jz .not_main
    mov rax, [rdi + 24]
    mov [main_addr], rax
.not_main:
    
    inc dword [func_count]
    
    pop rdi
    pop rsi
    pop rbx
    ret

func_find:
    ; RCX = name to find
    ; Returns: RAX = JIT address or 0
    push rbx
    push rsi
    push rdi
    push r12
    
    mov r12, rcx                ; Save name
    
    xor ebx, ebx
    mov ecx, [func_count]
    test ecx, ecx
    jz .ff_not_found
    
.ff_loop:
    mov eax, ebx
    shl eax, 5                  ; * 32
    lea rdi, [func_table]
    add rdi, rax
    
    mov rsi, r12
    push rdi
    call str_eq
    pop rdi
    
    test eax, eax
    jnz .ff_found
    
    inc ebx
    cmp ebx, [func_count]
    jl .ff_loop
    
.ff_not_found:
    xor eax, eax
    xor rax, rax
    jmp .ff_done

.ff_found:
    mov rax, [rdi + 24]

.ff_done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; String for main function
str_main db 'main',0

sym_add:
    ; RCX = name pointer
    ; Returns: EAX = offset (negative from RBP)
    push rbx
    push rsi
    push rdi
    
    mov rsi, rcx
    
    ; First check if exists
    call sym_find
    test eax, eax
    jnz .sym_exists
    
    ; Add new entry
    mov eax, [sym_count]
    shl eax, 5                  ; * 32 (new entry size)
    lea rdi, [sym_table]
    add rdi, rax
    
    ; Copy name string (up to 24 chars)
    push rdi
    mov rcx, 24
.copy_sym_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_sym_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_sym_name
.copy_sym_done:
    mov byte [rdi], 0
    pop rdi
    
    ; Assign offset (stored at offset 24 in entry)
    mov eax, [sym_offset]
    
    mov [rdi + 24], eax         ; Store offset at offset 24 (after 24-byte name)
    
    ; Update offset for next
    sub dword [sym_offset], 8
    inc dword [sym_count]
    
    ; Return the offset we just assigned
    jmp .sym_done

.sym_exists:
    ; sym_find already returned the offset in EAX
    ; Just return it

.sym_done:
    pop rdi
    pop rsi
    pop rbx
    ret

; -----------------------------------------------------------------------------
; sym_add_param - Register function parameter with POSITIVE offset
; RCX = name pointer
; Parameters are at [RBP+16], [RBP+24], etc. (above return address)
; -----------------------------------------------------------------------------
sym_add_param:
    push rbx
    push rsi
    push rdi
    
    mov rsi, rcx
    
    ; Add new entry (don't check if exists - params are always new)
    mov eax, [sym_count]
    shl eax, 5                  ; * 32 (entry size)
    lea rdi, [sym_table]
    add rdi, rax
    
    ; Copy name string (up to 24 chars)
    push rdi
    mov rcx, 24
.copy_param_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_param_done
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_param_name
.copy_param_done:
    mov byte [rdi], 0
    pop rdi
    
    ; Get current param offset (+16, +24, etc.)
    mov eax, [param_offset]
    mov [rdi + 24], eax         ; Store POSITIVE offset
    
    ; Update for next param
    add dword [param_offset], 8
    inc dword [sym_count]
    
    pop rdi
    pop rsi
    pop rbx
    ret

sym_find:
    ; RCX = name to find
    ; Returns: EAX = offset or 0
    push rbx
    push rsi
    push rdi
    push r12
    
    mov r12, rcx                ; Save name
    
    xor ebx, ebx
    mov ecx, [sym_count]
    test ecx, ecx
    jz .not_found
    
.find_loop:
    mov eax, ebx
    shl eax, 5                  ; * 32 (new entry size)
    lea rdi, [sym_table]
    add rdi, rax
    
    mov rsi, r12
    push rdi
    ; rdi already points to name string (not a pointer now)
    call str_eq
    pop rdi
    
    test eax, eax
    jnz .found
    
    inc ebx
    cmp ebx, [sym_count]
    jl .find_loop
    
.not_found:
    xor eax, eax
    jmp .sf_done

.found:
    mov eax, [rdi + 24]         ; Read offset from offset 24

.sf_done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; AST (minimal for now)
; =============================================================================
ast_init:
    lea rax, [ast_buffer]
    mov [ast_ptr], rax
    ret

; =============================================================================
; MEMORY
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 1024*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call [VirtualAlloc]
    mov [heap_base], rax
    mov [heap_ptr], rax
    add rsp, 40
    ret

jit_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 64*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_RW
    call [VirtualAlloc]
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    add rsp, 40
    ret

; =============================================================================
; FILE I/O
; =============================================================================
load_file:
    ; RCX = filename
    push rbx
    push r12
    sub rsp, 56
    
    mov r12, rcx
    
    ; Open file
    mov rcx, r12
    mov edx, GENERIC_READ
    xor r8d, r8d
    xor r9d, r9d
    mov dword [rsp+32], OPEN_EXISTING
    mov dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+48], 0
    call [CreateFileA]
    
    cmp rax, INVALID_HANDLE_VALUE
    je .fail
    
    mov [file_handle], rax
    
    ; Get size
    mov rcx, rax
    xor edx, edx
    call [GetFileSize]
    mov [file_size], rax
    mov rbx, rax
    
    ; Allocate buffer
    add rbx, 16
    xor ecx, ecx
    mov edx, ebx
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call [VirtualAlloc]
    mov r12, rax
    
    ; Read file
    mov rcx, [file_handle]
    mov rdx, r12
    mov r8, [file_size]
    lea r9, [bytes_read]
    mov qword [rsp+32], 0
    call [ReadFile]
    
    ; Close
    mov rcx, [file_handle]
    call [CloseHandle]
    
    ; Null terminate
    mov rax, r12
    add rax, [file_size]
    mov byte [rax], 0
    
    mov rax, r12
    jmp .lf_done

.fail:
    xor eax, eax

.lf_done:
    add rsp, 56
    pop r12
    pop rbx
    ret

; =============================================================================
; OUTPUT
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

; =============================================================================
; dump_hex - Dump RCX bytes from RSI as hex
; =============================================================================
dump_hex:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    
    mov r12, rsi            ; Source pointer
    mov r13, rcx            ; Count
    
.dump_loop:
    test r13, r13
    jz .dump_done
    
    ; Get byte and save it
    movzx r14d, byte [r12]
    
    ; High nibble
    mov rax, r14
    shr rax, 4
    lea rbx, [hex_chars]
    movzx eax, byte [rbx + rax]
    lea rdi, [num_buffer]
    mov [rdi], al
    mov byte [rdi+1], 0
    mov rcx, rdi
    call print_string
    
    ; Low nibble
    mov rax, r14
    and rax, 0x0F
    lea rbx, [hex_chars]
    movzx eax, byte [rbx + rax]
    lea rdi, [num_buffer]
    mov [rdi], al
    mov byte [rdi+1], ' '
    mov byte [rdi+2], 0
    mov rcx, rdi
    call print_string
    
    inc r12
    dec r13
    jmp .dump_loop
    
.dump_done:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

print_number:
    push rbx
    push rdi
    
    lea rdi, [num_buffer + 30]
    mov byte [rdi], 0
    dec rdi
    
    mov rbx, 10
    test rax, rax
    jnz .pn_conv
    mov byte [rdi], '0'
    dec rdi
    jmp .pn_print
    
.pn_conv:
    test rax, rax
    jz .pn_print
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    jmp .pn_conv
    
.pn_print:
    inc rdi
    mov rcx, rdi
    call print_string
    
    pop rdi
    pop rbx
    ret
