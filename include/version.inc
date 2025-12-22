; =============================================================================
; SYNAPSE Version Information
; =============================================================================

SYNAPSE_VERSION_MAJOR = 2
SYNAPSE_VERSION_MINOR = 6
SYNAPSE_VERSION_PATCH = 0

; Stage: 1=alpha, 2=beta, 3=rc, 4=stable
SYNAPSE_VERSION_STAGE = 4

; Build date (YYYYMMDD)
SYNAPSE_BUILD_DATE = 20251222

; Component versions
SYNAPSE_LEXER_VERSION = 2
SYNAPSE_PARSER_VERSION = 6       ; +vector operations
SYNAPSE_JIT_VERSION = 6          ; +array assign fix
SYNAPSE_AVX_VERSION = 1
SYNAPSE_NEURAL_VERSION = 2
SYNAPSE_CRYPTO_VERSION = 1
SYNAPSE_LEDGER_VERSION = 2
SYNAPSE_CORE_VERSION = 1
SYNAPSE_BRIDGE_VERSION = 1
SYNAPSE_CODEGEN_VERSION = 5      ; +while array assign
SYNAPSE_SYMBOLS_VERSION = 2      ; +param reversal
SYNAPSE_FUNCTIONS_VERSION = 2    ; +pointer args

; Version strings for display
SYNAPSE_VERSION_STR equ 'v2.6.0-vectors'
SYNAPSE_FULL_NAME   equ 'SYNAPSE v2.6.0 - Vector Operations'
