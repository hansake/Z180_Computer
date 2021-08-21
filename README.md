# Z180_Computer
## Design of a Z180 computer.

Includes a Z180 CPU which has a simple MMU extending the 64KB lagical address range to a physical
address range of 1MB. Ths Z180 computer also includes 1MB of RAM memory and 256KB of EPROM memory.
The lower 256KB physical memory is switchable between EPROM and RAM.
The logic for memory selection is implemented in an ATF22V10 PLD.
PLD programmer: [hansake/PLD_programmer: GAL/PLD programmer used to program Atmel ATF22V10 and ATF16V8.](https://github.com/hansake/PLD_programmer).

A manual reset connector is available. The design is a bit peculiar as reset is made when the reset switch opens, this is to make use of the
MCP130 supervisory circuit to create a stable reset when the supply voltage is out of bounds or the reset switch is pressed.

The interfaces include two RS-232 ports, two SPI interfaces to use with SD cards.
A SD Card Adapter is needed as an interface between SPI and the SD cards.
* [How to use the &quot;MicroSD Card Adapter&quot; with the Arduino Uno | Michael Schoeffler](https://mschoeffler.com/2017/02/22/how-to-use-the-microsd-card-adapter-with-the-arduino-uno/).
* [SOLVED. Nrf24 (Mirf lib) + Micro SD-card works OK together - Using Arduino / Storage - Arduino Forum](https://forum.arduino.cc/t/solved-nrf24-mirf-lib-micro-sd-card-works-ok-together/347787/9)

An ATmega328P (the IC used in Arduino UNO) with SPI or Tx/Rx interfaces to the Z180 is also available.
The connectors to the ATmega328P are intended to make it possible to use Arduino shields to add
functionality to the Z180 computer. In the SPI connection between the Z180 CSI/O interface configured as a SPI master 
and the ATmega328P configured as a SPI slave.

The ATmega328P has a separate reset that is controlled by the Z180.

Using Z180 CSI/O as a SPI master seems possible according to: [SC126, v1.0, Circuit Explained | Small Computer Central](https://smallcomputercentral.wordpress.com/sc126-z180-motherboard-rc2014/sc126-v1-0-circuit-explained/). Using ATmega328P as SPI slave is described in: [Serial peripheral interface in AVR microcontrollers - Embedds](https://embedds.com/serial-peripheral-interface-in-avr-microcontrollers/).

The ATmega328P Tx and Rx pins may be connected to the Z180 ASCI 1 Rx and Tx pins, or directly to one of the external RS-232 connectors via one of the MAX232 converters.

I am planning to program the ATmega328P with [Pocket AVR Programmer Hookup Guide - learn.sparkfun.com](https://learn.sparkfun.com/tutorials/pocket-avr-programmer-hookup-guide?_ga=2.127691909.94672799.1626256475-796128395.1619009331). 

My selection of components is mainly based on what I found in the component boxes tucked away in my basement.

## Jumper configuration

JP1 Tx Jumper
* Pin 1: Connected to channel 1 Tx D-sub output via RS-232
* Pin 2: Connected to channel 1 Tx from Z180
* Pin 3: Connected to Rx input on ATmega328P
* Pin 4: Connected to channel 1 Rx D-sub input via RS-232

JP2 Rx Jumper
* Pin 1: Connected to channel 1 Rx D-sub input via RS-232
* Pin 2: Connected to channel 1 Rx to Z180
* Pin 3: Connected to Tx output on ATmega328P
* Pin 4: Connected to channel 1 Tx D-sub output via RS-232

JP1 & JP2 function
* Pin 1 to Pin 2: Tx and Rx from Z180 connected to RS-232 D-sub
* Pin 2 to Pin 3: Tx and Rx from Z180 connected to Rx and Tx on ATmega328P
* Pin 3 to Pin 4: RS-232 D-sub connected to Rx and Tx on ATmega328P

JP3
* Connection from Z180 CKS to SCK on ATmega328P SPI interface
JP4
* Connection from Z180 RXS to MISO on ATmega328P SPI interface
JP5
* Connection from Z180 TXS to MOSI on ATmega328P SPI interface
JP6
* Connection from bit 2 on output port 0x44 to SS on ATmega328P SPI interface

PJ3, JP4, JP5, JP6 function
* All jumpers in place to connect Z180 SPI interface to ATmega328P SPI interface

JP7 EPROM/FLASH jumper
* Pin 1 connected to +5V
* Pin 2 connected to pin 31 on U1
* Pin 3 connected to /WR on Z180

JP7 Function
* Pin 1 to Pin 2: select EPROM in U1 (for example M27C2001)
* Pin 2 to Pin 3: select FLASH in U1 (for example SST39SF020)

JP8 ATmega328P reset function
* Pin 1: connected to RS-232 D-sub channel 1 DSR via RS-232 to logic and a 100nF capacitor
* Pin 2: connected to ATmega328P /RESET
* Pin 3: connection from bit 3 on output port 0x44 to control reset from Z180

JP8 Function
* Pin 1 to Pin 2: reset of ATmega328P from DSR on serial channel 1
* Pin 2 to Pin 3: reset of ATmega328P from Z180 by setting bit 3 to "1" on output port 0x44

## Output port functions

The function is selected by writing to the specified port (data bits, don't care)
* Write to port 0x40: select EPROM/FLASH in lower 256KB physical memory (data bits, don't care)
* Write to port 0x41: select RAM in lower 256KB physical memory (data bits, don't care)
* Write to port 0x42: LED off (data bits, don't care)
* Write to port 0x43: LED on (data bits, don't care)
* Write to port 0x44:
* - data bit 0 set to "1": select SD0 SPI FLASH
* - data bit 1 set to "1": select SD1 SPI FLASH
* - data bit 2 set to "1": select ATmega328P SPI interface
* - data bit 3 set to "1": reset from Z180 to ATmega328P (if LP8 pin 2 and pin 3 are connected)

## Testing the Z180 computer board

Sofar only some very simple test are run on this board. The AVR CPU is blinking one LED and outputs
text on the serial port.

The Z180 CPU is blinking another LED and outputs text on serial port 0 and 1. The test program also recieves
any character input on the serial ports.

The testprogram is copied to RAM and running from there.
