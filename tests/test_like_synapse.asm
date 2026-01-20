format PE64 console
entry start

section '.text' code readable executable

rb 0x3FFFF  ; 256KB - 1 byte padding to match synapse_new layout

start:
    sub rsp, 40
    mov ecx, 42
    call [ExitProcess]
    add rsp, 40
    ret

section '.idata' import data readable

    dd RVA kernel32_lookup, 0, 0, RVA kernel32_name, RVA kernel32_table
    dd 0, 0, 0, 0, 0

    kernel32_lookup:
        dq RVA _ExitProcess
        dq 0

    kernel32_name db 'KERNEL32.DLL', 0, 0, 0, 0  ; 16 bytes

    kernel32_table:
        ExitProcess dq RVA _ExitProcess
                    dq 0

    _ExitProcess dw 0
                 db 'ExitProcess',0

section '.bss' data readable writeable
    rb 0x100000

