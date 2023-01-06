; z180hwinit.s
;
; Initialize hardware for the Z180 computer
;
; Code for my DIY Z180 Computer. This program
; is assembled with Whitesmiths/COSMIC tools for Z80/Z180
;
; You are free to use, modify, and redistribute
; this source code. No warranties are given.
; Hastily Cobbled Together 2021 and 2022
; by Hans-Ake Lund

.include "z180.inc"

    .psect  _text

    .public z180hwinit

z180hwinit:

    out(LEDON), a      ; status LED on while initializing hardware

; When running from RAM configure no memory wait states
    ld bc, DCNTL
    in a, (c)
    and 00111111b      ; reset MVI0 and MVI1
    out (c), a

; Initialize serial ports

; Initialize serial port 0
    ld a, 01100100b
            ; bit 7 = 0: MPE - disabled
            ; bit 6 = 1: RE - Rx enabled
            ; bit 5 = 1: TE - Tx enabled
            ; bit 4 = 0: RTS0 - set to low, RTS active (?)
            ; bit 3 = 0: MPBR/EFR - not used
            ; bit 2 - 0 = 100 - Start + 8 bit data + 1 stop
    ld bc, CNTLA0
    out (c), a

    ; set Baudrate: PHI / (PS * DR * SS) = Baud Rate
    ; 9216000 Hz / (30 * 16 * 1) = 19200 Baud
    ld a, 00100000b
            ; bit 7 = 0:  MPBT - disabled
            ; bit 6 = 0:  MP - disabled
            ; bit 5 = 1:  CTS/PS - prescale = 30 (PS as SS2-0 are not 111)
            ; bit 4 = 0:  PEO - ignored as no parity configured
            ; bit 3 = 0:  DR - Clock factor = 16
            ; bit 2 - 0 = 000:  SS2-SS0 - Divide Ratio: 1
    ld bc, CNTLB0
    out (c), a

; Initialize serial port 1
    ld a, 01100100b
            ; bit 7 = 0: MPE - disabled
            ; bit 6 = 1: RE - Rx enabled
            ; bit 5 = 1: TE - Tx enabled
            ; bit 4 = 0: RTS0 - set to low, RTS active (?)
            ; bit 3 = 0: MPBR/EFR - not used
            ; bit 2 - 0 = 100 - Start + 8 bit data + 1 stop
    ld bc, CNTLA1
    out (c), a

    ; set Baudrate: PHI / (PS * DR * SS) = Baud Rate
    ; 9216000 Hz / (30 * 16 * 1) = 19200 Baud
    ld a, 00100000b
            ; bit 7 = 0:  MPBT - disabled
            ; bit 6 = 0:  MP - disabled
            ; bit 5 = 1:  CTS/PS - prescale = 30 (PS as SS2-0 are not 111)
            ; bit 4 = 0:  PEO - ignored as no parity configured
            ; bit 3 = 0:  DR - Clock factor = 16
            ; bit 2 - 0 = 000:  SS2-SS0 - Divide Ratio: 1
    ld bc, CNTLB1
    out (c), a

; Initialize Clocked Serial I/O Port
    ld a, 00000001b
            ; bit 7 = 0:  EF - End Flag
            ; bit 6 = 0:  EIE - End Interrupt Enable - disabled
            ; bit 5 = 0:  RE - Receive Enable - disabled
            ; bit 4 = 0:  TE - Transmit Enable - disabled
            ; bit 2 - 0 = 001:  SS2, 1, 0 - Speed Select 2, 1, 0
            ;     divide ratio: 40
    ld bc, CNTR
    out (c), a

; Disable all external interrupts
    ld bc, ITC
    ld a, 00000000b
    out (c), a

    out(LEDOFF), a     ; status LED off
    ret

    .end

