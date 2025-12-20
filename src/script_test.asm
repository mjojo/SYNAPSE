; =============================================================================
; SYNAPSE Script Test (Phase 5.3) - The Final Pipeline
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; TEXT -> LEXER -> PARSER -> AST -> JIT -> MOVA -> BLOCKCHAIN
;
; This is the culmination of SYNAPSE:
; - Source code is tokenized by Lexer
; - Parser builds AST from tokens
; - JIT compiles AST to machine code
; - MOVA kernel executes with blockchain protection
; =============================================================================

format PE64 console
entry start

; Include version info
include '..\include\version.inc'

; Windows constants
MEM_COMMIT      = 0x1000
MEM_RESERVE     = 0x2000
PAGE_READWRITE  = 0x04
PAGE_EXECUTE_RW = 0x40

; Block Header (64 bytes - AVX2 Aligned)
BLOCK_HEADER_SIZE = 64
MAGIC_BLOK = 0x4B4F4C42

; AST Node Types
NODE_PROGRAM    = 0
NODE_FUNCTION   = 1
NODE_LET        = 2
NODE_RETURN     = 3
NODE_IF         = 4
NODE_BLOCK      = 5
NODE_CALL       = 6
NODE_NUMBER     = 7

; Token Types (from synapse_tokens.inc)
STOK_EOF        = 0
STOK_IDENT      = 1
STOK_NUMBER     = 2
STOK_FLOAT      = 3
STOK_STRING     = 4
STOK_KEYWORD    = 5
STOK_OPERATOR   = 6
STOK_NEWLINE    = 7
STOK_INDENT     = 8
STOK_DEDENT     = 9
STOK_COMMENT    = 10

; Operator subtypes
SOP_LPAREN      = 40
SOP_RPAREN      = 41

; Intrinsic IDs
ID_MERKLE_ALLOC  = 0
ID_MERKLE_COMMIT = 1
ID_SHA256        = 2

; Token structure offsets (24 bytes)
STOKEN_TYPE     = 0
STOKEN_SUBTYPE  = 1
STOKEN_LENGTH   = 2
STOKEN_LINE     = 4
STOKEN_COLUMN   = 6
STOKEN_VALUE    = 8
STOKEN_EXTRA    = 16
STOKEN_SIZE     = 24

; AST Node Layout (32 bytes per node)
; +0:  type (8 bytes)
; +8:  next (8 bytes - pointer to sibling)
; +16: child (8 bytes - pointer to first child)
; +24: value (8 bytes - number or string ptr)

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
        VirtualAlloc    dq RVA _VirtualAlloc
                        dq 0

    kernel32_name   db 'kernel32.dll',0
    _GetStdHandle   db 0,0,'GetStdHandle',0
    _WriteConsoleA  db 0,0,'WriteConsoleA',0
    _ExitProcess    db 0,0,'ExitProcess',0
    _VirtualAlloc   db 0,0,'VirtualAlloc',0

; =============================================================================
; Data
; =============================================================================
section '.data' data readable writeable

    ; =========================================================================
    ; THE SCRIPT - This is what we're compiling!
    ; =========================================================================
    source_code db 'alloc(64)', 10
                db 'alloc(128)', 10
                db 'commit()', 0

    banner      db '==================================================',13,10
                db '  SYNAPSE ',SYNAPSE_VERSION_STR,' - The Script Engine',13,10
                db '  Phase 5.3: From Text to Blockchain',13,10
                db '==================================================',13,10,13,10,0
    
    msg_src     db '[SRC] Source Code:',13,10,0
    msg_sep     db '--------------------------------------------------',13,10,0
    msg_lex     db '[LEX] Tokenizing...',13,10,0
    msg_token   db '  Token: ',0
    msg_prs     db '[PRS] Parsing to AST...',13,10,0
    msg_node    db '  Node: ',0
    msg_jit     db '[JIT] Compiling to x64...',13,10,0
    msg_run     db '[RUN] Executing...',13,10,0
    msg_done    db '[DONE] Execution complete!',13,10,0
    msg_hash    db '  Root Hash: ',0
    msg_success db 13,10,'*** SUCCESS! From Text to Blockchain! ***',13,10
                db '    Source -> Tokens -> AST -> Machine Code -> Hash',13,10,0
    msg_call    db 'CALL ',0
    msg_num     db 'NUMBER ',0
    msg_ident   db 'IDENT ',0
    msg_op      db 'OP ',0
    msg_lparen  db '(',0
    msg_rparen  db ')',0
    msg_newline_str db 'NEWLINE',13,10,0
    msg_eof     db 'EOF',13,10,0
    newline     db 13,10,0
    
    ; Function names for AST
    str_alloc   db 'alloc',0
    str_commit  db 'commit',0
    
    hex_chars   db '0123456789abcdef'

    ; SHA-256 K constants
    k_table dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
            dd 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
            dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
            dd 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
            dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
            dd 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
            dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
            dd 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
            dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
            dd 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
            dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
            dd 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
            dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
            dd 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
            dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
            dd 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

    h_init  dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
            dd 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

; =============================================================================
; BSS
; =============================================================================
section '.bss' data readable writeable

    stdout          dq ?
    bytes_written   dd ?
    
    ; Heap
    heap_base       dq ?
    heap_ptr        dq ?
    
    ; JIT
    jit_buffer      dq ?
    jit_cursor      dq ?
    
    ; Ledger
    last_block_ptr  dq ?
    root_hash       rb 32
    
    ; Intrinsics Table
    intrinsics_table rq 16
    
    ; Token Buffer (simplified - max 256 tokens)
    token_buffer    rb STOKEN_SIZE * 256
    token_count     dd ?
    token_read_idx  dd ?
    
    ; AST Buffer (max 64 nodes, 32 bytes each)
    ast_buffer      rb 32 * 64
    ast_ptr         dq ?
    ast_first_node  dq ?
    ast_last_node   dq ?
    
    ; Lexer state
    lex_source      dq ?
    lex_pos         dq ?
    lex_line        dd ?
    
    ; String table for identifiers (copy names here)
    string_table    rb 1024
    string_ptr      dq ?
    
    ; SHA-256 working area
    sha_state       rd 8
    sha_w           rd 64
    sha_block       rb 64
    
    ; Temp
    hex_buffer      rb 4
    num_buffer      rb 16

; =============================================================================
; Code
; =============================================================================
section '.text' code readable executable

start:
    sub rsp, 40
    
    mov ecx, -11
    call [GetStdHandle]
    mov [stdout], rax
    
    lea rcx, [banner]
    call print_string
    
    ; ===========================================
    ; 1. INITIALIZE ALL SYSTEMS
    ; ===========================================
    call mem_init
    call merkle_init
    call jit_init
    call init_intrinsics
    call lexer_init
    call parser_init
    
    ; ===========================================
    ; 2. SHOW SOURCE CODE
    ; ===========================================
    lea rcx, [msg_src]
    call print_string
    
    lea rcx, [msg_sep]
    call print_string
    
    lea rcx, [source_code]
    call print_string
    
    lea rcx, [newline]
    call print_string
    
    lea rcx, [msg_sep]
    call print_string
    
    ; ===========================================
    ; 3. LEXER: Text -> Tokens
    ; ===========================================
    lea rcx, [msg_lex]
    call print_string
    
    lea rcx, [source_code]
    call lexer_scan
    
    ; Show tokens
    call print_tokens
    
    ; ===========================================
    ; 4. PARSER: Tokens -> AST
    ; ===========================================
    lea rcx, [msg_prs]
    call print_string
    
    call parser_run
    
    ; Show AST
    call print_ast
    
    ; ===========================================
    ; 5. JIT: AST -> Machine Code
    ; ===========================================
    lea rcx, [msg_jit]
    call print_string
    
    ; Reset JIT cursor
    mov rax, [jit_buffer]
    mov [jit_cursor], rax
    
    ; Compile AST
    mov rsi, [ast_first_node]
    call codegen_run
    
    ; Add RET at end
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xC3        ; RET
    
    ; ===========================================
    ; 6. EXECUTE!
    ; ===========================================
    lea rcx, [msg_run]
    call print_string
    
    lea rcx, [msg_sep]
    call print_string
    
    ; THE MAGIC MOMENT!
    call [jit_buffer]
    
    lea rcx, [msg_sep]
    call print_string
    
    ; ===========================================
    ; 7. SHOW RESULTS
    ; ===========================================
    lea rcx, [msg_done]
    call print_string
    
    lea rcx, [msg_hash]
    call print_string
    
    lea rsi, [root_hash]
    call print_hash
    
    lea rcx, [newline]
    call print_string
    
    lea rcx, [msg_success]
    call print_string

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
; LEXER: Tokenize source code
; =============================================================================
lexer_init:
    mov dword [token_count], 0
    mov dword [token_read_idx], 0
    mov dword [lex_line], 1
    lea rax, [string_table]
    mov [string_ptr], rax
    ret

lexer_scan:
    ; RCX = source code pointer
    mov [lex_source], rcx
    mov [lex_pos], rcx
    
    lea rdi, [token_buffer]     ; Token write pointer
    
.scan_loop:
    mov rsi, [lex_pos]
    
    ; Skip whitespace (but not newlines)
.skip_ws:
    mov al, [rsi]
    cmp al, ' '
    je .skip_one
    cmp al, 9                   ; Tab
    je .skip_one
    jmp .check_char
.skip_one:
    inc rsi
    jmp .skip_ws
    
.check_char:
    mov [lex_pos], rsi
    mov al, [rsi]
    
    ; EOF
    test al, al
    jz .emit_eof
    
    ; Newline
    cmp al, 10
    je .emit_newline
    cmp al, 13
    je .emit_newline
    
    ; Number
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .scan_number
    
.check_alpha:
    ; Letter or underscore -> identifier
    cmp al, 'a'
    jl .check_upper
    cmp al, 'z'
    jle .scan_ident
    
.check_upper:
    cmp al, 'A'
    jl .check_underscore
    cmp al, 'Z'
    jle .scan_ident
    
.check_underscore:
    cmp al, '_'
    je .scan_ident
    
    ; Operators
    cmp al, '('
    je .emit_lparen
    cmp al, ')'
    je .emit_rparen
    
    ; Unknown - skip
    inc qword [lex_pos]
    jmp .scan_loop

.scan_number:
    ; Parse decimal number
    mov byte [rdi + STOKEN_TYPE], STOK_NUMBER
    xor ecx, ecx                ; Value
    
.num_loop:
    mov al, [rsi]
    cmp al, '0'
    jl .num_done
    cmp al, '9'
    jg .num_done
    
    ; value = value * 10 + digit
    imul ecx, 10
    sub al, '0'
    movzx eax, al
    add ecx, eax
    inc rsi
    jmp .num_loop
    
.num_done:
    mov [rdi + STOKEN_VALUE], rcx
    mov [lex_pos], rsi
    add rdi, STOKEN_SIZE
    inc dword [token_count]
    jmp .scan_loop

.scan_ident:
    ; Parse identifier
    mov byte [rdi + STOKEN_TYPE], STOK_IDENT
    
    ; Copy identifier to string table
    mov r8, [string_ptr]
    mov [rdi + STOKEN_VALUE], r8
    xor ecx, ecx                ; Length
    
.ident_loop:
    mov al, [rsi]
    
    ; a-z
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
    je .ident_copy
    jmp .ident_done
    
.ident_copy:
    mov [r8], al
    inc r8
    inc rsi
    inc ecx
    jmp .ident_loop
    
.ident_done:
    mov byte [r8], 0            ; Null terminate
    inc r8
    mov [string_ptr], r8
    mov word [rdi + STOKEN_LENGTH], cx
    mov [lex_pos], rsi
    add rdi, STOKEN_SIZE
    inc dword [token_count]
    jmp .scan_loop

.emit_newline:
    mov byte [rdi + STOKEN_TYPE], STOK_NEWLINE
    inc qword [lex_pos]
    ; Skip CR+LF
    mov rsi, [lex_pos]
    cmp byte [rsi], 10
    jne .nl_done
    inc qword [lex_pos]
.nl_done:
    add rdi, STOKEN_SIZE
    inc dword [token_count]
    jmp .scan_loop

.emit_lparen:
    mov byte [rdi + STOKEN_TYPE], STOK_OPERATOR
    mov byte [rdi + STOKEN_SUBTYPE], SOP_LPAREN
    inc qword [lex_pos]
    add rdi, STOKEN_SIZE
    inc dword [token_count]
    jmp .scan_loop

.emit_rparen:
    mov byte [rdi + STOKEN_TYPE], STOK_OPERATOR
    mov byte [rdi + STOKEN_SUBTYPE], SOP_RPAREN
    inc qword [lex_pos]
    add rdi, STOKEN_SIZE
    inc dword [token_count]
    jmp .scan_loop

.emit_eof:
    mov byte [rdi + STOKEN_TYPE], STOK_EOF
    inc dword [token_count]
    ret

; =============================================================================
; PARSER: Build AST from tokens
; =============================================================================
parser_init:
    lea rax, [ast_buffer]
    mov [ast_ptr], rax
    mov qword [ast_first_node], 0
    mov qword [ast_last_node], 0
    mov dword [token_read_idx], 0
    ret

parser_run:
    ; Process all tokens and build AST
    
.parse_loop:
    call get_token
    
    ; Check token type
    movzx eax, byte [rdi + STOKEN_TYPE]
    
    cmp al, STOK_EOF
    je .parse_done
    
    cmp al, STOK_NEWLINE
    je .parse_loop              ; Skip newlines
    
    cmp al, STOK_IDENT
    je .parse_call              ; Identifier = start of call
    
    ; Skip unknown
    jmp .parse_loop

.parse_call:
    ; We found an identifier - expect function call
    ; Save function name pointer
    mov r12, [rdi + STOKEN_VALUE]
    
    ; Expect '('
    call get_token
    movzx eax, byte [rdi + STOKEN_TYPE]
    cmp al, STOK_OPERATOR
    jne .parse_loop
    movzx eax, byte [rdi + STOKEN_SUBTYPE]
    cmp al, SOP_LPAREN
    jne .parse_loop
    
    ; Create NODE_CALL
    call alloc_ast_node
    mov r13, rax                ; R13 = call node
    mov qword [rax], NODE_CALL
    mov [rax + 24], r12         ; value = function name
    
    ; Check for argument (number)
    call get_token
    movzx eax, byte [rdi + STOKEN_TYPE]
    
    cmp al, STOK_NUMBER
    jne .check_rparen
    
    ; Create NODE_NUMBER as child
    mov r14, [rdi + STOKEN_VALUE]  ; Number value
    push r13
    call alloc_ast_node
    mov qword [rax], NODE_NUMBER
    mov [rax + 24], r14         ; value = number
    pop r13
    mov [r13 + 16], rax         ; call.child = number node
    
    ; Expect ')'
    call get_token
    
.check_rparen:
    ; Should be ')' now
    movzx eax, byte [rdi + STOKEN_TYPE]
    cmp al, STOK_OPERATOR
    jne .link_node
    movzx eax, byte [rdi + STOKEN_SUBTYPE]
    cmp al, SOP_RPAREN
    jne .link_node
    
.link_node:
    ; Link node to list
    mov rax, [ast_last_node]
    test rax, rax
    jz .first_node
    
    mov [rax + 8], r13          ; prev.next = current
    jmp .update_last
    
.first_node:
    mov [ast_first_node], r13
    
.update_last:
    mov [ast_last_node], r13
    jmp .parse_loop

.parse_done:
    ret

get_token:
    ; Returns token in RDI
    mov eax, [token_read_idx]
    mov ecx, STOKEN_SIZE
    imul eax, ecx
    lea rdi, [token_buffer]
    add rdi, rax
    inc dword [token_read_idx]
    ret

alloc_ast_node:
    ; Returns node pointer in RAX
    mov rax, [ast_ptr]
    add qword [ast_ptr], 32
    ; Clear node
    mov qword [rax], 0
    mov qword [rax + 8], 0
    mov qword [rax + 16], 0
    mov qword [rax + 24], 0
    ret

; =============================================================================
; CODEGEN: AST -> Machine Code
; =============================================================================
codegen_run:
    ; RSI = pointer to current AST node
    push rbx
    push r12
    push r13
    
.process_node:
    test rsi, rsi
    jz .codegen_done
    
    ; Get node type
    mov eax, [rsi]
    
    cmp eax, NODE_CALL
    je .gen_call
    
    ; Unknown node - skip
    jmp .next_node

.gen_call:
    ; RSI = NODE_CALL
    ; [RSI+24] = function name ptr
    ; [RSI+16] = argument node ptr (or NULL)
    
    mov rbx, [rsi+24]               ; Get function name
    
    ; Check first character
    cmp byte [rbx], 'a'             ; "alloc"?
    je .do_alloc
    
    cmp byte [rbx], 'c'             ; "commit"?
    je .do_commit
    
    jmp .next_node

.do_alloc:
    ; === GENERATE: ptr = merkle_alloc(SIZE) ===
    
    ; Get argument value
    mov r12, [rsi+16]               ; Child node (arg)
    test r12, r12
    jz .next_node                   ; No arg = error
    
    mov r13, [r12+24]               ; Get number value
    
    ; Save RSI (codegen uses it)
    push rsi
    
    ; Generate: MOV ECX, size (argument for alloc)
    mov rdi, [jit_cursor]
    mov byte [rdi], 0xB9            ; MOV ECX, imm32
    mov [rdi+1], r13d
    add rdi, 5
    mov [jit_cursor], rdi
    
    ; Generate: MOV RAX, [intrinsics_table+0]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [intrinsics_table]
    mov [rdi+2], rax
    add rdi, 10
    
    ; Generate: MOV RAX, [RAX]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x00
    add rdi, 3
    
    ; Generate: CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    mov [jit_cursor], rdi
    
    pop rsi
    jmp .next_node

.do_commit:
    ; === GENERATE: merkle_commit() ===
    
    push rsi
    
    mov rdi, [jit_cursor]
    
    ; Generate: MOV RAX, [intrinsics_table+8]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    lea rax, [intrinsics_table + 8]
    mov [rdi+2], rax
    add rdi, 10
    
    ; Generate: MOV RAX, [RAX]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x00
    add rdi, 3
    
    ; Generate: CALL RAX
    mov word [rdi], 0xD0FF
    add rdi, 2
    
    mov [jit_cursor], rdi
    
    pop rsi
    jmp .next_node

.next_node:
    mov rsi, [rsi+8]                ; Move to next sibling
    jmp .process_node

.codegen_done:
    pop r13
    pop r12
    pop rbx
    ret

; =============================================================================
; INTRINSICS TABLE
; =============================================================================
init_intrinsics:
    lea rdi, [intrinsics_table]
    lea rax, [merkle_alloc]
    mov [rdi + ID_MERKLE_ALLOC*8], rax
    lea rax, [merkle_commit]
    mov [rdi + ID_MERKLE_COMMIT*8], rax
    lea rax, [sha256_compute]
    mov [rdi + ID_SHA256*8], rax
    ret

; =============================================================================
; MEMORY MANAGER
; =============================================================================
mem_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 1024*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call [VirtualAlloc]
    add rsp, 40
    mov [heap_base], rax
    mov [heap_ptr], rax
    ret

mem_alloc_aligned:
    mov rax, [heap_ptr]
    dec rdx
    add rax, rdx
    not rdx
    and rax, rdx
    mov r8, rax
    add r8, rcx
    mov [heap_ptr], r8
    ret

; =============================================================================
; JIT INIT
; =============================================================================
jit_init:
    sub rsp, 40
    xor ecx, ecx
    mov edx, 64*1024
    mov r8d, MEM_COMMIT or MEM_RESERVE
    mov r9d, PAGE_EXECUTE_RW
    call [VirtualAlloc]
    add rsp, 40
    mov [jit_buffer], rax
    mov [jit_cursor], rax
    ret

; =============================================================================
; MERKLE LEDGER
; =============================================================================
merkle_init:
    mov qword [last_block_ptr], 0
    ret

merkle_alloc:
    push rbx
    mov rbx, rcx
    
    add rcx, BLOCK_HEADER_SIZE
    mov rdx, 32
    call mem_alloc_aligned
    
    mov dword [rax], MAGIC_BLOK
    mov dword [rax+4], ebx
    
    mov rdx, [last_block_ptr]
    mov [rax+8], rdx
    
    xor rcx, rcx
    mov [rax+16], rcx
    mov [rax+24], rcx
    mov [rax+32], rcx
    mov [rax+40], rcx
    mov [rax+48], rcx
    mov [rax+56], rcx
    
    mov [last_block_ptr], rax
    add rax, BLOCK_HEADER_SIZE
    
    pop rbx
    ret

merkle_commit:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    mov r12, [last_block_ptr]
    
.pass1:
    test r12, r12
    jz .pass1_done
    
    mov rax, [r12+8]
    mov [rsp+32], rax
    
    mov r14d, [r12+4]
    lea rcx, [r12+64]
    mov rdx, r14
    lea r8, [r12+16]
    
    mov [rsp+24], r12
    call sha256_compute
    
    mov r12, [rsp+32]
    jmp .pass1

.pass1_done:
    lea rdi, [root_hash]
    xor rax, rax
    mov [rdi], rax
    mov [rdi+8], rax
    mov [rdi+16], rax
    mov [rdi+24], rax
    
    mov r12, [last_block_ptr]

.xor_loop:
    test r12, r12
    jz .commit_done
    
    mov rax, [rdi]
    xor rax, [r12+16]
    mov [rdi], rax
    
    mov rax, [rdi+8]
    xor rax, [r12+24]
    mov [rdi+8], rax
    
    mov rax, [rdi+16]
    xor rax, [r12+32]
    mov [rdi+16], rax
    
    mov rax, [rdi+24]
    xor rax, [r12+40]
    mov [rdi+24], rax
    
    mov r12, [r12+8]
    jmp .xor_loop

.commit_done:
    lea rax, [root_hash]
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; SHA-256
; =============================================================================
sha256_compute:
    push rbx
    push rsi
    push rdi
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
    
    mov [rsp+40], rcx
    mov [rsp+48], rdx
    mov r14, r8
    
    lea rsi, [h_init]
    lea rdi, [sha_state]
    mov ecx, 8
.sha_init:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .sha_init
    
    lea rdi, [sha_block]
    mov r15, rdi
    xor eax, eax
    mov ecx, 16
    rep stosd
    
    mov rsi, [rsp+40]
    mov rdi, r15
    mov rcx, [rsp+48]
    cmp rcx, 55
    jg .sha_toolong
    rep movsb
    
    mov rax, [rsp+48]
    mov byte [r15 + rax], 0x80
    
    mov rax, [rsp+48]
    shl rax, 3
    bswap rax
    mov qword [r15 + 56], rax
    
    call sha256_transform
    
    lea rsi, [sha_state]
    mov rdi, r14
    mov ecx, 8
.sha_out:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .sha_out
    
.sha_toolong:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rdi
    pop rsi
    pop rbx
    ret

sha256_transform:
    push rbx
    push rsi
    push rdi
    push rbp
    push r12
    push r13
    push r14
    push r15
    
    lea rsi, [sha_block]
    lea rdi, [sha_w]
    mov ecx, 16
.tf_loadw:
    mov eax, [rsi]
    bswap eax
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .tf_loadw
    
    lea rdi, [sha_w]
    mov ebx, 16
.tf_expand:
    mov eax, [rdi + rbx*4 - 60]
    mov edx, eax
    ror edx, 7
    mov r8d, eax
    ror r8d, 18
    xor edx, r8d
    mov r8d, eax
    shr r8d, 3
    xor edx, r8d
    
    mov eax, [rdi + rbx*4 - 8]
    mov r9d, eax
    ror r9d, 17
    mov r8d, eax
    ror r8d, 19
    xor r9d, r8d
    mov r8d, eax
    shr r8d, 10
    xor r9d, r8d
    
    mov eax, [rdi + rbx*4 - 64]
    add eax, edx
    add eax, [rdi + rbx*4 - 28]
    add eax, r9d
    mov [rdi + rbx*4], eax
    
    inc ebx
    cmp ebx, 64
    jl .tf_expand
    
    lea rsi, [sha_state]
    mov eax, [rsi]
    mov ebx, [rsi+4]
    mov ecx, [rsi+8]
    mov edx, [rsi+12]
    mov r8d, [rsi+16]
    mov r9d, [rsi+20]
    mov r10d, [rsi+24]
    mov r11d, [rsi+28]
    
    lea rbp, [k_table]
    lea rdi, [sha_w]
    xor rsi, rsi
    
.tf_round:
    mov r12d, r8d
    ror r12d, 6
    mov r13d, r8d
    ror r13d, 11
    xor r12d, r13d
    mov r13d, r8d
    ror r13d, 25
    xor r12d, r13d
    
    mov r13d, r8d
    and r13d, r9d
    mov r14d, r8d
    not r14d
    and r14d, r10d
    xor r13d, r14d
    
    add r12d, r13d
    add r12d, r11d
    add r12d, [rbp + rsi*4]
    add r12d, [rdi + rsi*4]
    
    mov r13d, eax
    ror r13d, 2
    mov r14d, eax
    ror r14d, 13
    xor r13d, r14d
    mov r14d, eax
    ror r14d, 22
    xor r13d, r14d
    
    mov r14d, eax
    and r14d, ebx
    mov r15d, eax
    and r15d, ecx
    xor r14d, r15d
    mov r15d, ebx
    and r15d, ecx
    xor r14d, r15d
    
    add r13d, r14d
    
    mov r11d, r10d
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, edx
    add r8d, r12d
    mov edx, ecx
    mov ecx, ebx
    mov ebx, eax
    mov eax, r12d
    add eax, r13d
    
    inc rsi
    cmp rsi, 64
    jl .tf_round
    
    lea rsi, [sha_state]
    add [rsi], eax
    add [rsi+4], ebx
    add [rsi+8], ecx
    add [rsi+12], edx
    add [rsi+16], r8d
    add [rsi+20], r9d
    add [rsi+24], r10d
    add [rsi+28], r11d
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rdi
    pop rsi
    pop rbx
    ret

; =============================================================================
; Print utilities
; =============================================================================
print_string:
    push rsi
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
    mov rdx, rsi
    mov r8d, ecx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call [WriteConsoleA]
    add rsp, 48
.dn:
    pop rsi
    ret

print_hash:
    push rbx
    push rcx
    mov ecx, 32
.lp:
    push rcx
    movzx eax, byte [rsi]
    call print_hex_byte
    inc rsi
    pop rcx
    dec ecx
    jnz .lp
    pop rcx
    pop rbx
    ret

print_hex_byte:
    push rdi
    mov ebx, eax
    shr eax, 4
    and eax, 0xF
    lea rdi, [hex_chars]
    mov al, [rdi + rax]
    mov [hex_buffer], al
    mov eax, ebx
    and eax, 0xF
    mov al, [rdi + rax]
    mov [hex_buffer + 1], al
    mov byte [hex_buffer + 2], 0
    lea rcx, [hex_buffer]
    call print_string
    pop rdi
    ret

print_number:
    ; EAX = number to print
    push rbx
    push rcx
    push rdx
    
    lea rdi, [num_buffer + 15]
    mov byte [rdi], 0
    dec rdi
    
    mov ecx, eax
    test ecx, ecx
    jnz .num_loop
    mov byte [rdi], '0'
    jmp .num_print
    
.num_loop:
    test ecx, ecx
    jz .num_print
    
    xor edx, edx
    mov eax, ecx
    mov ebx, 10
    div ebx
    mov ecx, eax
    add dl, '0'
    mov [rdi], dl
    dec rdi
    jmp .num_loop
    
.num_print:
    inc rdi
    mov rcx, rdi
    call print_string
    
    pop rdx
    pop rcx
    pop rbx
    ret

print_tokens:
    push rbx
    push r12
    
    mov ebx, [token_count]
    lea r12, [token_buffer]
    
.tok_loop:
    test ebx, ebx
    jz .tok_done
    
    lea rcx, [msg_token]
    call print_string
    
    movzx eax, byte [r12 + STOKEN_TYPE]
    
    cmp al, STOK_IDENT
    je .print_ident
    cmp al, STOK_NUMBER
    je .print_num
    cmp al, STOK_OPERATOR
    je .print_op
    cmp al, STOK_NEWLINE
    je .print_nl
    cmp al, STOK_EOF
    je .print_eof
    
    ; Unknown
    lea rcx, [newline]
    call print_string
    jmp .tok_next
    
.print_ident:
    lea rcx, [msg_ident]
    call print_string
    mov rcx, [r12 + STOKEN_VALUE]
    call print_string
    lea rcx, [newline]
    call print_string
    jmp .tok_next
    
.print_num:
    lea rcx, [msg_num]
    call print_string
    mov eax, [r12 + STOKEN_VALUE]
    call print_number
    lea rcx, [newline]
    call print_string
    jmp .tok_next
    
.print_op:
    lea rcx, [msg_op]
    call print_string
    movzx eax, byte [r12 + STOKEN_SUBTYPE]
    cmp al, SOP_LPAREN
    je .print_lp
    cmp al, SOP_RPAREN
    je .print_rp
    jmp .print_op_done
.print_lp:
    lea rcx, [msg_lparen]
    call print_string
    jmp .print_op_done
.print_rp:
    lea rcx, [msg_rparen]
    call print_string
.print_op_done:
    lea rcx, [newline]
    call print_string
    jmp .tok_next
    
.print_nl:
    lea rcx, [msg_newline_str]
    call print_string
    jmp .tok_next
    
.print_eof:
    lea rcx, [msg_eof]
    call print_string
    jmp .tok_next

.tok_next:
    add r12, STOKEN_SIZE
    dec ebx
    jmp .tok_loop
    
.tok_done:
    pop r12
    pop rbx
    ret

print_ast:
    push rbx
    push r12
    
    mov r12, [ast_first_node]
    
.ast_loop:
    test r12, r12
    jz .ast_done
    
    lea rcx, [msg_node]
    call print_string
    
    mov eax, [r12]
    cmp eax, NODE_CALL
    jne .ast_next
    
    lea rcx, [msg_call]
    call print_string
    
    mov rcx, [r12 + 24]
    call print_string
    
    ; Check for argument
    mov rax, [r12 + 16]
    test rax, rax
    jz .ast_no_arg
    
    lea rcx, [msg_lparen]
    call print_string
    
    mov rax, [r12 + 16]
    mov eax, [rax + 24]
    call print_number
    
    lea rcx, [msg_rparen]
    call print_string
    jmp .ast_newline
    
.ast_no_arg:
    lea rcx, [msg_lparen]
    call print_string
    lea rcx, [msg_rparen]
    call print_string
    
.ast_newline:
    lea rcx, [newline]
    call print_string
    
.ast_next:
    mov r12, [r12 + 8]
    jmp .ast_loop
    
.ast_done:
    pop r12
    pop rbx
    ret
