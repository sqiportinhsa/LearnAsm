.code


;==========================================================
;            | TextInFrame |
;----------------------------------------------------------
; Draws frame and prints text in it
;----------------------------------------------------------
; Expects: ES -> video memory
;
; Entry: DI = position for 1st symbol
;        DS = offset text array
;        AH = color
;        BH = line width in symbols
;
; Exit: None
; 
; Destroys: 
;----------------------------------------------------------

TextInFrame proc




;==========================================================
;            | WriteText |
;----------------------------------------------------------
; Prints $-terminated text to screen using video memory 
; Feature: if text is longer than string length
; it would be written in several strings automatically
; Breaking line is carried out by spaces, using '-'
; for breaking words longer than string length
;----------------------------------------------------------
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
;---------------------------------------------------------

WriteText proc

    xor ch, ch

??LineLoop:
    mov dh, [bp]
    mov dl,  bh
    sub dl, dh
    shr dl              ; dl = shift for string in sym
    shl dl              ; dl = shift for string in bytes
    xor dh, dh          ; dx = shift for string in bytes
    add di, dx          ; di -> 1st sym of string

    mov dh, [bp]        ; dh = len of string in sym
                        ; dl = shift from left border

    jdxz ??Exit         ; stop if end of array

    mov cl, dh          ; set counter = str len

    ??SymLoop:
        mov al, [si]
        stosw
        inc si
        loop ??SymLoop

    cmp al, ' '
    jnz ??LongWord

    ??GoNextLine:

    shl dl              ; dl = len of string in bytes 
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
    inc bh  ; return bh to origin value
    ret

endp

;==========================================================


;==========================================================
;            | CountLinesAndLength |
;----------------------------------------------------------
; Counts lines for writing with auto line breaking
;----------------------------------------------------------
; Expects: ES -> video memory
; 
; Entry: DI = offset lengths array
;        SI = offset text    array
;        AH = color
;        BH = line width in symbols 
;
; Exit:  DH = amount of strings
;        DI = offset lengthes array
;
; Destroys: AL, CX, DX, DS, SI
;---------------------------------------------------------

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

??StopOnSpace
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
    mov [di], 0 ; end of strings len arr
    inc bh      ; return bh to origin value
    inc dh      ; counter from 0 -> from 1
    ret

endp

;==========================================================

;==========================================================
;            | CalcShift |
;----------------------------------------------------------
; Calculates shifts in bytes to make strings centered
;----------------------------------------------------------
; Expects: None
; 
; Entry: DI = offset length array
;        BH = max str len
;
; Exit:  DI = offset shift array
;
; Dectroys: AX, CX
;---------------------------------------------------------

CalcShift proc

    mov cx, di      ; save arr start 

??CalcLoop:
    mov al,  bh
    mov ah, [di]

    test ah, ah     ; end of arr
    jz ??Exit

    sub al, ah      ; al = spaces at line
    shr al          ; shift

    mov [di], al
    inc di
    jmp ??CalcLoop

??Exit:
    mov di, cx      ; restore arr start
    ret

endp
;==========================================================

;==========================================================
;			 | PrFrame |
;----------------------------------------------------------
; Prints colored rectangular frame by top left
;                                  and lower right corners
;----------------------------------------------------------
; Expects: es -> video memory
;
; Entry: DI = top left  corner position
; 	 DS = offset table of symbols
;    AH = color
;    CX = width  in symbols
;    BH = height in symbols
;
;    table:
;           1------2------3
;           |             |
;           4      5      6
:           |             |
:           7------8------9
;
; Exit: None
;
; Destroys: AX, BL, CX, DL, SI, DI
;----------------------------------------------------------

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

    sub cx, 2           ; width count for central sym
    mov si, cx          ; save count

    sub bh, 2           ; height  count for central sym

    mov al, [ds + 0]    ; first line
    mov bl, [ds + 1]
    mov dl, [ds + 2]

    DrawLine

    mov al, [ds + 4]    ; inner lines
    mov bl, [ds + 5]
    mov dl, [ds + 6]

??LineLoop: mov cx, si  
            DrawLine
            dec bh 
            test bh, bh
            jnz ??LineLoop

    mov cx, si          ; restore count
    
    mov al, [ds + 7]    ; last line
    mov bl, [ds + 8]
    mov dl, [ds + 9]

    DrawLine

ret
endp

;==========================================================

;==========================================================
;			 | GetNum |
;----------------------------------------------------------
; Expects: None
;
; Entry:   None
;
; Exit: BX = num
;
; Destroys: AX, BX, CX, DX
;----------------------------------------------------------

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
;==========================================================

.data

ScrWidth equ 160d

end Start