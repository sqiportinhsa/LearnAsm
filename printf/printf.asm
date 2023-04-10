section .text
global call_printf
extern printf

call_printf:
    pop qword [RetAddress]                 ; remove return adress from stack

    mov [StoreR9], r9
    mov [StoreR8], r8
    mov [StoreRCX], rcx
    mov [StoreRDX], rdx
    mov [StoreRSI], rsi
    mov [StoreRDI], rdi
 
    call printf

    mov rdi, [StoreRDI]
    mov rsi, [StoreRSI]
    mov rdx, [StoreRDX]
    mov rcx, [StoreRCX]
    mov r8,  [StoreR8]
    mov r9,  [StoreR9]

    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    call NewPrintf

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    call printf

    mov rdi, MyStr
    mov rsi, 10
    mov rdx, 2

    call printf

    push qword [RetAddress]

ret

;---------------------------------------------------------------------------------------------------

section .data
    HigherByteMask  equ 0xFF000000

    MaxDecLen equ 20
    buf_size  equ 256

    HexArr: db "0123456789abcdef"
    DecBuf  db MaxDecLen dup(0)
    StrBuf  db buf_size  dup(0)

    RetAddress dq 0

    MyStr: db "Hello world! %d %b :3", 0x0a, 0x00

    StoreR9  db 8 dup(0)
    StoreR8  db 8 dup(0)
    StoreRCX db 8 dup(0)
    StoreRDX db 8 dup(0)
    StoreRSI db 8 dup(0)
    StoreRDI db 8 dup(0)

section .text

;===================================================================================================
;                                       NewPrintf
;---------------------------------------------------------------------------------------------------
; Same func as printfs from stdio.h
;---------------------------------------------------------------------------------------------------
; Input: format srt and arguments in stack
; Destroys: rbx rcx rdx rsi rdi
;---------------------------------------------------------------------------------------------------

NewPrintf:
    push rbp 
    push rbx                            ; save old rbp & rbx, it's preserved
    lea rbp, [rsp + 8*3]                ; rbp -> 1st arg in stack (format line)
    mov rsi, [rbp]                      ; rsi -> format line
    lea rbp, [rsp + 8*4]                ; rbp -> 2nd arg

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

        cmp al, 'b'                     ; check borders of jump table
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
        pop rbx
        pop rbp
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
    
    .skip_sign:                     ; after skip or without it positive num is in rax
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

    mov rcx, MaxDecLen              ; len of dec format in DecBuf
    dec rdi

    .skip_high_zero:
        mov al, [rdi]
        cmp al, '0'
        jnz .break
        dec rdi
    loop .skip_high_zero

    inc rdi                         ; ! jumped to break => rdx = 0 => write last zero
    inc rcx

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
    
    .skip_high_byte_zero:
        mov r9, rdx
        shr r9, 7*8                 ; r9 = higher byte of rdx
        test r9, r9                 ; check higher byte for zero
        jnz .break                  ; stop if not zero byte found
        shl rdx, 8                  ; skip zero byte
    loop .skip_high_byte_zero

    .break: 
    shl rcx, 3              ; rcx *= 8 (rcx: byte counter -> bit counter)
    test rdx, rdx
    je .inc_for_zero

    .skip_high_bit_zero:
        mov r9, rdx
        shr r9, 8*8 - 1             ; r9 = higher bit of rdx
        test r9, r9                 ; check higher byte for zero
        jnz .write                  ; stop if not zero bit found
        shl rdx, 1                  ; skip zero byte
    loop .skip_high_bit_zero

    .inc_for_zero: inc rcx           ; if rcx == 0, rdx was 0 => write '0' 1 time

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
    add rax, buf_size + 2               ; ax = max pos in buf after writing (2 sym per byte)
    cmp rdi, rax                        ; check if buffer fits string + char
    js .skip_dump                       ; if fits continue writing to buf without dump

    mov r8, rsi                         ; save rsi
    call DumpBuf                        ; dump buffer
    mov rsi, r8                         ; restore rsi

    .skip_dump: 
    mov rdx, [rbp]
    mov rcx, 8*2                        ; reg number has 8 bytes, common counter 
                                        ; for skip high zero bytes and write non-zero bytes.
                                        ; for zero 8 skips and 1 writing of zero
    
    .skip_high_zero:
        mov r9, rdx
        shr r9, 7*8 + 4                 ; r9 = higher 4 bits of rdx
        test r9, r9                     ; check higher byte for zero
        jnz .write                      ; stop if not zero byte found
        shl rdx, 4                      ; skip zero byte
    loop .skip_high_zero

    inc rcx                             ; if rcx == 0, rdx was 0 => write '0' 1 time

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
    add rax, buf_size + 22              ; ax = max pos in buf after writing (63+1 bit = 21+1 sym)
    cmp rdi, rax                        ; check if buffer fits string + char
    js .skip_dump                       ; if fits continue writing to buf without dump

    mov r8, rsi                         ; save rsi
    call DumpBuf                        ; dump buffer
    mov rsi, r8                         ; restore rsi

    .skip_dump: 
    mov rdx, [rbp]
    mov rcx, 21                         ; rdx = 63 + 1 bit, 3 bit = 1 sym

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
        jnz .write                      ; stop if not zero bits found
        shl rdx, 3                      ; skip zero bits
    loop .skip_high_zero

    inc rcx                             ; if rcx == 0, rdx was 0 => write '0' 1 time

    .write:
        mov rax, rdx
        shr rax, 8*8 - 3                ; rax = al = higher 3 bits of rdx
        add al, '0'                     ; al := ascii code of num in al
        stosb
        shl rdx, 3                      ; go to next 3 bits
    loop .write

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
