.286
.model tiny
locals ??
.code
org 100h

Start:
    mov ax, 0
    mov bx, 1111h
    mov cx, 2222h
    mov dx, 3333h
    
    InfLoop:
    jmp InfLoop

end Start