BIT90 RS232 COM program
-----------------------

Introduction
------------
The purpose is to load and save BIT90 programs or data on a PC via the RS232 interface.
The serial interface is preset to 2400 baud, 8 bits, no parity, 1 stop bit.
You can change this by patching the program.

Preparation
-----------
1. Connect BIT90 RS232 to PC serial port e.g. with a null modem cable.
2. BIT90: load and run "BIT90COM" program.
   This will load a small assembler communication program at RAM address 0x7500.
   It will remain in place until you switch off the BIT90 or reboot.
3. Initialize Windows PC serial interface, from command prompt:
    mode com1: to=on
    mode com1: 2400,n,8,1


LOAD on BIT90
-------------
1. BIT90 command: CLOAD
2. PC Windows cmd: type file.bin > com1:

To load machine code use the command CBLOAD START,LENGTH
START is the start address (decimal)
LENGTH is the length of the file (decimal)


SAVE from BIT90
---------------
1. PC Windows cmd: type com1: > file.bin
2. BIT90 command: CSAVE

To save machine code use the command CBSAVE START,LENGTH
START is the start address (decimal)
LENGTH is the length of the file (decimal)

On the PC wait for the timeout after the save is finished on the BIT90.

If there is no data transfer then the programs will timeout after appr. 20 seconds,
or if the data transfer stops then the programs will quit after a few seconds.

