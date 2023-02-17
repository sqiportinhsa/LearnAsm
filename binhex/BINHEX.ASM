.model tiny
.code

org 100h

Start:	mov ax, 0b800h
	mov es, ax

	mov ah, 9h
	mov dx, 01h
	xor si, si
	call PrBin

	mov ah, 0bh
	mov dx, 0A1h
	call PrHex

	mov ax, 64h
	mov bh, 0Ah
	call PrDec

	mov si, 160*5d  + 10d
	mov di, 160*10d + 20d
	call PrFrame

	mov ax, 4c00h  ; exit 0
	int 21h
	
;-----------------------------------------------------------
; Print colored number in binary system
;-----------------------------------------------------------
; Expects: 	es -> video memory
;
; Entry:	AH = color
;		DX = number
;		SI = start position
;
; Exit:		None
;
; Destroys:	SI, DX, AL
;-----------------------------------------------------------

PrBin	proc

	mov cx, 10h

??Next: mov al, dh			; 8 higher bytes of dx
	shr al, 7h
	and al, 1h			; highest byte of dx
	add ax, 48

	mov word ptr es:[si], ax	; move to video memory

	shl dx, 1h			; multiply dx to 2
	add si, 2h			; move index in vmem

	loop ??Next

	ret
	endp
;-----------------------------------------------------------
;			 | PrHex |
;-----------------------------------------------------------
; Prints colored number in hex system
;-----------------------------------------------------------
; Expects: es -> video memory
;
; Entry: AH = color
;	 SI = start position
;	 DX = number
;
; Exit: None
;
; Destroys: BX, DX, SI, CX, AL
;-----------------------------------------------------------

PrHex   proc
	mov cx, 04h

??Num:	mov bx, dx
	shr bx, 0ch
	mov al, HexArr[bx]	
	
	mov word ptr es:[si], ax

	shl dx, 4h
	add si, 2h	

	loop ??Num

	ret
	endp

;----------------------------------------------------------
;			 | PrDec |
;----------------------------------------------------------
; Prints colored number in dec system
;----------------------------------------------------------
; Expects: es -> video memory
;
; Entry: BH = color
;	 SI = start position
;	 AX = number
;
; Exit: None
;
; Destroy: AX, CX, DX, SI, DI
;----------------------------------------------------------

PrDec 	  proc

	  mov cx, 5h	; max number 2^16 has 5 digits
	  add si, 08h   ; move ptr to the last digit
	  mov di, 0ah   ; di = 10

??Digit:  xor DX, DX	; complement AX to dword	 

	  div DI	; (DX, AX) / 10
			; DX := num %  10
			; AX := num // 10
	  
	  add DL, 30h	; ascii '0'
	  mov DH, BH	; add color

	  mov word ptr es:[si], dx 	; move digit & color to vmem
	  sub si, 2h			; move ptr to prev digit

	  loop ??Digit

	  add si, 0Ah	; move SI to the end of number

	  ret
	  endp

;----------------------------------------------------------
;			 | PrFrame |
;----------------------------------------------------------
; Prints colored rectangular frame by top left
;                                  and lower right corners
;----------------------------------------------------------
; Expects: es -> video memory
;
; Entry: SI = top left  corner position
;	 DI = low right corner position
;	 BH = color
; 	 
; Exit: None
;
; Destroys: AX, DX, SI, DI
;----------------------------------------------------------

PrFrame proc

	mov AX, DI
	sub AX, SI	; diff between DI and SI
	xor DX, DX	; complement AX to dword

	push bx
	mov  bx, ScrWidth
				; AX := frame height
	div  bx			; DX := frame width

	mov  bl, 2		; div dx to 2
	xchg ax, dx
	div  bl
	xchg ax, dx
 
	pop  bx	

	mov BL, TLCorner		; set top left corner
	mov word ptr es:[si], bx
	add SI, ScrWidth

	mov BL, LRCorner		; ser low right corner
	mov word ptr es:[di], bx
	sub di, ScrWidth

	dec AX

	mov BL, VerLine			; draw vert lines
	mov CX, AX

??Vert: mov word ptr es:[si], bx
	mov word ptr es:[di], bx
	add si, ScrWidth
	sub di, ScrWidth
	loop ??Vert

	mov BL, LLCorner		; set low left corner
	mov word ptr es:[si], bx
	add SI, 2

	mov BL, TRCorner		; set top right corner
	mov word ptr es:[di], bx
	sub DI, 2

	dec DX

	mov BL, HorLine			; draw hor lines
	mov CX, DX

??Hor:	mov word ptr es:[si], bx
	mov word ptr es:[di], bx
	inc si
	inc si
	dec di
	dec di
	loop ??Hor

	ret
	endp


.data

HexArr db '0123456789ABCDEF'

HorLine  db '-'
VerLine  db '|'
TLCorner db '+'
TRCorner db '+'
LLCorner db '+'
LRCorner db '+'

ScrWidth equ 160d

end Start