; Test simple exit 42
format PE64 console
entry start

section '.data' data readable writeable
    message db 'Hello!', 13, 10, 0

section '.text' code readable executable

start:
    sub rsp, 40
    mov rcx, 42
    call [ExitProcess]

section '.idata' import data readable

    dd 0, 0, 0, RVA kernel_name, RVA kernel_table
    dd 0, 0, 0, 0, 0

kernel_table:
    ExitProcess dq RVA _ExitProcess
    dq 0

kernel_name db 'kernel32.dll', 0
_ExitProcess db 0,0,'ExitProcess', 0
