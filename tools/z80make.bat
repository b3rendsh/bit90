@echo  off
REM Make z80 binary from asm source with z88dk tools
z80asm -b %1 -m
z88dk-appmake +glue -b %1 --filler 0x00 --clean
copy /b/y %1_*.bin %1.bin
del %1_*.bin
