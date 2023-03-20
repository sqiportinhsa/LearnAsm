section .text
global _start

_start: 
        mov rax, 0x01
        mov rdi, 1
        mov rsi, Msg
        mov rdx, MsgLen
        syscall

        mov rax, 0x3c
        xor rdi, rdi
        syscall

section .rodata
    Msg:   db "helloworldhehe", 0x0a
    MsgLen equ $ - Msg

    HigherByteMask     equ 0xFF00000000000000
    TwoHigherBytesMask equ 0xFFFF000000000000

    MaxDecLen equ 20

    HexArr: db "0123456789ABCDEF"
    DecBuf: times MaxDecLen db 0

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

    mov rax, 0x01                   ; prepare write syscall
    mov rdi, 0x01
    mov rsi, rbx                    ; rsi -> start of buffer
    mov rdx, rdi                    
    sub rdx, rdi                    ; calculate msg len
    syscall

    mov rdi, rdb                    ; rdi -> start of buffer
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
    pop rax
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

    mov rcx, MaxDecLen
    mov r8, rsi
    mov rsi, DumpBuf
    pop rax

    .digit_loop:
        xor rdx, rdx                ; complement rax to 2 regs
        div 0xA                     ; rdx := num % 10
                                    ; rax := num // 10

        xchg rdx, rax               ; rax = al = digit
        add al, '0'                 ; al = digit ascci code
        stosb
        xchg rdx, rax
    loop .digit_loop

    mov rcx, rsi
    sub rcx, DumpBuf                ; calc len of dec format

    .skip_high_zero:
        mov al, [rsi]
        cmp al, '0'
        jnz .load_number
        dec rsi
    loop .skip_high_zero

    .load_number:
        mov al, [rsi]
        stosb
        dec rsi
    loop .load_number

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
; Destroy: rax, rcx, rdx
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
    pop rdx
    mov rcx, 8                      ; reg number has 8 bytes, common counter 
                                    ; for skip high zero bytes and write non-zero bytes
                                    ; for zero 8 skips and 1 writing of zero
    
    .skip_high_zero:
        test rdx, HigherByteMask    ; check higher byte for zero
        jnz .break                  ; stop if not zero byte found
        shl rdx, 8                  ; skip zero byte
    loop .skip_high_zero

    .break: shl rcx, 3              ; rcx *= 8 (rcx: byte counter -> bit counter)

    .write:
        mov rax, rdx
        shr rax, 4*8 - 1            ; higher bit of rax
        add al, '0'                 ; get acsii code of 0 or 1 in rax
        stosb                       ; write to buffer
        shl rax, 1                  ; go to next bit
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
; Destroy: rax, rcx, rdx, r8
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
    pop rdx 
    mov rcx, 8                          ; reg number has 8 bytes, common counter 
                                        ; for skip high zero bytes and write non-zero bytes.
                                        ; for zero 8 skips and 1 writing of zero

    mov al, '0'                         ; write "0x"   
    stosb
    mov al, 'x'
    stosb
    
    .skip_high_zero:
        test rdx, HigherByteMask        ; check 2 higher byte for zero
        jnz .break                      ; stop if not zero byte found
        shl rdx, 8                      ; skip zero byte
    loop .skip_high_zero

    .break: shl rcx, 1                  ; rcx *= 2 (rcx: byte counter -> 4-bit counter)

    .write:
        mov r8, rdx
        shr r8, 8*7 + 4                 ; r8 = higher 4 bits of rdx
        mov al, [HexArr + r8]           ; get ascii of byte in r8
        stosb
        shl rax, 4                      ; go to next 4 bits
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
; Destroy: rax, rcx, rdx, r8
;---------------------------------------------------------------------------------------------------

PrintfOct:

    mov rax, rbx
    add rax, buf_size + 4*8 + 1         ; ax = max pos in buf after writing (0 + 4 sym per byte)
    cmp rdi, rax                        ; check if buffer fits string + char
    js .skip_dump                       ; if fits continue writing to buf without dump

    mov r8, rsi                         ; save rsi
    call DumpBuf                        ; dump buffer
    mov rsi, r8                         ; restore rsi

    .skip_dump: 
    pop rdx 
    mov rcx, 8                          ; reg number has 8 bytes, common counter 
                                        ; for skip high zero bytes and write non-zero bytes.
                                        ; for zero 8 skips and 1 writing of zero

    mov al, '0'                         ; write "0" for oct output start   
    stosb
    
    .skip_high_zero:
        test rdx, HigherByteMask        ; check higher byte for zero
        jnz .break                      ; stop if not zero byte found
        shl rdx, 8                      ; skip zero byte
    loop .skip_high_zero

    .break: shl rcx, 1                  ; rcx *= 2 (rcx: byte counter -> 4-bit counter)

    .write:
        mov rax, rdx
        shr rax, 8*7 + 4                ; rax = al = higher 4 bits of rdx
        add al, '0'                     ; al := ascii code of num in al
        stosb
        shl rax, 4                      ; go to next 4 bits
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
    pop rsi                         ; rsi -> start of string
    
    .external_loop:
        .internal_loop:             ; copy str to buf till full buf or end of str
            lodsb
            cmp al, '$'
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
;                                       PrintfPerc
;---------------------------------------------------------------------------------------------------
; proc for %% format output
;---------------------------------------------------------------------------------------------------
; Input: rbx -> start of buffer
;        rdi -> end of buffer
; Exit:  rdi, rbx -> start of buffer
; Destroy: rax, rdx, rsi
;---------------------------------------------------------------------------------------------------

PrintfPerc:

    mov rax, rbx
    add rax, buf_size + 1           ; ax = pos in buf after char writing
    cmp rdi, rax                    ; check if buffer fits string + char
    js .skip_dump                   ; if fits continue writing to buf without dump

    mov r8, rsi                     ; save rsi
    call DumpBuf                    ; dump buffer
    mov rsi, r8                     ; restore rsi

    .skip_dump:
    mov al, '%'
    stosb

ret