; z180aio.s
;
; Assembler input/output routines for the Z180 computer.
;
; Code for my DIY Z180 Computer. This program
; is assembled with Whitesmiths/COSMIC tools for Z80/Z180
;
; You are free to use, modify, and redistribute
; this source code. No warranties are given.
; Hastily Cobbled Together 2021, 2022 and 2023
; by Hans-Ake Lund

.include "z180.inc"

    .psect  _text

    .public _out
    .public _in
    .public _ledon
    .public _ledoff
    .public _putchar
    .public _getchar
    .public _putspi
    .public _getspi
	.public _spiselect
	.public _spideselect
    .public _jumpto
    .public _jumptoram
    .public _reload

; I/O C functions for the Z180 Computer
;
;/* Output byte to i/o port
; */
;void out(unsigned int ioport, unsigned char obyte)
_out:
    ld c, l         ; i/o port
    ld b, h
    ld hl, 2
    add hl, sp
    ld a, (hl)      ; byte to output
    out (c), a
    ret

;/* Input byte from i/o port
; */
;unsigned char in(unsigned int ioport)
_in:
    ld c, l         ; i/o port
    ld b, h
    in a, (c)
    ld c, a         ; byte that was input
    ld b, 0
    ret

;/* Status LED on
; */
;void ledon()
_ledon:
    out(LEDON), a
    ret

;/* Status LED off
; */
;void ledoff()
_ledoff:
    out(LEDOFF), a
    ret

;/* Print character on serial port 0
; */
;int putchar(char pchar)
_putchar:
    push de
    ld e, l
    ld bc, STAT0
putchk:
    in a, (c)
    and 00000010b   ; test bit 1 = TDRE: Transmit Data Register Empty
    jr z, putchk
    ld bc, TDR0
    out (c), e      ; output character
    ld a, e
    cp '\n'         ; put CR if LF
    jr nz, putnolf
    ld e, '\r'
    ld bc, STAT0
    jr putchk
putnolf:
    ld c, l
    ld b, h
    pop de
    ret

;/* Get character from serial port 0
; */
;int getchar()
_getchar:
    ld bc, STAT0
getchk:
    in a, (c)
    and 10000000b   ; test bit 7 = RDRF: Recieve data in FIFO
    jr z, getchk

    ld bc, RDR0
    in a, (c)       ; input character
    ld c, a
    ld b, 0
    ret

; Reverse bits in A reg
;
; Using registers A and L
;
; 17 bytes / 66 cycles
; From: http://www.retroprogramming.com/2014/01/fast-z80-bit-reversal.html
revbits:
    ld l,a
    rlca
    rlca
    xor l
    and 0aah
    xor l
    ld l,a
    rlca
    rlca
    rlca
    rrc l
    xor l
    and 066h
    xor l
    ret

;/* Output byte to SPI interface
; */
;void putspi(unsigned char pbyte)
_putspi:
    ld bc, CNTR
    in a, (c)       ; check that no transmit or reciecve is ongoing
    and 00110000b   ; test that RE and TE are both 0
    jr nz, _putspi
    ld bc, TRDR
    ld a, l
    call revbits
    out (c), a      ; load output byte
    ld bc, CNTR
    in a, (c)
    or 00010000b    ; set TE
    out (c), a
spisent:
    in a, (c)
    and 00010000b   ; test if TE reset
    jr nz, spisent  ; not yet
    ret

;/* Input byte from SPI interface
; */
;unsigned char getspi()
_getspi:
    ld bc, CNTR
    in a, (c)       ; check that no transmit or reciecve is ongoing
    and 00110000b   ; test that RE and TE are both 0
    jr nz, _getspi
    in a, (c)
    or 00100000b    ; set RE
    out (c), a
spirec:
    in a, (c)
    and 00100000b   ; test if RE reset
    jr nz, spirec   ; not yet
    ld bc, TRDR
    in a, (c)       ; get input byte
    call revbits
    ld c, a
    ld b, 0
    ret

;/* Select SPI for SD card 0
; */
;void spiselect()
_spiselect:
    ld bc, CSPORT
    ld a, (csmem)
    or 001h
    out (c), a
    ld (csmem), a
    ret

;/* Deselect SPI for SD card 0
; */
;void spideselect()
_spideselect:
    ld bc, CSPORT
    ld a, (csmem)
    and 0feh
    out (c), a
    ld (csmem), a
    ret

;/* Jump to address and put arguments in registers
; */
;void jumpto(unsigned int address, unsigned int arg1, unsigned int arg2)
_jumpto:
    push hl
    pop ix
    ld  hl, 2
    add hl, sp
    ld c, (hl)      ; arg1 -> reg BC (for loader; upload address)
    inc hl
    ld b, (hl)
    inc hl
    ld e, (hl)      ; arg2 -> reg DE (for loader; start execute address)
    inc hl
    ld d, (hl)
    jp (ix)         ; jump to address

;/* Jump to address after switching to RAM and put arguments in registers
; */
;void jumptoram(unsigned int address, unsigned int arg1, unsigned int arg2)
_jumptoram: ; copy the jump code to upper RAM before switching to lower RAM
    push hl
    ld de, ramjmpcode
    ld hl, jumpram
    ld bc, jumpramend - jumpram
    ldir
    pop ix
    ld  hl, 2
    add hl, sp
    ld c, (hl)      ; arg1 -> reg BC (for loader; upload address)
    inc hl
    ld b, (hl)
    inc hl
    ld e, (hl)      ; arg2 -> reg DE (for loader; start execute address)
    inc hl
    ld d, (hl)
    jp ramjmpcode

;Code fragment to copy to RAM
jumpram:
    out (RAMSEL),a  ; select RAM in lower 32KB logical address range
    jp (ix)         ; jump to address
jumpramend:

;/* Reload program from EPROM
; */
;void reload()
_reload:    ; copy the jump code to upper RAM before switching to EPROM
    push hl
    ld de, ereloadcode
    ld hl, ereload
    ld bc, ereloadend - ereload
    ldir
    pop hl
    jp ereloadcode

;Code fragment to copy to RAM
ereload:
    out (ROMSEL),a ; select EPROM in lower 32KB logical address range
    jp 0000h       ;jump to start of EPROM
ereloadend:

    .psect  _data

; Chip select latch value
csmem:
    .byte 00h

; RAM area to where jump code is placed
ramjmpcode:
    .byte 00h (jumpramend - jumpram)
ereloadcode:
    .byte 00h (ereloadend - ereload)

    .end

