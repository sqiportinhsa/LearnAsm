section .text
global _start

_start: 
        mov rax, 0x01
        mov rdi, 1
        mov rsi, Msg
        mov rdx, MsgLen
        syscall

        push 127
        push 33
        push 100
        push 3802
        push love
        push -1
        push 0x30
        push 1
        push 1
        push 1
        push -1
        push String
        push Msg
        call Printf
        pop rax
        pop rax
        pop rax
        pop rax
        pop rax
        pop rax
        pop rax

        mov rax, 0x3c
        xor rdi, rdi
        syscall

;---------------------------------------------------------------------------------------------------

section .data
    HigherByteMask  equ 0xFF000000

    MaxDecLen equ 20
    buf_size  equ 256

    HexArr: db "0123456789ABCDEF"
    DecBuf  db MaxDecLen dup(0)
    StrBuf  db buf_size  dup(0)

    Msg:   db "-hehe %Y %e %% %s %d %b %o %x %c he", 0x0a, "%d %s %x %d%%%c%b", 0x0a, 0x00
    MsgLen equ $ - Msg

    String db "i wanna sleep", 0x00
    love   db "love", 0x00

section .text

;===================================================================================================
;                                       Printf
;---------------------------------------------------------------------------------------------------
; Same func as printfs from stdio.h
;---------------------------------------------------------------------------------------------------
; Input: format srt and arguments in stack
;---------------------------------------------------------------------------------------------------

Printf:
    lea rbp, [rsp + 8*1]                ; rbp -> 1st arg in stack (format line)
    mov rsi, [rbp]                      ; rsi -> format line
    lea rbp, [rsp + 8*2]                ; rbp -> 2nd arg

    mov rbx, StrBuf
    mov rdi, StrBuf

    .get_sym:
        mov rax, rbx
        add rax, buf_size + 1           ; ax = pos in buf after char writing
        cmp rdi, rax                    ; check if buffer fits string + char
        js .skip_dump                   ; if fits continue writing to buf without dump

        mov r8, rsi                     ; save rsi
        call DumpBuf                    ; dump buffer
        mov rsi, r8                     ; restore rsi

        .skip_dump:
        xor rax, rax
        mov al, [rsi]                   ; load next sym of format str

        test al, al                     ; check for end of str
        je .end

        cmp al, '%'                     ; check for argument
        jne .load_to_buf                ; load ordinary symbol if not %

        inc rsi                         ; get argument format
        mov al, [rsi]

        cmp al, 'b'                    
        js .load_to_buf
        cmp al, 'y'
        jns .load_to_buf

        call [call_table + (rax - 'b') * 8] ; (call_table - 8*'b') + rax*8
        add rbp, 8                          ; go to next arg in stack
        inc rsi                             ; go to next sym in string
        jmp .get_sym

        .load_to_buf:
        stosb
        inc rsi
        jmp .get_sym

    .end: 
        call DumpBuf
ret

;---------------------------------------------------------------------------------------------------


section .rodata
    call_table dq PrintfBin
               dq PrintfChar
               dq PrintfDec
               dq 10 dup(PrintfSym)
               dq PrintfOct
               dq 3 dup(PrintfSym)
               dq PrintfString
               dq 4 dup(PrintfSym)
               dq PrintfHex

section .text
;===================================================================================================
;                                       DumpBuf
;---------------------------------------------------------------------------------------------------
; writes text from buffer
;---------------------------------------------------------------------------------------------------
; Input: rbx -> start of buffer
;        rdi -> end of buffer
; Exit:  rdi, rbx -> start of buffer
; Destroy: rax, rdx, rsi 
;---------------------------------------------------------------------------------------------------

DumpBuf:

    mov rdx, rdi                    
    sub rdx, rbx                    ; calculate msg len
    mov rsi, rbx                    ; rsi -> start of buffer
    mov rax, 0x01                   ; prepare write syscall
    mov rdi, 0x01
    syscall

    mov rdi, rbx                    ; rdi -> start of buffer
ret

;===================================================================================================
;                                       PrintfChar
;---------------------------------------------------------------------------------------------------
; proc for %c format output
;---------------------------------------------------------------------------------------------------
; Input:   rbx -> start of buffer
;          rdi -> end of buffer
; Exit:    rbx -> start of buffer
;          rdi -> new end of buffer
; Destroy: rax 
;---------------------------------------------------------------------------------------------------

PrintfChar:

    mov rax, rbx
    add rax, buf_size + 1           ; ax = pos in buf after char writing
    cmp rdi, rax                    ; check if buffer fits string + char
    js .skip_dump                   ; if fits continue writing to buf without dump

    mov r8, rsi                     ; save rsi
    call DumpBuf                    ; dump buffer
    mov rsi, r8                     ; restore rsi

    .skip_dump:
    mov rax, [rbp]
    stosb

ret

;===================================================================================================
;                                       PrintfDec
;---------------------------------------------------------------------------------------------------
; proc for %d format output
;---------------------------------------------------------------------------------------------------
; Input:   rbx -> start of buffer
;          rdi -> end of buffer
; Exit:    rbx -> start of buffer
;          rdi -> new end of buffer
; Destroy: rax, rcx, rdx, r8
;---------------------------------------------------------------------------------------------------

PrintfDec:

    mov rax, rbx
    add rax, buf_size + MaxDecLen   ; ax = max pos in buf after writing (8 sym per byte)
    cmp rdi, rax                    ; check if buffer fits string + bin num
    js .skip_dump                   ; if fits continue writing to buf without dump

    mov r8, rsi                     ; save rsi
    call DumpBuf                    ; dump buffer
    mov rsi, r8                     ; restore rsi

    .skip_dump: 
    mov rax, [rbp]                  ; get number from stack
    mov rdx, rax

    shr rdx, 8*8 - 1                ; get sign bit of num
    test rdx, rdx                   ; if sign bit = 0 skip writing '-'
    je .skip_sign        

    mov rdx, rax                    ; save num in rdx
    mov al, '-'                     ; write "-" to strbuf
    stosb
    mov rax, rdx                    ; restore num in rax
    not rax                         ; num = -num - 1
    inc rax                         ; num = -num
    
    .skip_sign:                     ; after skipping or without it positive num to write is in rax
    mov rcx, MaxDecLen              ; set counter
    mov r8, rdi                     ; save rdi
    mov rdi, DecBuf                 ; write reversed num to special buffer
    mov r9, 0x0A                    ; set r9 = 10 to divide

    .digit_loop:
        xor rdx, rdx                ; complement rax to 2 regs
        div r9                      ; rdx := num % 10
                                    ; rax := num // 10

        xchg rdx, rax               ; rax = al = digit, rdx = num // 10
        add al, '0'                 ; al = digit asccii code
        stosb
        xchg rdx, rax               ; rax = num // 10 = new num
    loop .digit_loop

    mov rcx, rdi
    sub rcx, DecBuf                 ; calc len of dec format
    dec rdi

    .skip_high_zero:
        mov al, [rdi]
        cmp al, '0'
        jnz .break
        dec rdi
    loop .skip_high_zero

    .break:
    xchg r8, rdi                    ; r8  -> DecBuf end, rdi -> StrBuf
    xchg r8, rsi                    ; rsi -> DecBuf end, r8  -> Format String
    .load_number:
        mov al, [rsi]
        stosb
        dec rsi
    loop .load_number

    mov rsi, r8
ret


;===================================================================================================
;                                       PrintfBin
;---------------------------------------------------------------------------------------------------
; proc for %b format output
;---------------------------------------------------------------------------------------------------
; Input:   rbx -> start of buffer
;          rdi -> end of buffer
; Exit:    rbx -> start of buffer
;          rdi -> new end of buffer
; Destroy: rax, rcx, rdx, r9
;---------------------------------------------------------------------------------------------------

PrintfBin:

    mov rax, rbx
    add rax, buf_size + 8*8         ; ax = max pos in buf after writing (8 sym per byte)
    cmp rdi, rax                    ; check if buffer fits string + bin num
    js .skip_dump                   ; if fits continue writing to buf without dump

    mov r8, rsi                     ; save rsi
    call DumpBuf                    ; dump buffer
    mov rsi, r8                     ; restore rsi

    .skip_dump:
    mov rdx, [rbp]
    mov rcx, 8                      ; reg number has 8 bytes, common counter 
                                    ; for skip high zero bytes and write non-zero bytes
                                    ; for zero 8 skips and 1 writing of zero
    
    .skip_high_zero:
        mov r9, rdx
        shr r9, 7*8                 ; r9 = higher byte of rdx
        test r9, r9                 ; check higher byte for zero
        jnz .break                  ; stop if not zero byte found
        shl rdx, 8                  ; skip zero byte
    loop .skip_high_zero

    .break: shl rcx, 3              ; rcx *= 8 (rcx: byte counter -> bit counter)

    .write:
        mov rax, rdx
        shr rax, 8*8 - 1            ; higher bit of rax
        add al, '0'                 ; get acsii code of 0 or 1 in rax
        stosb                       ; write to buffer
        shl rdx, 1                  ; go to next bit
    loop .write

ret


;===================================================================================================
;                                       PrintfHex
;---------------------------------------------------------------------------------------------------
; proc for %x format output
;---------------------------------------------------------------------------------------------------
; Input:   rbx -> start of buffer
;          rdi -> end of buffer
; Exit:    rbx -> start of buffer
;          rdi -> new end of buffer
; Destroy: rax, rcx, rdx, r8, r9
;---------------------------------------------------------------------------------------------------

PrintfHex:


    mov rax, rbx
    add rax, buf_size + 2*9             ; ax = max pos in buf after writing (0x + 2 sym per byte)
    cmp rdi, rax                        ; check if buffer fits string + char
    js .skip_dump                       ; if fits continue writing to buf without dump

    mov r8, rsi                         ; save rsi
    call DumpBuf                        ; dump buffer
    mov rsi, r8                         ; restore rsi

    .skip_dump: 
    mov rdx, [rbp]
    mov rcx, 8                          ; reg number has 8 bytes, common counter 
                                        ; for skip high zero bytes and write non-zero bytes.
                                        ; for zero 8 skips and 1 writing of zero

    mov al, '0'                         ; write "0x"   
    stosb
    mov al, 'x'
    stosb
    
    .skip_high_zero:
        mov r9, rdx
        shr r9, 7*8                     ; r9 = higher byte of rdx
        test r9, r9                     ; check higher byte for zero
        jnz .break                      ; stop if not zero byte found
        shl rdx, 8                      ; skip zero byte
    loop .skip_high_zero

    .break: shl rcx, 1                  ; rcx *= 2 (rcx: byte counter -> 4-bit counter)

    .write:
        mov r8, rdx
        shr r8, 8*7 + 4                 ; r8 = higher 4 bits of rdx
        mov al, [HexArr + r8]           ; get ascii of byte in r8
        stosb
        shl rdx, 4                      ; go to next 4 bits
    loop .write

ret

;===================================================================================================
;                                       PrintOct
;---------------------------------------------------------------------------------------------------
; proc for %o format output
;---------------------------------------------------------------------------------------------------
; Input:   rbx -> start of buffer
;          rdi -> end of buffer
; Exit:    rbx -> start of buffer
;          rdi -> new end of buffer
; Destroy: rax, rcx, rdx, r8, r9
;---------------------------------------------------------------------------------------------------

PrintfOct:

    mov rax, rbx
    add rax, buf_size + 22 + 1          ; ax = max pos in buf after writing (max 22 for num + '0')
    cmp rdi, rax                        ; check if buffer fits string + char
    js .skip_dump                       ; if fits continue writing to buf without dump

    mov r8, rsi                         ; save rsi
    call DumpBuf                        ; dump buffer
    mov rsi, r8                         ; restore rsi

    .skip_dump: 
    mov rdx, [rbp]
    mov rcx, 8*8 - 1                    ; reg number has 8 bytes, skip higher 
                                        ; for skip high zero bytes and write non-zero bytes.
                                        ; for zero 8 skips and 1 writing of zero

    mov al, '0'                         ; write "0" for oct output start   
    stosb

    mov r9, rdx
    shr r9, 8*8 - 1                     ; write higher bit separately (64 = 1 + 21*3)
    shl rdx, 1                          ; skip higher bit
    test r9, r9                         ; if higher bit is zero processing is unneeded
    je .skip_high_zero 

    mov al, '1'                         ; higher byte \neq 0 \Leftarrow higher byte = 1, write 1
    stosb

    .skip_high_zero:
        mov r9, rdx
        shr r9, 8*8 - 3                 ; r9 = higher 3 bits
        test r9, r9                     ; check it for zero
        jnz .break                      ; stop if not zero bits found
        shl rdx, 3                      ; skip zero bits
        sub rcx, 3
    jmp .skip_high_zero

    .break:

    .write:
        mov rax, rdx
        shr rax, 8*8 - 3                ; rax = al = higher 3 bits of rdx
        add al, '0'                     ; al := ascii code of num in al
        stosb
        shl rdx, 3                      ; go to next 3 bits
        sub rcx, 3
    jne .write

ret

;===================================================================================================
;                                       PrintfString
;---------------------------------------------------------------------------------------------------
; proc for %s format output
;---------------------------------------------------------------------------------------------------
; Input:   rbx -> start of buffer
;          rdi -> end of buffer
; Exit:    rbx -> start of buffer
;          rdi -> new end of buffer
; Destroy: rax, rcx, rdx, r8, r9
;---------------------------------------------------------------------------------------------------

PrintfString:

    mov rcx, rbx
    add rcx, buf_size
    sub rcx, rdi                    ; cx = avaible space in buffer
    mov r8, rsi                     ; save rsi
    mov rsi, [rbp]                  ; rsi -> start of string
    
    .external_loop:
        .internal_loop:             ; copy str to buf till full buf or end of str
            lodsb
            test al, al
            je .break
            stosb
        loop .internal_loop

        mov r9, rsi                 ; save rsi
        call DumpBuf                ; dump buffer
        mov rsi, r9                 ; restore rsi

        mov cx, buf_size            ; renew buf size for int loop
    jmp .external_loop
    
    .break: mov rsi, r8

ret

;===================================================================================================

PrintfSym:

    push rax
    mov r9, rbp
    mov rbp, rsp
    call PrintfChar
    pop rax
    mov rbp, r9
    sub rbp, 8

ret
