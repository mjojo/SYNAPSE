format PE64 console
entry start

section '.text' code readable executable
start:
    sub rsp, 40
    
    ; Call VirtualAlloc
    xor ecx, ecx        ; lpAddress = NULL
    mov edx, 100        ; dwSize = 100
    mov r8d, 0x3000     ; flAllocationType = MEM_COMMIT | MEM_RESERVE
    mov r9d, 4          ; flProtect = PAGE_READWRITE
    call [VirtualAlloc]
    
    ; Exit with code 99
    mov ecx, 99
    call [ExitProcess]

section '.idata' import data readable writeable
    dd 0,0,0,RVA kernel_name,RVA kernel_table
    dd 0,0,0,0,0
    
    kernel_table:
        ExitProcess dq RVA _ExitProcess
        VirtualAlloc dq RVA _VirtualAlloc
        dq 0
        
    kernel_name db 'KERNEL32.DLL',0
    
    _ExitProcess dw 0
        db 'ExitProcess',0
    _VirtualAlloc dw 0
        db 'VirtualAlloc',0
