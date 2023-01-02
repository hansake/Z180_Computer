; Definitions for the Z180 computer
;
; You are free to use, modify, and redistribute
; this source code. The software is provided "as is",
; without warranty of any kind.
; Hastily Cobbled Together 2021 by Hans-Ake Lund.
; Modified 2022-2023

; Internal ports

; ASCI Registers port 0 and 1
.define CNTLA0 = 0000h  ; ASCI Channel Control Register A 0
.define CNTLA1 = 0001h  ; ASCI Channel Control Register A 1
.define CNTLB0 = 0002h  ; ASCI Control Register B 0
.define CNTLB1 = 0003h  ; ASCI Control Register B 1
.define STAT0 = 0004h   ; ASCI Status Register 0
.define STAT1 = 0005h   ; ASCI Status Register 1
.define TDR0 = 0006h    ; ASCI Transmit Data Register 0
.define TDR1 = 0007h    ; ASCI Transmit Data Register 1
.define RDR0 = 0008h    ; ASCI Receive Data FIFO 0
.define RDR1 = 0009h    ; ASCI Receive Data FIFO 1

; Timer Registers
.define TMDR0L = 000ch  ; Timer Data Register Channel 0L
.define TMDR0H = 000dh  ; Timer Data Register Channel 0H
.define RLDR0L = 000eh  ; Timer Reload Register 0L
.define RLDR0H = 000fh  ; Timer Reload Register 0H
.define TCR = 0010h     ; Timer Control Register
.define TMDR1L = 0014h  ; Timer Data Register Channel 1L
.define TMDR1H = 0015h  ; Timer Data Register Channel 1H
.define RLDR1L = 0016h  ; Timer Reload Register 1L
.define RLDR1H = 0017h  ; Timer Reload Register 1H

; DMA/WAIT Control Register
.define DCNTL = 0032h   ; DMA/WAIT Control Register

; Interrupt Control
.define IL = 0033h      ; Interrupt Vector Low Register
.define ITC = 0034h     ; Int/TRAP Control Register

; MMU Registers
.define CBR = 0038h     ; MMU Common Base Register
.define BBR = 0039h     ; MMU Bank Base Register
.define CBAR = 003ah    ; MMU Common/Bank Area Register

; CSIO Registers
.define CNTR = 000ah    ; CSIO Control/Status Register
.define TRDR = 000bh    ; CSIO Transmit/Receive Data Register

; External ports

; Select EPROM or RAM on address 0x0000 - 0x3ffff
.define ROMSEL = 40h    ; Write selects EPROM (reset condition)
.define RAMSEL = 41h    ; Write selects RAM

; LED on/off
.define LEDOFF = 42h    ; Write turns LED off (reset condition)
.define LEDON = 43h     ; Write turns LED on

; SPI device select and AVR reset
.define CSPORT = 44h    ; Write to bit 0 - 3 (reset condition, all 0)
                        ; Bit 0: select SD_CS0 when set to 1
                        ; Bit 1: select SD_CS1 when set to 1
                        ; Bit 2: select ATSS (AVR) when set to 1
                        ; Bit 3: reset AVR when set to 1
                        ;        if JP8 pin 2-3 connected

