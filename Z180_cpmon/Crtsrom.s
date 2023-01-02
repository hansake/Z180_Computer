; Crtsrom.s
;
; Modified 2022 by Hans-Ake Lund
;
;   SAMPLE STARTUP CODE FOR FREESTANDING SYSTEM
;   Copyright (c) 1989 by COSMIC (France)
;
; Code for my DIY Z180 Computer. This program
; is assembled with Whitesmiths/COSMIC tools for Z80/Z180
;

.include "z180.inc"

    .external z180hwinit
    .external _main
    .external __memory
    .external __toram
    .public _binsize
    .public _binstart
    .public _exit
    .public __text
    .public __data
    .public __bss
;
;   PROGRAM STARTS HERE SINCE THIS FILE IS LINKED FIRST
;
    .psect _text

__text:
    jp mmusetup       ; jump over the size and exec start header,
                      ; also a kind of file signature (0xc3, 0x07, 0x00)
_binsize:
    .word 0           ; the size of the binary file to be patched here
_binstart:
    .word __text      ; the start address of this program

mmusetup:

; Set up the Z180 MMU initially
;
; Common Bank 0, 32KB
;    logical: 0x0000 - 0x7fff
;             always start at 0x0000
;    physical: 0x00000 - 0x07fff, EPROM or start of low RAM if enabled
;              always start at 0x00000
; Bank Area, 28KB
;    logical: 0x8000 - 0xefff,
;             start given by <BA> = 08h (lower 4 bits of CBAR)
;             shifted to upper 4 bits of 16 bit logical address
;    physical: 0x48000 - 0x4efff, low RAM chip above EPROM
;              start given by BBR 8 bits = 040h
;              shifted to upper 8 bits of physical address
;              and added to logical address
; Common Bank 1, 4KB
;    logical: 0xf000 - 0xffff,
;             start given by <CA> = 0fh (upper 4 bits of CBAR)
;             shifted to upper 4 bits of 16 bit logical address
;    physical: 0xff000 - 0xfffff, end of high RAM chip
;              start given by CBR 8 bits = 0f0h
;              shifted to upper 8 bits of physical address
;              and added to logical address
;
; The MMU function is a bit mysterious but I learned that CBAR
; must be configured before CBR and BBR otherwise strange
; things will happen.

    ld a,0f8h             ; <CA><BA>
    ld bc, CBAR
    out (c), a
    ld a, 0f0h
    ld bc, CBR
    out (c), a
    ld a, 040h
    ld bc, BBR
    out (c), a

;   After that we must zero bss if needed
;
    ld  hl, __memory      ; __memory is the end of the bss
                          ; it is defined by the link line
    ld  de, __bss         ; __bss is the start of the bss (see below)
    sub a
    sbc hl, de            ; compute size of bss
    jr z, bssok           ; if zero do nothing
    ex de, hl
loop:
    ld (hl), 0            ; zero  bss
    inc hl
    dec de
    ld a, e
    or d
    jr nz, loop           ; any more left ???
bssok:

;
;   Set up stack
;
;   The code below sets up an 8K byte stack   
;   after the bss. This code can be modified
;   to set up stack in any other convenient way
;
    ld bc, __memory       ; get end of bss 
    ld ix, 8192           ; ix = 8K
    add ix, bc            ; ix = end of mem + 8k
    ld sp, ix             ; init sp
;
;
;   Perform ROM to RAM copy for initialized data
;   the -dprom option is specified on the compiler command line
;
    call __toram
;
;   Initialize hardware
;
    call z180hwinit
;
;
;   Then call main
;
    call _main
_exit:                   ; exit code
    jr  _exit            ; for now loop forever
;
;
    .psect _data
__data:                  ; define start of data
    .word 0              ; NULL cannot be a valid pointer
;
;
;
    .psect  _bss
__bss:                   ; define start of bss
    .end

