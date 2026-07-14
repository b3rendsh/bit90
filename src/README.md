# BIT90 sources

Recreated source code for the BIT90 BASIC and GAME system ROM.

## Binaries

Build the binaries using z88dk r2.4 or newer and make.

The BASIC binaries are 16KB, split this in two 8KB files for ROM U2 and U3.

The game binary is for ROM U4.

## Build targets

**v30/v31**  
Original system versions.

**v32**  
V3.2 includes game rom modifications to improve Coleco compatibility.

**r26**  
Under construction!  
V3.2 with additional changes to support non mirrored 8KB internal RAM.  

**test**
Used for checking Coleco OS7 differences. This build is intentionally incomplete.

## Sources

The BIT90 system sources were recreated using:  
* Ghidra to reverse engineer the original system roms.  
* The Colecovision Coding Guide for analysis of the GAME rom.  
* Application and system notes provided by BIT Corporation.  

## Disclaimer

The source code is shared here for educational and non commercial purposes only. It is considered fair use of orphaned software.

The material is provided freely and "as it is" in the hope that it will be useful, but without any warranty of any kind, either expressed or implied. Use at own risk!
