.model tiny
locals ??
.code
org 100h

;-------------------------------------------------------------------------
; Input Format:
; <pos_x> <pos_y> <wid> <col> <frame> <text>
; pos_x - horisontal coordinate of table's top left corner in symbols   
; pos_y - vertical   coordinate of table's top left corner in symbols 
;         note: count in symbols from 0
;         note: screen size in symbols is 80d x 25d
; wid   - frame width in symbols. keep in mind that text string max len
;         is 2 symbols lower because of borders.
;         feature: frame height is picked up automatically
; col   - color - number from 0 to 256. check technical help
;         to get full colors table
; frame - preset styles: single number fron 1 to 4. For user style
;         format use single 5 and then 9 ascii codes of symbols 
;         separated by spaces. Check  Example:
;         5 <1> <2> <3> <4> <5> <6> <7> <8> <9> 
;
;         preset styles:        1--2--3
;         1) single line        |     |     correspondence between
;         2) double line        4  5  6  <- symbols and its positions
;         3) asterisk           |     |     for user frame style
;         4) hearts             7--8--9
;
; text  - string that would be written in the frame
;         feature: autosplit to lines, autocentering in frame
;-------------------------------------------------------------------------

CallGetNum macro reg
    call GetNum     ; num in bx is lower than 256d => bl = num, bh = 0
    mov reg, bl     ; reg = num
    inc si          ; si -> next number
endm

Start:

    mov si, 80h     ; get amount of symbols got from cmd line
    mov al, [si]    ; al = amount
    xor ah, ah      ; ax = amount

    add si, ax               ; si -> last text byte
    inc si                   ; si -> first byte after the text
    mov byte ptr [si], '$'   ; set end of text

    mov si, 82h     ; start reading cmd line args
    
    CallGetNum cl   ; cl = pos_x
    CallGetNum ch   ; ch = pos_y
    CallGetNum dl   ; dl = width
    CallGetNum dh   ; dh = color

    mov al, ch
    mov bl, ScrWidth
    mul bl          ; ax = pos_y * ScrWidth -> 1st byte of pos_y str
    mov bp, ax      ; bp -> 1st byte of pos_y str
    xor ah, ah
    mov al, cl      ; ax = pos_x (shift from 1 sym of scr str in sym)
    shl ax, 1       ; ax = shift from 1 sym of scr str in bytes
    add bp, ax      ; bp -> top left corner of frame

    mov al, [si]    ; al = frame style num in ascii
    sub al, '1'     ; al = frame style num - 1
    add si, 2       ; si -> <1> or 1st text sym

    xchg cx, dx     ; cx = color, width

    cmp al, 4       ; check for user style
    jz ??UserStyle 

    mov bl, 9               ; size of style arr
    mul bl                  ; ax = shift from Style1
    mov bx, offset Style1   ; bx -> Style1
    add bx, ax              ; bx -> style 

    ??ContinueUserStyle:

    mov dx, 0b800h	        ; es -> vmem
	mov es, dx
    mov dh, cl              ; dh = width
    mov ah, ch              ; ah = color

    mov di, offset FreeMem  ; di -> free memory

    call TextInFrame

    mov ax, 4c00h	        ; exit(0)
	int 21h

??UserStyle: 
    push cx                 ; save cx
    mov cx, 9               ; amount of user symbols
    mov di, offset Style5   ; arr for user style

    ??GetNumLoop:
        CallGetNum [di]
        inc di
    loop ??GetNumLoop

    pop cx
    mov bx, offset Style5
    jmp ??ContinueUserStyle


.data
Style1  db  0dah, 0c4h, 0bfh, 0b3h, 020h, 0b3h, 0c0h, 0c4h, 0d9h
Style2  db  0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch
Style3  db  '**** ****'
Style4  db  003h, 003h, 003h, 003h, 0b0h, 003h, 003h, 003h, 003h
Style5  db  0, 0, 0, 0, 0, 0, 0, 0, 0 ; to write user style here

include frame.asm

FreeMem:
end Start