; ------------------------------------------------------------------------------
; bit90.inc
;
; BIT90 definitions
; ------------------------------------------------------------------------------

; I/O ports
IOVDP0:		equ	$be		; TMS9929A R/W data
IOVDP1:		equ	$bf		; TMS9929A Control

IOPSG0:		equ	$ff		; SN74689AN Sound control 

IOKEY0:		equ	$f8		; Keyboard (out)
IOKEY1:		equ	$cf		; Keyboard (in)

IOCTL0:		equ	$80		; Select keypad (out)
IOCTL1:		equ	$c0		; Select joystick (out)
IOJOY1:		equ	$fc		; Joystick 1 (in)
IOJOY2:		equ	$ff		; Joystick 2 (in)

IOTAP0:		equ	$fb		; Audio out to tape
IOTAP1:		equ	$ff		; Audio in from tape

IORAM0:		equ	$4e		; Expansion RAM off 
IORAM1:		equ	$4f		; Expansion RAM on

IOROM0:		equ	$80		; Select Coleco ROM 
IOROM1:		equ	$88		; Select BASIC ROM 

IOCOM0:		equ	$44		; RS232 Data I/O
IOCOM1:		equ	$45		; RS232 Command or Read status
IOCOM2:		equ	$46		; RS232 Select Baud Rate

IOEXT0:		equ	$07		; Extension ROM (in) 0x00-0x07 
IOEXT1:		equ	$0f		; Extension ROM (in)

IOPRT0:		equ	$10		; Printer 90201 (out)
IOPRT1:		equ	$11		; Printer 90201 (out)
IOPRT2:		equ	$12		; Printer 90201 (in)
IOPRT3:		equ	$13		; Printer 90201 (out)

IOLPT0:		equ	$4a		; Centronics printer (in/out)
IOLPT1:		equ	$48		; Centronics printer (in/out)

; ---------------------------------------------------------
; Error codes
ERR_BREAK	equ	$00		; break
ERR_SYNTAX	equ	$01		; syntax error
ERR_NOMEM	equ	$02		; out of memory
ERR_CONT	equ	$03		; can't continue
ERR_LBO		equ	$04		; line buffer overflow
; 
ERR_FC		equ	$05		; illegal function call
ERR_OV		equ	$06		; overflow
ERR_UN		equ	$07		; underflow
ERR_ST		equ	$08		; error in expression stack
ERR_EC		equ	$09		; expression too complex
ERR_UF		equ	$0a		; undefined function
ERR_RD		equ	$0b		; redimensioned array
ERR_D0		equ	$0c		; divided by zero
ERR_TM		equ	$0d		; type mismatch
ERR_NR		equ	$0e		; no resume
ERR_RE		equ	$0f		; resume without error
ERR_NF		equ	$10		; next without for
ERR_FN		equ	$11		; for without next
ERR_RG		equ	$12		; return without gosub
ERR_OD		equ	$13		; out of data
ERR_BL		equ	$14		; bad line number
ERR_BS		equ	$15		; bad subscript
ERR_IS		equ	$16		; incorrect statement
ERR_ID		equ	$17		; illegal direct
ERR_TP		equ	$18		; tape i/o error
;
ERR_LS		equ	$19		; (not documented)

; ---------------------------------------------------------
; System ram
WARM		equ	$7000		; warm boot flag "BIT90"
TOKENE		equ	$7005		; external token table vector (default internal)
INTVEC		equ	$7007		; interrupt subroutine vector
NMTVEC		equ	$700a		; nmi subroutine vector
var_700d	equ	$700d
var_700e	equ	$700e		; V30
CURPOS		equ	$700f		; cursor position (x*32 + y)
var_7010	equ	$7010		; cursor position 2nd byte
var_7011	equ	$7011
var_7012	equ	$7012
VDPR0		equ	$7014		; VDP shadow register 0
VDPR1		equ	$7015		; VDP shadow register 1
var_7016	equ	$7016
var_7017	equ	$7017
IMMBUF		equ	$7018		; immed (commandline) input buffer
IOBUF		equ	$7098		; i/o buffer
var_70a8	equ	$70a8
var_709d	equ	$709d
var_709e	equ	$709e
var_709f	equ	$709f
var_70a9	equ	$70a9
var_70ed	equ	$70ed
var_7118	equ	$7118
var_711a	equ	$711a
var_7142	equ	$7142
var_7198	equ	$7198
var_7199	equ	$7199
var_719a	equ	$719a
var_719b	equ	$719b
var_719c	equ	$719c
var_719d	equ	$719d
var_719e	equ	$719e
var_71a0	equ	$71a0
var_71a4	equ	$71a4
var_71a5	equ	$71a5
var_71a8	equ	$71a8
var_71a9	equ	$71a9
var_71aa	equ	$71aa
var_71ab	equ	$71ab
var_71ac	equ	$71ac
var_71ad	equ	$71ad
var_71b0	equ	$71b0
var_71b1	equ	$71b1
var_71b4	equ	$71b4
var_71b5	equ	$71b5
var_71b8	equ	$71b8
var_71bc	equ	$71bc
var_71bd	equ	$71bd
var_71be	equ	$71be
var_71bf	equ	$71bf
var_71c0	equ	$71c0
var_71c1	equ	$71c1
var_71c2	equ	$71c2
var_71c3	equ	$71c3
var_71c4	equ	$71c4
var_71c5	equ	$71c5
var_71c7	equ	$71c7
var_71c8	equ	$71c8
var_71c9	equ	$71c9
var_71cb	equ	$71cb
var_71cc	equ	$71cc
var_71ce	equ	$71ce
var_71cf	equ	$71cf
var_71d4	equ	$71d4
var_71d6	equ	$71d6
var_71d7	equ	$71d7
var_71df	equ	$71df
var_71e0	equ	$71e0
var_71e1	equ	$71e1
var_71e8	equ	$71e8		; V30
var_71ec	equ	$71ec
var_71ee	equ	$71ee
LINEH		equ	$71e2           ; last line number of current BASIC program
ADDR		equ	$71e4           ; last memory address of current BASIC program
LOMEM		equ	$71e6           ; lowest memory address for BASIC program
HIMEM		equ	$71e8           ; highest memory address available RAM
MEMT		equ	$71ea           ; highest address for BASIC program (MEMT to HIMEM for string variables)
var_71ef	equ	$71ef
var_71f1	equ	$71f1
PROMPT		equ	$71f2		; ">"
var_71f3	equ	$71f3
var_71f5	equ	$71f5
var_71f7	equ	$71f7
var_71f9	equ	$71f9
var_71fa	equ	$71fa
CURLIN		equ	$71fb           ; current line number
var_71fd	equ	$71fd
var_71ff	equ	$71ff
var_7201	equ	$7201
var_7203	equ	$7203
var_7205	equ	$7205
var_7207	equ	$7207
var_722f	equ	$722f
var_7230	equ	$7230
DIMED		equ	$7231           ; last address array variables (DIMED to HIMEM is free memory)
DIMA		equ	$7233           ; start address array variables (DIMA to DIMED for array variables)
DTAD		equ	$7235           ; start address variable table (DTAD to DIMA for simple variables)
var_7237	equ	$7237
var_7239	equ	$7239
var_723b	equ	$723b
var_723d	equ	$723d
var_723e	equ	$723e
var_7240	equ	$7240
var_7242	equ	$7242
var_7244	equ	$7244
var_7276	equ	$7276
var_72a6	equ	$72a6
var_72a7	equ	$72a7
var_72a8	equ	$72a8
var_72a9	equ	$72a9
var_72b2	equ	$72b2
var_72b4	equ	$72b4
var_72b6	equ	$72b6
var_72b8	equ	$72b8
var_72ba	equ	$72ba
var_72bc	equ	$72bc
var_72be	equ	$72be
var_72d2	equ	$72d2
var_72fa	equ	$72fa
var_7322	equ	$7322
var_7336	equ	$7336
var_7338	equ	$7338
var_7345	equ	$7345
var_7347	equ	$7347
var_7391	equ	$7391
var_733b	equ	$733b		; screen mode
var_733c	equ	$733c
var_733d	equ	$733d
FLSCUR		equ	$733e           ; flash cursor flag
var_733f	equ	$733f
var_7340	equ	$7340		; V30
var_7341	equ	$7341
var_7343	equ	$7343
var_7348	equ	$7348
var_7349	equ	$7349
var_734a	equ	$734a
var_734b	equ	$734b
var_734c	equ	$734c
CPYPC		equ	$7340           ; number chars per line for printer interface
GETKEY		equ	$734d		; console get keyboard character hook
GETLIN		equ	$7350		; console line input hook
DSPCHR		equ	$7353		; console display character hook
DSPLIN		equ	$7356		; console line output hook
BREAK		equ	$7359		; console break hook
var_735c	equ	$735c
var_735d	equ	$735d
var_735e	equ	$735e
var_735f	equ	$735f
var_7360	equ	$7360
var_7361	equ	$7361
var_7363	equ	$7363
var_736e	equ	$736e
var_7379	equ	$7379
var_7384	equ	$7384
var_738f	equ	$738f
BREAK2		equ	$7393
var_74ff	equ	$74ff		; stack pointer

IFDEF R26
  ; 8KB internal RAM, not mirrored
  ; use lower 4KB for user programs
  var_lomem	equ	$6000
  var_himem	equ	$6fff
ELSE
  ; if no valid extension ram then use internal system RAM,
  ; 768 bytes free for user programs (!)
  var_lomem	equ	$7500
  var_himem	equ	$77ff
ENDIF

; IOBUF tape record:
; ------------------
; 7098	$42=header, $44=data
; 7099	checksum
; 709b	number of data bytes in block 		(header: filesize)
; 709d	current block number
; 709e	last block number
; 709f	file type M(achine) or B(asic)
; 70a0	origin address (for binary files)
; 70a2	? 6 bytes same values in every block
; 70a8	data record 256 bytes			(header: length of filename)
; 71a9	M or B file type
; 71aa	start address
; 71ac	file size
; 71ae	filler
; 71b0	filename length
; 71b1	filename (save) 16x0xff (load)
; 71c1	block id (header $42, data $44)
; 71c2	block number
; 71c3	filler
; 71c4	last block number
; 71c5	flag to end load data
; 71c6	filler
; 71c7	start address of data save/load
; 71c9	file length (in bytes)
; 71cb	header id ($42)

