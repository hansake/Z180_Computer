The monitor implements a simple menu for upload of programs, test of memory and CPU,
SD card tests and loading and running CP/M 2.2.

```
=============================================
z180cpmon version 3.0, built 2023-01-06 18:40
Program is executing in: EPROM
Hdr: binstart: 0x0000, binsize: 0x79c4 (31172)
cmd (? for help):  ? - help
z180cpmon version 3.0, built 2023-01-06 18:40
Program is executing in: EPROM
Commands:
  ? - help
  a - set address for upload
  c - boot CP/M from EPROM
  d - dump memory content to screen
  e - set address for execute
  i - initialize SD card
  l - print SD card partition layout
  n - set/show block #N to read/write
  p - print block last read/to write
  q - test probe SD card
  r - read block #N
  s - print SD registers
  t - run test program
  u - upload code with Xmodem to 0x0000
      and execute at: 0x0000
  w - write block #N
  Ctrl-C to reload monitor from EPROM
cmd (? for help):  c - boot CP/M from EPROM
  but first initialize SD card  - ok
  and then find and print partition layout
      Disk partition sectors on SD card
       MBR disk identifier: 0x071a6f5a
 Disk     Start      End     Size Part Type Id
 ----     -----      ---     ---- ---- ---- --
 1 (A)     2048     4095     2048  MBR CP/M 0x52
 2 (B)     4096     6143     2048  MBR CP/M 0x52
 3 (C)     6144     8191     2048  MBR CP/M 0x52
 4 (D)     8192    10239     2048  MBR CP/M 0x52
CP/M 2.2 & Z180 BIOS v2.0 with SPI/SD card interface
(Ctrl-Z to reboot from EPROM)

A>dir 
A: DUMP     COM : SDIR     COM : SUBMIT   COM : ED       COM
A: STAT     COM : BYE      COM : RMAC     COM : CREF80   COM
A: LINK     COM : L80      COM : M80      COM : SID      COM
A: RESET    COM : WM       HLP : ZSID     COM : MAC      COM
A: TRACE    UTL : HIST     UTL : LIB80    COM : WM       COM
A: HIST     COM : DDT      COM : Z80ASM   COM : CLS      COM
A: SLRNK    COM : MOVCPM   COM : ASM      COM : LOAD     COM
A: XSUB     COM : LIB      COM : PIP      COM : SYSGEN   COM
A>
```

The assembler, compiler, linker etc. used to create the code is here: https://github.com/hansake/Z80_Computer/tree/main/software/tools
