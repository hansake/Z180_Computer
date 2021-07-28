# Z180_Computer
## Initial design of Z180 computer. Not tested yet.

Includes a Z180 CPU which has a simple MMU extending the 64KB lagical address range to a physical
address range of 1MB. Ths Z180 computer also includes 1MB of RAM memory and 256KB of EPROM memory.
The lower 256KB physical memory is switchable between EPROM and RAM.
The logic for memory selection is implemented in an ATF22V10 PLD.
PLD programmer: [hansake/PLD_programmer: GAL/PLD programmer used to program Atmel ATF22V10 and ATF16V8.](https://github.com/hansake/PLD_programmer).

A manual reset connector is available. The design is a bit peculiar as reset is made when the reset switch opens, this is to make use of the
MCP130 supervisory circuit to create a stable reset when the supply voltage is out of bounds or the reset switch is opened.

The interfaces include two RS-232 ports, two SPI interfaces to use with SD cards.
A SD Card Adapter is needed as an interface between SPI and the SD cards.
* [How to use the &quot;MicroSD Card Adapter&quot; with the Arduino Uno | Michael Schoeffler](https://mschoeffler.com/2017/02/22/how-to-use-the-microsd-card-adapter-with-the-arduino-uno/).
* [SOLVED. Nrf24 (Mirf lib) + Micro SD-card works OK together - Using Arduino / Storage - Arduino Forum](https://forum.arduino.cc/t/solved-nrf24-mirf-lib-micro-sd-card-works-ok-together/347787/9)

An ATmega328P (the IC used in Arduino UNO) with SPI or Tx/Rx interfaces to the Z180 is also available.
The connectors to the ATmega328P are intended to make it possible to use Arduino shields to add
functionality to the Z180 computer. In the SPI connection between the Z180 CSI/O interface configured as a SPI master 
and the ATmega328P configured as a SPI slave.

The ATmega328P has a sepatate reset that is controlled by the Z180.

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
* Connection from bit2 on output port 0x44 to SS on ATmega328P SPI interface

PJ3, JP4, JP5, JP6 function
* All jumpers in place to connect Z180 SPI interface to ATmega328P SPI interface



