.code

;====================================================================
;			 | PrBin |
;--------------------------------------------------------------------
; Print colored number in binary system
;--------------------------------------------------------------------
; Expects: 	es -> video memory
;
; Entry:	AH = color
;		DX = number
;		SI = start position
;
; Exit:		None
;
; Destroys:	SI, DX, AL
;--------------------------------------------------------------------

PrBin	proc

	mov cx, 10h

??Next: 
    mov al, dh	        ; 8 higher bytes of dx
	shr al, 7h
	and al, 1h			; highest byte of dx
	add ax, 48

	stosw

	shl dx, 1h			; multiply dx to 2

	loop ??Next

	ret
	endp
;====================================================================


;====================================================================
;			 | PrHex | 
;--------------------------------------------------------------------
; Prints colored number in hex system
;--------------------------------------------------------------------
; Expects: es -> video memory
;
; Entry: AH = color
;	 	 DI = start position
;	 	 DX = number
;
; Exit: DI -> 1st sym after num
;
; Destroys: BX, DX, DI, CX, AL
;--------------------------------------------------------------------

PrHex   proc
	mov cx, 04h 		; num in bx is 16-bit = 4 * 4 bit

??Num:	
    mov bx, dx
	shr bx, 0ch 		; 4 higher bits of num
	mov al, HexArr[bx]	; get ascii code 
	
	stosw 				; move digit with color to vmem
	shl dx, 4h 			; get next 4 higher bits

	loop ??Num

	ret
	endp
;====================================================================


;====================================================================
;			 | PrDec |
;--------------------------------------------------------------------
; Prints colored number in dec system
;--------------------------------------------------------------------
; Expects: es -> video memory
;
; Entry: BH = color
;	 DI = start position
;	 AX = number
;
; Exit: None
;
; Destroy: AX, CX, DX, SI, DI
;--------------------------------------------------------------------

PrDec proc

	mov cx, 5h	  ; max number 2^16 has 5 digits
	add di, 08h   ; move ptr to the last digit
	mov si, 0ah   ; di = 10

??Digit:  
    xor DX, DX	    ; complement AX to dword	 
	div SI	        ; (DX, AX) / 10
		            ; DX := num %  10
		            ; AX := num // 10
	  
	add DL, 30h	    ; ascii '0'
	mov DH, BH	    ; add color

	mov word ptr es:[si], dx 	; move digit & color to vmem
	sub di, 2h			        ; move ptr to prev digit

loop ??Digit

	add di, 0Ah	    ; move SI to the end of number

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
;---------------------------------------------------------------------

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

; data

HexArr db '0123456789ABCDEF'
ScrWidth equ 160d

end Start