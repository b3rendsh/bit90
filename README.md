# BIT90
BIT90 home computer

## General Information
The BIT90 is an 8-bit home computer from 1983. It can play Colecovision games from cartridge or tape, or it can be used as a BASIC computer. The BIT90 is a rare computer, the hardware is similar to the Colecovision,SV-328,SC-3000 and MSX1 family. The manufacturer Bit Corporation worked with Colecovision on some games and parts of it's popular console. I have used the BIT90 for many years in the eighties as my first home computer. Now it's a fun project to rediscover, reverse engineer and meanwhile learn modern day tools like Ghidra, Audacity, SDR, Python, etc. 
  
In this repository you find technical documentation, tools and BASIC programs I collected and wrote over time.

## Hardware
The code shared in this repository is tested and works on the following hardware:
- BIT90 Computer (PAL EU version)
- BASIC 3.1 ROM
- 32K Memory expansion card
- RS232 serial interface expansion card
- Parallel expansion card for BIT90 printer (not Centronics)
- Sanyo DR101 taperecorder
- 11.6" TFT Display with composite video + audio

Note: in the (PAL) version 3.1 of the BIT90 rom 30x24 characters are available in textmode instead of the 32x24 in the (NTSC) 3.0 version.
Due to some errors in the PAL RF TV module, the far left side of the screen is not visible. The composite out works just fine.  

## BASIC
The BIT90 BASIC is similar to MSX and TI-99/4A. You can extend it with your own commands.  
In the xbas folder there is an extended basic library. The documentation for that is in the xbas.asm source file.  
  
Some examples uploaded include:  
- The demo from Bit Corporation.  
- Games Breakout, Othello, Memory.    
- Conway's game of LIFE (UI in BASIC / engine in Assembler).    
- Simple RS232 terminal that uses a BASIC extension for a 50x24 text mode.  
  
Quickstart guide for use in mame:  
start mame in debug-mode: mame bit90 -debug  
start the machine with F5  
load a BASIC binary \*.bin file at address 8004   
run BIT90 command: CALL 12491  
  
Conversion from other BASIC systems:  
Converting TI-BASIC or any Microsoft BASIC version prior to 1983 (eg. BASIC-80 or Applesoft) is relatively easy. One limitation of BIT90 BASIC is that numeric variables are single precision floating point (4 bytes), no integers or double precision. Although the syntax is much the same as Microsoft BASIC versions, the internal structure and subroutines are unique and tailered for the BIT90. 

## Decoding tools
-The bit90decode.py program decodes tape data to a binary file.  
-The bit90bas.py program decodes a binary coded file to a basic text file.  
-The bit90bin.py program encodes a basic text file to a binary coded file.  
The demo folder contains an example how to use the decoding tools.  

## Documentation
In the docs folder there is the Operation Manual and additional info like hardware/system diagrams, usefull memory addresses and BASIC extension.  

## Mame emulator
The developers of Mame created a bit90 machine which is working excellent:  
http://adb.arcadeitalia.net/dettaglio_mame.php?game_name=bit90  
There's no tape interface yet but you can load a basic program in memory using the debugger.  
I have created an example in the Mame folder how to do this.  

## RS232
Communication program to upload/download files (ie. memory dumps) via the RS232 COM port to/from a PC.  

## Other
There is a RC2014 retro hardware solution which may run the BIT90 / Colecovision roms:  
https://hackaday.io/project/159057-game-boards-for-rc2014  
The main issue here is that you have to rewrite the console routines for keyboard input and text output, which is possible because there are hooks for it in the BIT90 RAM. Instead I decided to port BBC BASIC Z80 for CP/M to the BIT90, while preserving BIT90 specifics like tape load/save and plot graphics, and use my own xbas library for the console. I have published this "BBX80" BASIC OS in a separate repository.
