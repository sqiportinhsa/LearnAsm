.code

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
; Entry: DI = position for 1st symbol
;        DS = offset text array
;        AH = color
;        BH = line width  in symbols 
;
; Exit: None
;
; Destroys: AL, CX, DX, DS, SI
;---------------------------------------------------------

WriteText proc

    xor cx, cx          ; cl = pos in string in sym
                        ; ch = string number in sym

    xor dx, dx          ; dl = last ' ' pos in string
                        ; dh = last ' ' string number

    dec bh              ; num of last sym in str

??SymLoop:
    mov al, [ds]

    cmp al, '$'         ; stop if next sym is $
    jz ??Exit

    cmp cl, bh          ; check string len
    jz ??BreakLine

    stosw               ; write sym to vmem
    inc cl
    inc ds

    cmp al, ' '
    jz ??NewSpace       ; renew last space's pos 

    jmp ??SymLoop

??BreakLine:
    cmp al, ' '
    jz ??StopOnSpace

    cmp ch, dh
    jnz ??LongWord

    mov al, ' '         ; clear everything after last ' '
    xor ch, ch              ; calc sym amount to clean
    sub cl, dl 
    sub ds, cx              ; return ds to 1st word sym
    rep stosw               ; clear after ' '
                 
    mov cx, dx
    jmp ??GoNextLine

??LongWord:
    mov al, '-'
    stosw
    jmp ??GoNextLine

??StopOnSpace
    stosw
    jmp ??GoNextLine

??GoNextLine:
    mov si, cx          ; save cx
    xor ch, ch
    shl cl
    sub di, cx          ; di -> 1st sym of current string
    add di, ScrWidth    ; di -> 1st sym of next string

    mov cx, si          ; ch - prev string
    inc ch              ; ch - current string
    xor cl, cl          ; cl - 1st sym of string

    jmp ??SymLoop


??NewSpace:
    mov dx, cx
    dec dx
    jmp ??SymLoop

??Exit:
    inc bh  ; return bh to origin value
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

HorLine  db '-'
VerLine  db '|'
TLCorner db '+'
TRCorner db '+'
LLCorner db '+'
LRCorner db '+'

ScrWidth equ 160d

end Start