.code

;====================================================================
;            | WriteReg |
;--------------------------------------------------------------------
; Prints string '<REG> = <NUM>' to screen using vmem
; where REG is reg name (consist of 2 ascii codes) and <NUM> is 
; value that can be stored in reg.
;--------------------------------------------------------------------
; Expects: ES -> video memory
; 
; Entry: ES:[DI] = position for 1st symbol
;        BH, BL = first and second syms of REG name
;        AH = color
;
; Exit: ES:[DI] -> ES:[DI] + ScrWidth
;
; Destroys: AL - to store sym for writing to vmem
;           DI - moved 1 string lower
;           BX, DX, CX - destroyed in PrHex
;--------------------------------------------------------------------

WriteSym macro SRC
    mov al, SRC
    stosw
endm

WriteReg proc

    WriteSym bh         ; A (or other reg)
    WriteSym bl         ; X (or other reg)
    WriteSym ' '        ; 
    WriteSym '='        ; =
    WriteSym ' '        ; 

    sub di, 0Ah         ; 5 symbols was written
    add di, ScrWidth    ; di -> next string

endp
;====================================================================


;====================================================================
;			 | PrFrame |
;--------------------------------------------------------------------
; Prints colored rectangular frame of given size 
;                                        from top left corner pos
;--------------------------------------------------------------------
; Expects: es -> video memory
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

    mov al, cs:[si + 0]    ; first line
    mov bl, cs:[si + 1]
    mov dl, cs:[si + 2]

    DrawLine

    mov al, cs:[si + 3]    ; inner lines
    mov bl, cs:[si + 4]
    mov dl, cs:[si + 5]

??LineLoop: DrawLine
            dec bh 
            test bh, bh
            jnz ??LineLoop
    
    mov al, cs:[si + 6]    ; last line
    mov bl, cs:[si + 7]
    mov dl, cs:[si + 8]

    DrawLine

    add cl, 2           ; restore origin value

ret
endp
;====================================================================

; data
ScrWidth equ 160d