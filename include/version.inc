; =============================================================================
; SYNAPSE Version Information
; =============================================================================

SYNAPSE_VERSION_MAJOR = 2
SYNAPSE_VERSION_MINOR = 9
SYNAPSE_VERSION_PATCH = 1

; Stage: 1=alpha, 2=beta, 3=rc, 4=stable
SYNAPSE_VERSION_STAGE = 4

; Build date (YYYYMMDD)
SYNAPSE_BUILD_DATE = 20251224

; Component versions
SYNAPSE_LEXER_VERSION = 4        ; +token grouping
SYNAPSE_PARSER_VERSION = 7       ; +file I/O parsing
SYNAPSE_JIT_VERSION = 8          ; +multi-arg calls in while/if
SYNAPSE_AVX_VERSION = 1
SYNAPSE_NEURAL_VERSION = 2
SYNAPSE_CRYPTO_VERSION = 1
SYNAPSE_LEDGER_VERSION = 2
SYNAPSE_CORE_VERSION = 1
SYNAPSE_BRIDGE_VERSION = 2       ; +file I/O intrinsics
SYNAPSE_CODEGEN_VERSION = 6      ; +alloc_bytes/get_byte/set_byte
SYNAPSE_SYMBOLS_VERSION = 2      ; +param reversal
SYNAPSE_FUNCTIONS_VERSION = 2    ; +pointer args
SYNAPSE_FILEIO_VERSION = 1       ; NEW: File I/O support

; Version strings for display
SYNAPSE_VERSION_STR equ 'v2.9.0-selfhost'
SYNAPSE_FULL_NAME   equ 'SYNAPSE v2.9.0 - Self-Hosting Foundation'
