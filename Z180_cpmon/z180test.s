; test180.s
;
; Test program for the Z180 computer
; Modified 2022-12-02 for Whitesmiths/COSMIC
; Z80/Z180 assembler and C compiler
;
; testing:
;   - simple MMU setup
;   - RAM as stack
;   - Serial output port 0 & 1
;   - Serial input port 0 & 1
;   - MMU setup with Common Bank 0, Bank Area, Common Bank 1
;   - simple RAM test
;   - copy test program to RAM and execute
;   - switch to low RAM using MEMSEL
;   - test 74LS74 select outputs
;   - test all RAM using MMU and MEMSEL
;   - set no wait states for RAM access
;   - interupt test
;
; You are free to use, modify, and redistribute
; this source code. The software is provided "as is",
; without warranty of any kind.
; Hastily Cobbled Together 2021 by Hans-Ake Lund.
; Modified 2022-2023

.include "z180.inc"

    .psect _text

prgstart:
; Set up Stack Pointer (first push/call will wrap to 0xffff)
    ld sp, 0000h
    ; the hardware is supposed to be initialized by the
    ; program that is uploading this code

; Initialize timer 0
    ld bc, TMDR0L
    and 0ffh           ; set low byte, timer 0
    out (c), a
    ld bc, TMDR0H
    and 0efh           ; set high byte, timer 0
    out (c), a

    ld bc, TCR
    ld a, 00010001b    ; bit 4 TIE0 (Timer Interrupt Enable, timer 0)
                       ; bit 0 TDE0 (Timer Down Count Enable, timer 0)
    out (c), a

; Initialize internal interupts and enable
intinit:
    ld hl, ivblock
    ld a, h
    ld i, a
    ld a, l
    ld bc, IL
    out (c), a
    ei

    ld a, 0            ; set print indicator index
    ld (indindex), a
    ld a, 00010001b    ; set rotating bits for 74LS74 CS output
    ld (cspattern), a
    ld a, 0            ; reset interrupt indicator
    ld (gotint), a

    jp testloop

reload:
    out (ROMSEL),a     ; select EPROM in lower 32KB address range
    jp 0000h           ; jump to start of EPROM

; ASCI routines
; Output a character on port 0
; reg E contains character to output
asci0putc:
    ld bc, STAT0
    in a, (c)
    and 00000010b      ; test bit 1 = TDRE: Transmit Data Register Empty
    jr z, asci0putc    ; not empty yet
    ld a, e
    ld bc, TDR0
    out (c), a         ; output character
    ret

; Input a character from port 0
; reg E contains the character
; if E == 0 no character is available
asci0getc:
    ld e, 0
    ld bc, STAT0
    in a, (c)
    and 10000000b       ; test bit 7 = RDRF: Recieve data in FIFO
    ret z               ; empty
    ld a, e
    ld bc, RDR0
    in a, (c)           ; input character
    ld e, a
    ret

; Output a character string on port 0
; reg HL points to string to output
; the string is ended by 0
asci0pstr:
    ld a, (hl)
    or a
    ret z
    ld e, (hl)
    inc hl
    call asci0putc
    jr asci0pstr

; Output a character on port 1
; reg E contains character to output
asci1putc:
    ld bc, STAT1
    in a, (c)
    and 00000010b      ; test bit 1 = TDRE: Transmit Data Register Empty
    jr z, asci1putc    ; not empty yet
    ld a, e
    ld bc, TDR1
    out (c), a         ; output character
    ret

; Input a character from port 1
; reg E contains the character
; if E == 0 no character is available
asci1getc:
    ld e, 0
    ld bc, STAT1
    in a, (c)
    and 10000000b      ; test bit 7 = RDRF: Recieve data in FIFO
    ret z              ; empty
    ld a, e
    ld bc, RDR1
    in a, (c)          ; input character
    ld e, a
    ret

; Output a character string on port 1
; reg HL points to string to output
; the string is ended by 0
asci1pstr:
    ld a, (hl)
    or a
    ret z
    ld e, (hl)
    inc hl
    call asci1putc
    jr asci1pstr

; Test RAM
; reg bc: number of bytes to test
; reg hl: start address of test
; reg a; returns 0 if RAM ok, 1 if error
ramtest:
    ld a,0            ; reset RAM test error flag
    ld (ramerr),a
ramtstlop:
    ld e,00h
    ld (hl),e
    ld a,(hl)
    cp e
    jp z,ramtstff
    ld a,1
    ld (ramerr),a
ramtstff:
    ld e,0ffh
    ld (hl),e
    ld a,(hl)
    cp e
    jp z,ramtstnxt
    ld a,1
    ld (ramerr),a
ramtstnxt:
    inc hl
    dec bc
    ld a,b
    or c
    jr nz, ramtstlop
    ld a, (ramerr)
    ret

; Main test loop
testloop:
    ld a, (indindex)
    and 1
    jr z, ledoff
    out(LEDON), a
    jr ledend
ledoff:
    out(LEDOFF), a
ledend:
    ld hl, asci0txt
    call asci0pstr
    ld hl, indicator
    ld b, 0
    ld a, (indindex)
    ld c, a
    add hl, bc
    ld e, (hl)
    call asci0putc
    ld hl, built
    call asci0pstr
    call asci0getc
    ld a, e
    or a
    jp z, asci0noin
    cp 3 ; Ctrl-C
    jp z, reload
    call asci0putc
    ld hl, inptxt
    call asci0pstr
asci0noin:

    ld hl, asci1txt
    call asci1pstr
    ld hl, indicator
    ld b, 0
    ld a, (indindex)
    ld c, a
    add hl, bc
    ld e, (hl)
    call asci1putc
    ld hl, built
    call asci1pstr
    call asci1getc
    ld a, e
    or a
    jp z, asci1noin
    call asci1putc
    ld hl, inptxt
    call asci1pstr
asci1noin:

;Indicator index for messages
    ld a, (indindex)
    inc a
    and 00000011b
    ld (indindex), a

;Chip Select and reset outputs
    ld a, (cspattern)
    out (CSPORT), a
    rlca
    ld (cspattern), a

; Test RAM

; Enable RAM in low memory
    ld a, 1
    out (RAMSEL), a       ; select RAM instead of EPROM from address 0

; Test physical RAM
    ld ix, ramtsttab
ramtloop:
    ld l, (ix + 0)
    ld h, (ix + 1)
    ld a, h
    or l
    jr z, ramtend         ; end of test table
    ld a, (ix + 2)
    ld bc, BBR
    out (c), a

    call asci0pstr
    ld l, (ix + 0)
    ld h, (ix + 1)
    call asci1pstr
    ld l, (ix + 3)
    ld h, (ix + 4)
    ld c, (ix + 5)
    ld b, (ix + 6)
    call ramtest
    or a
    jr z, ramisok
    ld hl, ramtxterr
    call asci0pstr
    ld hl, ramtxterr
    call asci1pstr
    jr ramtnxt
ramisok:
    ld hl, ramtxtok
    call asci0pstr
    ld hl, ramtxtok
    call asci1pstr
ramtnxt:
    ld bc, 7
    add ix, bc
    jr ramtloop
ramtend:

; Test if interupt recieved and print
    ld a, (gotint)        ; Interupt recieved?
    or a
    jp z, prtnoint        ; no
    ld hl, int_msg
    call asci0pstr
    ld hl, int_msg
    call asci1pstr
    jr prtintend
prtnoint:
    ld hl, no_int_msg
    call asci0pstr
    ld hl, no_int_msg
    call asci1pstr
prtintend:

; Enable EPROM in low memory
    ld a, 0
    out (ROMSEL), a

; Restore Bank Area
    ld a, 040h
    ld bc, BBR
    out (c), a

    jp testloop

asci0txt:
    .text "ASCI port 0 "
    .byte 0
asci1txt:
    .text "ASCI port 1 "
    .byte 0

indicator:
    .byte '|', '/', '-', '\\'

built:
    .text "Test program for Z180 computer, z180test\r\n"
    .text "assembled and linked with Whitesmiths/COSMIC tools\r\n"
    .byte 0

inptxt:
    .text " <- was recieved\r\n"
    .byte 0

int_msg:
    .text "Interupt from timer 0\r\n", 0
no_int_msg:
    .text "No interupt from timer 0\r\n", 0

; RAM test table
ramtsttab:
    .word ramtxt0  ; test message, end of table if NUL
    .byte 000h     ; BBR
    .word 00000h   ; logical test start address
    .word 0f000h   ; size of RAM block to test

    .word ramtxt1  ; test message
    .byte 00eh     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt2  ; test message
    .byte 01ch     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt3  ; test message
    .byte 02ah     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt4  ; test message
    .byte 038h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt5  ; test message
    .byte 046h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt6  ; test message
    .byte 054h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt7  ; test message
    .byte 062h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt8  ; test message
    .byte 070h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt9  ; test message
    .byte 07eh     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt10 ; test message
    .byte 08ch     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt11 ; test message
    .byte 09ah     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt12 ; test message
    .byte 0a8h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt13 ; test message
    .byte 0b6h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt14 ; test message
    .byte 0c4h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt15 ; test message
    .byte 0d2h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt16 ; test message
    .byte 0e0h     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt17 ; test message
    .byte 0eeh     ; BBR
    .word 01000h   ; logical test start address
    .word 0e000h   ; size of RAM block to test

    .word ramtxt18 ; test message
    .byte 0fch     ; BBR
    .word 01000h   ; logical test start address
    .word 02000h   ; size of RAM block to test

    .word 0        ; end of table

ramtxtok:
    .text " - OK"
    .byte '\r', '\n'
    .byte 0

ramtxterr:
    .text " - ERROR"
    .byte '\r', '\n'
    .byte 0

ramtxt0:
    .text "Test physical RAM 0x00000 - 0x0efff"
    .byte 0

ramtxt1:
    .text "Test physical RAM 0x0f000 - 0x1cfff"
    .byte 0

ramtxt2:
    .text "Test physical RAM 0x1d000 - 0x2afff"
    .byte 0

ramtxt3:
    .text "Test physical RAM 0x2b000 - 0x38fff"
    .byte 0

ramtxt4:
    .text "Test physical RAM 0x39000 - 0x46fff"
    .byte 0

ramtxt5:
    .text "Test physical RAM 0x47000 - 0x54fff"
    .byte 0

ramtxt6:
    .text "Test physical RAM 0x55000 - 0x62fff"
    .byte 0

ramtxt7:
    .text "Test physical RAM 0x63000 - 0x70fff"
    .byte 0

ramtxt8:
    .text "Test physical RAM 0x71000 - 0x7efff"
    .byte 0

ramtxt9:
    .text "Test physical RAM 0x7f000 - 0x8cfff"
    .byte 0

ramtxt10:
    .text "Test physical RAM 0x8d000 - 0x9afff"
    .byte 0

ramtxt11:
    .text "Test physical RAM 0x9b000 - 0xa8fff"
    .byte 0

ramtxt12:
    .text "Test physical RAM 0xa9000 - 0xb6fff"
    .byte 0

ramtxt13:
    .text "Test physical RAM 0xb7000 - 0xc4fff"
    .byte 0

ramtxt14:
    .text "Test physical RAM 0xc5000 - 0xd2fff"
    .byte 0

ramtxt15:
    .text "Test physical RAM 0xd3000 - 0xe0fff"
    .byte 0

ramtxt16:
    .text "Test physical RAM 0xe1000 - 0xeefff"
    .byte 0

ramtxt17:
    .text "Test physical RAM 0xef000 - 0xfcfff"
    .byte 0

ramtxt18:
    .text "Test physical RAM 0xfd000 - 0xfefff"
    .byte 0

; Timer interrupt
inttimer:
    push af
    push bc
    ld a, 1
    ld (gotint), a
    ld bc, TCR
    in a, (c)
    ld bc, TMDR0L
    in a, (c)
    ld bc, TMDR0H
    in a, (c)
    pop bc
    pop af
    ei
    reti

; Interrupt routines, dummy for unused devices
intdummy:
    ei
    reti

; Interupt vectors for internal devices
; make sure that the block is on an even 32 byte address
ivstart:
.if ivstart & 0x001fh
    .byte 00h (32 - ((ivstart - prgstart) & 0001fh))
.endif

ivblock:
ivint1:    .word intdummy
ivint2:    .word intdummy
ivprt0:    .word inttimer
ivprt1:    .word intdummy
ivdma0:    .word intdummy
ivdma1:    .word intdummy
ivcsio:    .word intdummy
ivasci0:   .word intdummy
ivasci1:   .word intdummy

prgend:      ;end address for copied code and constants from EPROM to RAM

    .psect _data

; The rest of RAM is for variables and stack

indindex:    ; indicator index for printout
    .byte 0

cspattern:   ; rotating bits for 74LS74 CS output
    .byte 0

ramerr:      ; RAM test error flag
    .byte 0

gotint:      ; interrupt indicator
    .byte 0

.end

