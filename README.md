# BIT90
BIT90 home computer

## General Information
The BIT90 is an 8-bit home computer from 1983. It can play Colecovision games from cartridge or tape, or it can be used as a BASIC computer. The BIT90 is a rare computer. Although this is speculative, it looks like a missing link between Colecovision and Spectravideo (SV-328), and from there to MSX. I have used it for many years in the eighties as my first home computer. Now it's a fun project to rediscover, reverse engineer and meanwhile learn modern day tools like Ghidra, Audacity, SDR, Python, etc. 
  
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
Due to some errors in the PAL RF TV module, the far left side of the screen is not visible.

## BASIC
The BIT90 BASIC is similar to MSX and TI-99/4A. You can extend it with your own commands.  
Some examples uploaded include: 
- The demo from Bit Corporation.  
- Games Breakout, Othello, Memory.    
- Conway's game of LIFE (UI in BASIC / engine in Assembler).    
- Simple RS232 terminal that uses a BASIC extension for a 50x24 text mode.  
  
Quickstart guide for use in mame:  
start mame in debug-mode: mame bit90 -debug  
in the debug window load binary M7800-*.bin files at address 7800.  
load all other binary *.bin files at address 8004 and then run BIT90 command: CALL 12491.  

Conversion from other BASIC systems:
Cnverting TI-BASIC or any Microsoft BASIC version prior to 1983 (eg. BASIC-80) is relatively easy.
One limitation of BIT90 BASIC is that numeric variables are single precision floating point, no integers or double precision.
The graphics commands are almost identical to TI and there are music notes to PLAY music like in MSX.
The "BIOS" is different than MSX and certainly the TI-99/4A.  
Programs that PEEK and POKE around in memory are more challenging to convert.

## Decoding tools
-The bit90decode.py program decodes tape data to a binary file.  
-The bit90bas.py program decodes a binary coded file to a basic text file.  
-The bit90bin.py program encodes a basic text file to a binary coded file.  
The demo folder contains an example how to use the decoding tools.  

## Documentation
The manual you can find here: https://www.retrocomputers.gr/media/kunena/attachments/47/BIT90manual.zip  
In the docs folder is additional info like hardware/system diagrams, usefull memory addresses and BASIC extension.

## Mame emulator
The developers of Mame created a bit90 machine which is working excellent:  
http://adb.arcadeitalia.net/dettaglio_mame.php?game_name=bit90  
There's no tape interface yet but you can load a basic program in memory using the debugger.  
I have created an example in the Mame folder how to do this.

## To do
1. Look into a RC2014 retro hardware solution if it can run the BIT90 roms:  
https://hackaday.io/project/159057-game-boards-for-rc2014  
  
2. Create RS-232 communication program to upload/download files (ie. memory dumps) to/from pc.




