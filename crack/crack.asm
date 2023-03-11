.286
.model tiny
locals ??
.code
org 100h

Start:

jmp Main

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

    cmp al, 10h             ; skip Q (dont ask why)
    je ??SkipDraw
    
    cmp al, 80h             ; check if press key
    jns ??SetPress
    
    mov ah, 1Ch

    ??LoadLoseString:

    cmp al, 90h
    je ??SkipDraw

    call WriteString

    ??SkipDraw:

    in al, 61h
    or al, 80h
    out 61h, al
    and al, not 80h
    out 61h, al

    mov al, 20h
    out 20h, al

    pop ax bx cx dx di si bp es ds ss sp
    iret

??SetPress:
    mov bx, Int09hPos
    mov [bx], al
    mov bx, offset Int09hPos
    inc word ptr [bx]

    mov ah, 0Ah
    jmp ??LoadLoseString

endp
;====================================================================

Int09hPos dw 0
Int09hData db 20 dup(0)

;====================================================================
;                           WriteString
;--------------------------------------------------------------------
; Expects: es:[di] -> first byte for string in vmem
;          ds:[si] -> first sym of string in memory
; Entry: ah = color
;        cx = len
; Exit: none
; Destroys: cx, al, si, di
;--------------------------------------------------------------------
WriteString proc

??LoadString:
    lodsb
    stosw
loop ??LoadString

ret
endp
;====================================================================

Main:

GetSym macro
    mov ah, 01h
    int 21h                         ; get sym from keyboard
    cmp al, 0dh                     ; check for end of line
endm

    mov bx, offset ??StartOfShield
    mov cx, offset ??EndOfShield
    sub cx, bx
    xor dx, dx
    xor ax, ax

    ??CalcHash:
        mov byte ptr ax, [bx]
        add dx, ax
        inc bx
    loop ??CalcHash

    mov ax, PrHash
    cmp ax, dx
    je ??StartOfShield
    jmp ??Denied

??StartOfShield:

    xor bx, bx                      ; set es:[bx] -> int09h in table
    mov es, bx
    mov bx, 9*4

    mov ax, es:[bx]                 ; save old int09h
    mov [Old09Ofs], ax
    mov ax, es:[bx+02]
    mov [Old09Seg], ax

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
    xor al, cl
    xor ah, cl
    cmp ax, bx
    jne ??Denied
    dec cl
jmp ??CheckLoop

??Success:
    mov ax, 0b800h
    mov es, ax
    mov di, 160d*20 + 160d/2 - 10d
    mov si, offset SuccessStr
    mov cx, SuccessStrLen
    mov ah, 0Ah
    cld

    ??LoadGranted:
        lodsb
        stosw
    loop ??LoadGranted

    cli                           
    xor bx, bx                  ; set es:[bx] -> int09h in table
    mov es, bx
    mov bx, 9*4

    mov ax, [Old09Ofs]
    mov es:[bx], ax             ; replace int09h with old 
    mov ax, [Old09Seg]
    mov es:[bx+2], ax
    sti

    mov ax, 4c00h	; exit(0)
	int 21h
    

??Denied:
    mov ax, 0b800h
    mov es, ax
    mov di, 160d*20 + 160d/2 - 10d
    mov si, offset DeniedStr
    mov cx, DeniedStrLen
    mov ah, 0Ch
    cld

    call WriteString

    mov ax, offset Int09hData
    mov bx, offset Int09hPos
    mov [bx], ax

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

??EndOfShield:

LoseString db "You lost The Game"
DeniedStr  db "Access denied"
SuccessStr db "Access allowed"

IncorrectPassword2 db "AbehDpo"
CorrectPassword    db "KtqvSbwwrjtb"
IncorrectPassword1 db "seRklM"

Old09Ofs dw 0
Old09Seg dw 0

PasswordLen equ 12d

LoseStrLen    equ 17d
DeniedStrLen  equ 13d
SuccessStrLen equ 14d

PrHash equ 0F87Ah

ProgramEnd:

end Start