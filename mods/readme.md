# BIT90 Modifications
I made following modifications to the ROM BIOS and hardware.
Disclaimer/warning: use this information at your own risk, these changes can cause damage beyond repair. First check the system board revision, there may be differences.

## ROM 
### COLECO ROM 
1. Improve Colecovision BIOS compatibility:
   a. Boot sequence: check for cartridge code "55 AA" at address 0x8000 to directly start the cartridge.
   b. InitFont (0x1927), InitRAMSprt (0x1C66) and WrtVRAM (0x1D01): fixed the differences with the Colecovision code.
   c. Init SP to 0x73B9 to prevent boot loop error (e.g. in Carnival game).
   d. Fixed bug where keyboard key 6 was mapped to keypad key 7 instead of 6.
2. Reduce opening credits screen wait time from appr. 12 to 6 seconds (also when starting the machine in BASIC mode).
3. The font character definitions are aligned to the top like the Coleco font and many lower case characters are redefined to improve readability. Note that this same font definition is also used in BASIC mode.

### BASIC v3.2 ROM
1. Cursor starts at position 0 when in 32x24 text mode (like in BASIC 3.0).
2. Minimize vertical spacing for the prompt. Don't display "READY" before ">".
3. Opening message "BIT90 VERSION 3.2". Can also be used for BIOS version check in programs: V=PEEK(12894)-48.
4. Changes to LIST command: 
   a. Pressing the space-bar pauses listing instead of the ?-key.
   b. Insert a space after line number instead of a tab.
5. Moved up the orange cursor sprite one line to align with the redefined font.

### IPS PATCHES
The changes are published here as IPS patches for the original ROM files. They only work for the BIT90 V3.1 ROMS (!) You can use the mame bit90.zip and patch the d32*.* files. The patched files also work in the mame emulator but you have to start the emulator from the commandline and ignore checksum warnings.

### ROM CHIP 2364 TO 2764
The BIT90 may have either 24-pin 2364 Mask ROM's or 28-pin 2764 Eprom or a mix of both. There are pin adapters available from 2364 to 2764 but on the system board there are also 3 jumper locations where you can make the necessary changes if needed. For convenience I soldered jumper pins and removed the horizontal lanes between the pins on the PCB.

I also replaced the 8KB Roms with 27C256 Eproms and wired A13+A14 with a 4K7 pull-up resistor to 5V and via a 3-way switch to ground so I can choose between 3 
different ROM versions. This solution can be undone without leaving traces:
[BIT90 Eprom mod](BIT90%20Eprom%20mod.png)

## HARDWARE
### Replace power supply
The original powersuply can get very hot and the voltages may be out of spec after all these decades. This can cause instability, screen artifacts or even permanent damage. I replaced the PSU with a "MEAN WELL GP25B13A-R1B" power supply. It has the same DIN plug but the pinout is different! You will have to do some rewiring of the plug if you use this power supply with the BIT90. Note that the pin numbers in the spec sheet are actualy the same but a standard 5-pin DIN physical pin layout from one side to the other is numbered 1-4-2-5-3 while the BIT90 used 1-2-3-4-5 so only pin 1 (GND) is physically the same pin: [PSU Connector](PSU%20Connector.png)

### Replace electrolytic capacitors
To prolong the lifetime of the computer it is recommended to replace the 8 electrolytic capacitors. A few old ones were also out of spec on my system.

### Video chip cooling
To prolong the lifetime of the videochip (TMS9929A) I added a heatsink.

