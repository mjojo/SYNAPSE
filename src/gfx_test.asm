; =============================================================================
; SYNAPSE GFX Test (Phase 21) - THE EYE (FillRect version)
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; =============================================================================

format PE64 GUI
entry start

WS_OVERLAPPED       = 0x00000000
WS_CAPTION          = 0x00C00000
WS_SYSMENU          = 0x00080000
WS_MINIMIZEBOX      = 0x00020000
WS_VISIBLE          = 0x10000000
CS_HREDRAW          = 0x0002
CS_VREDRAW          = 0x0001
IDC_ARROW           = 32512
WM_DESTROY          = 0x0002
WM_PAINT            = 0x000F

section '.data' data readable writeable

    class_name      db 'SynapseEye',0
    window_title    db 'SYNAPSE Phase 21: Neural Heatmap',0
    
    wndclass:
        .cbSize         dd 80, 0
        .style          dd CS_HREDRAW or CS_VREDRAW, 0
        .lpfnWndProc    dq 0
        .cbClsExtra     dd 0
        .cbWndExtra     dd 0
        .hInstance      dq 0
        .hIcon          dq 0
        .hCursor        dq 0
        .hbrBackground  dq 0
        .lpszMenuName   dq 0
        .lpszClassName  dq 0
        .hIconSm        dq 0
    
    themsg          rb 48
    paintstruct     rb 72
    rect            dd 0, 0, 0, 0   ; left, top, right, bottom
    
    hwnd            dq 0
    hdc             dq 0
    hInstance       dq 0
    hbrush          dq 0

section '.text' code readable executable

start:
    sub rsp, 104
    
    xor ecx, ecx
    call [GetModuleHandleA]
    mov [hInstance], rax
    mov [wndclass.hInstance], rax
    
    xor ecx, ecx
    mov edx, IDC_ARROW
    call [LoadCursorA]
    mov [wndclass.hCursor], rax
    
    mov ecx, 0x202020       ; Dark grey background
    call [CreateSolidBrush]
    mov [wndclass.hbrBackground], rax
    
    lea rax, [WndProc]
    mov [wndclass.lpfnWndProc], rax
    lea rax, [class_name]
    mov [wndclass.lpszClassName], rax
    
    lea rcx, [wndclass]
    call [RegisterClassExA]
    test eax, eax
    jz .exit
    
    xor ecx, ecx
    lea rdx, [class_name]
    lea r8, [window_title]
    mov r9d, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_VISIBLE
    
    mov dword [rsp+32], 100
    mov dword [rsp+40], 100
    mov dword [rsp+48], 420
    mov dword [rsp+56], 420
    mov qword [rsp+64], 0
    mov qword [rsp+72], 0
    mov rax, [hInstance]
    mov [rsp+80], rax
    mov qword [rsp+88], 0
    
    call [CreateWindowExA]
    mov [hwnd], rax
    test rax, rax
    jz .exit
    
.msg_loop:
    lea rcx, [themsg]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call [GetMessageA]
    
    test eax, eax
    jle .exit
    
    lea rcx, [themsg]
    call [TranslateMessage]
    
    lea rcx, [themsg]
    call [DispatchMessageA]
    
    jmp .msg_loop

.exit:
    xor ecx, ecx
    call [ExitProcess]

; =============================================================================
WndProc:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    mov [rbp+40], r9
    
    cmp edx, WM_DESTROY
    je .destroy
    cmp edx, WM_PAINT
    je .paint
    
    call [DefWindowProcA]
    jmp .done

.destroy:
    xor ecx, ecx
    call [PostQuitMessage]
    xor eax, eax
    jmp .done

.paint:
    mov rcx, [rbp+16]
    lea rdx, [paintstruct]
    call [BeginPaint]
    mov [hdc], rax
    test rax, rax
    jz .paint_end
    
    ; Draw 8x8 grid
    xor r12d, r12d      ; row
.row:
    cmp r12d, 8
    jge .paint_end
    
    xor r13d, r13d      ; col
.col:
    cmp r13d, 8
    jge .next_row
    
    ; Create color: gradient green
    mov eax, r12d
    imul eax, 8
    add eax, r13d
    mov ecx, eax
    shl ecx, 2
    and ecx, 0xFF
    shl ecx, 8          ; Green channel
    add ecx, 0x001500   ; Base green
    
    call [CreateSolidBrush]
    mov r14, rax        ; Save brush
    
    ; Calculate rect
    mov eax, r13d
    imul eax, 48
    add eax, 10
    mov [rect], eax             ; left
    
    mov eax, r12d
    imul eax, 48
    add eax, 10
    mov [rect+4], eax           ; top
    
    mov eax, r13d
    inc eax
    imul eax, 48
    add eax, 5
    mov [rect+8], eax           ; right
    
    mov eax, r12d
    inc eax
    imul eax, 48
    add eax, 5
    mov [rect+12], eax          ; bottom
    
    ; FillRect
    mov rcx, [hdc]
    lea rdx, [rect]
    mov r8, r14
    call [FillRect]
    
    ; Delete brush
    mov rcx, r14
    call [DeleteObject]
    
    inc r13d
    jmp .col

.next_row:
    inc r12d
    jmp .row

.paint_end:
    mov rcx, [rbp+16]
    lea rdx, [paintstruct]
    call [EndPaint]
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret

section '.idata' import data readable
    dd 0,0,0,RVA kernel32_name,RVA kernel32_table
    dd 0,0,0,RVA user32_name,RVA user32_table
    dd 0,0,0,RVA gdi32_name,RVA gdi32_table
    dd 0,0,0,0,0

    kernel32_table:
        GetModuleHandleA    dq RVA _GetModuleHandleA
        ExitProcess         dq RVA _ExitProcess
                            dq 0
    
    user32_table:
        RegisterClassExA    dq RVA _RegisterClassExA
        CreateWindowExA     dq RVA _CreateWindowExA
        GetMessageA         dq RVA _GetMessageA
        TranslateMessage    dq RVA _TranslateMessage
        DispatchMessageA    dq RVA _DispatchMessageA
        DefWindowProcA      dq RVA _DefWindowProcA
        PostQuitMessage     dq RVA _PostQuitMessage
        BeginPaint          dq RVA _BeginPaint
        EndPaint            dq RVA _EndPaint
        LoadCursorA         dq RVA _LoadCursorA
        FillRect            dq RVA _FillRect
                            dq 0
    
    gdi32_table:
        CreateSolidBrush    dq RVA _CreateSolidBrush
        DeleteObject        dq RVA _DeleteObject
                            dq 0

    kernel32_name   db 'KERNEL32.DLL',0
    user32_name     db 'USER32.DLL',0
    gdi32_name      db 'GDI32.DLL',0
    
    _GetModuleHandleA   db 0,0,'GetModuleHandleA',0
    _ExitProcess        db 0,0,'ExitProcess',0
    _RegisterClassExA   db 0,0,'RegisterClassExA',0
    _CreateWindowExA    db 0,0,'CreateWindowExA',0
    _GetMessageA        db 0,0,'GetMessageA',0
    _TranslateMessage   db 0,0,'TranslateMessage',0
    _DispatchMessageA   db 0,0,'DispatchMessageA',0
    _DefWindowProcA     db 0,0,'DefWindowProcA',0
    _PostQuitMessage    db 0,0,'PostQuitMessage',0
    _BeginPaint         db 0,0,'BeginPaint',0
    _EndPaint           db 0,0,'EndPaint',0
    _LoadCursorA        db 0,0,'LoadCursorA',0
    _FillRect           db 0,0,'FillRect',0
    _CreateSolidBrush   db 0,0,'CreateSolidBrush',0
    _DeleteObject       db 0,0,'DeleteObject',0
