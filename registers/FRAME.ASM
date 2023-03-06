.code

;====================================================================
;                    | WriteRegs |
;--------------------------------------------------------------------
; Prints all regs data in format "reg = data"
;--------------------------------------------------------------------
; Expects: ES -> video memory
;          regs pushed to stack in order:
;          sp ss ds es bp si di dx cx bx ax
;
; Entry: ES:[DI] = position for 1st symbol
;        AH      = color
; 
; Exit: None
; Destroys: ax, bx, cx, dx, di, bp
;--------------------------------------------------------------------
WriteRegs proc

WriteReg macro REG_1, REG_2
    irp sym, <'&REG_1&', '&REG_2&', ' ', '=', ' '>
        mov al, sym
        stosw
    endm

    mov dx, [bp]
    add bp, 2
    call PrHex          ;; destroys: BX, DX, DI, CX, AL

    sub di, 12h         ;; 9 symbols was written
    add di, ScrWidth    ;; di -> next string
endm

    mov bp, sp
    add bp, 2

    WriteReg A X
    WriteReg B X
    WriteReg C X 
    WriteReg D X 
    WriteReg D I 
    WriteReg S I 
    WriteReg B P 
    WriteReg E S 
    WriteReg D S 
    WriteReg S S 

    ;write sp without macro because its lower than real 
    irp sym, <'S', 'P', ' ', '=', ' '>
        mov al, sym
        stosw
    endm

    mov dx, [bp]
    add bp, 2         
    add dx, 6           ; sp is 6 lower than before interrupt
    call PrHex          ; destroys: BX, DX, DI, CX, AL
    
ret
endp
;====================================================================

;====================================================================
;			 | PrFrame |
;--------------------------------------------------------------------
; Prints colored rectangular frame of given size 
;                                        from top left corner pos
;--------------------------------------------------------------------
; Expects: es -> video memory, ds -> data segment
;
; Entry: DI = top left corner position
; 	     SI = offset table of symbols
;        AH = color
;        CL = width  in symbols
;        BH = height in symbols
;
;    table:
;           1------2------3
;           |             |
;           4      5      6
;           |             |
;           7------8------9
;
; Exit: None
;
; Destroys: AL, BX, CH, DX, DI, SI
;--------------------------------------------------------------------

DrawLine macro 
        cld             ;; draws line 12........23
        stosw           ;;             ^        ^
        mov al, bl      ;;             |--------|
        rep stosw       ;;              cx times
        mov al, dl      ;; 1 - al, 2 - bl, 3 - dl
        stosw
        mov cl, dh          ;; restore #inners symbols
        add cl, 2           ;; add borders, cl = frame width in sym
        shl cl, 1           ;; cl = frame width in bytes
        sub di, cx          ;; di -> left border
        add di, ScrWidth    ;; di -> next string left border
        mov cl, dh          ;; cl = #inner symbols
endm

PrFrame proc

    xor ch, ch          ; cx = cl = width in symbols

    sub cx, 2           ; symbols between borders
    mov dh, cl          ; save count

    sub bh, 2           ; height  count for central sym

    mov al, [si + 0]    ; first line
    mov bl, [si + 1]
    mov dl, [si + 2]

    DrawLine

    mov al, [si + 3]    ; inner lines
    mov bl, [si + 4]
    mov dl, [si + 5]

??LineLoop: DrawLine
            dec bh 
            test bh, bh
            jnz ??LineLoop
    
    mov al, [si + 6]    ; last line
    mov bl, [si + 7]
    mov dl, [si + 8]

    DrawLine

    add cl, 2           ; restore origin value

ret
endp
;====================================================================

; data
ScrWidth equ 160d