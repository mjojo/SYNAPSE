format PE64 console
entry start

section '.text' code readable executable

start:
    sub rsp, 40
    mov ecx, 42
    call [ExitProcess]
    ret

rb 0x800  ; <-- ONLY DIFFERENCE!

section '.idata' import data readable

    dd RVA kernel32_lookup, 0, 0, RVA kernel32_name, RVA kernel32_table
    dd 0, 0, 0, 0, 0

    kernel32_name db 'KERNEL32.DLL', 0

    kernel32_lookup:
        dq RVA _ExitProcess
        dq 0

    kernel32_table:
        ExitProcess dq RVA _ExitProcess
                    dq 0

    _ExitProcess db 0,0,'ExitProcess',0
