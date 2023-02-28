.model tiny
locals ??
.code
org 100h

Start:

    mov ax, 4c00h	; exit(0)
	int 21h

;====================================================================
;            | TextInFrame |
;--------------------------------------------------------------------
; Draws frame and prints text in it
;--------------------------------------------------------------------
; Expects: ES -> video memory
;
; Entry: BP = left corner of the table
;        SI = offset text array
;        DI = offset free memory   
;        BX = offset frame style
;        AH = color
;        DH = table width in symbols
;
; Exit: None
; 
; Destroys: AL, BX, CX, DX, SI, DI, BP
;--------------------------------------------------------------------

TextInFrame proc

    push bx dx si di           ; save style, width, text, len
    mov bh, dh                 ; frame width
    sub bh, 2                  ; string len = fr wid - borders
    call CountLines                 ; call
    mov bh, dh                 ; height
    mov di, bp                 ; pos in vmem
    pop bp dx cx si            ; restore len, text, width, style


    push dx di                 ; text, vmem
    call PrFrame                    ; call
    mov bh, cl                 ; frame width
    pop di si                  ; vmem, text

    add di, 160d               ; text starts 1 line above frame start
    inc di                     ; move text because of left border
    sub bh, 2                  ; string len = fr wid - borders
    call WriteText                  ; call

    ret
endp
;====================================================================

;====================================================================
;            | WriteText |
;--------------------------------------------------------------------
; Prints $-terminated text to screen using video memory 
; Feature: if text is longer than string length
; it would be written in several strings automatically
; Breaking line is carried out by spaces, using '-'
; for breaking words longer than string length
;--------------------------------------------------------------------
; Expects: ES -> video memory
; 
; Entry: ES:[DI] = position for 1st symbol
;        BP = offset len  array
;        SI = offset text array
;        AH = color
;        BH = line width in symbols 
;
; Exit: None
;
; Destroys: AL - sym for writing to vmem
;           CX - counter for loops
;           DX - store len & shift
;           DI - moved ptr in vmem 
;           SI - moved to the end of text arr
;           BP - moved to the end of len  arr
;--------------------------------------------------------------------

WriteText proc

    xor ch, ch

??LineLoop:
    mov dh, [bp]
    mov dl,  bh
    sub dl, dh
    shr dl, 1           ; dl = shift for string in sym
    shl dl, 1           ; dl = shift for string in bytes
    xor dh, dh          ; dx = shift for string in bytes
    add di, dx          ; di -> 1st sym of string

    mov dh, [bp]        ; dh = len of string in sym
                        ; dl = shift from left border

    test dx, dx
    jz ??Exit         ; stop if end of array

    mov cl, dh          ; set counter = str len

    ??SymLoop:
        mov al, [si]
        stosw
        inc si
        loop ??SymLoop

    cmp al, ' '
    jnz ??LongWord

    ??GoNextLine:

    shl dl, 1           ; dl = len of string in bytes 
    add dl, dh          ; dl = shitf from left brd in bytes

                        ; di -> 1st sym from border
    sub di, dx          ; on current string
    add di, ScrWidth    ; on next string

    inc bp
    jmp ??LineLoop

??LongWord:
    mov al, '-'
    stosw
    jmp ??GoNextLine

??Exit:
    ret

endp
;====================================================================


;====================================================================
;            | CountLines |
;--------------------------------------------------------------------
; Counts lines for writing with auto line breaking
;--------------------------------------------------------------------
; Expects: ES -> video memory
; 
; Entry: DI = offset len  array
;        SI = offset text array
;        AH = color
;        BH = line width in symbols 
;
; Exit:  DH = amount of strings
;        DI -> end of offset len array
;
; Destroys: AL, CX, DX, SI, DI
;--------------------------------------------------------------------

CountLines proc

    xor cx, cx          ; cl = pos in string in sym
                        ; ch = string number in sym

    xor dx, dx          ; dl = last ' ' pos in string
                        ; dh = last ' ' string number

    dec bh              ; count elems from 0

??SymLoop:
    mov al, [si]

    cmp al, '$'         ; stop if sym is $
    jz ??Exit

    cmp cl, bh          ; check string len
    jz ??BreakLine

    inc cl              ; go to next sym
    inc si

    cmp al, ' '
    jz ??NewSpace       ; renew last space's pos 

    jmp ??SymLoop

??BreakLine:
    cmp al, ' '
    jz ??StopOnSpace

    cmp ch, dh
    jnz ??LongWord

    xor ch, ch              ; calc written part len
    sub cl, dl 
    sub si, cx              ; return si to 1st word sym
                 
    mov cx, dx              ; cx -> 1st sym after ' ' 
    inc cl
    jmp ??GoNextLine

??LongWord:
    jmp ??GoNextLine

??StopOnSpace:
    mov dx, cx
    inc si
    jmp ??GoNextLine

??GoNextLine:
    mov [di], cl        ; save str len
    inc di

    inc ch              ; ch -> current string
    xor cl, cl          ; cl -> 1st sym of string

    jmp ??SymLoop


??NewSpace:
    mov dx, cx
    jmp ??SymLoop

??Exit:
    xor cx, cx
    mov [di], cx        ; end of strings len arr
    inc bh              ; return bh to origin value
    inc dh              ; counter from 0 -> from 1
    ret

endp
;====================================================================

;====================================================================
;			 | PrFrame |
;--------------------------------------------------------------------
; Prints colored rectangular frame by top left
;                                         and lower right corners
;--------------------------------------------------------------------
; Expects: es -> video memory
;
; Entry: DI = top left  corner position
; 	 SI = offset table of symbols
;    AH = color
;    CL = width  in symbols
;    BH = height in symbols
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
; Destroys: AL, BL, CH, DX, DI, SI
;--------------------------------------------------------------------

DrawLine macro 
        cld             ;; draws line 12........23
        stosw           ;;             ^        ^
        mov al, bl      ;;             |--------|
        rep stosw       ;;              cx times
        mov al, dl      ;; 1 - al, 2 - bl, 3 - dl
        stosw
        add di, ScrWidth
endm

PrFrame proc

    xor ch, ch          ; cx = cl = width in symbols

    sub cx, 2           ; width count for central sym
    mov dh, cl          ; save count

    sub bh, 2           ; height  count for central sym

    mov al, [si + 0]    ; first line
    mov bl, [si + 1]
    mov dl, [si + 2]

    DrawLine

    mov al, [si + 4]    ; inner lines
    mov bl, [si + 5]
    mov dl, [si + 6]

??LineLoop: mov cl, dh
            DrawLine
            dec bh 
            test bh, bh
            jnz ??LineLoop

    mov cl, dh          ; restore count
    
    mov al, [si + 7]    ; last line
    mov bl, [si + 8]
    mov dl, [si + 9]

    DrawLine

    mov cl, dh
    add cl, 2

ret
endp
;====================================================================

;====================================================================
;			 | GetNum |
;--------------------------------------------------------------------
; Expects: None
;
; Entry:   None
;
; Exit: BX = num
;
; Destroys: AX, BX, CX, DX
;--------------------------------------------------------------------

GetNum	proc

	xor bx, bx	; to store number
	xor dx, dx	; to store digit and 0Ah

	mov dh, 0Ah	; new num = num*10 + new digit
	mov cx, 05h	; max num in word is 5-digit

??Digit:
	xor ax, ax	; clean ax
	mov ah, 01h	; getc()
	int 21h		 

	cmp al, 0Dh	; if '\r' break
	je ??Break

	sub al, '0'	; get digit from ascii code
	mov dl, al	; save digit

	mov ax, bx	; bx * 10
	mul dh		
	mov bx, ax

	xor ax, ax	; clear ax
	mov al, dl	; restore digit
	add bx, ax	; bx += new digit

	loop ??Digit

??Break:
	ret
	endp
;====================================================================

.data

ScrWidth equ 160d

end Start