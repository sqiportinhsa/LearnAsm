.286
.model tiny
locals ??
.code
org 100h

Start:
    mov bx, 1111h
    mov cx, 2222h
    mov dx, 3333h
    mov di, 4444h
    mov si, 5555h
    mov bp, 6666h

    mov ax, 7777h
    mov es, ax

    mov ax, 8888h
    mov ds, ax

    mov ax, 9999h
    mov ss, ax
    
    xor ax, ax
    
    InfLoop:
    jmp InfLoop

end Start