; =============================================================================
; SYNAPSE AST STRUCTURES
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
;
; Abstract Syntax Tree node definitions for SYNAPSE compiler
; =============================================================================

; =============================================================================
; Node Size and Alignment
; =============================================================================
AST_NODE_SIZE   = 48        ; 6 x 8 bytes (64-bit aligned)

; =============================================================================
; Node Types
; =============================================================================
NODE_PROGRAM    = 0         ; Корень программы
NODE_MODULE     = 1         ; module name:
NODE_FUNC       = 2         ; fn name():
NODE_VAR_DECL   = 3         ; let x: type = value
NODE_ASSIGN     = 4         ; x = value
NODE_IF         = 5         ; if cond:
NODE_ELIF       = 6         ; elif cond:
NODE_ELSE       = 7         ; else:
NODE_FOR        = 8         ; for x in range:
NODE_WHILE      = 9         ; while cond:
NODE_LOOP       = 10        ; loop:
NODE_MATCH      = 11        ; match value:
NODE_RETURN     = 12        ; return value
NODE_BREAK      = 13        ; break
NODE_CONTINUE   = 14        ; continue
NODE_PASS       = 15        ; pass
NODE_BLOCK      = 16        ; Блок кода (INDENT...DEDENT)
NODE_CALL       = 17        ; function_call(args)
NODE_BINOP      = 18        ; a + b, a <dot> b
NODE_UNOP       = 19        ; -x, not x
NODE_IDENT      = 20        ; identifier
NODE_NUMBER     = 21        ; numeric literal
NODE_STRING     = 22        ; string literal
NODE_STRUCT     = 23        ; struct Name:
NODE_ENUM       = 24        ; enum Name:
NODE_CONTRACT   = 25        ; contract fn
NODE_NEURON     = 26        ; neuron fn
NODE_ASM        = 27        ; unsafe asm:

; Phase 7: Variable Support
NODE_LET        = 28        ; let x = value (JIT stack write)
NODE_VAR        = 29        ; variable reference (JIT stack read)
NODE_OP_ADD     = 30        ; a + b (addition)
NODE_OP_LT      = 31        ; a < b (less than comparison)
NODE_OP_MUL     = 37        ; a * b (multiplication) - Phase 10
NODE_OP_SUB     = 38        ; a - b (subtraction) - Phase 12

; Phase 8: Function Support
NODE_FUNC_DEF   = 32        ; fn name() { body }
NODE_FUNC_RET   = 33        ; return value
NODE_CALL_USER  = 34        ; call user-defined function

; Phase 9: Array Support
NODE_ARRAY_GET  = 35        ; ptr[index] read
NODE_ARRAY_SET  = 36        ; ptr[index] = value write

; =============================================================================
; Node Structure (48 bytes)
; =============================================================================
; struct AST_Node {
;     u64 type;       // NODE_* constant
;     u64 next;       // Pointer to next sibling
;     u64 child;      // Pointer to first child (for blocks)
;     u64 value;      // Pointer to name/literal OR numeric value
;     u64 extra;      // Extra data (type info, operator code, etc)
;     u64 line;       // Source line number (for errors)
; }

AST_TYPE    = 0
AST_NEXT    = 8
AST_CHILD   = 16
AST_VALUE   = 24
AST_EXTRA   = 32
AST_LINE    = 40

; =============================================================================
; Type System Constants
; =============================================================================
TYPE_UNKNOWN    = 0
TYPE_INT        = 1
TYPE_INT8       = 2
TYPE_INT16      = 3
TYPE_INT32      = 4
TYPE_INT64      = 5
TYPE_UINT8      = 6
TYPE_UINT16     = 7
TYPE_UINT32     = 8
TYPE_UINT64     = 9
TYPE_F32        = 10
TYPE_F64        = 11
TYPE_BOOL       = 12
TYPE_STRING     = 13
TYPE_TENSOR     = 100       ; + inner type
TYPE_VEC        = 200       ; + inner type
TYPE_HASH256    = 50
TYPE_PTR        = 60

; =============================================================================
; Operator Codes (for BINOP/UNOP nodes)
; =============================================================================
OP_ADD          = 1
OP_SUB          = 2
OP_MUL          = 3
OP_DIV          = 4
OP_MOD          = 5
OP_POW          = 6
OP_EQ           = 10
OP_NE           = 11
OP_LT           = 12
OP_GT           = 13
OP_LE           = 14
OP_GE           = 15
OP_AND          = 20
OP_OR           = 21
OP_NOT          = 22
OP_DOT_PRODUCT  = 30        ; <dot>
OP_TENSOR_ADD   = 31        ; <+>
OP_TENSOR_SUB   = 32        ; <->
OP_TENSOR_MUL   = 33        ; <*>
OP_TENSOR_DIV   = 34        ; </>
