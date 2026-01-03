; test_va.asm - Минимальный тест VirtualAlloc
format PE64 console
entry main

section '.text' code readable executable

main:
    sub rsp, 40                  ; Shadow space + alignment
    
    ; VirtualAlloc(NULL, 4096, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)
    xor ecx, ecx                 ; lpAddress = NULL
    mov edx, 4096                ; dwSize = 4096
    mov r8d, 0x3000              ; flAllocationType = MEM_COMMIT | MEM_RESERVE
    mov r9d, 4                   ; flProtect = PAGE_READWRITE
    call [VirtualAlloc]
    
    ; Если RAX != 0, вернем 99
    test rax, rax
    jz .failed
    
    mov ecx, 99
    jmp .exit
    
.failed:
    mov ecx, 1
    
.exit:
    call [ExitProcess]

section '.idata' import data readable

    dd 0, 0, 0, RVA kernel_name, RVA kernel_iat
    dd 0, 0, 0, 0, 0
    
kernel_iat:
    ExitProcess dq RVA _ExitProcess
    VirtualAlloc dq RVA _VirtualAlloc
    dq 0
    
kernel_name db 'KERNEL32.DLL',0

    _ExitProcess dw 0
                 db 'ExitProcess',0
    _VirtualAlloc dw 0
                  db 'VirtualAlloc',0
