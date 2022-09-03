# BIT90
BIT90 home computer

## General Information
The BIT90 computer is an 8-bit home computer from 1983.
It can play colecovision games from cartridge or tape or it can be used as a basic program machine.
The BIT90 is a rare computer so there's not much information about it (yet) on the internet.
I have used it for many years in the eighties as my first home computer.
In this repository you find technical documentation, tools and basic programs I collected and wrote over time.

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
This was a workaround for some video errors in the PAL RF TV module, that caused the most left part of the screen to be invisible.

## Basic
The BIT90 basic is similar to MSX and TI-99/4A. You can extend it with your own commands.
Some examples uploaded include:  
- Games Breakout, Othello, Memory.    
- Conway's game of LIFE (UI in BASIC / engine in Assembler).    
- Simple RS232 terminal that uses a BASIC extension for a 50x24 text mode.  
  

## Decoding tools
-The bit90decode.py program decodes tape data to a binary file.  
-The bit90bas.py program decodes binary code to a basic text file.  
The demo folder contains an example how to do this.  

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
  
2. Create RS-232 communication program to upload/download files (ie. memory dumps) to/from pc

3. Comparison of MSX, TI-99/4A and BIT90 Basic



