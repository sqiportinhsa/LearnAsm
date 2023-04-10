.code

;----------------------------------------------------------
;			   | strlen |
;----------------------------------------------------------
; returns the len of the given byte string terminated 
; with byte in bl
;----------------------------------------------------------
; Expects:
; Entry: es:[si] - adress of first byte
;        bl      - string ending
; Exit:  ax      - len of string
; Destroys: ax, cx, si
;----------------------------------------------------------

Strlen proc

mov cx, si ; adr of first byte

??Search: cld
          lodsw		; load 2 bytes to ax

	  cmp bl, al
	  je ??Odd

	  cmp bl, ah
	  je ??Even

	  jmp ??Search

??Odd:	  mov ax, si
	  sub ax, cx
	  dec ax
	  ret

??Even:	  mov ax, si
	  sub ax, cx
	  ret	  

endp

;----------------------------------------------------------


;----------------------------------------------------------
;			   | memcpy |
;----------------------------------------------------------
; copies count of bytes from the memory area pointed to by
; src to the memory area pointed to by dest
;----------------------------------------------------------
; Expects:
; Entry: ds:[si] - src
;	 	 es:[di] - dest
;	 	 cx      - count
; Exit: None
; Destroys: cx, si, di
;----------------------------------------------------------

Memcpy proc

	cld
	rep movsb
	ret

endp
;----------------------------------------------------------


;----------------------------------------------------------
;			   | strcpy |
;----------------------------------------------------------
; Copies bytes from the memory area pointed to by src
; to memory area pointed by dest before src string ending
;----------------------------------------------------------
; Expects: none
; Entry: ds:[si] - src
;	 	 es:[di] - dest
;	 	 bl      - end character
; Exit: none
; Destroys: ax, si, di
;----------------------------------------------------------

Strcpy proc

??Cpyw	cld
	lodsw		; get 2 bytes from src

	cmp al, bl	; check 1st for null term
	je ??Odd

	cmp ah, bl	; check 2nd for null term
	je ??Even

	stosw		; write 2 bytes to dest
	jmp ??Cpyw	; continue copying

??Odd:	stosb		; write 0-term
	ret

??Even: stosw		; write last byte and 0-term
	ret

endp
;----------------------------------------------------------


;----------------------------------------------------------
;			   | memset |
;----------------------------------------------------------
; Fills count bytes pointed by given ptr with given byte
;----------------------------------------------------------
; Expects:  None
; Entry:    es:[di] - pointer to the object to fill
;	    	al 	 - byte to copy
;	    	cx	 - count
; Exit:     None
; Destroys: cx, di
;----------------------------------------------------------

Memset proc

	cld
	rep stosb
	ret

endp
;----------------------------------------------------------


;----------------------------------------------------------
;			  | memcmp |
;----------------------------------------------------------
; compares the first count bytes from memory areas pointed
; to by given ptrs
;----------------------------------------------------------
; Expects:   None
; Entry:     es:[di] - first pointer
;	     	 ds:[si] - second pointer
; 	     	 cx	     - count
; Exit:	     cx = 0 for equal arrays
;	     	 cx < 0 if the first diff byte in 
;	     	 first arr is less then in second
;	     	 cx > 0 otherwise
; Destroys:  cx, si, di
;----------------------------------------------------------

Memcmp proc

??CMP:
	cld
	cmpsb

	js  ??First 	; second - first < 0
	jnz ??Second 	; second - first > 0 (not < and not =)
loop ??Cmp

	ret 			; after loop cx = 0

??Second:	
	xor cx, cx
	inc cx
	ret

??First:
	xor cx, cx
	dec cx
	ret

endp
;----------------------------------------------------------


;----------------------------------------------------------
;			  | strcmp |
;----------------------------------------------------------
; compares 2 strings lexicographically
;----------------------------------------------------------
; Expects: 	None
; Entry:	ds:[si] - first  string aka lhs
;			es:[di] - second string aka rhs
			bl 	- string end character
; Exit:		ax = 0 for equal strings
;			ax < 0 if lhs is before rhs
;			ax > 0 otherwise
; Destroys:	ax, si, di
;----------------------------------------------------------

Strcmp proc

??Cmp:	
	mov al, es:[di]
	mov ah, ds:[si]

	cld
	cmpsb
	js  ??Rhs 	; if byte in rhs is greater
	jnz ??Lhs	; if bytes are neq 
			    ;  but rhs isnt greater

	cmp al, bl
	je ??Eq		; strings are eq

	jmp ??Cmp

??Eq	xor ax, ax
	ret

??Rhs	mov ax, -1
	ret

?Lhs	mov ax, 1
	ret
endp
;----------------------------------------------------------