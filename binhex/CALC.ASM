.model tiny

locals ??

.code
org 100h

Start:	mov ax, 0b800h	; es -> vmem
	mov es, ax

	mov bh, 0bh	; set blue color in bh

	mov si, 160*5d + 160/2d - 40		; box for titles
	mov di, 160*7d + 160/2d + 40
	call PrFrame

	mov ah, 0eh				; start titles
	mov cx, 3

	xor si, si				; hex title
	mov di, 160*6d + HexSt

PHex:	mov al, HexW[si]
	mov word ptr es:[di], ax
	inc si
	add di, 2
	loop PHex

	xor si, si				; bin title
	mov di, 160*6d + BinSt
	mov cx, 3

PBin:	mov al, BinW[si]
	mov word ptr es:[di], ax
	inc si
	add di, 2
	loop PBin

	xor si, si				; dec title
	mov di, 160*6d + DecSt
	mov cx, 3

PDec:	mov al, DecW[si]
	mov word ptr es:[di], ax
	inc si
	add di, 2
	loop PDec

	mov si, 160*7d  + 160/2d - 40 		; create box 80*7
	mov di, 160*12d + 160/2d + 40
	call PrFrame

	mov di, 160*8d + 160/2d - 40 + 4	; write left column
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