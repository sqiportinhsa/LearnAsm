.model tiny
.code

org 100h

Start:	mov ax, 0b800h
	mov es, ax

	mov bx, 160d*4 + 160d/2
	
	mov byte ptr es:[bx], 65d
	mov byte ptr es:[bx+1], 3ch

	mov ax, 4c00h
	int 21h

end 	Start