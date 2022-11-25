; ------------------------------------------------------------------------------
; BIT90 eXtended BASIC v0.4
; Copyright (C) 2022 H.J. Berends
; 
; You can freely use, distribute or modify this program.
; It is provided freely and "as it is" in the hope that it will be useful, 
; but without any warranty of any kind, either expressed or implied.
; ------------------------------------------------------------------------------
; Load instructions:
; BLOAD "XBAS"
; CALL 61440
; 
; This library extends BIT90 BASIC with the following commands and functions:
; 
; Token	Command	 Parameters	Description
; 224	TXTMAP	 FG,BG		Init 50x24 chars in high res mode (256x192)
; 225	CLS			Clear the screen in txtmap mode (i.e. HOME)
; 226	LINPUT	 X,Y,LEN,V$	Get input for variable V$ in txtmap mode
; 227	LOCATE 	 X,Y		Place the cursor at position x,y 
; 228	CLOAD			COM load BASIC program 
; 229	CBLOAD	 [START,LEN]	COM load Binary file 
; 230	CSAVE			COM save BASIC program 
; 231	CBSAVE 	 [START,LEN]	COM save Binary file 
; 232	TERMINAL FG,BG		Terminal emulator (VT-52 light)
; 233   COLOR	 FG,BG		Change text color in txtmap mode
; 234   EXIT			Exit txtmap mode / return to screenmode 1
; 235	VPOKE	 ADDRESS,VALUE	Write a byte to video ram address (VDP)
; 236	VPEEK	 ADDRESS,R	Read a byte from video ram in variable R (VDP)
; 237	CIRCLE	 X,Y,R[,COLOR]	Draw a circle in graphics mode 1 or 2
; 238	PAINT	 X,Y[,COLOR]	Paint / flood fill area with color C
; 239	BEEP			Beep, same sound as ?CHR$(7);
; 240	XCALL	 [COMMAND]	Reserved for extended commands
; 241	INVERSE			Write text inverse in txtmap mode
; 242	NORMAL			Write text normal in txtmap mode
;
; 243..254: 12 more positions for future commands
; If more commands are created then implement XCALL [COMMAND] similar to CALL

; Prequisites:
; 32K RAM (16K RAM with some minor adjustments is possible)
; RS232 expansion module for cload/csave.
; 
; Notes:
; The commands with token 224..233 are assigned to a function key.
; Extended functions can't return a value, so a variable is used as last parameter.
; The code and static data is loaded in RAM at address F000 to FFFF (4K Bytes)
; The variables are stored in unused RAM at address 7500 to 77FF (2K Bytes)
; The library will remain in memory until the next cold or warm boot, 
; i.e. the NEW command will not erase it.
; Simultaneous use with other expansion modules (e.g. printer) may not work.
; The token name TXTMAP originates from text + bitmap mode.
;
; Backlog:
; TERMINAL - Implement additional VT52 escape codes / VT-100 terminal
;            Status bar on/off
; LINPUT   - Load initial value of the variable$ in the input buffer
; ------------------------------------------------------------------------------


; BIT90 V3.1 CONSTANTS

REGEXERR	=  $02FC	; BASIC expression validator / error routine
PRMVAL		=  $06B9	; BASIC routine to validate a parameter expression
GETPWORD	=  $22D6	; BASIC routine to get a parameter word value into register DE
GETPBYTE	=  $2540	; BASIC routine to get a parameter byte value into register A

TOKENE		=  $7005	; Extended token table
IOBUF		=  $7098	; IO buffer (256 bytes)
ADDR		=  $71E4	; Pointer to end program memory (marked by 2x zero)
LOMEM		=  $71E6	; Pointer to lowest program memory (LOMEM + 4 = start BASIC program)
HIMEM		=  $71E8	; Pointer to last free memory address
MEMT		=  $71EA	; Pointer to program top memory address
DIMED		=  $7231	; Pointer to first free memory address
SCRRES		=  $733B	; Current screen resolution
SCRCOL		=  $733C	; Current screen color (for plotting pixels)
FLSCUR		=  $733E	; Flash cursor flag
GETKEY		=  $734D	; Hook to routine: Get keyboard key pressed

; PROGRAM CONSTANTS

TXTBUF		=  $7500	; Text mode IO buffer (256 bytes), low byte must start at 00 (!)

CURPOS		=  $7600	; 30208 Cursor X,Y  (don't swap these 2 positions!)
CURPOSX		=  $7600	; 30208 Cursor X
CURPOSY		=  $7601	; 30209 Cursor Y
MINPOS		=  $7602	; 30210 Minimum curpos Y,X
MINPOSX		=  $7602	; 30210 Minimum curpos Y
MINPOSY		=  $7603	; 30211 Minimum curpos X
BUFLEN		=  $7604	; 30212 Length of input buffer
MAXLIN		=  $7605	; 30213 Maximum linenumber + 1
TXTMODE		=  $7606	; 30214 0=Standard 1=Bitmap/text 2=Monochrome
TXTCOLOR	=  $7607	; 30215 Text color
INVCHAR		=  $7608	; 30216 Inverse character (inverse color)
CURSAV		=  $7609	; 30217 Saved curpos Y,X
CURSAVX		=  $7609	; 30217 Saved curpos Y
CURSAVY		=  $760A	; 30218 Saved curpos X
COLORSAV	=  $760B	; 30219 Saved color (reserved)
COMSPEED	=  $760C	; 30220	Baudrate selection
COMMODE		=  $760D	; 30221	Baudrate divder / bits / parity / stopbits
COMTIMEOUT	=  $760E	; 30222	Timeout (20sec.)
TIMECOUNT	=  $760F	; 30223 Time counter for timeout
COMSELECT	=  $7610	; 30224 BASIC or Machine code ('B' is BASIC, 'M'is Machine)
COMFLAGS	=  $7611	; 30225	BIT 0: local echo on is 1, local echo off is 0 (default off)
				;       BIT 1-7: reserved (0)
VDPNTPOS	=  $7612	; 30226 VDP Nametable Offset for ypos (0..7)
RADIUSERR	=  $7613	; 30227 Radius Error variable used in CIRCLE command (2 byte value)

VDPBUF		=  $7700	; 256 Byte VDP buffer

EXTOKEN		=  $FE00 - 128	; Extended token table (Max 256 Bytes)
CHARDEF		=  $FE00	; Character set definitions (128 x 4 bytes)

; --------------
; Initialization
; --------------

SECTION PROGRAM

		ORG	$F000			; 61440 The code is relocatable to ROM
		
XBASINIT:	PUSH	HL
		; Init free memory
		LD	HL,$EFFF
		LD	(HIMEM),HL
		LD	(MEMT),HL
		LD	HL,EXTOKEN
		LD	(TOKENE),HL
		; Init text mode
		LD	A,0
		LD	(TXTMODE),A
		LD	(VDPNTPOS),A
		; Init communication port (UART 8251)
		LD	A,0		
		LD	(COMSPEED),A		; Speed: 2400 Baud
		LD	(COMFLAGS),A		; Terminal: local echo off, online
		LD	A,78			; Mode: 8 Bits, No parity, 1 Stopbit
		LD	(COMMODE),A
		LD	A,28			; Timeout: 20 seconds (N * 0.77)
		LD	(COMTIMEOUT),A	
		; End initialization		
		POP	HL
		RET

; ------------------------------------------------------------------------------
; Command: TXTMAP FG,BG 
; Purpose: Text map 50 characters per line, 24 lines in high res mode 256x192
;
; FG is foreground color (0..15) 
; BG is background color (0..15)
; ------------------------------------------------------------------------------
TXTMAP:		CALL	GETPBYTE		; Load next parameter: foreground color
		AND	$0F
		RLCA	
		RLCA
		RLCA
		RLCA
		LD	B,A
		CALL	parseComma		; Check for Comma
		CALL	GETPBYTE		; Load next parameter: background color
		AND	$0F
		LD	C,A			; Set backplane to background color
		ADD	A,B
		LD	(TXTCOLOR),A		; Color = 16 * foreground + background
		LD	B,$00		
		PUSH	HL			; HL is next position pointer in BASIC command parser

		LD	HL,endTxtmap		; Set return address for ROM routine at $247C
		PUSH	HL
		PUSH	BC			; Backplane color
		LD	C,$01			; Set screen mode 1 (bitmap highres)
		PUSH	BC
		CALL	$3FDD			; Hide screen
		JP	$247C			; Continue with ROM routine to initialize screen 
endTxtmap:	LD	HL,BREAKPROG		; Redirect BREAK command
		LD	($7394),HL
		LD	HL,DSPCHAR		; Redirect ROM Display Character routine
		LD	($7354),HL
		LD	HL,$0000		; Set cursor to 0,0
		LD	(CURPOS),HL
		LD	A,$FF			; Set input buffer to max value		
		LD	(BUFLEN),A
		LD	A,$18			; Set last line
		LD	(MAXLIN),A
		LD	A,0			; Clear nametable offset
		LD	(VDPNTPOS),A		
		LD	A,1			; set text mode flag to screen 1
		LD	(TXTMODE),A
		CALL	CLS			; Initialize patterns and colors		
		POP	HL
		RET

; -----------------------------------------------------
; New BREAK subroutine that first resets the screenmode
; -----------------------------------------------------
BREAKPROG:	CALL	EXIT
		JP	$03F1			; ROM Break routine

; ----------------------------------------------------
; Command: EXIT
; Purpose: Exit txtmap mode (but stay in screenmode 1)
; ----------------------------------------------------
EXIT:		PUSH	HL
		LD	HL,$36E0
		LD	($7354),HL		; reset DSPCHAR routine
		LD	A,$00
		LD	(TXTMODE),A
		LD	HL,$03F1
		LD	($7394),HL		; reset BREAK routine
		POP	HL
		RET

; ------------------------------------------------------------------------------
; Command: CLS
; Purpose: Clear screen (excluding lines starting at MAXLIN)
; ------------------------------------------------------------------------------
CLS:		LD	A,(MAXLIN)
		LD	B,A
		LD	C,$00
		LD	DE,$0000		; Start of VDP pattern table and curpos 0,0
		LD	(CURPOS),DE
		XOR	A			; A=0 clear all patterns
		CALL	$3888			; Block write to VDP
		LD	A,(TXTCOLOR)		; Set all pixel colors to default color
		LD	D,$20			; Color table offset
		CALL	$3888			
		RET

; ------------------------------------------------------------------------------
; Command: LINPUT [X,Y],Length,Variable$
; Purpose: Line input (keyboard input) string variable
;
; X,Y is optional cursor position
; Length is length of the variable string
; Variable$ will contain the keyboard input.
; Note: the variable$ must be declared before using it in LINPUT (!)
; ------------------------------------------------------------------------------
LINPUT:		LD	A,(HL)
		CP	$2C			
		JR	Z,_endCurpos		; Check if curpos parameters area omitted
		CALL	LOCATE			; set cursor position to x,y
		CALL	parseComma
		DEC	HL
_endCurpos:	INC	HL
		CALL	GETPBYTE		; Get input string length
		AND	A
		JR	Z,_endLen		; If length is 0 then use existing value
		LD	(BUFLEN),A
_endLen:	CALL	parseComma		; set pointer at Variable$ parameter
		CALL	keyboardInput		; actual input function
		CALL	$2FEB			; Assign keyboard input to Variable
		CALL	maxPos			; determine max cursor position
		INC	D			; set ypos to next line
		LD	E,$00			; set xpos to begin of line
		CALL	scroll			; scroll screen if needed
		LD 	(CURPOS),DE
		RET

; ------------------------------------------------------------------------------
; Command: LOCATE X,Y
; Purpose: Locate cursor to position X,Y on the screen
; ------------------------------------------------------------------------------
LOCATE:		LD	A,(TXTMODE)
		CP	$00
		JR	Z,locateOrg
		LD	A,(HL)
		CALL 	GETPBYTE		; Get cursor X position
		CP	$32			; X position < 50 ?
		JP	NC,$02F3		; No then syntax error
		LD	(CURPOSX),A
		CALL	parseComma
		LD	A,(MAXLIN)
		LD	B,A
		CALL	GETPBYTE		; Get cursor Y position
		CP	B			; Y position < maxlin ?
		JP	NC,$02F3		; No then syntax error
		LD	(CURPOSY),A
		RET

locateOrg:	CALL	GETPBYTE		; set curpos in textmode 32x24 chars or 30x24 in BASIC 3.1
		PUSH	AF
		CALL	parseComma
		CALL	GETPBYTE
		LD	D,A
		LD	A,($325E)		; Version X in text "BIT90 BASIC 3.X"
		CP	$31
		JR	Z, xInc2
		POP	AF
		JR	xIncDone
xInc2:
		INC	A			; add 2 positions to X coordinate for BASIC 3.1
		INC	A
xIncDone:
		AND	$1F	
		LD 	E,A
		XOR	A
		RR	D
		RRA
		RR	D
		RRA
		RR	D
		RRA
		OR	E
		LD	E,A
		LD	A,D
		AND	$03
		LD	D,A
		LD	($700F),DE		; CURPOS = Y*32+X
		RET

; ------------------------------------------------------------------------------
; Command: CLOAD
; Purpose: Load BASIC "file" in Memory via RS232 (COM port)
; 
; Default start address is $8004 for BASIC
; Default end address is last free address or until no more data is received
; ------------------------------------------------------------------------------
CLOAD:		PUSH	HL
		LD	A,$42			; 'B' for BASIC
		LD	(COMSELECT),A
		LD	HL,(HIMEM)		; Pointer to highest available ram 
		LD	DE,(ADDR)		; Pointer to first free memory address for BASIC program
		SBC	HL,DE
		EX	DE,HL
		INC	DE
		JR	comLoad

; ------------------------------------------------------------------------------
; Command: CBLOAD [START,LENGTH]
; Purpose: Load Machine coded "file" in Memory via RS232 (COM port)
; 
; Default start address is $8000 for Machine/game
; Default end address is last free address or until no more data is received
; ------------------------------------------------------------------------------
CBLOAD:		LD	A,$4D			; 'M' for Machine code
		LD	(COMSELECT),A
		CALL	$261A			; Check if there are parameters
		JR	Z,loadDefault
		CALL	PRMVAL			; Validate parameter
		CALL	GETPWORD		; Load the number parameter in DE register
		LD	BC,DE
		LD	A,(HL)
		CP	$2C		
		JP	NZ,REGEXERR
		INC	HL
		CALL	PRMVAL
		CALL	GETPWORD
		PUSH	HL
		LD	HL,BC
		JR	comLoad
loadDefault:	PUSH	HL
		LD	DE,(LOMEM)		; Default start address is lowest program memory address
		LD	HL,(HIMEM)		; Default end address is highest available memory address
		SBC	HL,DE
		EX	DE,HL
		INC	DE
comLoad:	CALL	initPort
		LD	BC,$0000
		LD	A,(COMTIMEOUT)		; Timeout start receiving after appr. 20 seconds
		LD	(TIMECOUNT),A
loadData:	IN	A,($45)
		AND	2
		JR	NZ,loadByte
		DJNZ	loadData		; Inner wait loop
		DEC	C
		JR	NZ,loadData		; Outer wait loop
		LD	A,(TIMECOUNT)
		DEC	A
		LD	(TIMECOUNT),A
		JR	NZ, loadData		; Appr. 0.77 seconds wait loop
		JR	loadEnd
loadByte:	IN	A,($44)
		LD	(HL),A
		INC	HL
		DEC	DE
		LD	A,D
		OR	E
		JR	Z,loadEnd
		LD	A,$03			
		LD	(TIMECOUNT),A		
		JR	loadData
loadEnd:	LD	A,(COMSELECT)
		CP	$42
		JR	NZ,_endCload
		CALL	$30CB			; Initialize pointers for the loaded BASIC program
_endCload:	POP	HL
		RET

; ------------------------------------------------------------------------------
; Command: CSAVE
; Purpose: Save BASIC memory "file" via RS232 (COM port)
; 
; ------------------------------------------------------------------------------
CSAVE:		PUSH	HL
		LD	A,$42			; 'B' for BASIC
		LD	(COMSELECT),A
		LD	DE,(LOMEM)		; start BASIC program area  is LOMEM + 4 Bytes
		INC	DE
		INC	DE
		INC	DE
		INC	DE
		LD	HL,(ADDR)		; end BASIC program area (include the 2 zero's in the save)
		INC	HL
		INC	HL
		INC	HL
		SBC	HL,DE
		EX	DE,HL
		JP	comSave

; ------------------------------------------------------------------------------
; Command: CBSAVE [START,LENGTH]
; Purpose: Save Machine code memory "file" via RS232 (COM port)
; 
; ------------------------------------------------------------------------------
CBSAVE:		LD	A,$4D			; 'M' for Machine code
		LD	(COMSELECT),A
		CALL	$261A
		JR	Z, saveDefault
		CALL	PRMVAL
		CALL	GETPWORD
		LD	BC,DE
		LD	A,(HL)
		CP	$2C
		JP	NZ,REGEXERR
		INC	HL
		CALL	PRMVAL
		CALL	GETPWORD
		PUSH	HL
		LD	HL,BC
		JR	comSave
saveDefault:	PUSH	HL
		LD	DE,(LOMEM)
		LD	HL,(HIMEM)
		SBC	HL,DE
		EX	DE,HL
		INC	DE
comSave:	CALL	initPort
		LD	BC,$0000
		LD	A,(COMTIMEOUT)		; Timeout start transmission after appr. 20 seconds
		LD	(TIMECOUNT),A
saveData:	IN	A,($45)
		AND	1
		JR	NZ,saveByte
		DJNZ	saveData		; Inner wait loop
		DEC	C
		JR	NZ,saveData		; Outer wait loop
		LD	A,(TIMECOUNT)
		DEC	A
		LD	(TIMECOUNT),A
		JR	NZ,saveData		; Appr. 0.77 seconds wait loop
		JR	saveEnd
saveByte:	LD	A,(HL)
		OUT	($44),A
		INC	HL
		DEC	DE
		LD	A,D
		OR	E
		JR	Z,saveEnd
		LD	A,$03			
		LD	(TIMECOUNT),A
		JR	saveData
saveEnd:	POP	HL
		RET

; ------------------------------------------------------------------------------
; Initialize UART 8251 / COM port to 2400 8N1 
; Faster baudrate may produce data errors
; ------------------------------------------------------------------------------
initPort:	LD	A,(COMSPEED)		; Set baudrate
		OUT	($46),A		
		LD	A,0			; Initialize with 3 zero's	
		OUT	($45),A
		OUT	($45),A
		OUT	($45),A
		LD	A,64			; Reset instruction
		OUT	($45),A		
		LD	A,(COMMODE)		; Mode instruction (baudrate divder / parity / stop bits)
		OUT	($45),A	
		LD	A,55			; Command instruction (transmit enable / receive enable / reset errors)
		OUT	($45),A		
		RET

; ------------------------------------------------------------------------------
; Command: TERMINAL FG,BG
; Purpose: Simple terminal program for use with RS232 (COM port) .
; In the host set the terminal to VT-52 with 50 columns and 23 rows.
; There is no buffering or handshake implemented, it is therefore recommended 
; to set a low baudrate e.g. 600 BAUD before starting the terminal.
; The 8251 uart can only be polled to check if a byte is received, 
; the interrupt capabilities are not used in the expansion card. (?) 
; For performance reasons also the screen is set to a monochrome mode.
; Example usage of terminal with an Ubuntu Linux host:
;     sudo /sbin/agetty -L=always -8 600 ttyS0 vt52
;     when logged in:
;     stty rows 23 columns 50
; ------------------------------------------------------------------------------
TERMINAL:	CALL	TXTMAP
		LD	A,2
		LD	(TXTMODE),A		; Monochrome mode for faster printing and scrolling
		CALL	initStatusBar
		CALL	initPort
repeatTerminal:	IN	A,($45)			; Get UART Status
		CP	$07			; Byte in receive buffer?
		JP	Z,receiveMode
		JP	C,transmitMode
		CALL	initPort		; if error then try again after resetting the port
		JP	repeatTerminal
	
receiveMode:	IN	A,($44)
		CP	$1B
		JP	Z,receiveEscape
		CP	$7F			; Check for Delete character
		JR	NZ, _endDelCheck
		LD	A,$08			; Replace Delete with Backspace
_endDelCheck:	CALL	DSPCHAR
		JP	repeatTerminal

; ------------------------------------------------------------------------------
; VT52 Escape codes:
; Current implementation only supports cursor movement.
;
; Code	Name 			Meaning
; ESC-A Cursor up 		Move cursor one line upwards. 
;				Does not cause scrolling when it reaches the top.
; ESC-B	Cursor down 		Move cursor one line downwards.
; ESC-C	Cursor right 		Move cursor one column to the right.
; ESC-D	Cursor left 		Move cursor one column to the left.
;
; Not supported:
; ESC-F	Enter graphics mode 	Use special graphics character set, VT52 and later.
; ESC-G	Exit graphics mode 	Use normal US/UK character set
; ESC-H	Cursor home 		Move cursor to the upper left corner.
; ESC-I	Reverse line feed 	Insert a line above the cursor, then move the cursor into it. 
;				May cause a reverse scroll if the cursor was on the first line.
; ESC-J	Clear to end of screen 	Clear screen from cursor onwards.
; ESC-K	Clear to end of line 	Clear line from cursor onwards.
; ESC-L	Insert line 		Insert a line.
; ESC-M	Delete line 		Remove line.
;
; ESC-Y-[Row]-[Column]		Set cursor position 	
; Move cursor to position Row, Column encoded as single characters. Substract 32(?) to get BIT90 Row and Column.
;
; ESC-Z	ident			Identify what the terminal is.(Respond with ESC-/-K )
; ESC-=	Alternate keypad 	Changes the character codes returned by the keypad.
; ESC->	Exit alternate keypad 	Changes the character codes returned by the keypad. 
; ------------------------------------------------------------------------------

receiveEscape:	LD	BC,$0000
escapeData:	IN	A,($45)
		AND	2
		JR	NZ,escapeByte
		DJNZ	escapeData		; Inner wait loop
		DEC	C
		JR	NZ,escapeData		; Outer wait loop
		CALL	initPort
		JP	repeatTerminal
escapeByte:	IN	A,($44)
		CP	$41
		JR	C,_endCodeCursor
		CP	$45
		JR	C,_codeCursor
_endCodeCursor:

;
; To do: add support for other VT52 escape sequences
;

		JP	repeatTerminal

_codeCursor:	ADD	A,$AF			; BIT90 cursor value starts at $F0 and VT52 at $41 ($F41 + $AF = $F0)
		CALL	DSPCHAR
		JP	repeatTerminal
	
; ------------------------------------------------------------------------------
; If key pressed then transmit it
; Escape will end the program (you may need to press multiple times)
; ------------------------------------------------------------------------------
transmitMode:	CALL	GETKEY			; Get key from keyboard
		CALL 	cursor
		CP	$FF			; Check if a key is pressed
		JP	Z,repeatTerminal
		LD	B,A
		CALL	GETKEY	 		; Verify that a key pressed
		CP	B
		JP	NZ,repeatTerminal
_keywait:	CALL	GETKEY			; Wait until key is released (key repeat not supported)
		CP	B
		JR	Z,_keywait
		LD	A,B
		CP	$1B
		JP	Z,BREAKPROG
		CP	$F4
		JR	NZ,_end2DelCheck
		LD	A,$08			; Replace DEL with BS
_end2DelCheck:	LD	B,A
		LD	A,(COMFLAGS)
		OR	A			; If more flags are used this should be changed to bit compare
		LD	A,B
		JR	Z,_endDspChar
		CALL	DSPCHAR			; Local echo on
		CP	$0D			; IF CR then add LF
		JR	NZ,_endDspChar
		LD	A,$0A
		CALL	DSPCHAR
		LD	A,$0D
_endDspChar:	CALL	statusCursor
		CP	$80
		JR	NC,transmitEscape
		CALL	transmitChar
		JP	repeatTerminal

; ----------------------------------------------------
; Subroutine: convert control characters to VT52 codes
; ----------------------------------------------------
transmitEscape:	CP	$F0
		JR	C,_endTxEscape
		CP	$F4
		JR	C,_escapeCursor
;
; To do: add support for conversion to other VT52 escape sequences
;
;

_endTxEscape:	JP	repeatTerminal
_escapeCursor:	SUB	$AF			; Escape sequence cursor movement is $1B + $41..$44 ($F0 - $AF = $41)
		PUSH	AF
		LD	A,$1B
		CALL	transmitChar
		POP	AF
		CALL	transmitChar
		JP	repeatTerminal
transmitChar:	LD	D,A
		LD	BC,$0040		; Wait counter (appr. 0.1 seconds)
_transmitData:	IN	A,($45)			; Wait for transmit ready
		AND	1
		JR	Z,_transmitWait
		LD	A,D
		OUT	($44),A
		RET
_transmitWait:	DJNZ	_transmitData
		DEC	C
		JR	NZ,_transmitData
		RET

; ---------------------
; Initialize status bar
; ---------------------
initStatusBar:	LD	A,1
		LD	(INVCHAR),A
		LD	DE,$1700		; Row 23 Column 0
		LD	HL,statusBar
_repeatStatBar:	LD	A,(HL)
		CP	$00
		JR	Z,_statBaudrate	
		CALL	screenWrite
		CALL	curPlus
		INC	HL
		JR	_repeatStatBar
_statBaudrate:	LD	A,(COMSPEED)
		CP	$4
		JR	NC,_endStatBar
		LD	HL,speedTable
		LD	D,$00
		LD	E,A
		ADD	HL,DE
		LD	A,(HL)
		LD	DE,$1722
		CALL	printNum
_endStatBar:	LD	A,0
		LD	(INVCHAR),A
		LD	A,$17			; Reserve bottom line for status bar	
		LD	(MAXLIN),A		
		LD	DE,$0000		; Row 0 Column 0
		LD	(CURPOS),DE		
		RET

; -----------------------------------------
; Display cursor Y,X position on status bar
; -----------------------------------------
statusCursor:	PUSH	AF
		LD	A,1
		LD	(INVCHAR),A
		LD	DE, $172C
		LD	A,(CURPOSY)
		CALL	printNum
		INC	E
		LD	A,(CURPOSX)
		CALL	printNum
		LD	A,0
		LD	(INVCHAR),A
		POP	AF
		RET

; --------------------------------------
; Print number (row / column / baudrate)
; --------------------------------------
printNum:	CP	40
		JR	C,_endNum40
		SUB	40
		LD	B,A	
		LD	A,$34
		JR	_endNum
_endNum40:	CP	30
		JR	C,_endNum30
		SUB	30
		LD	B,A	
		LD	A,$33
		JR	_endNum
_endNum30:	CP	20
		JR	C,_endNum20
		SUB	20
		LD	B,A	
		LD	A,$32
		JR	_endNum
_endNum20:	CP	10
		JR	C,_endNum10
		SUB	10
		LD	B,A
		LD	A,$31
		JR	_endNum
_endNum10:	LD	B,A
		LD	A,$30
_endNum:	CALL	screenWrite
		INC	E
		LD	A,B
		ADD	A,$30
		CALL	screenWrite
		INC	E
		RET

; -------------------------------------------------------------------------
; Subroutine: write character to the screen.
; A character is 5x8 pixels and must be mapped on 8x8 character patterns.
; The character can span 2 consecutive bytes in the pattern table.
; The color will spill over to the next character, due to VDP limitations. 
; -------------------------------------------------------------------------
screenWrite:	PUSH	BC
		PUSH	DE			; cursor position in DE
		PUSH	HL
		PUSH	AF
		LD	L,A			; Character to write (ascii)
		LD	H,$00
		ADD	HL,HL
		ADD	HL,HL
		CALL	ntOffset
		EX	DE,HL			; DE = 4 * A, HL = CURPOS
		LD	H,A			; curposy = curposy + ntoffset
		LD	IX,CHARDEF		; Memory offset Character set definition
		ADD	IX,DE

; Calculate bit positions and masks:
; begin ------------------------------------
		LD	A,L
		RLCA
		RLCA
		ADD	A,L
		ADD	A,$06
		LD	L,A			; L = CURPOSX * 5 + 6
		OR	$F8
		CPL
		INC	A
		LD	C,A
		; --------------------------
		LD	A,L
		AND	$F8
		LD	L,A
		; --------------------------
		EX	DE,HL
		LD	HL,$FF07
		LD	B,C
_shiftLeft:	ADD	HL,HL
		INC	L
		DJNZ	_shiftLeft
		EX	DE,HL
; end --------------------------------------
; HL = Location Char Byte 1 in pattern table
; DE = Byte Mask 1 and 2
; C  = Bitpattern offset to the left

		PUSH	HL

; Load 16 bytes from VDP in VBPBUF starting at address in HL
; begin ----------------------------------------------------
		PUSH	BC
		LD	C,$BF
		OUT	(C),L
		OUT	(C),H
		LD	HL,VDPBUF
		LD	B,$10
		LD	C,$BE
_repeatRxChar:	INI
		JR	NZ,_repeatRxChar
		POP	BC
; end ------------------------------------------------------
	
		LD	IY,VDPBUF
		LD	B,$08			; A Character pattern is 8 lines
		DI
_repeatRead:	PUSH	BC

; Read the character definition in 2 nibbles and apply inversion filter if needed
; begin -------------------------------------------------------------------------
		LD	H,$00
		LD	A,B
		AND	1
		JR	NZ,_rightNibble
		LD	A,(IX+$00)
		AND	$F0
		LD	L,A
		JR	_nibbleDone
_rightNibble:	LD	A,(IX+$00)
		AND	$0F
		RLCA
		RLCA
		RLCA
		RLCA
		LD	L,A
		INC	IX			; Move to next 2 line patterns
_nibbleDone:	LD	A,(INVCHAR)
		AND	1
		JR	Z,_invDone
		LD	A,L
		XOR	$F8			; Inverse character definition
		LD	L,A
_invDone:
; end ---------------------------------------------------------------------------

; Shift left the character to the correct position in the 2-byte pattern
; Then apply masks and insert character bits
; begin -------------------------------------------------------------------------
		LD	B,C
_shiftA:	ADD	HL,HL
		DJNZ	_shiftA
		LD	A,(IY+$00)		; Load 1st byte from buffer
		AND	D			; Mask neighbouring char
		OR	H			; Add new char pattern
		LD	(IY+$00),A
		LD	A,(IY+$08)		; Load 2nd byte from buffer
		AND	E
		OR	L
		LD	(IY+$08),A
		INC	IY			; Next position in write buffer
; end ---------------------------------------------------------------------------

		POP	BC
		DJNZ	_repeatRead

; Block write Char Byte 1 and Byte 2 patterns
; begin -------------------------------------------------------------------------
		POP	HL
		SET	6,H			; Write mode
		LD	DE,HL
		LD	C,$BF
		OUT	(C),E
		OUT	(C),D
		LD	HL,VDPBUF
		LD	B,$10
		LD	C,$BE
_repeatCharPat:	OUTI
		JR	NZ,_repeatCharPat	
; end ---------------------------------------------------------------------------

		LD	A,(TXTMODE)
		CP	$02
		JR	Z,_endCharCol

; Block write colors for Byte 1 and Byte 2
; begin -------------------------------------------------------------------------
		SET	5,D			; Offset Color table
		LD	C,$BF
		OUT	(C),E
		OUT	(C),D
		LD	A,(TXTCOLOR)
		LD	B,$10
		LD	C,$BE
_repeatCharCol:	OUT	(C),A
		NOP				; wait for VDP memory 29 T-states required
		DJNZ	_repeatCharCol
; end ---------------------------------------------------------------------------

_endCharCol:	EI				; Done writing to VDP
		POP	AF
		POP	HL
		POP	DE
		POP	BC
		RET

; ---------------------------------------
; Subroutine: process input from keyboard
; ---------------------------------------
keyboardInput:	PUSH	HL
		LD	A,(BUFLEN)
		LD	B,A
		LD	A,$20
		INC	B
		LD	HL,(CURPOS)
		LD	(MINPOS),HL
_repeatDisplay:	CALL	DSPCHAR			; Display character on screen
		DJNZ	_repeatDisplay
		LD	HL,(MINPOS)
		LD	(CURPOS),HL
_repeatGetkey:	CALL	GETKEY			; Get keyboard key pressed
		JR	C,_repeatGetkey
_newKey:	LD	B,$60			; time to wait for repeat
		LD	D,$FF
_repeatKey:	CALL	GETKEY			; repeat key pressed
		JR	NC,_endKey
		LD	HL,FLSCUR
		SET	6,(HL)
_endKey:	CALL	cursor
		JR	NC,_newKey
		CP	D			; compare with previous key press
		JR	NZ,_endNewkey		; not the same
		DJNZ	_repeatKey		; delay repeat key
		CALL	keyPressed
		LD	B,$04			; repeat speed
		JR	_repeatKey
_endNewkey:	LD	D,A
		CALL	keyPressed
		JR	_repeatKey

; -------------------------------------------
; Subroutine: process key pressed on keyboard
; -------------------------------------------
keyPressed:	PUSH	BC
		PUSH	DE
		PUSH	AF
		LD	A,$80			; key pressed sound
		OUT	($FF),A
		LD	A,$0A
		OUT	($FF),A
		LD	A,$94
		OUT	($FF),A
		LD	HL,$1000
_repeatSound:	DEC	HL
		LD	A,H
		OR	L
		JR	NZ,_repeatSound
		LD	A,$9F
		OUT	($FF),A
		POP	AF
		CP	$0D			; Enter pressed?
		JR	Z,_enterPressed
		LD	HL,(CURPOS)
		LD	(CURSAV),HL
		CALL	DSPCHAR			; display pressed key
		LD	HL,(CURPOS)
		LD	DE,(MINPOS)
		XOR	A
		SBC	HL,DE			; curpos < minpos ?
		JR	C,_posError
		CALL	maxPos
		LD	HL,(CURPOS)
		EX	DE,HL
		XOR	A
		SBC	HL,DE			; curpos > maxpos ?
_posError:	POP	DE
		POP	BC
		RET	NC
		LD	HL,(CURSAV)		; load curpos with saved value
		LD	(CURPOS),HL
		LD	A,$07			; BELL character (beep)
		JP	DSPCHAR
_enterPressed:	POP	HL
		POP	HL
		POP	HL
		LD	HL,FLSCUR
		RES	6,(HL)
		CALL	cursor
		LD	BC,$00FF		; Counter
		LD	DE,IOBUF		; Source buffer
		PUSH	DE
		LD	HL,TXTBUF		; Destination buffer
		LDIR
		POP	DE
		LD	HL,(BUFLEN)
		LD	H,B				
		ADD	HL,DE
		LD	(HL),B			; 0 is end of buffer
		POP	HL
		RET

; --------------------------------------
; Subroutine: count characters in buffer
; --------------------------------------
bufCount:	PUSH	AF
		LD	HL,(MINPOS)
		LD	A,D
		SUB	H
		SLA	A
		LD	H,A
		SLA	H
		SLA	H
		SLA	H
		ADD	A,H
		SLA	H
		ADD	A,H
		ADD	A,E
		SUB	L
		LD	HL,TXTBUF		
		LD	L,A
		POP	AF
		RET

; --------------------------------------
; Move 1 position the left
; --------------------------------------
curMin:		LD	A,$31			; Set curpos - 1
		DEC	E				
		CP	E
		RET	NC
		LD	E,A				
		DEC	D
		RET
	
; --------------------------------------
; Move 1 position the left
; --------------------------------------
curPlus:	LD	A,$31			; Set curpos + 1
		INC	E
		CP	E
		RET	NC
		INC	D
		LD	E,$00
		RET

; -----------------------------------------------------------------------
; Subroutine : DSPCHAR
; Replaces the BIT90 Console output driver (DSPCHR) used in PRINT command
; -----------------------------------------------------------------------
DSPCHAR:	PUSH	BC
		PUSH	DE
		PUSH	HL
		PUSH	AF
		LD	DE,(CURPOS)
		CP	$20			; Is it a control character?
		JR	NC,_noControl
		CP	$07
		JR	Z,charBell
		CP	$08
		JP	Z,charBS
		CP	$09
		JP	Z,charTab
		CP	$0A
		JP	Z,charDown
		CP	$0D
		JP	Z,charEnter
		JR	endChar			
_noControl:	CP	$80
		JP	C,charAscii
		CP	$F0
		JP	Z,charUp
		CP	$F1
		JP	Z,charDown
		CP	$F2
		JP	Z,charLeft
		CP	$F3
		JP	Z,charRight
		CP	$F4
		JP	Z,charDelete
		CP	$F5
		JP	Z,charInsert
		JR	endChar
endCharScroll:	CALL	scroll
endCharPos:	LD	(CURPOS),DE
endChar:	POP	AF
		POP	HL
		POP	DE
		POP	BC
		RET

charBell:	LD   B,$10
_repeat1Bell:	LD   A,$80
		OUT  ($FF),A
		LD   A,$03
		OUT  ($FF),A
		LD   A,$A0
		SUB  B
		OUT  ($FF),A
		LD   HL,$0A00
_repeat2Bell:	DEC  HL
		LD   A,H
		OR   L
		JR   NZ,_repeat2Bell
		DJNZ _repeat1Bell
		JP   endChar

charBS:		LD   A,D
		OR   E
		JP   Z,charBell
		CALL curMin
		LD   A,$20
		CALL screenWrite
		CALL bufCount
		LD   (HL),A
		JP   endCharPos

charTab:	LD   A,$09
_repeatTab:	CP   E
		JR   NC,_endTab
		ADD  A,$0A
		CP   $31
		JR   NZ,_repeatTab
		INC  D
		LD   E,$00
		JP   endCharScroll
_endTab:	INC  A
		LD   E,A
		JP   endCharPos

charEnter:	LD   E,$00
		JP   endCharPos

charAscii:	CALL screenWrite
		CALL bufCount
		LD   (HL),A
		CALL curPlus
		JP   endCharScroll

charUp:		XOR  A
		OR   D
		JP   Z,charBell
		DEC  D
		JP   endCharPos

charDown:	INC  D
		JP   endCharScroll

charLeft:	LD   A,E
		OR   D
		JP   Z,charBell
		CALL curMin
		JP   endCharPos

charRight:	CALL curPlus
		JP   endCharScroll

charDelete:	CALL bufCount
_repeatDelete:	INC  HL
		LD   A,(HL)
		DEC  HL
		LD   (HL),A
		CALL screenWrite
		CALL curPlus
		INC  HL
		LD   A,(BUFLEN)
		CP   L
		JR   NZ,_repeatDelete
		JP   endChar

charInsert:	CALL bufCount
		LD   A,(BUFLEN)
		DEC  A
		LD   C,A
		LD   B,H
		LD   A,(BC)
		CP   $20
		JP   NZ,charBell
_repeat1Insert:	DEC  BC
		LD   A,(BC)
		INC  BC
		LD   (BC),A
		DEC  BC
		LD   A,L
		CP   C
		JR   NZ,_repeat1Insert
		LD   A,$20
		LD   (BC),A
_repeat2Insert:	CALL screenWrite
		CALL curPlus
		INC  BC
		LD   A,(BUFLEN)
		CP   C
		JP   Z,endChar
		LD   A,(BC)
		JR   _repeat2Insert

; ------------------------------------------------------------------------------
; Command: COLOR FG,BG
; Purpose: Change Text Color
;
; FG = Foreground Color (0..15)
; BG = Background Color (0..15)
; ------------------------------------------------------------------------------
COLOR:		CALL 	GETPBYTE		; Get FG Color
		AND	$0F			; Color is 0..15
		RLCA
		RLCA
		RLCA
		RLCA
		LD	B,A
		CALL	parseComma
		CALL	GETPBYTE		; GET BG Color
		AND	$0F			; Color is 0..15
		ADD	A,B
		LD	(TXTCOLOR),A		; FG*15+BG
		RET


; ------------------------------------------------------------------------------
; Command: VPOKE ADDRESS,VALUE
; Purpose: Write a byte to video ram address (VDP)
;
; ADDRESS = Video address (0..16383)
; VALUE   = Byte value (0..255)
; ------------------------------------------------------------------------------

VPOKE:		CALL	PRMVAL
		CALL	GETPWORD			; DE := Address
		CALL	parseComma
		CALL	GETPBYTE		; A := Value
		PUSH	HL
		LD	HL,DE
		CALL	vdpWriteByte
		POP	HL
		RET

; ------------------------------------------------------------------------------
; Command: VPEEK ADDRESS,R
; Purpose: Read a byte from video ram address in variable R (VDP)
;
; ADDRESS = Video address (0..16383)
; ------------------------------------------------------------------------------

VPEEK:		CALL	PRMVAL
		CALL	GETPWORD			; DE := Address
		CALL	parseComma
		PUSH	HL
		LD	HL,DE
		CALL	vdpReadByte
		POP	HL
		CALL	$188C			; Convert byte value to floating point
		CALL	$0A5D			; Load variable
		CALL	$2BFB			; Assign value to variable
		RET


; ------------------------------------------------------------------------------
; Command: CIRCLE X,Y,R[,COLOR] 
; Purpose: Draw a circle in graphics mode 1 or 2
;
; The circle routine is implemented with the midpoint circle algorithm
; ------------------------------------------------------------------------------
CIRCLE:		CALL	GETPBYTE
		LD	E,A			; store center coordinate X
		CALL	parseComma
		CALL	GETPBYTE
		LD	D,A			; store center coordinate Y
		CALL	parseComma
		CALL	GETPBYTE
		; Register BC contains circle line coordinates X,Y
		LD	C,A			; X = Radius
		LD	B,0			; Y = 0
		LD	A,(HL)
		CP	$2C
		JR	NZ,_endColor
		INC	HL
		CALL	GETPBYTE
		LD	(SCRCOL),A		; store color for PLOT
_endColor:	PUSH HL
		LD	HL,0
		LD	(RADIUSERR),HL		; Radius Error = 0
		LD	A,C
		AND	A
		JR	Z, _endCircle		; if Radius = 0 then exit
		LD	HL,DE

		; HL = Center Y,X
		; BC = Y,X
		; DE = Calculated pixel Y,X

_repeatCircle:	LD	A,L
		ADD	A,C
		LD	E,A			; Pixel X = circleX + X
		LD	A,H
		ADD	A,B
		LD	D,A			; Pixel Y = circleY + Y
		CALL	plotPixel
		LD	A,H
		SUB	B
		LD	D,A			; Pixel Y = circleY - Y
		CALL	plotPixel
		LD	A,L
		SUB	C
		LD	E,A			; Pixel X = circleX - X
		CALL	plotPixel
		LD	A,H
		ADD	A,B
		LD	D,A			; Pixel Y = circleY + Y
		CALL	plotPixel

		LD	A,L
		ADD	A,B
		LD	E,A			; Pixel X = circleX + Y
		LD	A,H
		ADD	A,C
		LD	D,A			; Pixel Y = circleY + X
		CALL	plotPixel
		LD	A,H
		SUB	C
		LD	D,A			; Pixel Y = circleY - X
		CALL	plotPixel
		LD	A,L
		SUB	B
		LD	E,A			; Pixel X = circleX - Y
		CALL	plotPixel
		LD	A,H
		ADD	A,C
		LD	D,A			; Pixel Y = circleY + X
		CALL	plotPixel

		PUSH	HL
		LD	E,B
		LD	D,0
		LD	HL,(RADIUSERR)
		ADD	HL,DE
		ADD	HL,DE
		INC	HL			; Radius Error += 1 + 2*Y
		LD	(RADIUSERR),HL
		INC	B			; Y = Y + 1
		LD	E,C
		SBC	HL,DE		
		DEC	HL
		BIT	7,H			; Radius Error - X <= 0 ?
		JR	NZ,_endRadiusErr
		SBC	HL,DE
		INC	HL
		INC	HL			; Radius Error += 1 - 2*X
		LD	(RADIUSERR),HL
		DEC	C			; X = X - 1
_endRadiusErr:	LD	A,C
		CP	B			; IF Y >= X then done
		POP	HL
		JR	NC,_repeatCircle
_endCircle:	POP	HL
		RET

; Plot a pixel where register D=Y and E=X and mem address 733C is Color
; The routine at $173E is part of the BASIC PLOT command.

plotPixel:	PUSH	DE
		PUSH	BC
		CALL	$173E
		POP	BC
		POP	DE
		RET

; ------------------------------------------------------------------------------
; Command: PAINT X,Y[,C]
; Purpose: Paint / flood fill area starting at X,Y with color C.
;
; Uses a scanline flood fill algorithm, optimized for TMS9929A high res mode.
; The border is determined based on if a pixel is set or not (not on a color).
; ------------------------------------------------------------------------------

PAINT:		CALL	GETPBYTE
		LD	E,A			; store center coordinate X
		CALL	parseComma
		CALL	GETPBYTE
		LD	D,A			; store center coordinate Y
		LD	A,(HL)
		CP	$2C
		JR	NZ,_endPcolor
		INC	HL
		CALL	GETPBYTE
		LD	(SCRCOL),A		; store color for PLOT
_endPcolor:	PUSH	HL
		LD	HL,(DIMED)		; First free memory address
		LD	(HL),255		; End of queue marker
		INC	HL
		LD	(HL),255
		INC	HL
		LD	A,(SCRRES)		; Screen mode
		CP	$01
		JR	NZ, _endPaint		; Only high res graphics mode is supported
		CALL	getPixel
		JR	NZ,_endPaint

		; Main loop: HL = Seed Queue, DE = Y,X and C contains seed flags for line above / below

_nextSeed:	LD	C,0

_seekLeft:	LD	A,E
		OR	A
		JR	Z,_goRight		; Left border reached
		DEC	E
		CALL	getPixel		; get pixel pattern at Y,X in DE
		JR	Z,_seekLeft
_seekRight:    	INC	E
		JR	Z,_rightEdge		; Right border reached
_goRight:	CALL	getSetPixel
		JR	NZ,_rightEdge

		; check and save seeds for the line above (Y+1)
		INC	D
		LD	A,D
		CP	192			; Max row exceeded
		JR	NC,_endAbove
		CALL	getPixel
		JR	NZ,_aboveEdge
		LD	A,C
		AND	1
		JR	NZ,_endAbove
		OR	1			; Set above flag
		LD	C,A
		CALL	storeSeed
		JR	_endAbove
_aboveEdge:	LD	A,C
		AND	$FE			; Clear above flag
		LD	C,A
_endAbove:	DEC	D

		; check and save seeds for the line below (Y-1)
		LD	A,D
		OR	A
		JR	Z,_seekRight		; Already at line 0, no line below
		DEC	D
		CALL	getPixel
		JR	NZ,_belowEdge
		LD	A,C
		AND	2
		JR	NZ,_endBelow
		OR	2			; Set below flag
		LD	C,A
		CALL	storeSeed
		JR	_endBelow
_belowEdge:	LD	A,C
		AND	$FD			; Clear below flag
		LD	C,A
_endBelow:	INC	D
		JR	_seekRight

		; check to see if there's another seed to investigate
_rightEdge:	DEC	HL
		LD	E,(HL)			; Get next queued seed X
		DEC	HL
		LD	D,(HL)			; Get next queued Seed Y
		LD	A,D
		INC	A			; Y = 255 is end of queue marker
		JR	NZ,_nextSeed

_endPaint:	POP	HL
		RET

; calculate the pixel address and whether or not it's set
; DE = X,Y

getSetPixel:	PUSH	HL
		PUSH	BC
		CALL	vdpXYtoHLB		; calculate VDP address for X,Y position
		JR	NZ,_endSetPixel		; pixel is set?
		JR	C,_endSetPixel		; wrong X,Y value?
		CALL	vdpReadByte
		LD	C,A
		AND	B			; Z=0 if pixel not set
		JR	NZ,_endSetPixel
		LD	A,C
		OR	B
		CALL	vdpWriteByte
		SET	5,H			; Offset Color table
		LD	A,(SCRCOL)
		AND	$0F
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	vdpWriteByte
		XOR	A			; Z=1
_endSetPixel:	POP	BC
		POP	HL
		RET

getPixel:	PUSH	HL
		PUSH	BC
		CALL	vdpXYtoHLB		; calculate VDP address for X,Y position
		JR	C,_endGetPixel		; wrong X,Y value?
		CALL	vdpReadByte
		AND	B			; Z = 0 if pixel not set
_endGetPixel:	POP	BC
		POP	HL
		RET

storeSeed:	LD	A,(HIMEM+1)
		DEC	A
		CP	H
		RET	C			; Out of memory
		LD	(HL),D
		INC	HL
		LD	(HL),E
		INC	HL
		RET


; ------------------------------------------------------------------------------
; Command: BEEP
; Purpose: Make a beeping sound
; ------------------------------------------------------------------------------

BEEP:		PUSH	HL
		LD	A,7
		CALL	$7353		; DSPCHAR
		POP	HL
		RET

; ------------------------------------------------------------------------------
; Command: XCALL [COMMAND] 
; Purpose: More extended BASIC routines
; ------------------------------------------------------------------------------

XCALL:		RET


; ------------------------------------------------------------------------------
; Command: INVERSE
; Purpose: Write text inverse in txtmap mode
; ------------------------------------------------------------------------------

INVERSE:	LD	A,1
		LD	(INVCHAR),A
		RET

; ------------------------------------------------------------------------------
; Command: NORMAL
; Purpose: Write text inverse in txtmap mode
; ------------------------------------------------------------------------------

NORMAL:		LD	A,0
		LD	(INVCHAR),A
		RET


; ------------------------------------------------------------------------------
; General subroutines:
; parameters are passed in register A, HL or DE
; return value is in register A
; register BC may be affected
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Subroutine: Read Byte from VDP
; Parameters: HL = Address to readm
; Returns   : A  = Byte read 
; Replaces ROM routine $30E2, disable interrupts first
; There is really at least 4xNOP needed for a physical VDP unless during vblank
; ------------------------------------------------------------------------------
vdpReadByte:	LD	A,L
		OUT	($BF),A
		LD	A,H
		OUT	($BF),A
		NOP				; wait for VDP memory 29 T-states required 
		NOP				; "  
		NOP				; "
		NOP				; "
		IN	A,($BE)
 		RET

; -----------------------------------------------------
; Subroutine: Write Byte to VDP
; Parameters: HL = Address to readm
;             A  = Byte to write 
; Uses:       VDPBUF
; Replaces ROM routine $30F9
; -----------------------------------------------------
vdpWriteByte:	LD	(VDPBUF),A
		LD	A,L
		OUT	($BF),A
		LD	A,H
		SET	6,A
		OUT	($BF),A
		LD	A,(VDPBUF)
		OUT	($BE),A
		RET

; -----------------------------------------------------
; Subroutine: Calculate VDP address for Pixel X,Y
; Parameters: DE = Y,X
; Return    : HL = VDP address and B = Bitnr
;
; VDP Address is INT(Y/8)*256 + (Y MOD 8) + INT(X/8)*8
; -----------------------------------------------------
vdpXYtoHLB:	LD	A,D
		CP	192
		JR	NC,_errPixel		; invalid Y position
		LD	A,E
		AND	$07
		LD	B,A
		INC	B			; B = bit position in the pattern byte
		LD	A,E
		AND	$F8			
		LD	C,A			; C = INT(X/8)*8
		LD	A,D
		AND	$07
		OR	C			
		LD	L,A			; L = C + (Y MOD 8)
		LD	H,D
		SRL	H
		SRL	H
		SRL	H			; H = INT(Y/8)
		XOR	A
		SCF
_bitPixel:	RRA
		DJNZ	_bitPixel
		LD	B,A			; B = Bit mask X position
		RET

_errPixel:	XOR	A
		SCF
		RET

; ------------------------------------------------------------------
; Subroutine: VDP copy one line to another line (pattern + color)
; Parameters: H = Source
;             L = Destination
; Uses:       VDPBUF
; ------------------------------------------------------------------
vdpCopyLine:	PUSH	HL
		PUSH	DE
		LD	DE,HL
		SET	6,E			; Write modus for destination
		XOR	A
		LD	C,$BF
		OUT	(C),A
		OUT	(C),D			; Source line number
		LD	C,$BE
		LD	HL,VDPBUF
		LD	B,A
_repeatPatSrc:	INI
		JR	NZ,_repeatPatSrc
		LD	C,$BF
		OUT	(C),A
		OUT	(C),E
		LD	C,$BE
		LD	HL,VDPBUF
_repeatPatDest:	OUTI
		JR	NZ,_repeatPatDest
		LD	A,(TXTMODE)
		CP	$02
		JR	Z,_endCopyLine
		SET	5,D			; Offset Color table
		LD	C,$BF
		OUT	(C),A
		OUT	(C),D
		LD	C,$BE
		LD	HL,VDPBUF
_repeatColSrc:	INI
		JR	NZ,_repeatColSrc
		SET	5,E			; Offset Color table
		LD	C,$BF
		OUT	(C),A
		OUT	(C),E
		LD	C,$BE
		LD	HL,VDPBUF
_repeatColDest:	OUTI
		JR	NZ,_repeatColDest
_endCopyLine:	POP	DE
		POP	HL
		RET

; ------------------------------------------------------------------
; Subroutine: VDP clear a line (pattern + color)
; Parameters: A = Line to clear
; Uses:       VDPBUF
; ------------------------------------------------------------------
vdpClearLine:	LD	C,A
		SET	6,C
		XOR	A
		LD	B,A
		OUT	($BF),A
		LD	A,C			; Write modus
		OUT	($BF),A
		XOR	A
_repeatClrPat:	OUT	($BE),A			; Clear Pattern
		NOP				; wait for VDP memory 29 T-states required
		DJNZ	_repeatClrPat
		LD	A,(TXTMODE)
		CP	$02	
		RET	Z			; no color clear necessary in monochrome mode
		OUT	($BF),A
		SET	5,C			; Offset Color table
		LD	A,C
		OUT	($BF),A
		LD	A,(TXTCOLOR)
_repeatClrCol:	OUT	($BE),A			; Clear Color (set to default color)
		NOP				; wait for VDP memory 29 T-states required
		DJNZ	_repeatClrCol
		RET

; --------------------------------------------------------------------
; Subroutine: Get Nametable character offset
; Parameters: D = ypos
; Return    : A = ypos + offset
; --------------------------------------------------------------------
ntOffset:	LD	A,D
		AND	$07
		LD	B,A
		LD	A,(VDPNTPOS)
		ADD	A,B
		AND	$07
		LD	B,A
		LD	A,D
		AND	$F8
		ADD	A,B
		RET

; --------------------------------------------------------
; Subroutine: move to next parameter, separated by a comma
; --------------------------------------------------------
parseComma:	LD	A,(HL)
		CP	$2C
		JP	NZ,$02F3
		INC	HL
		RET

; -------------------------------------------------------------
; Subroutine: calculate max cursor position while in input mode
; -------------------------------------------------------------
maxPos:		LD	DE,(MINPOS)
		LD	A,(BUFLEN)
		DEC	A
_repeatPos:	CP	$32
		JR	C,_endPosY
		INC	D
		SUB	$32
		JR	_repeatPos
_endPosY:	ADD	A,E
		CP	$32
		JR	C,_endPosX
		INC	D
		SUB	$32
_endPosX:	LD	E,A
		RET

; -----------------------------------------------------------------------------------
; Subroutine: display cursor
; The cursor is a sprite and the position is not affected by scrolling the nametable
; -----------------------------------------------------------------------------------
cursor:		PUSH	BC
		PUSH	DE
		PUSH	HL
		PUSH	AF
		LD	BC,$0008		; Counter
		LD	DE,$3800		; Beginning of sprite pattern table
		LD	HL,$3C00		; Beginning of attribute table
		LD	A,$F8			; New pattern
		AND	A
		CALL	$3888			; Block write to VDP
		LD	A,(CURPOSY)
		RLCA
		RLCA
		RLCA
		DEC	A
		LD	D,A
		DI
		CALL	vdpWriteByte
		INC	HL
		LD	A,(CURPOSX)
		LD	B,A
		RLCA
		RLCA
		ADD	A,B
		ADD	A,$06
		CALL	vdpWriteByte
		INC	HL
		XOR	A
		CALL	vdpWriteByte
		INC	HL
		LD	A,(FLSCUR)		; Flash Cursor flag
		AND	$40
		JR	Z,_endFlash
		LD	A,(TXTCOLOR)
		SRL	A
		SRL	A
		SRL	A
		SRL	A
_endFlash:	CALL	vdpWriteByte
		EI
		POP	AF
		POP	HL
		POP	DE
		POP	BC
		RET

; --------------------------------------
; Subroutine: scroll screen up if needed
; --------------------------------------
scroll:		LD	A,(MAXLIN)
		DEC	A
		CP	D
		RET	NC			; No (further) scrolling needed
		PUSH	BC
		PUSH	DE
		PUSH	HL
		DI
		LD	D,A			; Save last line i.e. number of lines to scroll
		CP	$16
		JR	C,slowScroll
		LD	A,(TXTMODE)
		CP	$02
		JR	Z,fastScroll
slowScroll:	LD	HL,$0100		; Source=line 1, Destination line 0
_repeatScroll:	CALL	vdpCopyLine
		INC	H
		INC	L
		DEC	D			; Row counter
		JR	NZ, _repeatScroll
		DEC	H
		LD	A,H
		CALL	vdpClearLine

; fast scroll will also return here
endScroll:	EI
		LD	HL,MINPOSY
		CP	(HL)
		JR	Z,_endNewline		; cursor is at Y position 0
		DEC	(HL)
_endNewline:	LD	HL,CURSAVY
		DEC	(HL)
		POP	HL
		POP	DE
		POP	BC
		DEC	D			; cusor position Y -1
		JP	scroll			
 
; ----------------------------------------------------------------------
; Fast scroll moves the nametable and colors are discarded.
; This won't work in BASIC because some commands may reset the nametable.
;
; The routinge could be optimized by placing the steps in a NMI routine
; that is executed during VBLANK (use the NMTVEC hook at mem $700A).
; The VRAM writes can be faster then and there's less screen flickering.
; ----------------------------------------------------------------------
fastScroll:
	
; ----- Step 1: Move Pane #1 lines 0..6 up --> 7 x 32 = 224 bytes, start = $00
		LD	HL,$1800		; Nametable starts at $1800
		CALL	vdpReadByte
		ADD	A,$20			; scroll 1 line up by adding 32 to the nametable characters
		LD	E,A			; save starting fill byte
		LD	B,$E0			; Number of bytes
		LD	HL,$5800		; Added write bit
		CALL	vdpNTscroll		; Next fill value is saved in E

; ----- Step 2: Invisible copy old line 8 to new line 7 --> Pattern/Color row 8 to  0
		LD	A,(VDPNTPOS)
		LD	L,A
		ADD	A,$08			
		LD	H,A
		CALL	vdpCopyLine		; Copy old line 8 to new line 7

; ----- Step 3: Move Pane #2 lines 7..14 up --> 8 x 32 = 256 bytes, start = $E0
		LD	B,$00
		LD	HL,$58E0
		CALL	vdpNTscroll

; ----- Step 4: Invisible copy old line 16 to new line 15 --> Pattern/Color row 16 to 8
		LD	A,(VDPNTPOS)
		ADD	A,$08
		LD	L,A
		ADD	A,$08
		LD	H,A
		CALL	vdpCopyLine		

; ----- Step 5: Move Pane #3 lines 15..21 up --> 7 x 32 = 224 bytes, start = $01E0
		LD	B,$E0	
		LD	HL,$59E0
		CALL	vdpNTscroll

; ----- Step 6: If statusline Then: 
;                   Invisible copy old line 23 to new line 23 --> Pattern/Color row 23 to 16
;		    Clear old line 23
;               Else:
;                   Invisible clear new line 23 (old line 16 + offset)

		LD	A,(MAXLIN)		; Line $17 or $18
		CP	$17
		JR	NZ,_noStatusLine
		LD	A,(VDPNTPOS)
		ADD	A,$10			
		LD	L,A
		LD	D,$17
		CALL	ntOffset
		LD	H,A
		CALL	vdpCopyLine		; Copy old line 23 to new line 23
		LD	A,H
		CALL	vdpClearLine
		JR	_endStatusLine
_noStatusLine:	LD	A,(VDPNTPOS)
		ADD	A,$10	
		CALL	vdpClearLine	
_endStatusLine:

; ----- Step 7: Move Pane #3 last 2 lines --> 64 bytes, start = $02C0
		LD	B,$40
		LD	HL,$5AC0
		CALL	vdpNTscroll
		LD	A,(VDPNTPOS)		; Update Nametable offset
		INC	A
		AND	7
		LD	(VDPNTPOS),A
		JP	endScroll

; ---------------------------------------------------------------------
; Subroutine: scroll the nametable, used in fast scroll
; Parameters: Register A=Fill Byte, B=Number of bytes, HL=Start Address
; Returns   : A=Next Fill Byte
; ---------------------------------------------------------------------
vdpNTscroll:	LD	C,$BF
		OUT	(C),L
		OUT	(C),H
		LD	A,E
_ntUpdate:	OUT	($BE),A
		INC	A
		DJNZ	_ntUpdate
		LD	E,A			; Save the position for follow up scrolls
		RET

; ------------------------------------------------------------------------------
; STATIC relocatable data below this line
; ------------------------------------------------------------------------------

; ----------------------------------
; Terminal status bar initial string
; ----------------------------------

statusBar:	DB	" "
		DB	"Press ESC to exit   "	; Column:01	20 characters
		DB	" "
		DB	"BIT90 VT52"		; Column:22	10 characters
		DB	" "
		DB	" 0000-8N1 "		; Column:33	10 characters
		DB	" "
		DB	"00 00"			; Column: 44	05 characters
		DB	" "
		DB	0

speedTable:	DB	24	; 0 = 2400 BAUD
		DB	12	; 1 = 1200 BAUD
		DB	06	; 2 = 0600 BAUD
		DB	03	; 3 = 0300 BAUD

; ----------------------------------
; Extended token table
; ----------------------------------

SECTION ETOKENTABLE

		ORG	EXTOKEN

		BYTE	"TXTMAP"
		BYTE	$E0
		WORD	TXTMAP
		BYTE	"CLS"
		BYTE	$E1
		WORD	CLS
		BYTE	"LINPUT"
		BYTE	$E2
		WORD	LINPUT
		BYTE	"LOCATE"
		BYTE	$E3
		WORD	LOCATE
		BYTE	"CLOAD"
		BYTE	$E4
		WORD	CLOAD
		BYTE	"CBLOAD"
		BYTE	$E5
		WORD	CBLOAD
		BYTE	"CSAVE"		
		BYTE	$E6
		WORD	CSAVE
		BYTE	"CBSAVE"		
		BYTE	$E7
		WORD	CBSAVE
		BYTE	"TERMINAL"
		BYTE	$E8
		WORD	TERMINAL
		BYTE	"COLOR"
		BYTE	$E9
		WORD	COLOR
		BYTE	"EXIT"
		BYTE	$EA
		WORD	EXIT
		BYTE	"VPOKE"
		BYTE	$EB
		WORD	VPOKE
		BYTE	"VPEEK"
		BYTE	$EC
		WORD	VPEEK
		BYTE	"CIRCLE"
		BYTE	$ED
		WORD	CIRCLE
		BYTE	"PAINT"
		BYTE	$EE
		WORD	PAINT
		BYTE	"BEEP"
		BYTE	$EF
		WORD	BEEP
		BYTE	"XCALL"
		BYTE	$F0
		WORD	XCALL
		BYTE	"INVERSE"
		BYTE	$F1
		WORD	INVERSE
		BYTE	"NORMAL"
		BYTE	$F2
		WORD	NORMAL
		BYTE	$FF

; -----------------------------------------------------------------------------
; Characterset bitmap definition 8x4 bit
;
; Example character 'A':
;
;   Line:           $Nibble
;      1: - - - -   0
;      2: - X X -   6
;      3: X - - X   9
;      4: X - - X   9
;      5: X X X X   F
;      6: X - - X   9
;      7: X - - X   9
;      8: - - - -   0
;
; Each line is a nibble, with 2 nibble in 1 byte results in 4 bytes per char:
; A = $06 $99 $F9 $90
;
; To separate the characters 1 more column is required so each character is 8x5
; Horizontal 5 x 50 = 250 pixels (the first character starts at pixel 6)
; Vertical   8 x 24 = 192 pixels
; -----------------------------------------------------------------------------

SECTION	CHARACTERSET

		ORG	CHARDEF+128	; Offset 32 x 4 bytes

		DB	$00,$00,$00,$00	; 32 <space>
		DB	$04,$44,$40,$40	; 33 !
		DB	$0A,$A0,$00,$00	; 34 "
		DB	$09,$F9,$9F,$90	; 35 #
		DB	$02,$7A,$65,$E4	; 36 $
		DB	$09,$A2,$45,$90	; 37 %
		DB	$0E,$A4,$BA,$D0	; 38 &
		DB	$06,$24,$00,$00	; 39 '
		DB	$02,$44,$44,$20	; 40 (
		DB	$04,$22,$22,$40	; 41 )
		DB	$00,$96,$F6,$90	; 42 *
		DB	$00,$44,$E4,$40	; 43 +
		DB	$00,$00,$06,$24	; 44 ,
		DB	$00,$00,$F0,$00	; 45 -
		DB	$00,$00,$06,$60	; 46 .
		DB	$01,$22,$44,$80	; 47 /
		DB	$06,$9B,$D9,$60	; 48 0
		DB	$02,$62,$22,$70	; 49 1
		DB	$06,$91,$68,$F0	; 50 2
		DB	$0F,$12,$19,$60	; 51 3
		DB	$08,$AA,$F2,$20	; 52 4
		DB	$0F,$8E,$19,$60	; 53 5
		DB	$06,$8E,$99,$60	; 54 6
		DB	$0F,$12,$44,$40	; 55 7
		DB	$06,$96,$99,$60	; 56 8
		DB	$06,$99,$71,$60	; 57 9
		DB	$00,$66,$06,$60	; 58 :
		DB	$00,$66,$06,$24	; 59 ;
		DB	$00,$24,$84,$20	; 60 <
		DB	$00,$0F,$0F,$00	; 61 =
		DB	$00,$84,$24,$80	; 62 >
		DB	$06,$92,$40,$40	; 63 ?
		DB	$06,$91,$79,$60	; 64 @
		DB	$06,$99,$F9,$90	; 65 A
		DB	$0E,$9E,$99,$E0	; 66 B
		DB	$07,$88,$88,$70	; 67 C
		DB	$0E,$99,$99,$E0	; 68 D
		DB	$0F,$8E,$88,$F0	; 69 E
		DB	$0F,$8E,$88,$80	; 70 F
		DB	$06,$98,$B9,$60	; 71 G
		DB	$09,$9F,$99,$90	; 72 H
		DB	$07,$22,$22,$70	; 73 I
		DB	$01,$11,$19,$60	; 74 J
		DB	$09,$AC,$CA,$90	; 75 K
		DB	$08,$88,$88,$F0	; 76 L
		DB	$09,$F9,$99,$90	; 77 M
		DB	$09,$DD,$BB,$90	; 78 N
		DB	$06,$99,$99,$60	; 79 O
		DB	$0E,$99,$E8,$80	; 80 P
		DB	$06,$99,$9A,$70	; 81 Q
		DB	$0E,$99,$EA,$90	; 82 R
		DB	$07,$86,$11,$E0	; 83 S
		DB	$0E,$44,$44,$40	; 84 T
		DB	$09,$99,$99,$60	; 85 U
		DB	$09,$99,$9A,$C0	; 86 V
		DB	$09,$99,$9F,$90	; 87 W
		DB	$09,$96,$69,$90	; 88 X
		DB	$09,$99,$71,$60	; 89 Y
		DB	$0F,$12,$48,$F0	; 90 Z
		DB	$06,$44,$44,$60	; 91 [
		DB	$08,$44,$22,$10	; 92 \
		DB	$06,$22,$22,$60	; 93 ]
		DB	$00,$69,$00,$00	; 94 ^
		DB	$00,$00,$00,$0F	; 95 _
		DB	$06,$42,$00,$00	; 96 `
		DB	$00,$69,$9F,$90	; 97 a
		DB	$08,$8E,$99,$E0	; 98 b
		DB	$00,$68,$88,$60	; 99 c
		DB	$01,$17,$99,$70	; 100 d
		DB	$00,$69,$E8,$70	; 101 e
		DB	$02,$44,$E4,$48	; 102 f
		DB	$00,$79,$97,$16	; 103 g
		DB	$08,$8E,$99,$90	; 104 h
		DB	$02,$02,$22,$20	; 105 i
		DB	$02,$02,$22,$24	; 106 j
		DB	$08,$9A,$CA,$90	; 107 k
		DB	$04,$44,$44,$60	; 108 l
		DB	$00,$9F,$99,$90	; 109 m
		DB	$00,$E9,$99,$90	; 110 n
		DB	$00,$69,$99,$60	; 111 o
		DB	$00,$E9,$9E,$88	; 112 p
		DB	$00,$79,$97,$11	; 113 q
		DB	$00,$68,$88,$80	; 114 r
		DB	$00,$68,$42,$C0	; 115 s
		DB	$08,$8C,$88,$60	; 116 t
		DB	$00,$99,$99,$60	; 117 u
		DB	$00,$99,$9A,$C0	; 118 v
		DB	$00,$99,$9F,$90	; 119 w
		DB	$00,$09,$66,$90	; 120 x
		DB	$00,$99,$71,$16	; 121 y
		DB	$00,$F1,$68,$F0	; 122 z
		DB	$00,$64,$84,$60	; 123 {
		DB	$04,$40,$44,$40	; 124 |
		DB	$00,$C4,$24,$C0	; 125 }
		DB	$00,$05,$A0,$00	; 126 ~
		DB	$00,$00,$00,$00	; 127 <del>

		.END