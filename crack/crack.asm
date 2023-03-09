.model tiny
locals ??
.code
org 100h

Start:

GetSym macro
    mov ah, 01h
    int 21h                         ; get sym from keyboard
    cmp al, 0dh                     ; check for end of line
endm

    xor cl, cl                      ; set len counter (cl = len // 2)

    mov si, offset CorrectPassword
    add si, PasswordLen - 2
    std 

??GetPassSym:
    GetSym
    je ??CheckLoop                  ; if len is even
    mov bl, al
    inc cl
    GetSym
    je ??OddLen                     ; if len is odd
    mov bh, al
    push bx                         ; store symbols in stack
jmp ??GetPassSym

??OddLen:
    mov ah, al
    lodsb
    cmp ah, al
    jne ??Denied

??CheckLoop:
    test cl, cl
    je ??Success
    pop bx
    lodsw
    cmp ax, bx
    jne ??Denied
    dec cl
jmp ??CheckLoop

??Success:
    mov ax, 0b800h
    mov es, ax
    mov di, 160d*20 + 160d/2 - 10d
    xor si, si
    mov cx, SuccessStrLen
    mov ah, 0Ah
    cld
    
    ??WriteSuccess:
        mov al, SuccessStr[si]
        stosw
        inc si
    loop ??WriteSuccess

    mov ax, 4c00h	; exit(0)
	int 21h
    

??Denied:
    mov ax, 0b800h
    mov es, ax
    mov di, 160d*20 + 160d/2 - 10d
    xor si, si
    mov cx, DeniedStrLen
    mov ah, 0Ch
    cld
    
    ??WriteDenied:
        mov al, DeniedStr[si]
        stosw
        inc si
    loop ??WriteDenied

    cli                             ; set es:[bx] -> int09h in table
    xor bx, bx
    mov es, bx
    mov bx, 9*4
 
    mov es:[bx], offset New09       ; replace int09h with new
    mov ax, cs
    mov es:[bx+2], ax
    sti

    mov ax, 3100h                   ; int 21h with 31 code to stay in mem
    mov dx, offset ProgramEnd       ; calc programm size
    shr dx, 4
    inc dx
    int 21h

;==============================================================================
New09 proc

    push sp ss ds es bp si di dx cx bx ax

    mov ax, cs
    mov ds, ax
    mov si, offset LoseString   ; ds:[si] -> LoseString
    mov ax, 0b800h
    mov es, ax
    mov di, 160d*15 + 70d        ; es:[di] -> video segment
    mov cx, LoseStrLen
    cld

    mov ah, 4eh
    in al, 60h              ; read from port 60h
    
    cmp al, 80h             ; check if press key
    js ??SetPressColor
    
    mov ah, 1Ch

    ??LoadLoseString:
        mov al, [si]
        inc si
        stosw
    loop ??LoadLoseString

    in al, 61h
    or al, 80h
    out 61h, al
    and al, not 80h
    out 61h, al

    mov al, 20h
    out 20h, al

    pop ax bx cx dx di si bp es ds ss sp
    iret

??SetPressColor:
    mov ah, 0Ah
    jmp ??LoadLoseString

endp
;====================================================================

LoseString db "You lost The Game"
DeniedStr  db "Access denied"
SuccessStr db "Access allowed"

CorrectPassword db "JustPassword"
PasswordLen equ 12

LoseStrLen    equ 17
DeniedStrLen  equ 13
SuccessStrLen equ 14

ProgramEnd:

end Start