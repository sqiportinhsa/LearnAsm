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

    xor cl, cl                      ; set len counter

    mov si, offset CorrectPassword
    add si, PasswordLen
    std 

??GetPassSym:
    GetSym
    je ??CheckLoop
    mov bh, al
    inc cl
    GetSym
    je ??OddLen
    mov bl, al
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
    lodsw
    pop bx
    cmp ax, bx
    jne ??Denied
    sub cl, 2
jmp ??CheckLoop

??Success:
    mov ax, 0b800h
    mov es, ax
    mov di, 160d*15 + 160d/2
    xor si, si
    mov ah, 12h
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
    mov di, 160d*15 + 160d/2
    xor si, si
    mov ah, 12h
    mov cx, DeniedStrLen
    mov ah, 0Ch
    cld
    
    ??WriteDenied:
        mov al, DeniedStr[si]
        stosw
        inc si
    loop ??WriteDenied

    mov ax, 4c00h	; exit(0)
	int 21h

    ;cli                             ; set es:[bx] -> int09h in table
    ;xor bx, bx
    ;mov es, bx
    ;mov bx, 9*4
 ;
    ;mov es:[bx], offset New09       ; replace int09h with new
    ;mov ax, cs
    ;mov es:[bx+2], ax
    ;sti
;
    ;mov ax, 3100h                   ; int 21h with 31 code to stay in mem
    ;mov dx, offset ProgramEnd       ; calc programm size
    ;shr dx, 4
    ;inc dx
    ;int 21h

;==============================================================================
New09 proc

    push sp ss ds es bp si di dx cx bx ax

    mov ax, cs
    mov ds, bx
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
    
    mov ah, 1Ah

    ??LoadLoseString:
        lodsb
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

CorrectPassword db "1111"
PasswordLen equ 15

LoseStrLen    equ 17
DeniedStrLen  equ 13
SuccessStrLen equ 14

ProgramEnd:

end Start