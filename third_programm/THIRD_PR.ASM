.model tiny
.code

org 100h

Start:	mov ax, 0b800h
	mov es, ax

	xor si, si			;phr index
	mov bx, 160*4d + 160d/2 - 8	;to make phrase centered
	mov cx, 0fh			;loop counter
	mov ah, 1h			;first color

Letter: mov al, Phr[si]			;move si letter

	mov byte ptr es:[bx],   al	;letter
	mov byte ptr es:[bx+1], ah	;color

	add bx, 2			;++ index in video memory
	add ah, 1			;++ color number
	add si, 1			;++ phr index

	loop Letter  

	mov ax, 4c00h
	int 21h

.data
Phr	db 'I lost the game$'

end 	Start