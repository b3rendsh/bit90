; ------------------------------------------------------------------------------
; BIT90 RS232 LOAD/SAVE v0.1.1
; Copyright (C) 2022 H.J. Berends
;
; You can freely use, distribute or modify this program.
; It is provided freely and "as it is" in the hope that it will be useful, 
; but without any warranty of any kind, either expressed or implied.
; ------------------------------------------------------------------------------
;
; Use this program to load and save large (up to 32K) programs to the COM port.
;
; Commands:
; Token	Command			Description
; 228	CLOAD			COM load BASIC program 
; 229	CBLOAD [START,LENGTH] 	COM load Binary file 
; 230	CSAVE			COM save BASIC program 
; 231	CBSAVE [START,LENGTH]	COM save Binary file 
;
; Load instructions (use BASIC loader):
; LOAD "BIT90COM"
; RUN
; ------------------------------------------------------------------------------

; BIT90 V3.1 CONSTANTS

TOKENE		=  $7005	; Extended token table
ADDR		=  $71E4	; Pointer to end program memory (marked by 2x zero)
LOMEM		=  $71E6	; Pointer to lowest program memory (LOMEM + 4 = start BASIC program)
HIMEM		=  $71E8	; Pointer to last free memory address

; PROGRAM CONSTANTS

COMSPEED	=  $77FB	; Baudrate selection
COMMODE		=  $77FC	; Baudrate divder / bits / parity / stopbits
COMTIMEOUT	=  $77FD	; Timeout (20sec.)
TIMECOUNT	=  $77FE	; Time counter for timeout
COMSELECT	=  $77FF	; BASIC or Machine code ('B' is BASIC, 'M'is Machine)

	ORG	$7500		; Unused 768 bytes memory area when 16/32KB RAM is present

COMINIT:
	PUSH	HL
	LD	HL,EXTOKEN
	LD	(TOKENE),HL
	LD	A,0		; Speed: 2400 Baud
	LD	(COMSPEED),A
	LD	A,78		; Mode: 8 Bits, No parity, 1 Stopbit
	LD	(COMMODE),A
	LD	A,$1C		; Timeout: 20 seconds ( N * 0.77)
	LD	(COMTIMEOUT),A	
	POP	HL
	RET

CLOAD:
	PUSH	HL
	LD	A,$42			
	LD	(COMSELECT),A
	LD	HL,(HIMEM)	
	LD	DE,(ADDR)
	SBC	HL,DE
	EX	DE,HL
	INC	DE
	JR	comLoad

CBLOAD:
	LD	A,$4D			
	LD	(COMSELECT),A
	CALL	$261A
	JR	Z,loadDefault
	CALL	$06B9
	CALL	$22D6
	LD	BC,DE
	LD	A,(HL)
	CP	$2C
	JP	NZ,$02F3
	INC	HL
	CALL	$06B9
	CALL	$22D6
	PUSH	HL
	LD	HL,BC
	JR	comLoad
loadDefault:	
	PUSH	HL
	LD	DE,(LOMEM)
	LD	HL,(HIMEM)
	SBC	HL,DE
	EX	DE,HL
	INC	DE

comLoad:
	CALL	initPort
	LD	BC, $0000
	LD	A, (COMTIMEOUT)	
	LD	(TIMECOUNT),A
loadData:
	IN	A,($45)
	AND	2
	JR	NZ,loadByte
	DJNZ	loadData		
	DEC	C
	JR	NZ,loadData		
	LD	A,(TIMECOUNT)
	DEC	A
	LD	(TIMECOUNT),A
	JR	NZ, loadData		
	JR	loadEnd
loadByte:
	IN	A,($44)
	LD	(HL),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	Z,loadEnd
	LD	A,$03			
	LD	(TIMECOUNT),A		
	JR	loadData		
loadEnd:
	LD	A,(COMSELECT)
	CP	$42
	JR	NZ,_endCload
	CALL	$30CB
_endCload:
	POP	HL
	RET

CSAVE:
	PUSH	HL
	LD	A,$42			
	LD	(COMSELECT),A
	LD	DE,(LOMEM)	
	INC	DE
	INC	DE
	INC	DE
	INC	DE
	LD	HL,(ADDR)		
	INC	HL
	INC	HL
	INC	HL
	SBC	HL,DE
	EX	DE,HL
	JP	comSave
CBSAVE:
	LD	A,$4D			
	LD	(COMSELECT),A
	CALL	$261A
	JR	Z, saveDefault
	CALL	$06B9
	CALL	$22D6
	LD	BC,DE
	LD	A,(HL)
	CP	$2C
	JP	NZ,$02F3
	INC	HL
	CALL	$06B9
	CALL	$22D6
	PUSH	HL
	LD	HL,BC
	JR	comSave
saveDefault:	
	PUSH	HL
	LD	DE,(LOMEM)
	LD	HL,(HIMEM)
	SBC	HL,DE
	EX	DE,HL
	INC	DE

comSave:
	CALL	initPort
	LD	BC, $0000
	LD	A, (COMTIMEOUT)	
	LD	(TIMECOUNT),A
saveData:
	IN	A,($45)
	AND	1
	JR	NZ,saveByte
	DJNZ	saveData	
	DEC	C
	JR	NZ,saveData		
	LD	A,(TIMECOUNT)
	DEC	A
	LD	(TIMECOUNT),A
	JR	NZ,saveData		
	JR	saveEnd
saveByte:
	LD	A,(HL)
	OUT	($44),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	Z,saveEnd
	LD	A,$03			
	LD	(TIMECOUNT),A
	JR	saveData

saveEnd:
	POP	HL
	RET

initPort:
	LD	A,(COMSPEED)		
	OUT	($46),A		
	LD	A,0		
	OUT	($45),A
	OUT	($45),A
	OUT	($45),A
	LD	A,64	
	OUT	($45),A		
	LD	A,(COMMODE)		
	OUT	($45),A	
	LD	A,55	
	OUT	($45),A		
	RET

EXTOKEN:
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
	BYTE	$FF

	.END	