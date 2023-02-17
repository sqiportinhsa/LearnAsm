.model tiny

locals ??

.code
org 100h

Start:	mov ax, 0b800h	; es -> vmem
	mov es, ax

	mov bh, 0bh	; set blue color in bh

	mov si, 160*7d + 160/2d - 40		; box for titles
	mov di, 160*9d + 160/2d + 40
	call PrFrame

	mov ah, 0eh				; start titles
	mov cx, 3

	xor si, si				; hex title
	mov di, 160*8d + HexSt

PHex:	mov al, HexW[si]
	mov word ptr es:[di], ax
	inc si
	add di, 2
	loop PHex

	xor si, si				; bin title
	mov di, 160*8d + BinSt
	mov cx, 3

PBin:	mov al, BinW[si]
	mov word ptr es:[di], ax
	inc si
	add di, 2
	loop PBin

	xor si, si				; dec title
	mov di, 160*8d + DecSt
	mov cx, 3

PDec:	mov al, DecW[si]
	mov word ptr es:[di], ax
	inc si
	add di, 2
	loop PDec

	mov si, 160*9d  + 160/2d - 40 		; create box 80*7
	mov di, 160*13d + 160/2d + 40
	call PrFrame

	mov di, 160*10d + 160/2d - 40 + 4	; write left column
	mov ah, 0eh

	mov al, 'a'			; 'a'
	mov word ptr es:[di], ax
	add di, 160d
	mov al, 'b'			; 'b'
	mov word ptr es:[di], ax
	add di, 160d

	mov cx, 3			; a + b
	xor si, si

SLoop:	mov al, SumP[si]
	mov word ptr es:[di], ax
	add di, 2
	inc si
	loop SLoop

	call GetNum		; a
	push bx			; save a

	mov dx, bx		; print bin
	mov ah, 0fh
	mov si, 160*10d + BinSt
	call PrBin
				; print hex:
	pop  dx			; restore a
	push dx			; save a
	mov si, 160*10d + HexSt
	call PrHex
				; print dec:
	mov bh, ah		; move color
	pop ax			; restore a
	push ax			; save a
	mov si, 160*10d + DecSt
	call PrDec

	call GetNum		; b
	push bx			; save b

	mov dx, bx		; print bin
	mov ah, 0fh
	mov si, 160*11d + BinSt
	call PrBin
				; print hex:
	pop  dx			; restore b
	push dx			; save b
	mov si, 160*11d + HexSt
	call PrHex
				; print dec:
	mov bh, ah		; move color
	pop ax			; restore b
	push ax			; save b
	mov si, 160*11d + DecSt
	call PrDec

	pop bx
	pop ax
	add ax, bx 		; sum
	push ax 		; save sum

	mov dx, ax		; print bin
	mov ah, 0fh
	mov si, 160*12d + BinSt
	call PrBin
				; print hex:
	pop  dx			; restore b
	push dx			; save b
	mov si, 160*12d + HexSt
	call PrHex
				; print dec:
	mov bh, ah		; move color
	pop ax			; restore b
	push ax			; save b
	mov si, 160*12d + DecSt
	call PrDec

	mov ax, 4c00h	; exit(0)
	int 21h

.data
HexW	db 'hex$'
DecW	db 'dec$'
BinW	db 'bin$'

HexSt   equ 160/2d - 40 + 70
DecSt	equ 160/2d - 40 + 14
BinSt	equ 160/2d - 40 + 30

SumP	db 'a+b$'

include binhex.asm

end Start