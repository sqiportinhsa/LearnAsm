.model tiny
.code

org 100h

Start:    mov ah, 09h			; puts(dx)
	  mov dx, offset Message
	  int 21h

	  mov ax, 4c00h			; exit (0)
	  int 21h

Message:  db 'I lost the game$'

end       Start