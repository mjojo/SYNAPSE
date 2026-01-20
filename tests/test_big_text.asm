format PE64 console
entry start

section '.text' code readable executable

; ??????????? ??????? ???? ????? .idata ??? ??????
rb 0x3F000  ; 256KB - 4KB = ????? ??? ? synapse_new

start:
    sub rsp, 48
    mov ecx, 42
    mov rax, [ExitProcess]
    call rax
    ret

section '.idata' import data readable

    dd RVA kernel32_lookup, 0, 0, RVA kernel32_name, RVA kernel32_table
    dd 0, 0, 0, 0, 0

    kernel32_name db 'KERNEL32.DLL', 0, 0, 0  ; Padding for alignment

    kernel32_lookup:
        dq RVA _ExitProcess
        dq 0

    kernel32_table:
        ExitProcess dq RVA _ExitProcess
                    dq 0

    _ExitProcess db 0,0,'ExitProcess',0

section '.bss' data readable writeable
    rb 0x100000  ; 1MB BSS

