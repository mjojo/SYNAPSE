; =============================================================================
; SYNAPSE Version Information
; =============================================================================

SYNAPSE_VERSION_MAJOR = 1
SYNAPSE_VERSION_MINOR = 0
SYNAPSE_VERSION_PATCH = 0

; Stage: 1=alpha, 2=beta, 3=rc, 4=stable
SYNAPSE_VERSION_STAGE = 4

; Build date (YYYYMMDD)
SYNAPSE_BUILD_DATE = 20251225

; Component versions
SYNAPSE_LEXER_VERSION = 5        ; +tokens 2.0
SYNAPSE_PARSER_VERSION = 8       ; +recursive descent
SYNAPSE_JIT_VERSION = 10         ; +stack machine
SYNAPSE_AVX_VERSION = 2          ; +matmul/relu
SYNAPSE_NEURAL_VERSION = 3       ; +inference
SYNAPSE_CRYPTO_VERSION = 2       ; +chain_hash
SYNAPSE_LEDGER_VERSION = 3       ; +introspection
SYNAPSE_CORE_VERSION = 1
SYNAPSE_BRIDGE_VERSION = 3       ; +intrinsics V2
SYNAPSE_CODEGEN_VERSION = 7      ; +emit_x64
SYNAPSE_SYMBOLS_VERSION = 3      ; +global/local
SYNAPSE_FUNCTIONS_VERSION = 3    ; +fastcall
SYNAPSE_FILEIO_VERSION = 2       ; +full support

; Version strings for display
SYNAPSE_VERSION_STR equ 'v1.0.0-singularity'
SYNAPSE_FULL_NAME   equ 'SYNAPSE v1.0.0 - The Singularity Release'
