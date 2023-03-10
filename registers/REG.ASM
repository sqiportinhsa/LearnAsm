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

    xor bx, bx                      ; set es:[bx] -> int08h in table
    mov es, bx
    mov bx, 8*4

    mov ax, es:[bx]                 ; save old int08h
    mov [Old08Ofs], ax
    mov ax, es:[bx+02]
    mov [Old08Seg], ax
 
    mov es:[bx], offset New08       ; replace int09h with new
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
    push sp ss ds es bp si di dx cx bx ax
    mov bx, cs
    mov ds, bx

    mov ah, 4eh
    in al, 60h          ; read from port 60h
    
    cmp al, 1dh         ; press ctrl code
    je ??PressCtrl

    cmp al, 9dh         ; release ctrl code
    je ??ReleaseCtrl

    cmp al, 02h         ; press 1 code
    je ??Press1

    cmp al, 01          ; press esc code
    jne ??Continue
    jmp ??PressEsc

    ??Continue:

    pop ax bx cx dx di si bp es ds ss sp

    db 0eah             ; call far
        Old09Ofs dw 0
        Old09Seg dw 0

??PressCtrl:
    mov bx, offset Ctrl
    mov ax, 1
    mov [bx], ax
    jmp ??Continue

??ReleaseCtrl:
    mov bx, offset Ctrl
    xor ax, ax
    mov [bx], ax
    jmp ??Continue

??Press1:
    mov bx, offset Ctrl
    mov al, [bx]
    test al, al
    jz ??Continue

    mov bx, offset RegsOn
    mov ax, 1
    mov [bx], ax

    mov bx, 0b800h
    mov ds, bx
    mov bx, cs
    mov es, bx
    xor si, si
    mov di, offset Saved
    cld

    mov ax, FrHeight

    ??SaveString:
        mov cx, FrWidth
        rep movsw
        add si, ScrWidth - 2*FrWidth
        dec ax
        test ax, ax
    jnz ??SaveString

    jmp ??Exit

??PressEsc:
    mov bx, offset Ctrl
    mov al, [bx]
    test al, al
    jnz ??SkipJump
    
    jmp ??Continue
    
    ??SkipJump:
    mov bx, offset RegsOn
    xor ax, ax
    mov [bx], ax

    mov bx, 0b800h
    mov es, bx
    mov bx, cs
    mov ds, bx
    xor di, di
    mov si, offset Saved
    cld

    mov ax, FrHeight

    ??RetString:
        mov cx, FrWidth
        rep movsw
        add di, ScrWidth - 2*FrWidth
        dec ax
        test ax, ax
    jnz ??RetString

;   jmp ??Exit

??Exit:
    in al, 61h
    or al, 80h
    out 61h, al
    and al, not 80h
    out 61h, al

    mov al, 20h
    out 20h, al

    pop ax bx cx dx di si bp es ds ss sp
    iret

endp
;====================================================================

;====================================================================
New08 proc
    push sp ss ds es bp si di dx cx bx ax
    
    mov bx, offset RegsOn
    mov al, cs:[bx]
    test al, al
    jnz ??RenewFrame

    jmp ??Continue

    ??RenewFrame:
    ; cmp image and screen, replace changes in Saved

    mov bx, 0b800h
    mov ds, bx              ; ds -> video segment
    mov bx, cs
    mov es, bx              ; es -> code segment

    xor si, si              ; ds:[si] -> frame
    mov di, offset Image    ; es:[di] -> image
    mov bx, offset Saved    ; es:[bx] -> Saved

    mov ax, FrHeight
    mov cx, FrWidth*2
    cld

    ??CmpString:
            mov dl,    [si]
            mov dh, es:[di]
            cmp dl, dh
            je ??SkipReplace
                mov es:[bx], dl     ; update byte in Saved
            ??SkipReplace:
            inc si
            inc bx
            inc di
        loop ??CmpString
        mov cx, FrWidth*2
        add si, ScrWidth - FrWidth*2    ; si -> next line
        add di, ScrWidth - FrWidth*2    ; di -> next line
        dec ax
        test ax, ax
    jnz ??CmpString

    ; draw new image

    mov bx, cs
    mov ds, bx              ; ds -> code segment
    mov di, offset Image    ; es:[di] -> Image
    mov si, offset Style    ; ds:[si] -> Style
    mov ah, 0Bh             ; ah = color
    mov cl, FrWidth
    mov bh, FrHeight - 2
    call PrFrame

    mov ah, 10
    mov di, offset Image + ScrWidth + 4
    call WriteRegs

    ; replace screen with image

    mov bx, 0b800h
    mov es, bx              ; es -> video segment

    xor di, di              ; es:[di] -> frame
    mov si, offset Image    ; ds:[di] -> image

    mov ax, FrHeight
    mov cx, FrWidth
    cld

    ??RepStrings:
        mov cx, FrWidth
        rep movsw
        add si, ScrWidth - FrWidth*2    ; si -> next line
        add di, ScrWidth - FrWidth*2    ; di -> next line
        dec ax
        test ax, ax
    jnz ??RepStrings


    ??Continue:
    pop ax bx cx dx di si bp es ds ss sp

    db 0eah             ; call far
        Old08Ofs dw 0
        Old08Seg dw 0

endp
;====================================================================
include FRAME.ASM
include BINHEX.ASM

Ctrl: dw 0
RegsOn: dw 0
Easter: dw 0

FrWidth  equ 14
FrHeight equ 15

Style db  003h, 003h, 003h, 003h, 020h, 003h, 003h, 003h, 003h
Saved db  FrWidth*FrHeight*2 dup(0)
Image db  ScrWidth*25*2 dup(0)

ProgramEnd:

end Start