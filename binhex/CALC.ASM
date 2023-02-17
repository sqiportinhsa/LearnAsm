.model tiny

locals ??

.code
org 100h

Start:	mov ax, 0b800h	; es -> vmem
	mov es, ax

	mov bh, 0bh	; set blue color in bh

	mov si, 160*5d  + 160/2d - 40 ; create box 80*7
	mov di, 160*12d + 160/2d + 40
	call PrFrame

	mov ax, 4c00h	; exit(0)
	int 21h

include binhex.asm

end Start