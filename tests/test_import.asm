format PE64 console
entry start

include 'd:\Projects\SYNAPSE\tools\INCLUDE\MACRO\IMPORT64.INC'

section '.text' code readable executable
start:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov ecx, -11
    call [GetStdHandle]
    
    xor ecx, ecx
    call [ExitProcess]

section '.idata' data readable

data import
  
  library kernel32,'KERNEL32.DLL'

  import kernel32,\
         ExitProcess,'ExitProcess',\
         GetStdHandle,'GetStdHandle'

end data
