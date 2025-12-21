; =============================================================================
; SYNAPSE Version Information
; =============================================================================

SYNAPSE_VERSION_MAJOR = 2
SYNAPSE_VERSION_MINOR = 5
SYNAPSE_VERSION_PATCH = 0

; Stage: 1=alpha, 2=beta, 3=rc, 4=stable
SYNAPSE_VERSION_STAGE = 4

; Build date (YYYYMMDD)
SYNAPSE_BUILD_DATE = 20251221

; Component versions
SYNAPSE_LEXER_VERSION = 2
SYNAPSE_PARSER_VERSION = 5       ; +alloc, +pointers
SYNAPSE_JIT_VERSION = 5          ; +memory access
SYNAPSE_AVX_VERSION = 1
SYNAPSE_NEURAL_VERSION = 2
SYNAPSE_CRYPTO_VERSION = 1
SYNAPSE_LEDGER_VERSION = 2
SYNAPSE_CORE_VERSION = 1
SYNAPSE_BRIDGE_VERSION = 1
SYNAPSE_CODEGEN_VERSION = 4      ; +alloc intrinsic
SYNAPSE_SYMBOLS_VERSION = 2      ; +param reversal
SYNAPSE_FUNCTIONS_VERSION = 2    ; +pointer args

; Version strings for display
SYNAPSE_VERSION_STR equ 'v2.5.0-memory'
SYNAPSE_FULL_NAME   equ 'SYNAPSE v2.5.0 - Memory Manager & Pointers'
