# BIT90
BIT90 home computer

# General Information
The BIT90 computer is an 8-bit home computer from 1983.
It can play colecovision games from cartridge or tape or it can be used as a basic program machine.
The BIT90 is a rare computer so there's not much information about it (yet) on the internet.
I have used it for many years in the eighties as my first home computer.
In this repository you find technical documentation, tools and basic programs I collected and wrote over time.

# Hardware
The code shared in this repository is tested and works on the following hardware:
- BIT90 Computer (PAL EU version)
- BASIC 3.1 ROM
- 32K Memory expansion card
- RS232 serial interface expansion card
- Parallel expansion card for BIT90 printer (not Centronics)
- Sanyo DR101 taperecorder
- 11.6" TFT Display with composite video + audio

Note: in the PAL version 3.1 of the BIT90 rom  30x24 lines of text are available instead of 32x24 text in the NTSC version.
This was a workaround for the video errors in the PAL RF TV module, that caused the most left part of the screen to be invisible.

# Basic
The BIT90 basic is similar to MSX and TI-99/4A. You can extend it with your own commands.
This is explained in the docs/application documentation.

# Decoding tools
-The bit90decode.py program decodes tape data to a binary file.
-The bit90bas.py program decodes binary code to a basic text file.
The demo folder contains an example howto do this.

# Documentation
The manual you can find here: https://www.retrocomputers.gr/media/kunena/attachments/47/BIT90manual.zip
The docs/system folder contains technical diagrams.
The docs/application folder contains additional info when the BIT90 is in "basic" mode.

# Mame emulator
The developers of Mame created a bit90 machine which is working excellent. 
There's no tape interface yet but you can load a basic program in memory uing the debugger.
I have created an example in the Mame folder on howto do this.

# To do
1. Share additional BASIC/Assembler programs after review:
- Simple games eg. Breakout, Othello, Memory
- Math / drawing apps
- Conway's game of LIFE (UI in BASIC / engine in Assembler)
- Z80 Assembler tools
- BASIC command extensions in assembler
- Custom text mode 50x24 characters, useable as BASIC extension

2. Look into a RC2014 retro hardware solution if it can run the BIT90 basic:
https://hackaday.io/project/159057-game-boards-for-rc2014

3. Create RS-232 communication program (rudimentary terminal emulation works)


