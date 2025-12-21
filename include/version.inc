; =============================================================================
; SYNAPSE Version Information
; =============================================================================

SYNAPSE_VERSION_MAJOR = 2
SYNAPSE_VERSION_MINOR = 2
SYNAPSE_VERSION_PATCH = 0

; Stage: 1=alpha, 2=beta, 3=rc, 4=stable
SYNAPSE_VERSION_STAGE = 4

; Build date (YYYYMMDD)
SYNAPSE_BUILD_DATE = 20251221

; Component versions
SYNAPSE_LEXER_VERSION = 2
SYNAPSE_PARSER_VERSION = 4       ; +control flow, +functions
SYNAPSE_JIT_VERSION = 4          ; +backpatching, +CALL/RET
SYNAPSE_AVX_VERSION = 1
SYNAPSE_NEURAL_VERSION = 2
SYNAPSE_CRYPTO_VERSION = 1
SYNAPSE_LEDGER_VERSION = 2
SYNAPSE_CORE_VERSION = 1
SYNAPSE_BRIDGE_VERSION = 1
SYNAPSE_CODEGEN_VERSION = 3      ; +variables, +functions
SYNAPSE_SYMBOLS_VERSION = 1      ; NEW: Symbol Table
SYNAPSE_FUNCTIONS_VERSION = 1    ; NEW: Function Table

; Version strings for display
SYNAPSE_VERSION_STR equ 'v2.2.0-matrix'
SYNAPSE_FULL_NAME   equ 'SYNAPSE v2.2.0 - Matrix Layer + Deep Learning Engine'
