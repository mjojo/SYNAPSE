; =============================================================================
; SYNAPSE PARSER v0.1 (Recursive Descent)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Парсит объявления переменных и сложные типы:
;   let x: int = 10
;   let w: tensor<f32, [784, 128]> = 0
;   fn name(args) -> type:
; =============================================================================

; Token structure (from lexer):
; [0]  type     (byte)
; [1]  subtype  (byte)
; [2]  length   (word)
; [4]  line     (word)
; [6]  column   (word)
; [8]  value    (qword)
; [16] extra    (qword)
; Total: 24 bytes

PARSER_TOKEN_SIZE = 24

; =============================================================================
; Data Section
; =============================================================================
section '.data' data readable writeable

    ; Parser state
    parse_token_ptr     dq 0        ; Pointer to current token
    parse_token_end     dq 0        ; End of token list
    parse_error         db 0        ; Error flag
    parse_depth         dd 0        ; Nesting depth (for debug)
    
    ; Parse results
    parsed_var_name     dq 0        ; Pointer to variable name
    parsed_var_len      dd 0        ; Variable name length
    parsed_var_type     dd 0        ; Type code
    parsed_type_shape   dd 0, 0, 0, 0  ; Tensor shape [dim1, dim2, dim3, dim4]
    
    ; Messages
    parse_ok_msg        db '[PARSE] OK: ',0
    parse_err_msg       db '[PARSE] ERROR: ',0
    parse_let_msg       db 'let declaration',13,10,0
    parse_fn_msg        db 'fn declaration',13,10,0
    parse_type_msg      db 'type=',0
    parse_int_msg       db 'int',0
    parse_f32_msg       db 'f32',0
    parse_f64_msg       db 'f64',0
    parse_tensor_msg    db 'tensor<>',0
    parse_unknown_msg   db '?',0
    
    ; Error messages
    err_expect_ident    db 'Expected identifier',13,10,0
    err_expect_colon    db 'Expected ":"',13,10,0
    err_expect_type     db 'Expected type',13,10,0
    err_expect_eq       db 'Expected "="',13,10,0
    err_expect_lt       db 'Expected "<"',13,10,0
    err_expect_gt       db 'Expected ">"',13,10,0
    err_expect_comma    db 'Expected ","',13,10,0
    err_expect_lbracket db 'Expected "["',13,10,0
    err_expect_rbracket db 'Expected "]"',13,10,0
    err_expect_lparen   db 'Expected "("',13,10,0
    err_expect_rparen   db 'Expected ")"',13,10,0
    err_expect_arrow    db 'Expected "->"',13,10,0
    err_unexpected      db 'Unexpected token',13,10,0

; =============================================================================
; Code Section  
; =============================================================================
section '.text' code readable executable

; -----------------------------------------------------------------------------
; parser_init: Initialize parser
; Input: RCX = pointer to first token
;        RDX = pointer past last token
; -----------------------------------------------------------------------------
parser_init:
    mov [parse_token_ptr], rcx
    mov [parse_token_end], rdx
    mov byte [parse_error], 0
    mov dword [parse_depth], 0
    ret

; -----------------------------------------------------------------------------
; current_token: Get current token pointer
; Output: RAX = pointer to current token (or 0 if EOF)
; -----------------------------------------------------------------------------
current_token:
    mov rax, [parse_token_ptr]
    cmp rax, [parse_token_end]
    jae .eof
    ret
.eof:
    xor rax, rax
    ret

; -----------------------------------------------------------------------------
; token_type: Get type of current token
; Output: EAX = token type
; -----------------------------------------------------------------------------
token_type:
    call current_token
    test rax, rax
    jz .eof
    movzx eax, byte [rax]       ; type is at offset 0
    ret
.eof:
    mov eax, STOK_EOF
    ret

; -----------------------------------------------------------------------------
; token_subtype: Get subtype of current token
; Output: EAX = token subtype
; -----------------------------------------------------------------------------
token_subtype:
    call current_token
    test rax, rax
    jz .none
    movzx eax, byte [rax + 1]   ; subtype is at offset 1
    ret
.none:
    xor eax, eax
    ret

; -----------------------------------------------------------------------------
; token_value: Get value/pointer of current token
; Output: RAX = value
; -----------------------------------------------------------------------------
token_value:
    call current_token
    test rax, rax
    jz .none
    mov rax, qword [rax + 8]    ; value is at offset 8
    ret
.none:
    xor rax, rax
    ret

; -----------------------------------------------------------------------------
; advance: Move to next token
; -----------------------------------------------------------------------------
advance:
    mov rax, [parse_token_ptr]
    add rax, PARSER_TOKEN_SIZE
    mov [parse_token_ptr], rax
    ret

; -----------------------------------------------------------------------------
; expect_keyword: Check if current token is a specific keyword
; Input: ECX = expected keyword code (SKW_*)
; Output: EAX = 1 if match, 0 if not
; -----------------------------------------------------------------------------
expect_keyword:
    push rcx
    call token_type
    cmp eax, STOK_KEYWORD
    pop rcx
    jne .no
    push rcx
    call token_subtype
    pop rcx
    cmp eax, ecx
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; -----------------------------------------------------------------------------
; expect_operator: Check if current token is a specific operator
; Input: ECX = expected operator code (SOP_*)
; Output: EAX = 1 if match, 0 if not
; -----------------------------------------------------------------------------
expect_operator:
    push rcx
    call token_type
    cmp eax, STOK_OPERATOR
    pop rcx
    jne .no
    push rcx
    call token_subtype
    pop rcx
    cmp eax, ecx
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; -----------------------------------------------------------------------------
; parse_program: Main entry point - parse entire program
; Output: EAX = 1 if success, 0 if error
; -----------------------------------------------------------------------------
parse_program:
    push rbx
    push r12
    
.loop:
    ; Check EOF
    call token_type
    cmp eax, STOK_EOF
    je .success
    
    ; Skip newlines and comments
    cmp eax, STOK_NEWLINE
    je .skip
    cmp eax, STOK_COMMENT
    je .skip
    cmp eax, STOK_INDENT
    je .skip
    cmp eax, STOK_DEDENT
    je .skip
    
    ; Check for declarations
    cmp eax, STOK_KEYWORD
    jne .skip
    
    call token_subtype
    
    cmp eax, SKW_LET
    je .parse_let
    
    cmp eax, SKW_FN
    je .parse_fn
    
    cmp eax, SKW_MUT
    je .parse_mut
    
    ; Unknown keyword - skip
    jmp .skip

.skip:
    call advance
    jmp .loop

.parse_let:
    call parse_let_decl
    test eax, eax
    jz .error
    jmp .loop

.parse_fn:
    call parse_fn_decl
    test eax, eax
    jz .error
    jmp .loop

.parse_mut:
    ; mut is like let but mutable
    call advance            ; Skip 'mut'
    call parse_let_body     ; Parse the rest like let
    test eax, eax
    jz .error
    jmp .loop

.success:
    mov eax, 1
    jmp .done

.error:
    xor eax, eax

.done:
    pop r12
    pop rbx
    ret

; -----------------------------------------------------------------------------
; parse_let_decl: Parse 'let' declaration
; Grammar: 'let' IDENT [':' TYPE] ['=' EXPR]
; Output: EAX = 1 if success
; -----------------------------------------------------------------------------
parse_let_decl:
    push rbx
    
    ; Skip 'let'
    call advance
    
    call parse_let_body
    
    pop rbx
    ret

; -----------------------------------------------------------------------------
; parse_let_body: Parse identifier, optional type, optional assignment
; -----------------------------------------------------------------------------
parse_let_body:
    push rbx
    push r12
    
    ; Expect IDENT
    call token_type
    cmp eax, STOK_IDENT
    jne .error_ident
    
    ; Save variable info
    call token_value
    mov [parsed_var_name], rax
    call current_token
    movzx eax, word [rax + 2]   ; length
    mov [parsed_var_len], eax
    
    call advance
    
    ; Check for optional ':' TYPE
    mov ecx, SOP_COLON
    call expect_operator
    test eax, eax
    jz .check_assign
    
    call advance            ; Skip ':'
    
    ; Parse type
    call parse_type
    test eax, eax
    jz .error_type
    mov [parsed_var_type], eax

.check_assign:
    ; Check for optional '=' EXPR
    mov ecx, SOP_ASSIGN
    call expect_operator
    test eax, eax
    jz .success
    
    call advance            ; Skip '='
    
    ; Parse expression (simplified - just accept any value token)
    call parse_expression
    test eax, eax
    jz .error

.success:
    ; Print success message
    lea rcx, [parse_ok_msg]
    call print_string
    lea rcx, [parse_let_msg]
    call print_string
    
    mov eax, 1
    jmp .done

.error_ident:
    lea rcx, [err_expect_ident]
    call print_string
    xor eax, eax
    jmp .done

.error_type:
    lea rcx, [err_expect_type]
    call print_string
    xor eax, eax
    jmp .done

.error:
    xor eax, eax

.done:
    pop r12
    pop rbx
    ret

; -----------------------------------------------------------------------------
; parse_fn_decl: Parse function declaration
; Grammar: 'fn' IDENT '(' [PARAMS] ')' ['->' TYPE] ':'
; -----------------------------------------------------------------------------
parse_fn_decl:
    push rbx
    
    call advance            ; Skip 'fn'
    
    ; Expect IDENT
    call token_type
    cmp eax, STOK_IDENT
    jne .error_ident
    
    ; Save function name
    call token_value
    mov [parsed_var_name], rax
    call current_token
    movzx eax, word [rax + 2]
    mov [parsed_var_len], eax
    
    call advance
    
    ; Expect '('
    mov ecx, SOP_LPAREN
    call expect_operator
    test eax, eax
    jz .error_lparen
    call advance
    
    ; Parse parameters (simplified - skip until ')')
.param_loop:
    mov ecx, SOP_RPAREN
    call expect_operator
    test eax, eax
    jnz .param_done
    call advance
    jmp .param_loop
.param_done:
    call advance            ; Skip ')'
    
    ; Check for optional '->' return type
    mov ecx, SOP_ARROW
    call expect_operator
    test eax, eax
    jz .check_colon
    
    call advance            ; Skip '->'
    call parse_type
    test eax, eax
    jz .error_type

.check_colon:
    ; Expect ':'
    mov ecx, SOP_COLON
    call expect_operator
    test eax, eax
    jz .error_colon
    call advance

.success:
    lea rcx, [parse_ok_msg]
    call print_string
    lea rcx, [parse_fn_msg]
    call print_string
    
    mov eax, 1
    jmp .done

.error_ident:
    lea rcx, [err_expect_ident]
    call print_string
    jmp .error
.error_lparen:
    lea rcx, [err_expect_lparen]
    call print_string
    jmp .error
.error_type:
    lea rcx, [err_expect_type]
    call print_string
    jmp .error
.error_colon:
    lea rcx, [err_expect_colon]
    call print_string
.error:
    xor eax, eax
.done:
    pop rbx
    ret

; -----------------------------------------------------------------------------
; parse_type: Parse type annotation
; Grammar: 'int' | 'f32' | 'f64' | 'tensor' '<' TYPE ',' '[' DIMS ']' '>'
; Output: EAX = type code (non-zero if success)
; -----------------------------------------------------------------------------
parse_type:
    push rbx
    push r12
    
    call token_type
    cmp eax, STOK_KEYWORD
    jne .error
    
    call token_subtype
    mov r12d, eax           ; Save type code
    
    ; Check for basic types
    cmp eax, SKW_INT
    je .type_int
    cmp eax, SKW_INT8
    je .type_int
    cmp eax, SKW_INT16
    je .type_int
    cmp eax, SKW_INT32
    je .type_int
    cmp eax, SKW_INT64
    je .type_int
    cmp eax, SKW_F32
    je .type_f32
    cmp eax, SKW_F64
    je .type_f64
    cmp eax, SKW_BOOL
    je .type_simple
    cmp eax, SKW_STRING
    je .type_simple
    
    ; Check for complex types
    cmp eax, SKW_TENSOR
    je .type_tensor
    cmp eax, SKW_VEC
    je .type_vec
    cmp eax, SKW_HASH256
    je .type_simple
    
    jmp .error

.type_int:
    call advance
    mov eax, 1              ; Type code for int
    jmp .done

.type_f32:
    call advance
    mov eax, 2              ; Type code for f32
    jmp .done

.type_f64:
    call advance
    mov eax, 3              ; Type code for f64
    jmp .done

.type_simple:
    call advance
    mov eax, r12d           ; Return keyword code as type
    jmp .done

.type_tensor:
    ; tensor<T, [shape]>
    call advance            ; Skip 'tensor'
    
    ; Expect '<'
    mov ecx, SOP_LT
    call expect_operator
    test eax, eax
    jz .error_lt
    call advance
    
    ; Parse inner type (recursive)
    call parse_type
    test eax, eax
    jz .error
    mov r12d, eax           ; Save inner type
    
    ; Expect ','
    mov ecx, SOP_COMMA
    call expect_operator
    test eax, eax
    jz .error_comma
    call advance
    
    ; Expect '['
    mov ecx, SOP_LBRACKET
    call expect_operator
    test eax, eax
    jz .error_lbracket
    call advance
    
    ; Parse shape dimensions (numbers separated by commas)
    xor ebx, ebx            ; Dimension counter
.shape_loop:
    ; Check for ']'
    mov ecx, SOP_RBRACKET
    call expect_operator
    test eax, eax
    jnz .shape_done
    
    ; Expect number
    call token_type
    cmp eax, STOK_NUMBER
    jne .skip_shape_token
    
    ; TODO: Save dimension value
    ; call token_value
    ; mov [parsed_type_shape + rbx*4], eax
    ; inc ebx
    
.skip_shape_token:
    call advance
    
    ; Check for comma
    mov ecx, SOP_COMMA
    call expect_operator
    test eax, eax
    jz .shape_loop
    call advance
    jmp .shape_loop

.shape_done:
    call advance            ; Skip ']'
    
    ; Expect '>'
    mov ecx, SOP_GT
    call expect_operator
    test eax, eax
    jz .error_gt
    call advance
    
    mov eax, 100            ; Type code for tensor
    add eax, r12d           ; Encode inner type
    jmp .done

.type_vec:
    ; Vec<T>
    call advance            ; Skip 'Vec'
    
    mov ecx, SOP_LT
    call expect_operator
    test eax, eax
    jz .error_lt
    call advance
    
    call parse_type
    test eax, eax
    jz .error
    mov r12d, eax
    
    mov ecx, SOP_GT
    call expect_operator
    test eax, eax
    jz .error_gt
    call advance
    
    mov eax, 200            ; Type code for Vec
    add eax, r12d
    jmp .done

.error_lt:
    lea rcx, [err_expect_lt]
    call print_string
    jmp .error
.error_gt:
    lea rcx, [err_expect_gt]
    call print_string
    jmp .error
.error_comma:
    lea rcx, [err_expect_comma]
    call print_string
    jmp .error
.error_lbracket:
    lea rcx, [err_expect_lbracket]
    call print_string
    jmp .error

.error:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

; -----------------------------------------------------------------------------
; parse_expression: Parse expression (simplified)
; Just accepts a single value for now
; Output: EAX = 1 if success
; -----------------------------------------------------------------------------
parse_expression:
    call token_type
    
    ; Accept number
    cmp eax, STOK_NUMBER
    je .accept
    cmp eax, STOK_FLOAT
    je .accept
    
    ; Accept string
    cmp eax, STOK_STRING
    je .accept
    
    ; Accept identifier
    cmp eax, STOK_IDENT
    je .accept
    
    ; Accept keyword (true/false)
    cmp eax, STOK_KEYWORD
    jne .error
    call token_subtype
    cmp eax, SKW_TRUE
    je .accept
    cmp eax, SKW_FALSE
    je .accept
    jmp .error

.accept:
    call advance
    mov eax, 1
    ret

.error:
    xor eax, eax
    ret
