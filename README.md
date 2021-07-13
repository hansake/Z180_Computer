# Z180_Computer
Initial design of Z180 computer. Not tested yet.

Includes a Z180 CPU which includes a simple MMU extending the 64KB lagical address range to a physical
address range of 1MB. Ths Z180 computer also includes 1MB RAM of memory and 128KB of EPROM memory.
The lower 128KB physical memory is switchable between EPROM and RAM.
The logic for memory selection is implemented in an ATF22V10 PLD.

The interfaces include two RS-232 ports, two SPI interfaces to use with SD cards.
A SD Card Adapter is needed as an interface between SPI and the SD cards.
[How to use the &quot;MicroSD Card Adapter&quot; with the Arduino Uno | Michael Schoeffler](https://mschoeffler.com/2017/02/22/how-to-use-the-microsd-card-adapter-with-the-arduino-uno/)

An ATmega328P (the IC used in Arduino UNO) with SPI or Tx/Rx interfaces to the Z180 is also available.
The connectors to the ATmega328P are intended to make it possible to use Arduino shields to add
functionality to the Z180 computer.

My selection of components is mainly based on what I found in the component boxes tucked away in the basement.
