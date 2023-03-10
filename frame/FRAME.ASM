.code

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
    mov bh, dh                 ; bh = frame width
    sub bh, 4                  ; string len = fr wid - borders
    call CountLines                 ; call
    mov bh, dh                 ; height
    mov di, bp                 ; pos in vmem
    pop bp dx cx si            ; restore len, text, width, style
    
    mov cl, ch                 ; cl = frame width
    add bh, 2                  ; table hight = #strings + borders
    push dx di                 ; text, vmem
    call PrFrame                    ; call
    mov bh, cl                 ; frame width
    pop di si                  ; vmem, text

    add di, 160d               ; text starts 1 line above frame start
    add di, 4                  ; move text because of left border
    sub bh, 4                  ; string len = fr wid - borders
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
    mov dh, [bp]        ; dh = str len

    test dh, dh         ; stop if end of array
    jz ??Exit           ; needed for ' ' ended last string

    mov dl,  bh         ; dl = line len
    sub dl, dh          ; dl = free spaces in line
    inc dl              ; dl = free spaces + 1 to round shift up
    shr dl, 1           ; dl = shift for string in sym (free / 2)
    shl dl, 1           ; dl = shift for string in bytes
    xor dh, dh          ; dx = shift for string in bytes
    add di, dx          ; di -> 1st sym of string

    mov dh, [bp]        ; dh = str len
                        ; dl = start of str's 1st sym 
                        ;      from left board in bytes


    mov cl, dh          ; set counter = str len

    ??SymLoop:
        mov al, [si]
        stosw
        inc si
        loop ??SymLoop  

    mov al, [si]        ; stop if end of text
    cmp al, '$'         ; needed for 1-string text case
    jz ??Exit

    cmp al, ' '         ; if there isnt ' ' after last sym we need 
    jnz ??LongWord      ; '-' to split the word into two parts

    inc si              ; skip printing ' '

    ??GoNextLine:

    shl dh, 1           ; dl = len of string in bytes 
    add dl, dh          ; dl = current shitf from left brd in bytes 
    xor dh, dh

                        ; di -> 1st sym from border
    sub di, dx          ; on current string
    add di, ScrWidth    ; on next string

    inc bp
    jmp ??LineLoop

??LongWord:             ; '-' was counted for string len, the last
    sub di, 2           ; sym is extra. replace it symbol with '-'.
    mov al, '-'
    stosw
    dec si              ; extra sym was counted to be on next line
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

    dec dh              ; dh < 0 before first space
                        ; for long word on first string case

??SymLoop:
    mov al, [si]        ; al = sym

    cmp al, '$'         ; stop if sym is $
    jz ??Exit

    cmp cl, bh          ; check string len. if equal - prev sym
    jz ??BreakLine      ; was last on this string

    inc cl              ; go to next sym
    inc si 

    cmp al, ' '
    jz ??NewSpace       ; renew last space's pos

    jmp ??SymLoop

??BreakLine:
    cmp al, ' '         ; last string sym was the last for a word
    jz ??StopOnSpace    ; current sym is a space

    cmp ch, dh          ; if there was no spaces on this line
    jnz ??LongWord      ; continue write this long word on next line

    xor ch, ch              
    sub cl, dl              ; cx = len of written part of last word 
    sub si, cx              ; return si to 1st word sym
                 
    mov cx, dx              ; cx -> 1st sym after ' ' 
    dec cx                  ; last sym has pos cx - 2, len = pos + 1
    jmp ??GoNextLine

??LongWord:             ; word len is more than string len.
    dec si              ; return the last sym on string to array.
                        ; the next str would be started with it
    jmp ??GoNextLine    ; on this pos would be '-' sym, 
                        ; '-' is counted in len.
                        ; cx = last sym pos + 1 = string len.

??StopOnSpace:              ; last string sym was the last for a word
    mov dx, cx              ; current symbol is a space, skip it 
    inc si                  ; and start new line with new word.
    jmp ??GoNextLine        ; remember that last space was here.
                            ; cx = last sym pos + 1 = string len

??GoNextLine:
    mov [di], cl        ; save str len
    inc di

    inc ch              ; ch -> current string
    xor cl, cl          ; cl -> 1st sym of string

    jmp ??SymLoop


??NewSpace:
    mov dx, cx          ; dx -> first sym of word after ' '
    jmp ??SymLoop

??Exit:
    mov [di], cl        ; len[di] = #symbols in last string
    inc di              
    mov dh, ch          ; dh = amount of strings

    xor cx, cx
    mov [di], cx        ; end of strings len arr
    inc dh              ; counter from 0 -> from 1
    ret

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


;====================================================================
;			 | GetNum |
;--------------------------------------------------------------------
; Reads number written in dec notation from memory 
;                                             and returns its value
;--------------------------------------------------------------------
; Expects: None
;
; Entry: SI = offset num 
;
; Exit: BX = num
;       SI -> ' ' after num
;
; Destroys: AX, BX, DH
;--------------------------------------------------------------------

GetNum	proc

	xor bx, bx	; to store number
	xor dh, dh	; to store 0Ah

	mov dh, 0Ah	; new num = num*10 + new digit

??Digit:
	xor ax, ax	; clear ax
	mov al, [si]	 

	cmp al, ' '	; space is the end of number
	je ??Break

	sub al, '0'	; get digit from ascii code

	xchg ax, bx	; bx * 10
	mul dh		
	xchg bx, ax

	add bx, ax	; bx += new digit
    inc si

	jmp ??Digit

??Break:
	ret
	endp
;====================================================================

.data

ScrWidth equ 160d