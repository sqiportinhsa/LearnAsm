.286
.model tiny
locals ??
.code
org 100h

Start:
    cli                             ; set es:[bx] -> int09h in table
    xor bx, bx
    mov es, bx
    mov bx, 9*4

    mov ax, es:[bx]                 ; save old int09h
    mov [Old09Ofs], ax
    mov ax, es:[bx+02]
    mov [Old09Seg], ax
 
    mov es:[bx], offset New09       ; replace int09h with new
    mov ax, cs
    mov es:[bx+2], ax
    sti

    mov ax, 3100h                   ; int 31h to stay in mem
    mov dx, offset ProgramEnd       ; calc programm size
    shr dx, 4
    inc dx
    int 21h

;====================================================================

New09 proc
    push ax bx es

    mov bx, 0b800h
    mov es, bx
    mov bx, 160*5d + 80d

    mov ah, 4eh
    in al, 60h          ; read from port 60h
    
    cmp al, 1dh         ; press ctrl code
    jz ??PressCtrl

    cmp al, 9dh         ; release ctrl code
    jz ??ReleaseCtrl

    ??Continue:

    in al, 61h
    or al, 80h
    out 61h, al
    and al, not 80h
    out 61h, al

    mov al, 20h
    out 20h, al

    pop es bx ax

    pushf

    db 09ah           ; call far
        Old09Ofs dw 0
        Old09Seg dw 0

    iret

??PressCtrl:
    mov bx, offset Ctrl
    mov ax, 1
    mov [bx], ax
    mov ah, 0Ah
    mov es:[bx], ax
    jmp ??Continue

??ReleaseCtrl:
    mov bx, offset Ctrl
    mov ax, 0
    mov [bx], ax
    mov ah, 0Ah
    mov es:[bx], ax
    jmp ??Continue

endp
;====================================================================

Ctrl: dw 0

ProgramEnd:

end Start