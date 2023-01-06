; z180sdio.s
;
; Assembler SPI and SD card routines for the CP/M BIOS to work
; with my DIY Z180 Computer using a CSI/O based SPI interface.
;
; You are free to use, modify, and redistribute
; this source code. No warranties are given.
; Hastily Cobbled Together 2021, 2022 and 2023
; by Hans-Ake Lund
;
.include "z180.inc"

    .public _putspi
    .public _getspi
	.public _spiselect
	.public _spideselect
	.public _addblk
	.public _blk2byte
	.public _jumpto


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



;/* Make block address to byte address
; * by multiplying with 512 (blocksize)
; */
;int blk2byte(unsigned char *)
_blk2byte:
	;dsk parameter in HL
	; shift left 8 bits
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	ld	(hl), 0
	; then shift left 1 bit
	dec	hl
	sla	(hl)
	dec	hl
	rl	(hl)
	dec	hl
	rl	(hl)
	ret

; Jump to address
_jumpto:
	jp (hl)		;jump to address

;/* Add block addresses
; */
;void addblk(unsigned char *, unsigned char *);
_addblk:
	;first dsk parameter in HL
	ld	de, 3	;put pointer to LSB in DE
	add	hl, de
	ld	e, l
	ld	d, h
	;second dsk parameter on stack
	ld	hl, 2
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	hl, 3	;put pointer to LSB in HL
	add	hl, bc

	ld	b, 4
	scf
	ccf
addit:
	ld	a, (de)
	adc	a, (hl)
	ld	(de),  a
	dec	de
	dec	hl
	djnz	addit
	ret

    .psect  _data

; Chip select latch value
csmem:
    .byte 00h

	.end

