# Make z80 binary from asm source with z88dk tools

SOURCES1 := basic.asm
SOURCES2 := game.asm

MAKEFLAGS += --no-print-directory

# system agnostic commands
ifdef ComSpec
	RMF	:= del /f /q
	RMD	:=
	SEARCH	:= find
	CP	:= copy /b
	GETDATE	:= powershell get-date -format "{yyyy-MM-dd}" 
	QUOTE	:= "
	/	:= $(strip \)
else
	RMF	:= rm -f 
	RMD	:= /*
	SEARCH	:= grep
	CP	:= cp
	GETDATE	:= date +'%Y-%m-%d'
	QUOTE	:= '"'
	/	:= /
endif 

all:	v30 v31 v32 r26 test

rdate:
	@echo db $(QUOTE)$(shell $(GETDATE))$(QUOTE) > rdate.inc

# build logic for all targets
bit90:	rdate
	@echo Assembling $(VERSION)...
	$(RMF) obj$(RMD)
	z80asm -b -d -l -m $(DEFINES) -Oobj -o=basic $(SOURCES1)
	z88dk-appmake +glue -b obj/basic --filler 0xFF --clean
	$(CP) obj$/basic__.bin bin$/bit90_basic_$(SUFFIX).bin
	z80asm -b -d -l -m $(DEFINES) -Oobj -o=game $(SOURCES2)
	z88dk-appmake +glue -b obj/game --filler 0xFF --clean
	$(CP) obj$/game__.bin bin$/bit90_game_$(SUFFIX).bin
	@echo done

v30:
	@$(MAKE) bit90 VERSION="V30" DEFINES="-DBIT90 -DV30" SUFFIX=v30
v31:
	@$(MAKE) bit90 VERSION="V31" DEFINES="-DBIT90 -DV31" SUFFIX=v31

v32:
	@$(MAKE) bit90 VERSION="V32" DEFINES="-DBIT90 -DV32" SUFFIX=v32

r26:
	@$(MAKE) bit90 VERSION="R26" DEFINES="-DBIT90 -DR26" SUFFIX=r26
	
test:	rdate
	@echo Assembling Coleco test...
	$(RMF) obj$(RMD)
	z80asm -b -d -l -m -DCOLECO -Oobj -o=game $(SOURCES2)
	z88dk-appmake +glue -b obj/game --filler 0xFF --clean
	$(CP) obj$/game__.bin bin$/coleco_test.bin
	@echo done

clean:
	$(RMF) obj$(RMD)
	$(RMF) rdate.inc
