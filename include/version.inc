; =============================================================================
; SYNAPSE Version Information
; =============================================================================

SYNAPSE_VERSION_MAJOR = 3
SYNAPSE_VERSION_MINOR = 2
SYNAPSE_VERSION_PATCH = 0

; Stage: 1=alpha, 2=beta, 3=rc, 4=stable
SYNAPSE_VERSION_STAGE = 4

; Build date (YYYYMMDD)
SYNAPSE_BUILD_DATE = 20260102

; Component versions
SYNAPSE_LEXER_VERSION = 6        ; +bootstrap lexer
SYNAPSE_PARSER_VERSION = 9       ; +bootstrap parser
SYNAPSE_JIT_VERSION = 11         ; +PE32+ generation
SYNAPSE_AVX_VERSION = 2          ; +matmul/relu
SYNAPSE_NEURAL_VERSION = 3       ; +inference
SYNAPSE_CRYPTO_VERSION = 2       ; +chain_hash
SYNAPSE_LEDGER_VERSION = 3       ; +introspection
SYNAPSE_CORE_VERSION = 2         ; +graphics/GUI
SYNAPSE_BRIDGE_VERSION = 4       ; +mouse/keyboard
SYNAPSE_CODEGEN_VERSION = 8      ; +x64 prologue/epilogue
SYNAPSE_SYMBOLS_VERSION = 3      ; +global/local
SYNAPSE_FUNCTIONS_VERSION = 3    ; +fastcall
SYNAPSE_FILEIO_VERSION = 3       ; +fread/fwrite

; Version strings for display
SYNAPSE_VERSION_STR equ 'v3.2.0-ouroboros-returns'
SYNAPSE_FULL_NAME   equ 'SYNAPSE v3.2.0 - The Ouroboros Returns'
