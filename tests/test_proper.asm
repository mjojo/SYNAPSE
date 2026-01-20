format PE64 console
entry start

section '.text' code readable executable
start:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov ecx, -11
    call [GetStdHandle]
    
    xor ecx, ecx
    call [ExitProcess]

section '.idata' import data readable

  ; Import Directory Table
  dd RVA kernel32_ilt,0,0,RVA kernel32_name,RVA kernel32_iat
  dd 0,0,0,0,0
  
  ; Import Lookup Table (ILT) for kernel32
  kernel32_ilt:
  dq RVA _ExitProcess
  dq RVA _GetStdHandle
  dq 0
  
  ; Import Address Table (IAT) for kernel32
  kernel32_iat:
  ExitProcess dq RVA _ExitProcess
  GetStdHandle dq RVA _GetStdHandle
  dq 0
  
  ; DLL name
  kernel32_name db 'KERNEL32.DLL',0
  
  ; Hint/Name entries
  _ExitProcess dw 0
               db 'ExitProcess',0
  _GetStdHandle dw 0
                db 'GetStdHandle',0
