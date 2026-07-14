; ------------------------------------------------------------------------------
; basic.asm
; BIT90 BASIC ROM V3.X (2x 8KB)
;
; Disassembled and commented sources by H.J. Berends.
;
; The source code is shared for educational and non commercial purposes only. 
; It is considered fair use of orphaned software.
;
; Customization of the source code is indicated by build directives, and is
; copyright (c) 2026 H.J. Berends. All rights reserved.
; ------------------------------------------------------------------------------

		INCLUDE	"bit90.inc"

		SECTION BASIC
		ORG	$0000

; 0x0000		
RST0:		
	IFDEF V30
		ld	bc,$0000
		jp	basic_init
		db	$ff
	ELSE
		ld	sp,var_74ff
		xor	a
		jp	basic_init
	ENDIF
		db	$ff

; 0x0008		
RST1:		jp	print_crlf

fun_000b:	call	fun_2540
		ld	c,a
		ret

; 0x0010
RST2:		jp	BREAK2

fun_0013:	call	DSPCHR
		jr	lab_0033

; 0x0018 block copy
RST3:		ld	de,var_71bc
fun_001b:	ld	b,$04
fun_001d:	ld	a,(de)
		ld	(hl),a
		inc	hl
		inc	de
		djnz	fun_001d
		ret
		ds	4,$ff

; 0x0028		
RST5:		ld	de,var_71bc
fun_002b:	ld	b,$04
fun_002d:	ex	de,hl
fun_002e:	call	fun_001d
		ex	de,hl
		ret
		
lab_0033:	ld	c,$09
		jp	lab_0231

; 0x0038
RST7:		jp	INTVEC

; ---------------------------------------------------------
; 0x003b
FUN_PLAY:	ld	a,(VDPR1)
		set	5,a			; enable interrupts
		ld	(VDPR1),a
		call	FUN_SETMOD
		ret

; ---------------------------------------------------------
; 0x0047		
play_off:	ld	a,(VDPR1)
		res	5,a			; disable interrupts
		ld	(VDPR1),a
		call	FUN_SETMOD
		ret
		
lab_0053:	pop	af
		call	FUN_VRAMRD
		jr	lab_007a
		
fun_0059:	in	a,(IOVDP1)
		ld	a,$ff
		call	fun_32d5
		jp	FUN_SETMOD
		ds	3,$ff

; ---------------------------------------------------------
; Non maskable interrupt handler
; Note: the internal interrupt routine is only used to play music.
; 0x0066
NMI_ISR:	push	af
		in	a,(IOVDP1)
		ld	a,(var_735d)
		and	a			; is the vdp rw-flag set?
		jr	z,lab_007d		; z=no
		cp	$55			; vdp read interrupted?
		jr	z,lab_0053		; z=yes, finish vdp read first
		pop	af			; no, then vdp write interrupted
		ld	a,(var_738f)		; value to write to vdp ram
		call	FUN_VRAMWR		; finish vdp write first
		
lab_007a:	inc	sp
		inc	sp
		push	af
		
lab_007d:	push	bc
		push	de
		push	hl
		push	ix
		ld	a,(var_7361)
		dec	a
		ld	(var_7361),a
		ld	(var_735e),a
		jp	nz,lab_0145
		ld	a,(var_7360)
		ld	(var_7361),a
		ld	b,$04
		ld	ix,var_7363
		ld	a,$80
		ld	(var_735f),a
		ld	c,a
		xor	a
		ld	(var_735e),a
		
lab_00a5:	push	bc
		ld	a,(ix+$00)
		and	a
		jp	z,lab_0132
		ld	a,(ix+$01)
		and	a
		jr	z,@r_00b8
		dec	(ix+$01)
		jr	@r_0110
@r_00b8:	ld	a,(ix+$02)
		or	(ix+$03)
		jp	z,lab_0161
		ld	l,(ix+$04)
		ld	h,(ix+$05)
		ld	a,(hl)
		ld	d,a
		and	$c0
		rlca
		rlca
		ld	b,a
		ld	a,d
		and	$3f
		ld	(ix+$01),a
		dec	hl
		ld	e,(hl)
		ld	d,$00
		dec	hl
		ld	a,(ix+$02)
		sub	$01
		ld	(ix+$02),a
		jr	nc,@r_00e6
		dec	(ix+$03)
@r_00e6:	ld	(ix+$04),l
		ld	(ix+$05),h
		ld	a,e
		and	a
		jr	z,@r_0122
		ld	a,b
		and	a
		jr	z,@r_00fa
@r_00f4:	sla	e
		rl	d
		djnz	@r_00f4
@r_00fa:	ld	a,e
		and	$0f
		or	c
		out	(IOPSG0),a
		ld	a,e
		ld	b,$04
@r_0103:	rlca
		rl	d
		djnz	@r_0103
		ld	a,d
		out	(IOPSG0),a
		ld	a,(ix+$00)
		jr	@r_0122
@r_0110:	bit	7,(ix+$00)
		jr	z,@r_011f
		ld	a,(ix+$06)
		and	a
		jr	z,@r_011f
		dec	(ix+$06)
@r_011f:	ld	a,(ix+$06)
@r_0122:	and	$0f
		ld	(ix+$06),a
		xor	$0f
		or	c
		set	4,a
		out	(IOPSG0),a
		ld	hl,var_735e
		inc	(hl)
		
lab_0132:	pop	bc
		ld	a,(var_735f)
		add	a,$20
		ld	(var_735f),a
		ld	c,a
		ld	de,$000b
		add	ix,de
		dec	b
		jp	nz,lab_00a5
		
lab_0145:	pop	ix
		ld	hl,var_735c
		inc	(hl)
		pop	hl
		pop	de
		pop	bc
		ld	a,(var_735e)
		and	a
		jr	nz,@r_0157
		call	play_off
@r_0157:	xor	a
		ld	(var_735d),a
		pop	af
		call	NMTVEC
		retn
		
lab_0161:	bit	6,(ix+$00)
		jr	z,@r_0183
		ld	a,(ix+$07)
		ld	(ix+$02),a
		ld	a,(ix+$08)
		ld	(ix+$03),a
		ld	a,(ix+$09)
		ld	(ix+$04),a
		ld	a,(ix+$0a)
		ld	(ix+$05),a
		pop	bc
		jp	lab_00a5
@r_0183:	xor	a
		ld	(ix+$00),a
		xor	$0f
		or	c
		set	4,a
		out	(IOPSG0),a
		jr	lab_0132
	
; ---------------------------------------------------------
; BASIC initialization
; 0x0190
basic_init:
	IFDEF V30
		dec	bc
		ld	a,b
		or	c
		jr	nz,basic_init
		ld	sp,var_74ff
		xor	a
	ELSE
		ld	bc,$1800
		ld	de,$0000
		call	vdp_block_write
	ENDIF
		ld	(var_7016),a
		ld	(var_733f),a
		ld	(var_71e1),a
		ld	hl,dat_3f94
		ld	de,GETKEY
		ld	bc,$000f
		ldir
		ld	a,$07
		call	fun_0013
		ld	a,$4f
		ld	(CPYPC),a
		out	(IORAM1),a		; enable extension ram
		ld	hl,$8000		; ram start address
		ld	bc,$8000		; ram max size
		;  determine valid extension RAM size
@r_01bf:	ld	a,(hl)				
		cpl
		ld	(hl),a
		cp	(hl)
		jr	nz,@r_01cf
		cpl
		ld	(hl),a
		cpi
		jr	nz,@r_01ce
		jp	pe,@r_01bf
@r_01ce:	dec	hl
@r_01cf:	dec	hl
		ld	de,$8000
		and	a
		ld	b,h
		ld	c,l
		sbc	hl,de
		ld	h,b
		ld	l,c
		jr	z,@r_01de
		jr	nc,@r_01e6
@r_01de:	out	(IORAM0),a
		ld	de,var_lomem
		ld	hl,var_himem
@r_01e6:	
	IFDEF V30
		push	hl
		push	de
	ELSE
		push	de
		push	hl
	ENDIF
		ld	bc,$0005
		ld	hl,dat_3fa3
		ld	de,WARM
@r_01f1:	ld	a,(de)
		cpi
		jr	nz,@r_01fe
		inc	de
		jp	pe,@r_01f1
	IFDEF V30
		pop	de
		pop	hl
		jr	main_loop
@r_01fe:	pop	de
		pop	hl
	ELSE
		pop	hl
		pop	de
		jr	main_loop
@r_01fe:	pop	hl
		pop	de
	ENDIF
		ld	(LOMEM),de
		ld	(MEMT),hl
		ld	hl,dat_3fa3
		ld	de,WARM
		ld	bc,$0007
		ldir
		xor	a
		ld	(var_7011),a
		ld	bc,$4000
		ld	de,$0000
		call	vdp_block_write
	IFDEF V30
		call	FUN_NEW
	ENDIF
		call	FUN_INIEP1
		call	FUN_HOME
		ld	hl,dat_3250
		call	print_string
	IFNDEF V30
		call	init_new
	ENDIF
		jr	main_loop
		db	$00
		
lab_0231:	ld	hl,dat_3fa8
		ld	de,TOKENE
		jp	lab_3262
	
; ---------------------------------------------------------
; BASIC main loop	
; 0x023a
main_loop:	call	init_screen
		call	FUN_LSTCHR
		ld	(CURPOS),hl
		ld	a,(var_71e1)
		bit	4,a
		jr	nz,lab_0252
		rst	RST1
	IF V30 || V31
		rst	RST1
	ELSE
		; no extra blank line before ready prompt
		nop
	ENDIF
		ld	hl,dat_3270
		call	print_string
		
lab_0252:	rst	RST1
		call	GETLIN
		call	buf_to_bas
		ld	a,(var_71e0)
		and	a
		jr	nz,@r_0271
		call	fun_051d
		ld	a,(IOBUF+2)
		and	a
		jr	z,@r_026a
		jr	main_loop
@r_026a:	ld	hl,var_71e1
		res	4,(hl)
		jr	main_loop
@r_0271:	call	fun_0383
		ld	hl,IOBUF
		ld	de,IMMBUF
		ld	bc,$0080
		ldir
		ld	hl,var_71e1
		res	7,(hl)
		res	4,(hl)
		ld	hl,IMMBUF
		rst	RST1
		
lab_028a:	ld	(var_7203),hl
		ld	a,(HL)
		and	a
		jr	z,@r_029d
		call	fun_04cc
		ld	ix,@r_029d
		push	de
		ex	(sp),ix
		jp	(ix)
		
@r_029d:	call	FUN_FREA
		ld	a,(hl)
		and	a
		jr	z,lab_02a8
		cp	$95
		jr	nz,lab_02e6
		
lab_02a8:	ld	a,(var_71e1)
		bit	7,a
		jr	z,main_loop

lab_02af:
	IFNDEF V30
		call	BREAK
		cp	$1b
		jr	nz,@r_02b9
		jp	FUN_STOP
	ENDIF
@r_02b9:	ld	hl,(CURLIN)
		ld	a,(hl)
		and	a
		jr	nz,lab_0328
		inc	hl
		ld	a,(hl)
		and	a
		jr	z,@r_02c8
		dec	hl
		jr	lab_0328
@r_02c8:	ld	hl,(var_72b2)
		ld	de,(var_72bc)
		and	a
		sbc	hl,de
		jr	nz,@r_02e3
		ld	hl,var_71e1
		bit	1,(hl)
		ld	a,$0e
		jp	nz,BREAK2
		call	FUN_INITIAL
		pop	hl
		ret
@r_02e3:	ld	a,ERR_FN		; for without next
		rst	RST2
		
lab_02e6:	cp	$3a
		jr	nz,@r_02ed
		inc	hl
		jr	lab_028a
@r_02ed:	ld	a,(var_722f)
		and	a
		jr	nz,lab_02f6

; ---------------------------------------------------------
; Parse expression / syntax error
; V30 0x02e9 / V31 0x02f3		
parse_exp:	ld	a,ERR_SYNTAX		; syntax error (?)
		rst	RST2

; ---------------------------------------------------------
		
lab_02f6:	xor	a
		ld	(var_722f),a
		jr	lab_028a

; ---------------------------------------------------------
; 0x02fc
FUN_RUN:	ld	a,(var_71e1)
@r_02ff:	bit	7,a
@r_0301:	ret	nz
		call	fun_0621
		push	hl
		ld	hl,(LOMEM)
		ld	a,(var_71e0)
		and	a
		jr	z,@r_031c
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	a,(de)
		ld	b,a
		inc	de
		ld	a,(de)
		dec	de
		or	b
		jr	nz,@r_0324
		pop	hl
		ret
		
@r_031c:	call	FUN_LONUMB	
		jp	nc,parse_exp
		ld	h,d
		ld	l,e
	IFDEF V30
@r_0324:	call	FUN_INIEP1
	ELSE
@r_0324:	call	fun_0981
	ENDIF
		ex	de,hl
		
lab_0328:	ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	(CURLIN),de
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	(var_71f9),de
		inc	hl
		
lab_0338:	ld	a,(var_71e1)
		set	7,a
		ld	(var_71e1),a
		bit	0,a
		jr	z,@r_0351
		ld	a,'<'
		call	DSPCHR
		call	print_line_number
		ld	a,'>'
		call	DSPCHR
@r_0351:		
	IFDEF V30
		call	BREAK
		jp	nc,lab_028a
		cp	$1b
		jp	nz,lab_028a
		xor	a
		rst	RST2
	ELSE
		jp	lab_028a
	ENDIF
	
; ---------------------------------------------------------
; Initialize memory vectors
; 0x0354
init_memvec:	exx
		ld	a,(var_7011)
		and	a
		jr	nz,@r_037b
		ld	de,(ADDR)
		inc	de
		inc	de
@r_0361:	xor	a
		ld	(DIMED),de
		ld	(DIMA),de
		ld	(DTAD),de
		ld	de,(MEMT)
		ld	(HIMEM),de
		ld	(var_7230),a
		exx
		ret
@r_037b:	ld	de,var_lomem
		jr	@r_0361

; ---------------------------------------------------------
; Initialize memory arrangement and expression
; 0x0380		
FUN_INIEP1:	call	init_memvec
fun_0383:	
	IFDEF V30
		exx
		ld	hl,var_71e1
		bit	5,(hl)
		jr	nz,lab_03ef
		ld	hl,(LOMEM)
	ELSE
		ld	a,(var_71e1)
		bit	5,a
		jr	nz,lab_03f0

lab_038a:	exx
		ld	hl,(LOMEM)
	ENDIF
		ld	(var_7338),hl
		ld	de,$0000
		ld	(var_7336),de
		xor	a
		ld	de,var_722f
		ld	(var_7205),de
		ld	de,var_72be
		ld	(var_72b2),de
		ld	(var_72bc),de
		ld	de,var_72d2
		ld	(var_72b4),de
		ld	(var_72ba),de
		ld	de,var_72fa
		ld	(var_72b6),de
		ld	de,var_7322
		ld	(var_72b8),de
		ld	de,var_72a6
		ld	(var_723d),a
		ld	(de),a
		ld	(var_7240),de
		ld	(var_7244),de
		ld	de,var_7276
		ld	(var_723e),de
		ld	(var_7242),de
		ld	(var_722f),a
		ld	(var_71df),a
		ld	de,dat_13fa
		ld	hl,var_71cf
	IFDEF V30
		ld	b,$0c
	ELSE
		ld	b,$0f
	ENDIF
		call	fun_001d
lab_03ef:	exx
lab_03f0:	ret

; ---------------------------------------------------------
; 0x03f1
FUN_BREAK2:	push	hl
		push	af
		ld	a,(var_71e1)
		ld	(var_71f3),a
		call	FUN_INITIAL
		pop	af
		ld	hl,var_71f3
@r_0400:	bit	3,(hl)
		jr	nz,@r_044a
		and	a
		jr	z,@r_042c
@r_0407:	cp	$05
		jp	nc,@r_049f
		cp	$01
		jr	z,@r_041d
		cp	$02
		jr	z,@r_0422
		cp	$03
		jr	z,@r_0427
		ld	hl,dat_3f6d
		jr	@r_0435
@r_041d:	ld	hl,dat_3f43
@r_0420:	jr	@r_0435
@r_0422:	ld	hl,dat_3f50
		jr	@r_0435
@r_0427:	ld	hl,dat_3f5e
		jr	@r_0435
@r_042c:	ld	hl,(CURLIN)
		ld	(var_7237),hl
		ld	hl,dat_3f8e
@r_0435:	push	hl
		call	FUN_LSTCHR
		ld	(CURPOS),hl
		pop	hl
		rst	RST1
		call	print_string
		ld	a,(var_71f3)
		bit	7,a
		jr	z,@r_048b
		jr	@r_04c1
@r_044a:	ld	a,(var_71f3)
		bit 	7,a
		jr	z,@r_0407
		res	3,a
		set	1,a
		ld	(var_71e1),a
		ld	de,(var_71f9)
		ld	(var_71ff),de
		ld	de,(CURLIN)
		ld	(var_71fd),de
		ld	de,(var_7203)
		ld	(var_7201),de
		ld	de,(var_723b)
		call	FUN_LONUMB
		ld	a,$14
		jr	nc,@r_0407
		ld	h,d
		ld	l,e
		ld	sp,var_74ff
@r_0480:	ld	de,main_loop
		push	de
		push	de
		call	fun_0383
		jp	lab_0328
@r_048b:	ld	hl,var_71f3
		bit	2,(hl)
		jr	nz,@r_049b
		ld	sp,var_74ff
		call	fun_0383
		jp	lab_0252
@r_049b:	res	2,(hl)
		pop	hl
		ret
@r_049f:	sub	$05
		ld	hl,dat_3f0d
		sla	a
		ld	e,a
		ld	d,$00
		add	hl,de
		rst	RST1
		ld	a,(hl)
		call	DSPCHR
		inc	hl
		ld	a,(hl)
		call	DSPCHR
		ld	hl,dat_3f82
		call	print_string
		ld	hl,var_71f3
		bit	7,(hl)
		jr	z,@r_048b
@r_04c1:	ld	hl,dat_3f89
		call	print_string
		call	print_line_number
		jr	@r_048b

; ---------------------------------------------------------
		
fun_04cc:	push	bc
		push	hl
		ld	a,(hl)
		cp	$3f
		jr	nz,@r_04d7
		ld	a,$a0
		jr	@r_04db
@r_04d7:	bit	7,a
		jr	z,@r_04e8
@r_04db:	call	token_get_vec
		jr	nc,@r_04e8
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		pop	hl
		inc	hl
		pop	bc
		ret
@r_04e8:	ld	a,$b3
		pop	hl
		dec	hl
		push	hl
		jr	@r_04db

; ---------------------------------------------------------
; Get token vector
; 0x04ef
token_get_vec:	ld	hl,(TOKENE)
		ld	b,a
		call	fun_04fe
		ret	c
		ld	hl,dat_3a06
		call	fun_04fe
		ret
		
fun_04fe:	dec	hl
		dec	hl
		dec	hl
		jr	@r_0511
@r_0503:	ld	a,(hl)
		bit	7,a
		jr	nz,@r_050a
		jr	@r_0516
@r_050a:	cp	b
		jr	z,@r_051b
		cp	$ff
		jr	z,@r_0519
@r_0511:	ld	(var_71f5),hl
		inc	hl
		inc	hl
@r_0516:	inc	hl
		jr	@r_0503
@r_0519:	and	a
		ret
@r_051b:	scf
		ret

; ---------------------------------------------------------
		
fun_051d:	ld	a,(var_71e1)
		res	5,a
		ld	(var_71e1),a
		ld	a,(IOBUF)
		and	a
		jr	nz,@r_0530
		ld	a,(IOBUF+1)
		and	a
		ret	z
@r_0530:	call	fun_0614
		ld	hl,(ADDR)
		add	hl,bc
		ld	(DIMED),hl
		ld	a,(IOBUF+2)
		and	a
		jr	z,@r_0543
		call	FUN_FREA
@r_0543:	ld	hl,(IOBUF)
		ld	de,(LINEH)
		and	a
		sbc	hl,de
		jr	z,lab_0588
		jr	c,lab_0588
		ld	a,(IOBUF+2)
		and	a
		jr	z,lab_055d
		ld	hl,IOBUF
		call	fun_056e
		
lab_055d:	exx
		ld	hl,(ADDR)
		ld	ix,(ADDR)
		call	fun_2930
		call	fun_2704
		jp	init_memvec
		
fun_056e:	ld	ix,(ADDR)
		push	ix
		pop	de
		inc	de
		inc	de
		ldir
		ld	(ix+$00),e
		ld	(ix+$01),d
		ld	(ADDR),de
		xor	a
		ld	(de),a
		inc	de
		ld	(de),a
		ret
		
lab_0588:	push	bc
		ld	de,(IOBUF)
		call	FUN_LONUMB
		push	de
		jr	nc,lab_05a9
		pop	hl
		
lab_0594:	push	hl
		ld	(var_7345),hl
		ld	(var_7347),hl
		call	fun_28e2
		pop	hl
		pop	bc
		ld	a,(IOBUF+2)
		and	a
		jp	z,lab_055d
		push	bc
		push	hl
		
lab_05a9:	pop	de
		ld	hl,(ADDR)
		xor	a
		sbc	hl,de
		inc	hl
		inc	hl
		push	hl
		pop	bc
		pop	hl
		ld	a,(IOBUF+2)
		and	a
		jp	z,lab_055d
		push	de
		inc	hl
		inc	hl
		push	hl
		ld	de,(ADDR)
		inc	de
		add	hl,de
		ex	de,hl
		lddr
		pop	bc
		ld	hl,(ADDR)
		add	hl,bc
		ld	(ADDR),hl
		pop	de
		push	de
		pop	hl
		add	hl,bc
		ld	a,l
		ld	(de),a
		inc	de
		ld	a,h
		ld	(de),a
		inc	de
		push	bc
		dec	bc
		dec	bc
		ld	hl,IOBUF
		ldir
		pop	bc
		push	de
		pop	ix
		xor	a
		ld	hl,(ADDR)
		sbc	hl,de
		jr	z,@r_060b
@r_05ef:	ld	l,(ix+$00)
		ld	h,(ix+$01)
		add	hl,bc
		ld	(ix+$00),l
		ld	(ix+$01),h
		push	hl
		xor	a
		ld	de,(ADDR)
		sbc	hl,de
		jr	z,@r_060a
		pop	ix
		jr	@r_05ef
@r_060a:	pop	hl
@r_060b:	ld	a,(var_71ab)
		cp	$36
		ret	z
		jp	lab_055d
		
fun_0614:	ld	bc,$0003
		ld	hl,IOBUF+2
@r_061a:	ld	a,(hl)
		and	a
		ret	z
		inc	bc
		inc	hl
		jr	@r_061a
		
fun_0621:	push	bc
		ld	a,$ff
		ld	(var_71e0),a
		ex	de,hl
		ld	hl,$0000
		ld	c,$00
@r_062d:	ld	a,(de)
		cp	$30
		jr	c,@r_0648
		cp	$3a
		jr	nc,@r_0648
		sub	$30
		ld	b,a
		inc	c
		add	hl,hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
		ld	a,l
		or	b
		ld	l,a
		xor	a
		ld	(var_71e0),a
		inc	de
		jr	@r_062d
@r_0648:	ld	a,c
		cp	$05
		pop	bc
		jp	nc,lab_0667
		ex	de,hl
		ld	a,(var_71e0)
		cp	$ff
		jr	z,@r_0662
		ld	a,(var_71ad)
		cp	$76
		jr	z,@r_0662
		ld	a,d
		or	e
		jr	z,lab_0667
@r_0662:	ld	a,(var_71e0)
		and	a
		ret
		
lab_0667:	ld	a,ERR_BL		; bad line number
		rst	RST2
		
fun_066a:	ld	b,$00
		call	fun_2988
		dec	hl
		call	fun_2988
		inc	hl
		ret

; ---------------------------------------------------------
; Locate pointer of a line number
; 0x0675		
FUN_LONUMB:	push	hl
		ld	b,d
		ld	c,e
		ld	hl,(LOMEM)
@r_067b:	ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	a,d
		or	e
		jr	z,@r_069a
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		and	a
		sbc	hl,bc
		dec	de
		dec	de
		dec	de
		jr	z,@r_069e
		ex	de,hl
		jr	c,@r_067b
		ex	de,hl
@r_0697:	pop	hl
		and	a
		ret
@r_069a:	ex	de,hl
		dec	de
		jr	@r_0697
@r_069e:	scf
		pop	hl
		ret
		
; ---------------------------------------------------------
; Get token keyword
; 0x06a1
token_get_keyword:
		call	token_get_vec
		jr	c,@r_06a7
		ret
		;
@r_06a7:	ld	bc,(var_71f5)
		scf
		sbc	hl,bc
		ld	b,l
		ld	hl,(var_71f5)
		inc	hl
		inc	hl
		inc	hl
		dec	b
		dec	b
		scf
		ret

; ---------------------------------------------------------
; Get parameter (1)
; 0x06b9
param_get_1:	push	de
		push	iy
		ld	de,(var_7242)
		xor	a
		call	fun_0972
		ld	de,(var_7244)
		push	de
		ld	de,(var_723e)
		ld	(var_7242),de
		ld	de,(var_7240)
		ld	(var_7244),de
		call	fun_06ef
		pop	de
		ld	(var_7244),de
		call	fun_09ab
		ld	(var_7242),de
		pop	iy
		pop	de
		ret

lab_06ec:	jp	lab_0835

fun_06ef:	push	bc
		push	de
		push	ix
		push	iy
		ld	a,(var_723d)
		or	$01
		ld	(var_723d),a
		
lab_06fd:	ld	a,(hl)
		and	a
		jr	z,lab_06ec
		cp	$3a
		jr	z,lab_06ec
		cp	$2c
		jr	z,lab_06ec
		cp	$3b
		jr	z,lab_06ec
		cp	$80
		jr	c,@r_0729
		cp	$8b
		jr	z,@r_0729
		cp	$8f
		jr	z,@r_0729
		cp	$90
		jr	z,@r_0729
		cp	$af
		jr	z,@r_0729
		cp	$b9
		jr	c,lab_06ec
		cp	$dd
		jr	nc,lab_06ec
@r_0729:	ld	a,(var_723d)
		and	$01
		jp	z,@r_080d
		call	fun_09f8
@r_0734:	jr	nz,@r_0749
		call	fun_0c56
@r_0739:	ld	de,var_71bc
		call	fun_094d
		ld	a,(var_723d)
		and	$fe
		ld	(var_723d),a
		jr	lab_06fd
@r_0749:	ld	a,(hl)
		cp	$2e
		jr	z,@r_0734
		cp	$2d
		jp	z,@r_0807
		cp	$2b
		jr	z,@r_0734
		cp	$22
		jr	nz,@r_0760
		call	fun_0874
		jr	@r_0739
@r_0760:	call	fun_0a5d
		jr	nz,@r_078c
		ld	a,(var_723d)
		cp	$80
		jr	c,@r_0787
		ld	a,(var_72a8)
		cp	d
		jr	nz,@r_0787
		ld	a,(var_72a7)
		cp	e
		jr	nz,@r_0787
		exx
		ld	hl,var_72a9
		ld	de,var_71bc
		ld	bc,$0004
		ldir
		exx
		jr	@r_0739
@r_0787:	call	fun_2c39
		jr	@r_0739
@r_078c:	cp	$28
		jr	nz,@r_079e
		ld	de,fun_0a18		; set function
		inc	hl
		ld	iy,dat_089b
		call	fun_08f1
		jp	lab_06fd
@r_079e:	cp	$da
		jr	z,@r_07c9
		cp	$8b
		jr	z,@r_07c9
		cp	$8f
		jr	z,@r_07c9
		cp	$90
		jr	z,@r_07c9
		cp	$be
		jr	z,@r_080d
		jp	c,parse_exp
		cp	$cf
		jr	c,@r_07c9
		cp	$d0
		jr	z,@r_07c9
		ld	de,@r_0739
		push	de
		call	fun_04cc
		push	de
		pop	iy
		jp	(iy)
@r_07c9:	push	af
		call	fun_04cc
		ld	iy,dat_0893
		call	fun_08f1
		jr	z,lab_0832
		pop	af
		cp	$da
		jr	nz,@r_07fe
		call	fun_0a32
		jr	nz,@r_07f7
		call	fun_2c39
		call	fun_0b51
		jp	z,lab_0888
		push	hl
		ld	hl,(var_71bc)
		dec	hl
		ld	a,(hl)
		cp	$3d
		jr	nz,@r_07f7
		dec	hl
		ld	a,(hl)
		cp	$29
@r_07f7:	jp	nz,lab_0888
		pop	hl
		jp	@r_0739
@r_07fe:	ld	de,fun_0a18		; set function
		ld	iy,dat_089b
		jr	lab_082c
@r_0807:	ld	iy,dat_0895
		jr	lab_0823
@r_080d:	ld	de,$0005
		ld	b,$11
		ld	iy,dat_089a
		ld	a,(hl)
@r_0817:	cp	(iy+$00)
		jr	z,lab_0823
		add	iy,de
		djnz	@r_0817
lab_0820:	jp	parse_exp
lab_0823:	inc	hl
		inc	iy
		ld	e,(iy+$02)
		ld	d,(iy+$03)
lab_082c:	call	fun_08f1
		jp	nz,lab_06fd
lab_0832:	jp	lab_0890
lab_0835:	ld	iy,dat_08ef
		ld	de,@r_0841
		call	fun_08f1
		jr	z,lab_0832
@r_0841:	call	fun_098c
		jr	z,lab_0832
		ld	a,(var_723e)
		ld	de,(var_7242)
		cp	e
		jr	nz,lab_0820
		ld	a,(var_7240)
		ld	de,(var_7244)
		dec	de
		dec	de
		dec	de
		cp	e
		jr	nz,lab_0820
		ld	de,(var_7244)
		ld	(var_7240),de
		ld	a,(var_723d)
		and	$fe
		ld	(var_723d),a
		pop	iy
		pop	ix
		pop	de
		pop	bc
		ret
		
fun_0874:	push	de
		inc	hl
		ld	d,h
		ld	e,l
		ld	c,$00
		ld	a,$22
@r_087c:	cp	(hl)
		inc	hl
		jr	z,@r_0883
		inc	c
		jr	@r_087c
@r_0883:	call	fun_18a7
		pop	de
		ret
		
lab_0888:	ld	a,ERR_UF		; undefined function
		jr	lab_0892
		
lab_088c:	ld	a,ERR_LBO		; line buffer overflow
		jr	lab_0892
		
lab_0890:	ld	a,ERR_ST		; error in expression stack
lab_0892:	rst	RST2

; ---------------------------------------------------------
; expression table
dat_0893:	db	$72,$71
dat_0895:	db	$2d,$60,$61
		dw	fun_0eea
dat_089a:	db	$28
dat_089b:	db	$72,$07
		dw	fun_0a18
		db	$5e,$50,$50
		dw	fun_0f1d
		db	$2a,$40,$40
		dw	fun_0d18			
		db	$2f,$40,$40
		dw	fun_0dd9
		db	$2d,$30,$30
		dw	fun_0ef4
		db	$2b,$30,$30
		dw	fun_0e50
		db	$3e,$20,$20
		dw	fun_0a75
		db	$3c,$20,$20
		dw	fun_0a6d
		db	$3d,$20,$20
		dw	fun_0a7f
		db	$b9,$20,$20
		dw	fun_0a90
		db	$ba,$20,$20
		dw	fun_0a86
		db	$bb,$20,$20
		dw	fun_0a98
		db	$26,$10,$10
		dw	fun_0b69
		db	$bc,$10,$10
		dw	fun_0b69
		db	$bd,$10,$10
		dw	fun_0c02
		db	$be,$11,$11
		dw	fun_0c12
		db	$29,$06
dat_08ec:	db	$06
		dw	fun_09c6
dat_08ef:	db	$01,$01
		
; ---------------------------------------------------------

fun_08f1:	push	hl
@r_08f2:	ld	hl,(var_7240)
		ld	a,(hl)
		cp	(iy+$00)
		jr	c,@r_0933
		push	de
		push	iy
		ld	hl,@r_0928		; set subroutine address
		push	hl
		and	$01
		jr	nz,@r_091c
		ld	hl,(var_723e)		; set return address
		push	hl
		call	fun_098c
		jr	z,@r_0945
		call	fun_098c
		jr	z,@r_0945
		call	fun_09ab
		jr	z,@r_0945
		pop	hl
		jp	(iy)
@r_091c:	call	fun_098c
		jr	z,@r_0946
		call	fun_09ab
		jr	z,@r_0946
		jp	(iy)			; call subroutine
		;
@r_0928:	ld	de,var_71bc
		call	fun_094d
		pop	iy
		pop	de
		jr	@r_08f2
		;
@r_0933:	ld	a,(var_723d)
		or	$01
		ld	(var_723d),a
		ld	a,(iy+$01)
		call	fun_0972
		pop	hl
		or	$01
		ret
@r_0945:	pop	hl
@r_0946:	pop	iy
		pop	iy
		pop	de
		pop	hl
		ret
		
fun_094d:	push	de
		exx
		pop	hl
		ld	de,(var_723e)
		ld	bc,$0004
		inc	hl
		inc	hl
		inc	hl
		dec	de
		lddr
		inc	de
		inc	hl
		ld	(var_723e),de
		exx	
		ret

; ---------------------------------------------------------
; 0x0965
FUN_BREAK:	ld	a,$20
		out	(IOKEY0),a
		in	a,(IOKEY1)
		and	$20
		ret	nz
		scf
		ld	a,$1b
		ret

; ---------------------------------------------------------
		
fun_0972:	push	hl
		ld	hl,(var_7240)
		dec	hl
		ld	(hl),d
		dec	hl
		ld	(hl),e
		dec	hl
		ld	(hl),a
		ld	(var_7240),hl
		pop	hl
		ret
		
	IFDEF V30
		ds	6,$ff
	ELSE
fun_0981:	call	init_memvec
		jp	lab_038a
	ENDIF
		; 0x0987 unused
		ld	a,ERR_ST
		jp	lab_0892

fun_098c:	ld	a,(var_723e)
		push	de
		ld	de,var_7276
		cp	e
		pop	de
		ret	z
		push	bc
		push	de
		push	hl
		ld	hl,(var_723e)
		ld	de,var_71bc
		ld	bc,$0004
		ldir
		ld	(var_723e),hl
		pop	hl
		pop	de
		pop	bc
		ret

fun_09ab:	ld	a,(var_7240)
		push	de
		ld	de,var_72a6
		cp	e
		pop	de
		ret	z
		push	hl
		ld	hl,(var_7240)
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		push	de
		pop	iy
		inc	hl
		ld	(var_7240),hl
		pop	hl
		ret
		
fun_09c6:	ret
		
; ---------------------------------------------------------
; 0x09c7
FUN_FN:		ld	a,(var_723d)
		or	$80
		ld	(var_723d),a
		ld	de,var_72a9
		ld	bc,$0004
		ld	hl,var_71bc
		ldir
		call	fun_098c
		ld	hl,(var_71be)
		ld	(var_72a7),hl
		ld	hl,(var_71bc)
		call	param_get_1
		ld	a,(var_723d)
		and	$7e
		ld	(var_723d),a
		ret

; ---------------------------------------------------------
		
		; 0x09f2 unused
		pop	iy
		pop	iy
		jr	lab_0a24

; ---------------------------------------------------------
		
fun_09f8:	ld	a,(hl)
		cp	$20
		jr	nz,@r_0a00
		inc	hl
		jr	fun_09f8
@r_0a00:	cp	$30
		ret	c
		cp	$39
		
lab_0a05:	ret	z
		ret	nc
		cp	a
		ret
		
fun_0a09:	ld	a,(hl)
		cp	$41
		ret	c
		cp	$5b
		jr	c,lab_0a05
		cp	$61
		ret	c
		cp	$7a
		jr	lab_0a05
		
fun_0a18:	pop	iy
		pop	iy
		ld	a,(dat_08ec)
		cp	(iy+$00)
		jr	nz,lab_0a2f

lab_0a24:	ld	de,var_71bc
		call	fun_094d
		or	$01
		;
lab_0a2c:	pop	de
		pop	hl
		ret

lab_0a2f:	cp	a
		jr	lab_0a2c

fun_0a32:	call	fun_0a09
		jr	nz,@r_0a5c
		ld	d,a
		inc	hl
		ld	e,$00
		call	fun_0a09
		jr	z,@r_0a45
		call	fun_09f8
		jr	nz,@r_0a51
@r_0a45:	ld	e,a
@r_0a46:	inc	hl
		call	fun_0a09
		jr	z,@r_0a46
		call	fun_09f8
		jr	z,@r_0a46
@r_0a51:	ld	a,(hl)
		cp	$24
		jr	nz,@r_0a5b
		ld	a,e
		add	a,$80
		ld	e,a
		inc	hl
@r_0a5b:	xor	a
@r_0a5c:	ret

fun_0a5d:	call	fun_0a32
		ret	nz
		ld	a,(hl)
		cp	$28
		jr	nz,@r_0a6b
		ld	a,d
		add	a,$80
		ld	d,a
		inc	hl
@r_0a6b:	xor	a
		ret

; ---------------------------------------------------------

fun_0a6d:	call	fun_0af9
		jp	m,lab_0aa6
		jr	lab_0a9d

fun_0a75:	call	fun_0af9
		jr	z,lab_0a9d
		jp	p,lab_0aa6
		jr	lab_0a9d

fun_0a7f:	call	fun_0af9
		jr	z,lab_0aa6
		jr	lab_0a9d

fun_0a86:	call	fun_0af9
		jr	z,lab_0aa6
		jp	m,lab_0aa6
		jr	lab_0a9d

fun_0a90:	call	fun_0af9
		jp	p,lab_0aa6
		jr	lab_0a9d

fun_0a98:	call	fun_0af9
		jr	nz,lab_0aa6

lab_0a9d:	xor	a
		ld	(var_71bc),a
		ld	(var_71bd),a
		jr	lab_0ab0

lab_0aa6:	ld	a,$81
		ld	(var_71bc),a
		ld	a,$80
		ld	(var_71bd),a

lab_0ab0:	xor	a
		ld	(var_71be),a
		ld	(var_71bf),a
		ret
		
fun_0ab8:	ld	a,(ix+$01)
		and	a
		ret	nz
		ld	a,(ix+$00)
		and	a
		jr	nz,@r_0acb
		ld	a,(ix+$02)
		and	a
		jr	nz,@r_0acb
		inc	a
		ret
@r_0acb:	xor	a
		ret

; ---------------------------------------------------------

lab_0acd:	ld	a,(var_71bc)
		ld	c,a
		sub	(hl)
		ld	(var_71bc),a
		jr	c,@r_0ad8
		ld	c,(hl)
@r_0ad8:	ld	a,c
		and	a
		jr	z,lab_0af3
		inc	hl
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	hl,(var_71be)
		ld	b,$00
@r_0ae6:	ld	a,(de)
		cpi
		jp	m,lab_0b46
		jp	nz,lab_0b42
		inc	de
		jp	pe,@r_0ae6
		;
lab_0af3:	ld	a,(var_71bc)
		ld	b,a
		jr	lab_0b3a

; ---------------------------------------------------------
		;
fun_0af9:	push	bc
		push	de
		push	hl
		push	ix
		ld	ix,var_71bc
		call	fun_0ab8
		jr	nz,lab_0b14
		push	hl
		pop	ix
		call	fun_0ab8
		jr	z,lab_0acd

; ---------------------------------------------------------
		
lab_0b0f:	ld	a,ERR_TM	; type mismatch
		jp	lab_0892	; rst RST2

; ---------------------------------------------------------

lab_0b14:	push	hl
		pop	ix
		call	fun_0ab8
		jr	z,lab_0b0f
		call	fun_0ef4
		ld	a,(var_71bc)
		bit	7,a
		jr	nz,lab_0b46
		and	$7f
		jr	nz,lab_0b42
		ld	b,$03
		ld	ix,var_71bd
@r_0b30:	ld	a,(ix+$00)
		and	a
		jr	nz,lab_0b42
		inc	ix
		djnz	@r_0b30
		;
lab_0b3a:	xor	a
		or	b
		pop	ix
		pop	hl
		pop	de
		pop	bc
		ret
		;
lab_0b42:	ld	b,$01
		jr	lab_0b3a
		;
lab_0b46:	ld	b,$ff
		jr	lab_0b3a
		
; ---------------------------------------------------------

fun_0b4a:	ld	de,dat_0b63
		call	fun_0b54
		ret	z
		
fun_0b51:	ld	de,dat_0b65

fun_0b54:	push	hl
		ld	bc,$0004
@r_0b58:	ld	a,(de)
		cpi
		jr	nz,@r_0b61
		inc	de
		jp	pe,@r_0b58
@r_0b61:	pop	hl
		ret

dat_0b63:	db	$81,$80
dat_0b65:	db	$00,$00,$00,$00

; ---------------------------------------------------------

fun_0b69:	call	fun_0b4a
		jr	z,@r_0bd1
		push	hl
		ld	hl,var_71bc
		call	fun_0b4a
		jp	z,lab_0b0f
		pop	hl
		push	hl
		pop	ix
		call	fun_0ab8
		jp	nz,@r_0bd8
		ld	ix,var_71bc
		call	fun_0ab8
		jp	nz,@r_0bd8
		ld	de,(DIMED)
		ld	a,(var_71bc)
		ld	b,$00
		ld	c,a
		push	bc
		cp	b
		jr	z,@r_0ba1
		push	hl
		ld	hl,(var_71be)
		ldir	
		pop	hl
@r_0ba1:	ld	a,(hl)
		and	a
		jr	z,@r_0bb1
		ld	c,a
		push	bc
		inc	hl
		inc	hl
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		ld	h,b
		ld	l,c
		pop	bc
		ldir
@r_0bb1:	pop	bc
		add	a,c
		jp	c,lab_088c
		cp	$81
		jp	nc,lab_088c
		ld	c,a
		ld	(var_71bc),a
		ld	hl,(DIMED)
		ld	de,IOBUF
		ld	a,(var_71bc)
		ld	(var_71be),de
		and	a
		ret	z
		ldir
		ret
@r_0bd1:	push	hl
		ld	hl,var_71bc
		call	fun_0b4a
@r_0bd8:	jp	nz,lab_0b0f
		pop	hl
		ld	a,(var_71bc)
		and	a
		ret	z
		ld	a,(hl)
		and	a
		ret	nz
		;
lab_0be4:	ld	hl,dat_0b65
lab_0be7:	ld	de,var_71bc
		ld	bc,$0004
		ldir	
		ret
		
fun_0bf0:	call	fun_0b4a
		jp	nz,lab_0b0f
fun_0bf6:	push	hl
		ld	hl,var_71bc
		call	fun_0b4a
		jp	nz,lab_0b0f
		pop	hl
		ret

fun_0c02:	call	fun_0bf0
		ld	a,(var_71bc)
		and	a
		ret	nz
		ld	a,(hl)
		and	a
		ret	z
lab_0c0d:	ld	hl,dat_0b63
		jr	lab_0be7

fun_0c12:	call	fun_0bf6
		ld	a,(var_71bc)
		and	a
		jr	z,lab_0c0d
		jr	lab_0be4

; ---------------------------------------------------------
		
lab_0c1d:	push	ix
		ld	ix,var_71bc
		add	a,(ix+$03)
		jr	nc,@r_0c53
		ld	a,$00
		adc	a,(ix+$02)
		jr	nc,@r_0c53
		ld	a,(ix+$01)
		cp	$ff
		jr	nz,@r_0c48
		ld	a,(ix+$00)
		and	$3f
		cp	$3f
		jr	z,@r_0c53
		ld	a,(ix+$00)
		inc	a
		ld	(ix+$00),a
		ld	a,$7f
@r_0c48:	inc	a
		ld	(ix+$01),a
		xor	a
		ld	(ix+$02),a
		ld	(ix+$03),a
@r_0c53:	pop	ix
		ret
		
fun_0c56:	ex	de,hl
		ld	c,$00
		call	fun_0caa
		ld	b,$00
		cp	$2e
		call	z,fun_0cc2
		pop	af
		or	$18
		ld	(var_71bc),a
		ld	a,b
		add	a,c
		push	af
		push	de
		call	fun_0d72
		ld	a,(de)
		cp	$45
		jr	nz,@r_0c90
		ld	hl,var_71c0
		rst	RST3
		pop	de
		inc	de
		call	fun_0caa
		ld	a,(var_71bf)
		pop	bc
		inc	b
		jp	p,@r_0c88
		cpl
		inc	a
@r_0c88:	pop	bc
		add	a,b
		push	af
		ld	hl,var_71c0
		push	de
		rst	RST5
@r_0c90:	pop	hl
		pop	af
@r_0c92:	ret	z
		push	hl
		ld	hl,dat_1406
		jp	m,@r_0ca3
		dec	a
		push	af
		call	fun_0d18
@r_0c9f:	pop	af
		pop	hl
		jr	@r_0c92
@r_0ca3:	inc	a
		push	af
		call	fun_0dd9
		jr	@r_0c9f

fun_0caa:	ld	hl,var_71bc
		ld	b,$04
		call	fun_0e4a
		ld	hl,$8000
		ld	a,(de)
		cp	$2d
		jr	z,@r_0cc0
		ld	h,l
		cp	$2b
		jr	z,@r_0cc0
		dec	de
@r_0cc0:	ex	(sp),hl
		push	hl
		
fun_0cc2:	inc	de
		ld	a,(de)
		cp	$30
		ret	c
		cp	$3a
		ret	nc
		dec	b
		push	de
		push	bc
		call	fun_0cf3
		or	a
		jr	z,@r_0cdc
		ld	hl,var_71c4
		rst	RST5
		pop	bc
		inc	c
		pop	de
		jr	fun_0cc2
@r_0cdc:	pop	bc
		pop	de
		ld	a,(de)
		and	$0f
		ld	hl,var_71bf
		add	a,(hl)
		ld	(hl),a
		push	bc
		ld	b,$02
@r_0ce9:	dec	hl
		ld	a,(hl)
		adc	a,$00
		ld	(hl),a
		djnz	@r_0ce9
		pop	bc
		jr	fun_0cc2
		
fun_0cf3:	ld	hl,var_71c4
		rst	RST3
		call	fun_0d03
		call	fun_0d03
		ld	hl,var_71c7
		call	fun_0d06
		
fun_0d03:	ld	hl,var_71bf

fun_0d06:	ld	de,var_71bf
		ld	b,$04
		
fun_0d0b:	xor	a
@r_0d0c:	ld	a,(de)
		adc	a,(hl)
		ld	(de),a
		dec	de
		dec	hl
		djnz	@r_0d0c
		ret

fun_0d14:	ld	b,$03
		jr	fun_0d0b
		
fun_0d18:	call	fun_0dcb
		ret	z
		inc	hl
		ld	a,(hl)
		dec	hl
		or	a
		jp	z,RST5
		push	hl
		call	fun_0d9f
		add	a,b
		call	fun_0db5
		pop	hl
		ld	de,var_71c9
		ld	b,$03
		inc	hl
		call	fun_002d
		ld	hl,var_71c0
		ld	b,$06
		call	fun_0e4a
		ld	de,var_71bd
		ld	b,$03
@r_0d42:	ld	a,(de)
		ld	(hl),a
		xor	a
		ld	(de),a
		inc	de
		inc	hl
		djnz	@r_0d42
		ld	c,$18
@r_0d4c:	ld	b,$03
		ld	hl,var_71c9
		xor	a
@r_0d52:	rr	(hl)
		inc	hl
		djnz	@r_0d52
		jr	nc,@r_0d64
		ld	de,var_71c2
		ld	hl,var_71c8
		ld	b,$06
		call	fun_0d0b
@r_0d64:	ld	b,$06
		ld	hl,var_71c8
		xor	a
@r_0d6a:	rl	(hl)
		dec	hl
		djnz	@r_0d6a
		dec	c
		jr	nz,@r_0d4c
		
fun_0d72:	ld	hl,var_71bf
		ld	b,$02
		ld	a,(hl)
@r_0d78:	dec	hl
		or	(hl)
		djnz	@r_0d78
		dec	hl
		ld	b,(hl)
		ld	(hl),a
		ret	z
		ld	(hl),b
		push	bc
		call	fun_0da9
		ld	(hl),a
@r_0d86:	inc	hl
		ld	a,(hl)
		or	a
		jp	m,@r_0d98
		inc	hl
		inc	hl
		ld	b,$03
@r_0d90:	rl	(hl)
		dec	hl
		djnz	@r_0d90
		dec	(hl)
		jr	@r_0d86
@r_0d98:	dec	hl
		ld	a,(hl)
		call	fun_0db5
		pop	bc
		ret
		
fun_0d9f:	call	fun_0da9
		ld	b,a
		ld	hl,var_71bc
		ld	a,c
		add	a,(hl)
		ld	(hl),a
		
fun_0da9:	ld	a,(hl)
		and	$80
		ld	c,a
		ld	a,(hl)
		
fun_0dae:	and	$7f
		add	a,$40
		xor	$40
		ret
		
fun_0db5:	or	a
		jp	p,@r_0dc0
		cp	$c1
		jr	nc,@r_0dc7
		ld	a,ERR_UN		; underflow
		rst	RST2
@r_0dc0:	cp	$40
		jr	c,@r_0dc7
		ld	a,ERR_OV		; overflow
		rst	RST2
@r_0dc7:	and	$7f
		or	c
		ld	(hl),a
		
fun_0dcb:	ld	a,(var_71bd)
		or	a
		ret	z
		ld	a,(var_71bc)
		or	$7f
		ld	a,(var_71bc)
		ret
		
fun_0dd9:	inc	hl
		ld	a,(hl)
		dec	hl
		or	a
		jp	z,lab_13ee
		call	fun_0dcb
		ret	z
		push	hl
		call	fun_0d9f
		sub	b
		inc	a
		call	fun_0db5
		ld	de,var_71bd
		ld	hl,var_71c0
		ld	(hl),$00
		inc	hl
		ld	b,$03
@r_0df8:	ld	a,(de)
		ld	(hl),a
		xor	a
		ld	(de),a
		inc	hl
		inc	de
		djnz	@r_0df8
		pop	de
		ld	b,$03
		inc	de
		ld	(hl),$00
		inc	hl
		call	fun_001d
		ld	c,$18
@r_0e0c:	ld	de,var_71c3
		ld	hl,var_71c7
		ld	b,$04
		call	fun_0e41
		jr	nc,@r_0e25
		ld	de,var_71c3
		ld	hl,var_71c7
		ld	b,$04
		call	fun_0d0b
		scf
@r_0e25:	ccf
		ld	b,$03
		ld	hl,var_71bf
@r_0e2b:	rl	(hl)
		dec	hl
		djnz	@r_0e2b
		xor	a
		ld	b,$04
		ld	hl,var_71c3
@r_0e36:	rl	(hl)
		dec	hl
		djnz	@r_0e36
		dec	c
		jr	nz,@r_0e0c
		jp	fun_0d72
		
fun_0e41:	xor	a
@r_0e42:	ld	a,(de)
		sbc	a,(hl)
		ld	(de),a
		dec	de
		dec	hl
		djnz	@r_0e42
		ret
		
fun_0e4a:	ld	(hl),$00
		inc	hl
		djnz	fun_0e4a
		ret
		
fun_0e50:	inc	hl
		ld	a,(hl)
		or	a
		jp	z,fun_0dcb
		dec	hl
		call	fun_0dcb
		jp	z,RST5
		call	fun_0dae
		ld	b,a
		ld	a,(hl)
		call	fun_0dae
		ld	c,a
		sub	b
		jr	z,@r_0e7a
		jp	p,@r_0e6e
		cpl
		inc	a
@r_0e6e:	cp	$18
		jr	c,@r_0e7a
		ld	a,b
		sub	c
		jp	p,fun_0dcb
		jp	RST5
@r_0e7a:	push	af
		push	bc
		ld	de,var_71c0
		call	fun_002b
		pop	bc
		pop	af
		jr	z,@r_0ea7
		ld	hl,var_71c1
		push	af
		ld	a,b
		sub	c
		jp	p,@r_0e9a
		ld	hl,var_71bc
		res	7,c
		ld	a,(hl)
		and	$80
		or	c
		ld	(hl),a
		inc	hl
@r_0e9a:	pop	af
		ld	c,a
@r_0e9c:	ld	b,$03
		xor	a
		push	hl
		call	fun_0f0b
		pop	hl
		dec	c
		jr	nz,@r_0e9c
@r_0ea7:	ld	hl,var_71c0
		ld	a,(var_71bc)
		xor	(hl)
		ld	de,var_71bf
		ld	hl,var_71c3
		jp	m,@r_0ecf
		call	fun_0d14
		jp	nc,fun_0dcb
		ex	de,hl
		call	fun_0da9
		inc	a
		call	fun_0db5
		inc	hl
		scf
		ld	b,$03
		call	fun_0f0b
		jp	fun_0dcb
@r_0ecf:	ld	b,$03
		call	fun_0e41
		jp	nc,fun_0d72
		ld	hl,var_71bf
		ld	b,$03
		scf
@r_0edd:	ld	a,(hl)
		cpl
		jr	nc,@r_0ee3
		add	a,$01
@r_0ee3:	ld	(hl),a
		dec	hl
		djnz	@r_0edd
		call	fun_0d72
		
fun_0eea:	call	fun_0dcb
		ret	z
		xor	$80
		ld	(var_71bc),a
		ret

fun_0ef4:	call	fun_0f11
		dec	hl
		jp	z,fun_0dcb
		ld	a,(hl)
		xor	$80
		ld	(hl),a
		push	hl
		call	fun_0e50
		pop	hl
		ld	a,(hl)
		xor	$80
		ld	(hl),a
		jp	fun_0dcb
		
fun_0f0b:	rr	(hl)
		inc	hl
		djnz	fun_0f0b
		ret

fun_0f11:	ld	de,var_71c0
		push	de
		call	fun_002b
		pop	hl
		inc	hl
		ld	a,(hl)
		or	a
		ret

; ---------------------------------------------------------

fun_0f1d:	push	hl
		ld	hl,var_71a0
		rst	RST3
		pop	hl
		rst	RST5
		call	fun_0dcb
		jp	z,lab_10f3
		ld	hl,var_71b8
		rst	RST3
		call	FUN_INT
		ld	hl,var_71b8
		ld	de,var_71bc
		ld	b,$0004
@r_0f39:	ld	a,(de)
		cp	(hl)
		jp	nz,@r_0fa7
		inc	de
		inc	hl
		djnz	@r_0f39
		call	FUN_ABS
		ld	hl,var_71b8
		ld	de,var_71bc
		ld	a,(de)
		cp	(hl)
		jr	z,@r_0f53
		ld	a,$36
		jr	@r_0f55
@r_0f53:	ld	a,$00
@r_0f55:	ld	(var_71b4),a
		ld	hl,var_71b8
		rst	RST3
		ld	hl,var_71a0
		rst	RST5
		ld	hl,var_71a4
		rst	RST3
		call	fun_0dcb
		ret	z
@r_0f68:	ld	hl,var_71b8
		rst	RST5
		ld	hl,dat_1452
		call	fun_0ef4
		call	fun_0dcb
		jr	z,@r_0f8b
		ld	hl,var_71b8
		rst	RST3
		ld	hl,var_71a4
		rst	RST5
		ld	hl,var_71a0
		call	fun_0d18
		ld	hl,var_71a4
		rst	RST3
		jr	@r_0f68
@r_0f8b:	ld	a,(var_71b4)
		cp	$36
		jr	nz,@r_0f9e
		ld	hl,dat_1452
		rst	RST5
		ld	hl,var_71a4
		call	fun_0dd9
		jr	@r_0fa2
@r_0f9e:	ld	hl,var_71a4
		rst	RST5
@r_0fa2:	ld	a,$30
		jp	lab_0c1d
@r_0fa7:	ld	hl,var_71a0
		rst	RST5
		call	fun_0dcb
		ret	z
		call	FUN_LN
		ld	hl,var_71b8
		call	fun_0d18
		jp	FUN_EXP

; ---------------------------------------------------------
; 0x0fbb
FUN_LN:		call	fun_0dcb
		jp	m,lab_13f1
		jp	z,lab_13f1
		ld	hl,var_71a4
		rst	RST3
		ld	a,(var_71bc)
		call	fun_0dae
		jr	z,@r_0fd3
		jp	p,@r_0fde
@r_0fd3:	cpl
		add	a,$02
		call	fun_10db
		call	fun_0eea
		jr	@r_0fe3
@r_0fde:	sbc	a,$01
		call	fun_10db
@r_0fe3:	ld	hl,dat_1416
		call	fun_0d18
		ld	hl,var_71a0
		rst	RST3
		rst	RST5
		ld	a,$01
		ld	(var_71bc),a
		ld	hl,dat_1452
		push	hl
		call	fun_0ef4
		pop	de
		ld	hl,var_71a4
		call	fun_001b
		ld	hl,dat_146e
		jp	fun_1073
		
; ---------------------------------------------------------
; 0x1007
FUN_LOG:	call	fun_100f
		ld	a,$10
		jp	lab_0c1d
		
fun_100f:	call	FUN_LN
		ld	hl,dat_148a
		jp	fun_0d18

; ---------------------------------------------------------
; 0x1018
FUN_EXP:	call	fun_0dcb
		jp	p,fun_1032
		call	fun_0eea
		call	fun_1032
		ld	hl,var_71a0
		rst	RST3
		ld	hl,dat_1452
		rst	RST5
		ld	hl,var_71a0
		jp	fun_0dd9
		
fun_1032:	ld	hl,dat_1472
		call	fun_0d18
		ld	hl,var_71a8
		rst	RST3
		call	FUN_INT
		ld	hl,var_71ac
		rst	RST3
		rst	RST3
		ld	a,(var_71bc)
		ld	b,a
		ld	a,(var_71bd)
@r_104b:	rlca
		djnz	@r_104b
		inc	a
		ld	(var_71ac),a
		ld	a,$80
		ld	(var_71ad),a
		ld	hl,dat_1452
		rst	RST5
		ld	hl,var_71a0
		rst	RST3
		rst	RST3
		rst	RST5
		ld	hl,var_71b0
		call	fun_0ef4
		ld	hl,dat_1486
		call	fun_1073
		ld	hl,var_71ac
		jp	fun_0d18
		
fun_1073:	push	hl
		ld	hl,var_71a8
		rst	RST3
		pop	hl
		push	hl
		jr	@r_1083
@r_107c:	push	hl
		call	fun_0e50
		ld	hl,var_71a8
@r_1083:	call	fun_0d18
		pop	hl
		call	fun_13dd		; note: complicated function to dec hl by 4,
		db	$fc			; hl = hl + $$fffc = hl - 4
		ld	a,(hl)
		dec	a
		jr	nz,@r_107c
		ld	hl,var_71a4
		call	fun_0d18
		ld	hl,var_71a0
		jp	fun_0e50
		
; ---------------------------------------------------------
; 0x109b
FUN_INT:	ld	hl,var_71bc
		bit	6,(hl)
		jr	z,@r_10a7
		ld	b,$04
		jp	fun_0e4a
@r_10a7:	ld	a,(hl)
		bit	7,a
		jr	z,@r_10b6
		ld	hl,dat_1412
		call	fun_0e50
		ld	hl,var_71bc
		ld	a,(hl)
@r_10b6:	and	$3f
		cp	$18
		ret	p
		ld	b,a
		ld	a,$18
		sub	b
		ld	c,a
@r_10c0:	ld	hl,var_71bd
		xor	a
		ld	b,$03
@r_10c6:	ld	a,(hl)
		rra
		ld	(hl),a
		inc	hl
		djnz	@r_10c6
		dec	c
		jr	nz,@r_10c0
		ld	hl,var_71bc
		ld	a,(hl)
		and	$80
		add	a,$18
		ld	(hl),a
		jp	fun_0d72

fun_10db:	ld	e,a
fun_10dc:	ld	d,$00
fun_10de:	ld	hl,var_71bc
		ld	(hl),$018
		inc	hl
		ld	(hl),$00
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),e
		jp	fun_0d72
		
; ---------------------------------------------------------
; 0x10ed
FUN_SGN:	call	fun_0dcb
		ret	z
		and	$80
		;
lab_10f3:	or	$01
		push	af
		ld	hl,dat_1452
		rst	RST5
		pop	af
		ld	(var_71bc),a
		ret
		
; ---------------------------------------------------------
; 0x10ff
FUN_SQR:	call	fun_1107
		ld	a,$12
		jp	lab_0c1d
		
fun_1107:	call	fun_0dcb
		ret	z
		jp	m,lab_13f1
		ld	(var_71ce),a
		xor	a
		ld	(var_71bc),a
		ld	hl,var_71a4
		rst	RST3
		ld	hl,dat_141a
		call	fun_0d18
		ld	hl,dat_141e
		call	fun_0e50
		ld	hl,var_71a0
		rst	RST3
		call	fun_1144
		ld	hl,var_71a0
		rst	RST3
		call	fun_1144
		ld	a,(var_71ce)
		call	fun_0dae
		rra
		ld	(var_71bc),a
		ret	nc
		ld	hl,dat_1422
		jp	fun_0d18
		
fun_1144:	ld	hl,var_71a4
		rst	RST5
		ld	hl,var_71a0
		call	fun_0dd9
		ld	hl,var_71a0
		call	fun_0e50
		sub	$01
		ld	(var_71bc),a
		ret

lab_115a:	ld	a,$00
		ld	(var_71bc),a
		ld	(var_71bd),a
		ld	(var_71be),a
		ld	(var_71bf),a
		ret
		
; ---------------------------------------------------------
; 0x1169
FUN_SIN:	call	fun_0dcb
		ret	z
		push	af
		call	FUN_ABS
@r_1171:	pop	af
		cpl
		push	af
		ld	hl,dat_140a
		call	fun_0ef4
		jp	p,@r_1171
		ld	hl,dat_143e
		push	hl
		call	fun_0e50
		call	p,fun_0eea
		pop	hl
		call	fun_0e50
		pop	af
		or	a
		call	p,fun_0eea
		ld	hl,var_71a0
		rst	RST3
		ld	a,(var_71bc)
		call	fun_0dae
		jp	p,@r_11a4
		cp	$e0
		jr	c,lab_115a
		cp	$fd
		ret	c
@r_11a4:	ld	hl,dat_143e
		call	fun_0dd9
		ld	hl,var_71a4
		rst	RST3
		ld	hl,var_71a4
		call	fun_0d18
		ld	hl,dat_144e
		jp	fun_1073

; ---------------------------------------------------------
; 0x11ba
FUN_COS:	ld	hl,dat_143e
		call	fun_0e50
		jp	FUN_SIN

; ---------------------------------------------------------
; 0x11c3
FUN_TAN:	ld	hl,var_71ac
		rst	RST3
		call	FUN_COS
		ld	hl,var_71b8
		rst	RST3
		ld	hl,var_71ac
		rst	RST5
		call	FUN_SIN
		ld	hl,var_71b8
		jp	fun_0dd9

; ---------------------------------------------------------
; 0x11db
FUN_ATN:	call	fun_0dcb
		jp	p,fun_11ea
		call	fun_0eea
		call	fun_11ea
		jp	fun_0eea
		
fun_11ea:	ld	hl,dat_1452
		call	fun_0e50
		ld	hl,var_71a0
		rst	RST3
		ld	hl,dat_1402
		call	fun_0ef4
		ld	hl,var_71a0
		call	fun_0dd9
		ld	hl,var_71a4
		rst	RST3
		ld	hl,dat_140e
		call	fun_0e50
		ld	hl,var_71a0
		rst	RST3
		push	hl
		rst	RST5
		pop	hl
		call	fun_0d18
		ld	hl,dat_143a
		jp	fun_1073

; ---------------------------------------------------------
; 0x121a
FUN_ABS:	ld	a,(var_71bc)
		and	$7f
		ld	(var_71bc),a
		ret

; ---------------------------------------------------------
; 0x1223
FUN_RANDOMIZE:	exx
		ld	a,$01
		ld	(var_71df),a
		ld	hl,var_71d7
		ld	de,var_71cf
		ld	bc,$0008
		ldir
		exx
		ret

; ---------------------------------------------------------
; 0x1236
FUN_RND:	ld	hl,var_71b8
		rst	RST3
		ld	b,$04
		ld	hl,var_71bc
		call	fun_0e4a
		ld	c,$03
		ld	hl,var_71bd
		push	hl
@r_1248:	ld	hl,var_71d4
		ld	b,$06
		or	a
@r_124e:	rl	(hl)
		dec	hl
		djnz	@r_124e
		inc	hl
		ld	de,dat_13f4
		ld	b,$03
@r_1259:	ld	a,(de)
		cp	(hl)
		inc	hl
		inc	de
		jr	c,@r_1265
		jr	nz,@r_1271
		ld	a,(de)
		cp	(hl)
		jr	nc,@r_1271
@r_1265:	ex	de,hl
		ld	a,(de)
		sub	(hl)
		ld	(de),a
		dec	de
		dec	hl
		ld	a,(de)
		sbc	a,(hl)
		ld	(de),a
		inc	de
		inc	hl
		ex	de,hl	
@r_1271:	inc	de
		inc	hl
		djnz	@r_1259
		ld	b,$03
@r_1277:	ld	de,var_71d6
		ld	a,(de)
		add	a,(hl)
		ld	(de),a
		dec	de
		dec	hl
		ld	a,(de)
		adc	a,(hl)
		and	$3f
		ld	(de),a
		dec	hl
		djnz	@r_1277
		ld	a,$08
		sub	c
		rra
		pop	hl
		ld	a,(var_71d6)
		ld	(hl),a
		inc	hl
		push	hl
		dec	c
		jr	nz,@r_1248
		pop	hl
		ld	a,(var_71df)
		or	a
		jr	z,@r_12a7
		ld	de,var_71d7
		ld	hl,var_71cf
		ld	bc,$0008
		ldir
@r_12a7:	call	fun_0d72
		ld	hl,var_71b8
		jp	fun_0d18
		
fun_12b0:	ld	de,var_71bf
		ld	a,(de)
		or	$07
		ld	(de),a
		call	fun_0dcb
		jp	p,@r_12c0
		ld	(hl),$2d
		inc	hl
@r_12c0:	jr	nz,@r_12c8
		ld	(hl),$30
		inc	hl
		ld	(hl),$20
		ret
@r_12c8:	ld	a,(var_71bc)
		call	fun_0dae
		jr	nz,@r_12d2
		ld	a,$80
@r_12d2:	and	$80
		ld	(var_71ce),a
		push	hl
@r_12d8:	ld	a,(var_71bc)
		call	fun_0dae
		cp	$01
		jp	p,@r_12f7
@r_12e3:	ld	hl,var_71ce
		inc	(hl)
		ld	hl,dat_1406
		jp	p,@r_12f2
		call	fun_0d18
		jr	@r_12d8
@r_12f2:	call	fun_0dd9
		jr	@r_12d8
@r_12f7:	cp	$05
		jp	p,@r_12e3
		ld	hl,var_71c0
		rst	RST3
		ld	a,(var_71bc)
		call	fun_0dae
		ld	c,$06
		call	fun_1338
		cp	$0a
		jp	m,@r_1316
		ld	hl,var_71c0
		rst	RST5
		jr	@r_12e3
@r_1316:	call	fun_1327
@r_1319:	xor	a
		ld	(var_71bc),a
		call	fun_0cf3
		call	fun_1327
		jr	nz,@r_1319
		jr	lab_134c
		
fun_1327:	or	$30
		pop	hl
		ex	(sp),hl
		ld	(hl),a
		inc	hl
		ld	a,c
		cp	$06
		jr	nz,@r_1335
		ld	(hl),$2e
		inc	hl
@r_1335:	ex	(sp),hl
		dec	c
		jp	(hl)
		
fun_1338:	ld	e,a
		xor	a
		ld	(var_71bc),a
@r_133d:	ld	hl,var_71bf
		ld	b,$04
@r_1342:	rl	(hl)
		ld	a,(hl)
		dec	hl
		djnz	@r_1342
		dec	e
		jr	nz,@r_133d
		ret
		
lab_134c:	pop	hl
		ld	(hl),$45
		inc	hl
		ld	a,(var_71ce)
		ld	(hl),$2b
		ld	d,a
		or	a
		jp	p,@r_1363
		ld	(hl),$2d
		and	$7f
		cpl
		inc	a
		ld	d,a
		cpl
		inc	a
@r_1363:	inc	hl
		push	hl
		ld	e,$ff
@r_1367:	inc	e
		sub	$0a
		jp	p,@r_1367
		add	a,$0a
		ld	b,a
		ld	a,e
		call	fun_1327
		ld	a,b
		call	fun_1327
		pop	hl
		ld	(hl),$20
		ld	a,d
		or	a
		jp	p,@r_1385
		cp	$fe
		ret	c
		jr	@r_1388
@r_1385:	cp	$06
		ret	nc
@r_1388:	ld	c,a
		ld	b,$05
@r_138b:	ld	(hl),$20
		dec	hl
		djnz	@r_138b
		ex	de,hl
		ld	a,e
		sub	$05
		ld	l,a
		ld	a,d
		sbc	a,$00
		ld	h,a
		ld	a,c
		or	a
		jr	z,@r_13aa
		jp	m,@r_13bd
@r_13a0:	ld	b,(hl)
		inc	hl
		ld	a,(hl)
		ld	(hl),b
		dec	hl
		ld	(hl),a
		inc	hl
		dec	c
		jr	nz,@r_13a0
@r_13aa:	ex	de,hl
@r_13ab:	ld	a,(hl)
		cp	$30
		jr	nz,@r_13b5
		ld	(hl),$20
		dec	hl
		jr	@r_13ab
@r_13b5:	cp	$2e
		inc	hl
		ret	nz
		dec	hl
		ld	(hl),$20
		ret
@r_13bd:	inc	a
		jr	nz,@r_13c8
		dec	hl
		ld	a,(hl)
		ld	(hl),$2e
		inc	hl
		ld	(hl),a
		jr	@r_13aa
@r_13c8:	dec	hl
		ld	a,(hl)
		ld	(hl),$30
		inc	hl
		ld	(hl),a
		ld	h,d
		ld	l,e
		ld	b,$06
@r_13d2:	dec	hl
		ld	a,(hl)
		inc	hl
		ld	(hl),a
		dec	hl
		djnz	@r_13d2
		ld	(hl),$2e
		jr	@r_13aa
		
fun_13dd:	ex	(sp),hl
		ld	a,(hl)
		inc	hl
		ex	(sp),hl
		push	de
		ld	e,a
		or	a
		ld	d,$00
		jp	p,@r_13eb
		ld	d,$ff
@r_13eb:	add	hl,de
		pop	de
		ret

lab_13ee:	ld	a,ERR_D0		; divided by zero
		rst	RST2
		
lab_13f1:	ld	a,ERR_FC		; illegal function call
		rst	RST2
		
; ---------------------------------------------------------

; math lookup table
dat_13f4:	db	$3f,$fd,$3f,$eb,$3f,$dd
dat_13fa:	db	$1b,$ec,$33,$d3,$1a,$85,$2b,$1e
dat_1402:	db	$02,$80,$00,$00
dat_1406:	db	$04,$a0,$00,$00
dat_140a:	db	$02,$c9,$0f,$d7
dat_140e:	db	$00,$c9,$0f,$d7
dat_1412:	db	$80,$ff,$ff,$ff
dat_1416:	db	$00,$b1,$72,$16
dat_141a:	db	$00,$97,$14,$eb
dat_141e:	db	$7f,$d5,$a9,$56
dat_1422:	db	$01,$b5,$04,$f3
		db	$ff,$aa,$95,$bc,$7e,$ca,$d5,$20
		db	$fe,$87,$82,$d6,$7d,$a3,$13,$1c
		db	$fc,$89,$a6,$b8
dat_143a:	db	$79,$df,$3a,$9e
dat_143e:	db	$01,$c9,$0f,$da,$80,$a5,$5d,$de
		db	$7d,$a3,$34,$55,$f9,$99,$38,$60
dat_144e:	db	$74,$9e,$d7,$b6
dat_1452:	db	$01,$80,$00,$00,$00,$ff,$fe,$c1
		db	$ff,$ff,$ba,$b0,$7f,$a8,$0e,$2b
		db	$fe,$e7,$4b,$55,$7e,$89,$de,$e3
		db	$fc,$e1,$c5,$78
dat_146e:	db	$7a,$b0,$3f,$b0
dat_1472:	db	$01,$b8,$aa,$3c,$00,$b1,$6f,$e6
		db	$7e,$f6,$2f,$70,$7c,$e1,$c2,$ae
		db	$7a,$a0,$bb,$7e
dat_1486:	db	$77,$ca,$09,$cf
dat_148a:	db	$7f,$de,$5b,$d0
		
; ---------------------------------------------------------
; 0x148e
FUN_MUSIC:	call	play_off
		call	fun_000b
		push	hl
		ld	hl,var_7363
		and	$03
		jr	z,@r_14a3
		ld	b,a
		ld	de,$000b
@r_14a0:	add	hl,de
		djnz	@r_14a0
@r_14a3:	push	hl
		pop	ix
		ld	b,$0b
		xor	a
		ld	(var_735e),a
		ld	(var_735f),a
@r_14af:	ld	(hl),a
		inc	hl
		djnz	@r_14af
		ld	(ix+$01),a
		ld	de,(HIMEM)
		ld	(ix+$04),e
		ld	(ix+$09),e
		ld	(ix+$05),d
		ld	(ix+$0a),d
		pop	hl
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		call	fun_2540
		bit	7,a
		jr	z,@r_14d7
		xor	$7f
@r_14d7:	ld	(ix+$06),a
		call	fun_3fc1
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		ld	a,(hl)
		cp	$2a
		dec	hl
		jr	nz,@r_1500
		set	6,(ix+$00)
		inc	hl
		inc	hl
		jr	@r_1500
@r_14f2:	call	parse_endofcmd
		jp	z,@r_159f
		cp	$2c
		jp	nz,@r_1549
		call	fun_15b8
@r_1500:	ld	de,IOBUF
		inc	hl
		call	fun_15f4
		jp	nz,@r_1549
		push	hl
		ld	a,(var_71bc)
		ld	b,a
		ld	hl,(var_71be)
@r_1512:	ld	a,(hl)
		ld	c,$01
		cp	$2b
		jr	nz,@r_151c
		dec	c
		jr	@r_1521
@r_151c:	cp	$2d
		jr	nz,@r_1526
		inc	c
@r_1521:	inc	hl
		dec	b
		jp	z,@r_1549
@r_1526:	ld	a,c
		and	$03
		rrca
		rrca
		ld	c,a
		ld	a,(hl)
		push	de
		ld	de,dat_39f9
		cp	$23
		jr	nz,@r_153c
		inc	de
		inc	hl
		dec	b
		jp	z,@r_1549
		ld	a,(hl)
@r_153c:	cp	$41
		jp	c,@r_1549
		cp	$48
		jr	c,@r_154c
		cp	$52
		jr	z,@r_154c
@r_1549:	jp	parse_exp
@r_154c:	push	bc
		push	hl
		ld	hl,dat_39e9
		ld	bc,$000f
		cpir
		ld	c,(hl)
		pop	hl
		ld	b,$00
		ex	de,hl
		add	hl,bc
		ld	a,(hl)
		ex	de,hl
		pop	bc
		pop	de
		inc	de
		ld	(de),a
		dec	de
		dec	b
		jr	nz,@r_1570
		ld	a,$07
		or	c
		ld	(de),a
		inc	de
		inc	de
		pop	hl
		jp	@r_14f2
@r_1570:	push	bc
		inc	hl
		ld	a,(hl)
		sub	$30
		ld	b,a
		and	$f0
		ld	a,$07
		jr	nz,@r_1593
		ld	a,b
		push	hl
		ld	hl,dat_2ad9
		ld	c,a
		ld	b,$00
		add	hl,bc
		ld	a,(hl)
		pop	hl
		pop	bc
		or	c
		ld	(de),a
		inc	de
		inc	de
		dec	b
		jr	z,@r_159b
		inc	hl
		jp	@r_1512
@r_1593:	pop	bc
		or	c
		ld	(de),a
		inc	de
		inc	de
		jp	@r_1512
@r_159b:	pop	hl
		jp	@r_14f2
@r_159f:	push	hl
		call	fun_15b8
		ld	hl,(var_735e)
		srl	h
		rr	l
		ld	(ix+$02),l
		ld	(ix+$07),l
		ld	(ix+$03),h
		ld	(ix+$08),h
		pop	hl
		ret
		
fun_15b8:	push	hl
		and	a
		ld	hl,IOBUF
		ex	de,hl
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	hl,(var_735e)
		add	hl,bc
		ld	(var_735e),hl
		ld	hl,(HIMEM)
		and	a
		sbc	hl,bc
		call	fun_2f89
		ld	hl,IOBUF
		ld	de,(HIMEM)
@r_15d9:	ld	a,(hl)
		ld	(de),a
		cpi
		dec	de
		jp	pe,@r_15d9
		ld	(HIMEM),de
		pop	hl
		ret

; ---------------------------------------------------------
; 0x15e7
FUN_TEMPO:	call	fun_2540
		and	$7f
		inc	a
		ld	(var_7360),a
		ld	(var_7361),a
		ret

fun_15f4:	call	param_get_1
		call	fun_191a
		ret
; ---------------------------------------------------------
; 0x15fb
FUN_PLOT:	ld	a,(hl)
		cp	$a7
		jr	nz,@r_1615
		inc	hl
		call	fun_162d
		call	fun_164a
		ld	a,(hl)
		cp	$2c
		jr	nz,FUN_PLOT
		inc	hl
		call	fun_2540
		ld	(var_733c),a
		jr	FUN_PLOT
@r_1615:	call	parse_endofcmd
		ret	z
		call	fun_162d
		ld	a,(hl)
		cp	$2c
		jr	nz,@r_1628
		inc	hl
		call	fun_2540
		ld	(var_733c),a
@r_1628:	call	fun_173e
		jr	FUN_PLOT
		
fun_162d:	ld	de,(var_7343)
		ld	(var_7341),de
		call	fun_2540
		push	af
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		call	fun_2540
		pop	de
		ld	e,a
		ld	(var_7343),de
		ret
		
fun_164a:	push	hl
		ld	de,var_7341
		ld	hl,var_7343
		push	hl
		ld	b,$08
		ld	hl,var_7345
		call	fun_0e4a
		pop	hl
		ld	a,(de)
		ld	(var_7345+1),a
		ld	b,a
		inc	de
		ld	a,(de)
		ld	(var_734a),a
		ld	c,a
		ld	a,(hl)
		sub	b
		jr	nc,@r_166d
		neg
		scf
@r_166d:	ld	e,a
		inc	hl
		rra
		ld	b,a
		ld	a,(hl)
		sub	c
		jr	nc,@r_1678
		neg
		scf
@r_1678:	ld	d,a
		ld	a,b
		rra
		ld	b,a
		ld	a,e
		or	d
		jr	nz,@r_1683
		ld	c,a
		jr	z,@r_16db
@r_1683:	ld	a,e
		ld	hl,var_734c
		cp	d
		ld	a,$01
		jr	c,@r_1696
		ld	c,e
		ld	(var_7347+1),a
		jr	nz,@r_16a1
@r_1692:	ld	(hl),a
		jp	@r_16c0
@r_1696:	ld	(hl),a
		ld	hl,var_7348
		ld	c,d
		jp	z,@r_1692
		ld	a,d
		ld	d,e
		ld	e,a
@r_16a1:	push	hl
		push	bc
		push	de
		call	fun_10dc
		ld	hl,IOBUF
		rst	RST3
		pop	de
		ld	a,d
		call	fun_10db
		ld	hl,IOBUF
		call	fun_0dd9
		ld	hl,var_71bc
		call	fun_1711
		pop	bc
		pop	hl
		dec	hl
		ld	(hl),e
@r_16c0:	ld	a,b
		rla
		ld	d,a
		jr	nc,@r_16ce
		ld	hl,(var_734b)
		call	fun_1704
		ld	(var_734b),hl
@r_16ce:	ld	a,d
		rla
		jr	nc,@r_16db
		ld	hl,(var_7347)
		call	fun_1704
		ld	(var_7347),hl
@r_16db:	ld	b,c
		inc	b
@r_16dd:	push	bc
		ld	a,(var_7345+1)
		ld	e,a
		ld	a,(var_734a)
		ld	d,a
		call	fun_173e
		ld	hl,(var_7345)
		ex	de,hl
		ld	hl,(var_7347)
		add	hl,de
		ld	(var_7345),hl
		ld	hl,(var_7349)
		ex	de,hl
		ld	hl,(var_734b)
		add	hl,de
		ld	(var_7349),hl
		pop	bc
		djnz	@r_16dd
		pop	hl
		ret
		
fun_1704:	push	de
		ex	de,hl
		ld	hl,$0000
		or	a
		sbc	hl,de
		pop	de
		ret
		
		ld	hl,var_71bc		; unused
		
fun_1711:	ld	a,(hl)
		or	a
		ret	m
		add	a,$40
		xor	$40
		add	a,$07
		cp	$10
		ret	nc
		inc	hl
		sub	$07
		jr	c,@r_1734
		jr	z,@r_1739
		ld	d,(hl)
		inc	hl
		ld	e,(hl)
		ex	de,hl
		ld	b,a
		xor	a
@r_172a:	or	a
		adc	hl,hl
		rla
		djnz	@r_172a
		ld	d,a
		ld	e,h
		scf
		ret
@r_1734:	srl	(hl)
		inc	a
		jr	nz,@r_1734
@r_1739:	ld	e,(hl)
		ld	d,$00
		scf
		ret
		
fun_173e:	ld	a,(var_733b)		; screen mode
		cp	$01			; graphics mode 1?
		jr	z,@r_174a
		cp	$02			; graphics mode 2?
		jr	z,@r_179c
		ret
; plot graphics mode 1
@r_174a:	ld	a,e
		and	$07
		ld	b,a
		inc	b
		ld	a,e
		and	$f8
		ld	c,a
		ld	a,d
		and	$07
		or	c
		ld	e,a
		ld	a,d
		and	$c0
		cp	$c0
		ld	a,d
		jr	nz,@r_1762
		and	$3f
@r_1762:	ld	d,a
		srl	d
		srl	d
		srl	d
		push	hl
		ld	hl,(dat_3ee0)
		add	hl,de
		xor	a
		scf
@r_1770:	rra
		djnz	@r_1770
		ld	b,a
		call	FUN_VRAMRD
		ld	c,a
		ld	a,(var_733c)
		and	a
		jr	z,@r_1782
		ld	a,c
		or	b
		jr	@r_1785
@r_1782:	ld	a,b
		cpl
		and	c
@r_1785:	call	FUN_VRAMWR		; plot pixel
		ld	a,(var_733c)
		and	$0f
		jr	z,@r_179a
		rlca
		rlca
		rlca
		rlca
		ld	hl,(dat_3ee8)
		add	hl,de
		call	FUN_VRAMWR		; plot color
@r_179a:	pop	hl
		ret
; plot graphics mode 2
@r_179c:	push	hl
		ld	hl,(dat_3ee2)
		ld	a,d
		and	$07
		ld	b,a
		ld	c,e
		ld	a,e
		and	$3e
		rla
		rla
		or	b
		ld	e,a
		ld	a,d
		and	$38
		rra
		rra
		rra
		ld	d,a
		add	hl,de
		call	FUN_VRAMRD
		bit	0,c
		jr	nz,@r_17bf
		and	$0f
		jr	@r_17c1
@r_17bf:	and	$f0
@r_17c1:	ld	d,a
		ld	a,(var_733c)
		and	$0f
		bit	0,c
		jr	nz,@r_17cf
		rlca
		rlca
		rlca
		rlca
@r_17cf:	or	d
		call	FUN_VRAMWR		; plot colored pixel
		pop	hl
		ret

; ---------------------------------------------------------
; 0x17d5
FUN_TAB:	push	bc
	IFDEF V30
		call	fun_2543
	ELSE
		call	fun_3f37
	ENDIF
		and	$1f
		ld	b,a
		ld	a,(CURPOS)
		and	$1f
		cp	b
		jr	c,@r_17e5
		rst	RST1
@r_17e5:	ld	a,(CURPOS)
		and	$e0
		or	b
		ld	(CURPOS),a
		
lab_17ee:	xor	a
		ld	(var_71bc),a
		ld	(var_71bd),a
		dec	a
		ld	(var_71be),a
		pop	bc
		ret

; ---------------------------------------------------------
; 017fb
FUN_SPC:	push	bc
		call	fun_2543
		and	a
@r_1800:	jr	z,lab_17ee
		ld	b,a
		ld	a,$20
@r_1805:	call	DSPCHR
		djnz	@r_1805
		jr	lab_17ee

; ---------------------------------------------------------
; 0x180c
FUN_RIGHTS:	push	de
		push	bc
		call	fun_1868
		call	fun_254b
		cp	c
		jr	nc,lab_185f
		push	af
		sub	c
		cpl
		inc	a
		ld	c,a
		ld	b,$00
		ex	de,hl
		add	hl,bc
		ex	de,hl
		pop	af
		jr	lab_185e

; ---------------------------------------------------------
; 0x1824
FUN_LEFTS:	push	de
		push	bc
		call	fun_1868
		call	fun_254b
		cp	c
		jr	nc,lab_185f
		jr	lab_185e

; ---------------------------------------------------------
; 0x1831
FUN_MIDS:	push	de
		push	bc
		call	fun_1868
		push	af
		call	fun_254b
		cp	c
		jr	z,@r_183f
		jr	nc,lab_1865
@r_183f:	and	a
		jp	z,lab_1865
		ld	c,a
		ld	b,$00
		ex	de,hl
		add	hl,bc
		ex	de,hl
		dec	de
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		call	fun_254b
		ld	b,a
		pop	af
		sub	c
		inc	a
		cp	b
		jr	c,lab_185e
		ld	c,b
		jr	lab_185f
		
lab_185e:	ld	c,a

lab_185f:	call	fun_1881
		pop	bc
		pop	de
		ret

lab_1865:	ld	a,ERR_BS		; bad subscript
		rst	RST2

fun_1868:	call	param_get_1
		call	fun_191a
		jp	nz,lab_18ee
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		ld	de,(var_71be)
		ld	a,(var_71bc)
		ld	c,a
		inc	hl
		ret
		
fun_1881:	call	fun_18a7

fun_1884:	ld	a,(hl)
		cp	$29
		jp	nz,parse_exp
		inc	hl
		ret
		
fun_188c:	push	bc
		ld	b,$08
@r_188f:	bit	7,a
		jr	nz,@r_1897
		sla	a
		djnz	@r_188f
@r_1897:	ld	(var_71bd),a
		ld	a,b
		ld	(var_71bc),a
		pop	bc
		xor	a
		ld	(var_71be),a
		ld	(var_71bf),a
		ret
		
fun_18a7:	ld	b,$00
		ld	(var_71bc),bc
		ld	(var_71be),de
		ret

; ---------------------------------------------------------
; 0x18b2
FUN_LEN:	call	fun_1a69
		jr	nz,lab_18ee
		call	fun_1884
		ld	a,(var_71bc)
		call	fun_188c
		ret

; ---------------------------------------------------------
; 0x18c1
FUN_VAL:	push	de
		push	bc
		call	fun_1a69
		jr	nz,lab_18ee
		push	hl
		ld	hl,(var_71be)
		ld	a,(var_71bc)
		and	a
		jr	z,@r_18e9
		ld	c,a
		ld	b,$00
		ld	de,var_7118
		ldir
		xor	a
		ld	(de),a
		ld	hl,var_7118
		call	fun_0c56
@r_18e2:	pop	hl
		call	fun_1884
		pop	bc
		pop	de
		ret
@r_18e9:	call	fun_188c
		jr	@r_18e2
		
lab_18ee:	ld	a,ERR_TM		; type mismatch
		rst	RST2
		
; ---------------------------------------------------------
; 0x18f1
FUN_ASC:	call	fun_1a69
		jr	nz,lab_18ee
		call	fun_1884
		push	hl
		ld	a,(var_71bc)
		and	a
		jr	z,@r_1904
		ld	hl,(var_71be)
		ld	a,(hl)
@r_1904:	call	fun_188c
		pop	hl
		ret

; ---------------------------------------------------------
; 0x1909
FUN_CHRS:	push	bc
		push	de
		call	fun_2543
		
lab_190e:	ld	de,IOBUF
		ld	(de),a
		ld	c,$01
		call	fun_18a7
		pop	de
		pop	bc
		ret

fun_191a:	push	ix
		ld	ix,var_71bc
		call	fun_0ab8
		pop	ix
		ret
	
; ---------------------------------------------------------
; 0x1926
FUN_STRS:	push	de
		call	fun_191a
		jr	z,lab_18ee
		push	hl
		ld	hl,IOBUF
		push	hl
		call	fun_12b0
		pop	de
		and	a
		sbc	hl,de
		ld	c,l
		call	fun_18a7
		pop	hl
		pop	de
		ret

; ---------------------------------------------------------
; 0x193f
FUN_POS:	ld	a,(CURPOS)
		and	$1f
		call	fun_188c
		ret

; ---------------------------------------------------------
; 0x1948
FUN_PEEK:	push	de
		call	param_get_2
		ld	a,(de)
		call	fun_188c
		pop	de
		ret
		
; ---------------------------------------------------------
; 0x1952
FUN_IN:		push	bc
		call	fun_2543
		ld	c,a
		in	a,(c)
		call	fun_188c
		pop	bc
		ret

; ---------------------------------------------------------
; 0x195e
FUN_POKE:	push	de
		call	param_get_1
		call	param_get_2
		push	de
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		call	fun_2540
		pop	de
		ld	(de),a
		pop	de
		ret
		db	$00

; ---------------------------------------------------------
; 0x1975
FUN_OUT:	push	bc
		call	fun_2540
		ld	c,a
		push	bc
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		call	fun_2540
		pop	bc
		out	(c),a
		pop	bc
		ret

; ---------------------------------------------------------
; 0x198a
FUN_WAIT:	push	bc
		push	de
		call	fun_2540
		ld	c,a
		ld	a,(hl)
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		call	fun_2540
		ld	b,a
		ld	a,(hl)
		cp	$2c
		jr	z,@r_19a4
		ld	d,$00
		jr	@r_19a9
@r_19a4:	inc	hl
		call	fun_2540
		ld	d,a
@r_19a9:	in	a,(c)
		xor	d
		and	b
		jr	z,@r_19a9
		pop	de
		pop	bc
		ret

; ---------------------------------------------------------
; 0x19b2
FUN_HEXS:	push	bc
		push	de
		push	hl
		call	param_get_2
		ld	(IOBUF+4),de
		ld	hl,IOBUF+5
		ld	de,IOBUF
		call	fun_19e0
		call	fun_19e0
		ld	bc,$0304
		ld	hl,IOBUF
		ld	a,$30
@r_19d0:	cp	(hl)
		jr	nz,@r_19d7
		dec	c
		inc	hl
		djnz	@r_19d0
@r_19d7:	ld	d,h
		ld	e,l
		call	fun_18a7
		pop	hl
		pop	de
		pop	bc
		ret
		
fun_19e0:	ld	b,$02
@r_19e2:	xor	a
		rld
		add	a,$30
		cp	$3a
		jr	c,@r_19ed
		add	a,$07
@r_19ed:	ld	(de),a
		inc	de
		djnz	@r_19e2
		dec	hl
		ret

; ---------------------------------------------------------
; 0x19f3 unused
		push	af
		and	$f0
		rrca
		rrca
		rrca
		rrca
		or	$30
		ld	c,a
		pop	af
		and	$0f
		or	$30
		ld	b,a
		ret
	
; ---------------------------------------------------------
; 0x1a04
FUN_INKEYS:	push	bc
		push	de
		call	GETKEY
		jp	lab_190e

; ---------------------------------------------------------
; 0x1a0c
FUN_JOYST:	push	bc
		push	de
		push	hl
		call	fun_2543
		dec	a
		jp	m,parse_exp
		bit	$0,a			; select joystick 2?
		jr	nz,@r_1a1e		; nz=yes
		ld	c,$fc			; set joystick 1 port
		jr	@r_1a20
@r_1a1e:	ld	c,$ff			; set joystick 2 port
@r_1a20:	bit	$01,a			; select keypad?
		jr	nz,@r_1a3b		; nz=yes
		out	(IOCTL1),a		; set joystick mode
		in	a,(c)			; read joystick 1/2
		push	af
		and	$0f
		ld	hl,dat_1a86
		call	fun_1a54
		ld	a,b
		call	fun_188c
		pop	af
		call	fun_1a5d
		jr	@r_1a50
@r_1a3b:	out	(IOCTL0),a		; set keypad mode
		in	a,(c)			; read keypad 1/2
		push	af
		and	$0f
		ld	hl,dat_1a78
		call	fun_1a54
		ld	a,b
		call	fun_188c
		pop	af
		call	fun_1a5d
@r_1a50:	pop	hl
		pop	de
		pop	bc
		ret
		
fun_1a54:	ld	b,(hl)
		inc	hl
@r_1a56:	cp	(hl)
		ret	z
		inc	hl
		djnz	@r_1a56
		ld	b,(hl)
		ret
		
fun_1a5d:	bit	6,a
		ret	nz
		ld	a,(var_71bc)
		set	7,a
		ld	(var_71bc),a
		ret
		
fun_1a69:	call	fun_2e7c
		push	hl
		ld	hl,var_70ed
		call	param_get_1
		pop	hl
		call	fun_191a
		ret

; joystick lookup table
dat_1a78:	db	$0c,$06,$09,$0a,$0b,$01,$05,$0e,$03,$02,$0c,$07,$0d,$ff
dat_1a86:	db	$08,$06,$07,$03,$0b,$09,$0d,$0c,$0e,$ff

; ---------------------------------------------------------
; 0x1a90
FUN_BSAVE:	ld	(var_71f3),hl
		call	fun_1b31
		ld	a,(hl)
		cp	$2c
		jr	nz,@r_1aa6
		inc	hl
		call	param_get_1
		call	param_get_2
		push	de
		ld	a,(hl)
		cp	$2c
@r_1aa6:	jp	nz,parse_exp
		inc	hl
		call	param_get_1
		call	param_get_2
		push	de
		ld	de,var_70a9
		ld	hl,(var_71f3)
		call	fun_1b31
		call	FUN_DATA
		pop	de
		ld	(var_71c9),de
		ex	(sp),hl
		ld	(var_71c7),hl
		ld	(IOBUF+8),hl
		ex	de,hl
		ld	a,'M'			; binary (machine) file extension ".M"
		ld	(var_709f),a
		ld	(var_71a9),a
		jr	lab_1af4
		
; ---------------------------------------------------------
; 0x1ad4
FUN_SAVE:	call	fun_1b31
		push	hl
		ld	hl,(LOMEM)
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		ld	(var_71c7),hl
		ld	hl,(ADDR)
		inc	hl
		ld	(var_71ac),hl
		ld	a,$42
		ld	(var_709f),a
		ld	(var_71a9),a
		call	fun_1bd5

; common bsave and save
lab_1af4:	ld	a,l			; calculate number 256 byte blocks
		or	a
		ld	a,h
		jr	z,@r_1afa
		inc	a
@r_1afa:	ld	(var_709e),a		; 256-byte block counter
		call	fun_1c2e		; wait until user starts the tape unit
		jp	nz,lab_1b2c		; nz=not ready, terminate
		ld	hl,var_71b0		; copy file name to buffer
		ld	de,var_70a8
		ld	bc,$0010
		ldir
		ld	a,'B'			; set BASIC file header id
		ld	(var_71cb),a
		xor	a
		ld	(var_709d),a
		ld	hl,dat_1b9e		; "TAPE DUMP"
		call	print_string
		call	save_init_file		; display filename and calculate checksum
		call	save_print_file		; write file header to tape
		call	save_to_tape		; write file data to tape
		
lab_1b26:	ld	hl,dat_1bad		; "END"
		call	print_string
		
lab_1b2c:	call	print_crlf
		pop	hl
		ret

; write filename to buffer
fun_1b31:	ld	de,var_71b1
		call	parse_endofcmd
		jr	z,@r_1b49
		call	fun_15f4
		jp	nz,parse_exp
		ld	a,$01
		ld	(var_71a8),a
		ld	a,(var_71bc)
		jr	@r_1b4d
@r_1b49:	xor	a
		ld	(var_71a8),a
@r_1b4d:	push	hl
		ld	hl,(var_71be)
		and	$0f 			; max length of filename
		ld	(var_71b0),a
		ld	(var_70a8),a
		ld	b,a
		and	a
		jr	z,@r_1b63
@r_1b5d:	ld	a,(hl)
		ld	(de),a
		inc	hl
		inc	de
		djnz	@r_1b5d
@r_1b63:	pop	hl
		ret
		
		; 0x1b65 unused
		call	DSPCHR
		call	FUN_CURSOR
		ret

; 0x1b6c
save_print_file:
		ld	a,(var_71cb)
		ld	(IOBUF),a
		ld	hl,(var_71c7)
		ld	(var_71aa),hl
		ld	hl,(var_71c9)
		ld	(var_71ac),hl
		ld	(IOBUF+3),hl
		call	fun_1bc2		; calculate checksum
		ld	(IOBUF+1),de
		call	fun_1d6e
		ret

; tape i/o error
lab_1b8c:	ld	a,ERR_TP		; tape i/o error
		rst	RST2

; tape i/o text
dat_1b8f:	db	"\r\n*TAPE LOAD:\a",0
dat_1b9e:	db	"\r\n*TAPE DUMP:\a",0
dat_1bad:	db	"\r\n* END *\a",0
dat_1bb8:	db	"\n\rREADY?\a",0

; Calculate block checksum
fun_1bc2:	ld	bc,$010d		; block size = 13 control + 256 data = 269 bytes
		ld	hl,IOBUF+3
		xor	a
		ld	d,a
@r_1bca:	add	a,(hl)			; add all bytes in the block
		jr	nc,@r_1bce
		inc	d
@r_1bce:	cpi
		jp	pe,@r_1bca
		ld	e,a			; de = sum of data bytes
		ret
		
fun_1bd5:	ld	de,(var_71c7)
		ld	hl,(var_71ac)
		xor	a
		sbc	hl,de
		inc	hl
		ld	(var_71c9),hl
		ret

; 0x1be4
save_to_tape:	ld	a,$44			; block data id
		ld	(IOBUF),a
		ld	b,$01
@r_1beb:	push	bc
		ld	hl,(var_71ac)
		ld	a,h
		or	l
		jr	z,@r_1c1e
		ld	a,h
		or	a
		ld	bc,$0100
		jr	nz,@r_1bfe
		ld	c,l
		ld	b,a
		ld	l,b
		ld	h,b
@r_1bfe:	ld	(var_71ac),hl
		ld	hl,IOBUF+5
		inc	(hl)			; inc blocknumber
		ld	(IOBUF+3),bc
		ld	hl,(var_71aa)
		ld	de,var_70a8
		ldir
		ld	(var_71aa),hl
		call	fun_1bc2
		ld	(IOBUF+1),de
		call	fun_1d6e
@r_1c1e:	pop	bc
		ld	hl,(var_71ac)
		ld	a,h
		or	a
		ret	z
		djnz	@r_1beb
		dec	h
		ld	(var_71ac),hl
		jp	save_to_tape

; tape ready for save/load?
fun_1c2e:	ld	hl,dat_1bb8		; "READY?"
		call	print_string
@r_1c34:	call	FUN_CURSOR
		call	GETKEY
		jr	nc,@r_1c34
		push	af
		xor	a
		ld	(FLSCUR),a
		call	FUN_CURSOR
		pop	af
		call	DSPCHR
		cp	'Y'
		ret

; ---------------------------------------------------------
; 0x1c4b
FUN_BLOAD:	call	fun_1b31
		ld	a,'M'			; file is type 'M'achine (binary)
		ld	(var_71a9),a
		push	hl
		jr	lab_1c68

; ---------------------------------------------------------
; 0x1c56
FUN_LOAD:	call	fun_1b31
		push	hl
		ld	hl,(ADDR)
		ld	(var_71ec),hl
		ld	(var_71c7),hl
		ld	a,'B'			; file is type 'B'ASIC
		ld	(var_71a9),a
		
; Common code BLOAD and LOAD
lab_1c68:	ld	a,$42			; block header id
		ld	(var_71cb),a
		call	fun_1c2e
		jp	nz,lab_1b2c
		ld	hl,dat_1b8f
		call	print_string
		call	fun_1c8d
		call	fun_1cf6
		ld	a,(var_709f)
		cp	'M'
		jp	z,lab_1b26
		call	load_set_memvec
		jp	lab_1b26

fun_1c8d:	call	print_crlf
		call	FUN_CURSOR
		ld	d,$00
@r_1c95:	call	fun_1d78		; read block from tape
		ld	a,(IOBUF)
		ld	hl,var_71cb
		cp	(hl)			; is it a file header block?
		jr	nz,@r_1c95		; nz=no
		ld	a,(var_709d)
		and	a			; is the block number 0 (extra check)?
		jr	nz,@r_1c95		; nz=no
		call	fun_1d9c		; verify checksum block data
		jr	nz,@r_1c95
		call	save_init_file
		ld	a,(var_71a8)
		and	a			; is a filename specified?
		jr	z,@r_1ccd		; z=no, skip check
		ld	hl,var_71b1
		ld	a,(var_71b0)
		ld	b,a
		ld	a,(var_70a8)
		cp	b
		jr	nz,fun_1c8d
		ld	de,var_70a9
@r_1cc5:	ld	a,(de)
		cp	(hl)			; is correct filename?
		jr	nz,fun_1c8d		; nz=no
		inc	hl
		inc	de
		djnz	@r_1cc5
@r_1ccd:	ld	a,(var_709f)
		ld	hl,var_71a9		; 'M'achine or 'B'asic ?
		cp	(hl)
		jr	nz,fun_1c8d		; nz=not the right filetype
		cp	'M'
		jr	nz,@r_1ce0
		ld	hl,(IOBUF+8)
		ld	(var_71c7),hl
@r_1ce0:	ld	hl,(IOBUF+3)
		ld	(var_71c9),hl		; file size
		ld	(var_71ac),hl
		ld	a,(var_709e)		; last blocknumber from tape
		ld	(var_71c4),a
		ld	hl,(var_71c7)
		ld	(var_71aa),hl		; set destination address
		ret

; load file data from tape
fun_1cf6:	ld	b,$10			; counter
		ld	a,$ff			; value
		ld	hl,var_71b1		; destination address
@r_1cfd:	ld	(hl),a			; fill destination with 16 x 0xff
		inc	hl
		djnz	@r_1cfd
		xor	a
		ld	(var_71c5),a		; end load data flag
		ld	(var_71c2),a		; block number
		ld	a,$44			; data block id
		ld	(var_71c1),a
@r_1d0d:	ld	hl,var_71c2
		inc	(hl)
		call	fun_1d1c		; load data block from tape
		ld	a,(var_71c5)
		cp	$fe			; end load data?
		jr	nz,@r_1d0d
		ret

; load data block from tape		
fun_1d1c:	call	fun_1d78		; load block from tape
		ld	a,(IOBUF)
		ld	hl,var_71c1
		cp	(hl)			; is it a data block?
		jr	z,@r_1d31			
		ld	hl,var_71cb
		cp	(hl)
		jp	nz,lab_1b8c		; nz=tape error
		jr	fun_1d1c
@r_1d31:	ld	hl,var_709e
		ld	a,(var_71c4)
		cp	(hl)
		jp	nz,lab_1b8c
		ld	hl,var_71c2
		ld	a,(var_709e)
		cp	(hl)
		jr	nz,@r_1d49
		ld	a,$fe
		ld	(var_71c5),a
@r_1d49:	ld	a,(hl)
		ld	hl,var_709d
		cp	(hl)
		jr	z,@r_1d52
		jr	c,fun_1d1c
@r_1d52:	call	fun_1d9c		; verify checksum
		jr	z,@r_1d5a		; z=ok
		jp	lab_1b8c		; tape error
@r_1d5a:	ld	bc,(IOBUF+3)
		ld	hl,var_70a8
		ld	de,(var_71aa)
		ldir				; copy loaded data to destination address
		ld	(var_71aa),de
		ld	a,$99
		ret

fun_1d6e:	ld	bc,$0110
		ld	hl,IOBUF
		call	fun_1db7
		ret
		
; read block from tape
fun_1d78:	ld	bc,$0110		; block length
		ld	hl,IOBUF		; buffer address
		call	fun_1e2a
		ret	z
		jr	fun_1d78
		
; 0x1d84
save_init_file:	ld	hl,var_70a9
		ld	a,(var_70a8)
		ld	b,a
		and	a
		jr	z,@r_1d91
		call	fun_2a76
@r_1d91:	ld	a,$2e
		call	DSPCHR
		ld	a,(var_709f)
		call	DSPCHR

; verify checksum block data
fun_1d9c:	call	fun_1bc2		; calculate checksum
		ld	hl,(IOBUF+1)		; get stored checksum
		xor	a
		sbc	hl,de			; do the checksums match?
		ret

; ---------------------------------------------------------
; 0x1da6 unused
		ld	hl,(var_71c7)
		ld	de,(IOBUF+3)
		add	hl,de
		push	hl
		xor	a
		sbc	hl,de
		pop	hl
		jp	nz,lab_1b8c
		ret
		
; ---------------------------------------------------------

fun_1db7:	exx
		ld	hl,$78b4
		exx
		push	bc
		ld	de,$0096		; number of sync bit pairs
@r_1dc0:	and	a
		call	fun_1e06		; write sync bit 0
		scf
		push	hl
		pop	hl
		call	fun_1e06		; write sync bit 1
		dec	de
		ld	a,d
		or	e
		jp	nz,@r_1dc0
		ld	b,$1c			; number of sync bytes
		ld	c,$8f			; sync byte
@r_1dd4:	rrc	c
		nop
		call	fun_1e06		; sync bit
		djnz	@r_1dd4
		pop	bc
		nop
@r_1dde:	scf
		call	fun_1e06		; write control bit
		ld	e,$08			; write 8 data bits
		ld	d,(hl)			; get data byte in block
		inc	hl			; increase data pointer
@r_1de6:	rrc	d			; get nex bit from the data byte
		call	fun_1e06		; write to tape
		ld	a,$00
		dec	e
		jp	nz,@r_1de6
		scf
		nop
		call	fun_1e06		; write control bit
		dec	bc			; buffer counter
		ld	a,b
		or	c			; end of buffer?
		jp	nz,@r_1dde		; nz=no
		scf
		nop
		call	fun_1e06		; write control bit
		ld	a,$02			; sync signal level
		out	(IOTAP0),a		; write to tape port
		ret

; write carry flag bit to tape
fun_1e06:	exx
		ld	bc,$0306		; wavelength 1-bit
		jp	c,@r_1e10
		ld	bc,$0d0c		; wavelength 0-bit
@r_1e10:	ld	d,$07
		jp	@r_1e16
@r_1e15:	ld	b,c
@r_1e16:	djnz	@r_1e16
		rlc	h
		rla
		rlc	l
		rla
		out	(IOTAP0),a		; write to tape port
		dec	d
		jp	nz,@r_1e15
		rlc	h
		rlc	l
		exx
		ret

; read data from tape		
fun_1e2a:	push	hl
		push	bc
@r_1e2c:	ld	b,$18
@r_1e2e:	call	fun_1ef0
		ld	l,a
		call	fun_1ef0
		add	a,l
		ld	c,a
		cp	$10
		jr	c,@r_1e2c
		cp	$80
		jr	nc,@r_1e2c
		sub	h
		jr	nc,@r_1e44
		neg
@r_1e44:	cp	$06
		ld	h,c
		jr	nc,@r_1e2c
		djnz	@r_1e2e
		ld	d,$00
		call	fun_1ef0
		call	fun_1ef0
		ld	b,a
		call	fun_1ef0
		sub	b
		jr	nc,@r_1e5c
		neg
@r_1e5c:	push	af
		ld	d,$ff
		call	fun_1ef0
		call	fun_1ef0
		ld	b,a
		call	fun_1ef0
		sub	b
		jr	nc,@r_1e6e
		neg
@r_1e6e:	pop	hl
		cp	h
		jr	nc,@r_1e77
		ld	d,$00
		call	fun_1ef0
@r_1e77:	call	fun_1ef0
		ld	l,a
		call	fun_1ef0
		add	a,l
		srl	a
		ld	c,a
@r_1e82:	call	fun_1ef0
		jr	nc,@r_1e82
		ld	b,$18
@r_1e89:	call	fun_1ef0
		jr	c,@r_1e2c
		call	fun_1ef0
		jr	nc,@r_1e2c
		djnz	@r_1e89
		ld	l,a
		call	fun_1ef0
		add	a,l
		srl	a
		add	a,$01
		ld	c,a
		ld	l,$ff
@r_1ea1:	ld	b,$04
@r_1ea3:	call	fun_1ef0
		ex	af,af'
		dec	l
		jp	z,@r_1e2c
		ex	af,af'
		jr	nc,@r_1ea1
		djnz	@r_1ea3
@r_1eb0:	call	fun_1ef0
		jr	c,@r_1eb0
@r_1eb5:	call	fun_1ef0
		jr	nc,@r_1eb5
		exx
		pop	bc
		exx
		pop	h
		call	fun_1edc
		cp	$c7
		jp	nz,fun_1e2a
		call	fun_1edc
		cp	$f1
		jp	nz,fun_1e2a
@r_1ece:	call	fun_1edc
		ld	(hl),a
		ret	nc
		inc	hl
		exx
		dec	bc
		ld	a,b
		or	c
		exx
		jr	nz,@r_1ece
		ret
		
fun_1edc:	call	fun_1ef0
		ret	nc
		ld	b,$08
		push	hl
@r_1ee3:	call	fun_1ef0
		rr	h
		djnz	@r_1ee3
		call	fun_1ef0
		ld	a,h
		pop	hl
		ret

fun_1ef0:	in	a,(IOTAP1)		; read tape port (bit 7 is tape in)
		xor	d
		jp	m,fun_1ef0
		ld	e,$00
@r_1ef8:	inc	e
		in	a,(IOTAP1)
		xor	d
		jp	p,@r_1ef8
		ld	a,e
		cp	c
		ret

; ---------------------------------------------------------
; 0x1f02
FUN_READ:	push	de
@r_1f03:	call	fun_0a5d
		jp	nz,parse_exp
		push	de
		push	hl
		ld	hl,(var_7336)
		ld	a,h
		or	l
		call	z,fun_1f95
		jp	z,lab_1f92
		ld	a,e
		cp	$80
		jr	c,@r_1f26
		ld	a,(hl)
		cp	$22
		jp	nz,lab_0b0f
		call	fun_0874
		jr	@r_1f3d
@r_1f26:	call	fun_09f8
		jr	z,@r_1f38
		cp	$2b
		jr	z,@r_1f38
		cp	$2d
		jr	z,@r_1f38
		cp	$2e
		jp	nz,lab_0b0f
@r_1f38:	push	de
		call	fun_0c56
		pop	de
@r_1f3d:	ld	a,(hl)
		cp	$2c
		jr	z,@r_1f58
		and	a
		jr	z,@r_1f50
		cp	$3a
		jp	nz,parse_exp
		inc	hl
		ld	a,(hl)
		cp	$94
		jr	z,@r_1f58
@r_1f50:	call	fun_1f95
		jr	nz,@r_1f59
		ld	hl,$ffff
@r_1f58:	inc	hl
@r_1f59:	ld	(var_7336),hl
		pop	hl
		pop	de
		ld	ix,(var_71bc)
		push	ix
		ld	ix,(var_71be)
		push	ix
		ld	a,d
		cp	$80
		jr	c,@r_1f73
		call	fun_2e1f
		inc	hl
@r_1f73:	pop	ix
		ld	(var_71be),ix
		pop	ix
		ld	(var_71bc),ix
		call	fun_2ca5
		call	parse_endofcmd
		jr	z,@r_1f90
		cp	$2c
		jp	nz,parse_exp
		inc	hl
		jp	@r_1f03
@r_1f90:	pop	de
		ret

lab_1f92:	ld	a,ERR_OD		; out of data
		rst	RST2
		
fun_1f95:	push	de
		ld	de,(var_7338)
@r_1f9a:	ld	hl,(ADDR)
		xor	a
		sbc	hl,de
		jr	z,@r_1fcd
		ld	a,(de)
		ld	l,a
		inc	de
		ld	a,(de)
		ld	h,a
		inc	de
		inc	de
		inc	de
@r_1faa:	ld	a,(de)
		cp	$94
		jr	z,@r_1fc0
@r_1faf:	ld	a,(de)
		and	a
		jr	z,@r_1fbd
		cp	$3a
		jr	z,@r_1fba
		inc	de
		jr	@r_1faf
@r_1fba:	inc	de
		jr	@r_1faa
@r_1fbd:	ex	de,hl
		jr	@r_1f9a
@r_1fc0:	inc	de
		or	$01
@r_1fc3:	ld	(var_7336),de
		ld	(var_7338),hl
		ex	de,hl
		pop	de
		ret
@r_1fcd:	ex	de,hl
		jr	@r_1fc3
		
; ---------------------------------------------------------
; 0x1fd0
FUN_RESTORE:	push	de
		call	fun_0621
		push	hl
		ld	a,(var_71e0)
		cp	$ff
		jr	z,@r_1fff
		call	FUN_LONUMB
		ld	a,d
		or	e
		jr	nz,@r_1fe6
		ld	a,ERR_BL		; bad line number
		rst	RST2
@r_1fe6:	ld	a,(de)
		ld	(var_7338),a
		inc	de
		ld	a,(de)
		ld	(var_7338+1),a
		inc	de
		inc	de
@r_1ff1:	inc	de
		ld	a,(de)
		cp	$94
		jr	z,@r_1ffc
		and	a
		jr	z,@r_2005
		jr	@r_1ff1
@r_1ffc:	inc	de
		jr	@r_2008
@r_1fff:	ld	hl,(LOMEM)
		ld	(var_7338),hl
@r_2005:	ld	de,$0000
@r_2008:	ld	(var_7336),de
		pop	hl
		pop	de
		ret

; ---------------------------------------------------------
; 0x200f
FUN_DATA:	ld	a,(hl)
		cp	$22
		jr	z,@r_201b
		call	parse_endofcmd
		ret	z
@r_2018:	inc	hl
		jr	FUN_DATA
@r_201b:	inc	hl
		ld	a,(hl)
		and	a
		ret	z
		cp	$22
		jr	nz,@r_201b
		jr	@r_2018
		
; ---------------------------------------------------------
; 0x2025
FUN_FOR:	push	ix
		push	de
		push	bc
		call	FUN_LET
		push	hl
		push	de
		ld	hl,(var_72b2)
		ld	de,(var_72ba)
		xor	a
		sbc	hl,de
		jr	nc,lab_2099
		pop	de
		pop	hl
		ld	ix,(var_72b2)
		ld	(ix+$00),d
		ld	(ix+$01),e
		inc	ix
		inc	ix
		ld	(var_72b2),ix
		ld	a,(hl)
		cp	$a7
		jp	nz,parse_exp
		inc	hl
		call	param_get_1
		push	hl
		ld	hl,(var_72b4)
		rst	RST3
		ld	(var_72b4),hl
		pop	hl
		ld	a,(hl)
		cp	$a3
		jr	z,@r_206b
		ld	de,dat_1452
		jr	@r_2077
@r_206b:	inc	hl
		call	param_get_1
		call	fun_0dcb
		jr	z,lab_209c
		ld	de,var_71bc
@r_2077:	push	hl
		ld	hl,(var_72b6)
		call	fun_001b
		ld	(var_72b6),hl
		pop	hl
		ld	ix,(var_72b8)
		ld	(ix+$00),h
		ld	(ix+$01),l
		inc	ix
		inc	ix
		ld	(var_72b8),ix
		
lab_2094:	pop	bc
		pop	de
		pop	ix
		ret		
		
lab_2099:	ld	a,ERR_NOMEM		; out of memory
		rst	RST2
		
lab_209c:	ld	a,ERR_IS		; incorrect statement
		rst	RST2
		
; ---------------------------------------------------------
; 0x209f
FUN_NEXT:	push	ix
		push	de
		push	bc
		xor	a
		ld	(var_719a),a
		call	parse_endofcmd
		jr	nz,@r_20b3
		ld	a,$94
		ld	(var_719a),a
		jr	@r_20b6
@r_20b3:	call	fun_0a5d
@r_20b6:	push	hl
		ld	hl,(var_72b2)
		push	de
		push	hl
		ld	de,(var_72bc)
		xor	a
		sbc	hl,de
		jr	z,@r_20d9
		pop	hl
		dec	hl
		ld	e,(hl)
		dec	hl
		ld	d,(hl)
		ex	de,hl
		pop	de
		push	hl
		ld	a,(var_719a)
		cp	$94
		jr	z,@r_20e1
		xor	a
		sbc	hl,de
		jr	z,@r_20e1
@r_20d9:	ld	a,ERR_NF		; next without for
		rst	RST2
		db	$e1			; unused
@r_20dd:	pop	hl
		jp	lab_2094
@r_20e1:	pop	hl
		ex	de,hl
		call	fun_2c39
		call	fun_2146
		push	hl
		push	de
		call	fun_0e50
		pop	de
		call	fun_2ca5
		pop	hl
		ld	a,(hl)
		and	$80
		jr	z,@r_2106
		ld	hl,var_71b0
		rst	RST3
		call	fun_214e
		push	hl
		rst	RST5
		ld	hl,var_71b0
		jr	@r_210a
@r_2106:	call	fun_214e
		push	hl
@r_210a:	call	fun_0ef4
		ld	a,(var_71bc)
		jr	z,lab_2156
		and	$80
		jr	nz,lab_2156
		pop	hl
		ld	(var_72b4),hl
		call	fun_2146
		ld	(var_72b6),hl
		ld	hl,(var_72b8)
		dec	hl
		dec	hl
		ld	(var_72b8),hl
		ld	hl,(var_72b2)
		dec	hl
		dec	hl
		ld	(var_72b2),hl
		ld	de,(var_72bc)
		xor	a
		sbc	hl,de
		jp	z,@r_20dd
		pop	hl
		ld	a,(var_719a)
		cp	$94
		jp	z,@r_20b6
		jp	lab_2094
		
fun_2146:	ld	hl,(var_72b6)
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		ret
		
fun_214e:	ld	hl,(var_72b4)
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		ret
		
lab_2156:	pop	hl
		pop	hl
		ld	de,(var_72b8)
		dec	de
		ld	a,(de)
		ld	l,a
		dec	de
		ld	a,(de)
		ld	h,a
		push	hl
@r_2163:	ld	a,(hl)
		and	a
		jr	z,@r_216a
		inc	hl
		jr	@r_2163
@r_216a:	inc	hl
		ld	(CURLIN),hl
		ld	a,(var_71e1)
		and	$80
		jr	z,@r_2181
		push	de
		push	hl
		pop	ix
		call	fun_2930
		ld	(var_71f9),de
		pop	de
@r_2181:	pop	hl
		jp	lab_2094

; ---------------------------------------------------------
; 0x2185
FUN_GOSUB:	push	hl
		ld	(var_71b0),sp
		ld	sp,(var_7205)
		ld	hl,var_7207
		and	a
		sbc	hl,sp
		jp	z,lab_21c2
		ld	hl,(CURLIN)
		push	hl
		ld	(var_7205),sp
		ld	sp,(var_71b0)
		pop	hl
		call	FUN_GOTO
		call	FUN_DATA
		ld	(var_71b0),sp
		ld	sp,(var_7205)
		push	hl
		ld	(var_7205),sp
		ld	sp,(var_71b0)

fun_21bb:	ld	a,(hl)
		and	a
		ret	z
		inc	hl
		jr	fun_21bb
		db	$c9
		
lab_21c2:	ld	sp,(var_71b0)
		ld	a,ERR_NOMEM		; out of memory
		rst	RST2
		
; ---------------------------------------------------------
; 0x21c9
FUN_RETURN:	ld	(var_71b0),sp
		ld	sp,(var_7205)
		ld	hl,var_722f
		and	a
		sbc	hl,sp
		ld	a,$12
		jp	z,BREAK2
		pop	hl
		pop	de
		ld	(CURLIN),de
		ld	(var_7205),sp
		ld	sp,(var_71b0)
		ret
		
; ---------------------------------------------------------
; 0x21eb
FUN_CALL:	push	ix
		push	bc
		push	de
		ld	de,dat_2438
		call	token_get_id
		jr	nc,lab_2248
		ld	a,(hl)
		cp	$28
		jp	nz,parse_exp
		inc	hl
		push	hl
		ex	de,hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		pop	hl
		push	de
		pop	ix
		ld	de,lab_2240		; set call return address
		push	de
		ld	bc,$0000
		xor	a
		ld	(var_71a4),a
@r_2212:	ld	a,(hl)
		cp	$2c
		jr	nz,@r_2224
		ld	a,(var_71a4)
		and	a
		jr	nz,@r_2233
		sla	b
		sla	c
		inc	hl
		jr	@r_2212
@r_2224:	cp	$29
		jr	z,@r_223a
		call	fun_22e6
		push	de
		ld	a,$ff
		ld	(var_71a4),a
		jr	@r_2212
@r_2233:	xor	a
		ld	(var_71a4),a
		inc	hl
		jr	@r_2212
@r_223a:	inc	hl

lab_223b:	ld	(var_7391),hl
		jp	(ix)
		
lab_2240:	ld	hl,(var_7391)
		pop	de
		pop	bc
		pop	ix
		ret

lab_2248:	call	param_get_1
		call	param_get_2
		push	de
		pop	ix
		ld	de,lab_2240		; set return address
		push	de
		jr	lab_223b

lab_2257:	jp	parse_exp

fun_225a:	srl	c
		jr	nc,lab_2257
		srl	b
		jr	c,lab_2257
		ret

; 0x2263
CALL_CHAR:	ld	ix,(dat_3ee0)
		jr	lab_226d

; ---------------------------------------------------------
; 0x2269
CALL_SPRPTN:	ld	ix,(dat_3eea)

lab_226d:	srl	c
		jr	nc,lab_2257
		srl	b
		jr	nc,lab_2257
		pop	hl
		call	fun_225a
		pop	de
		ld	a,e
		call	fun_2335
		add	ix,de
		push	ix
		pop	de
		ex	de,hl
		ld	b,$08
@r_2286:	call	fun_2345
		jr	c,@r_2293
		call	FUN_VRAMWR
		inc	hl
		djnz	@r_2286
		jr	lab_229a
@r_2293:	xor	a
		call	FUN_VRAMWR
		inc	hl
		djnz	@r_2293
		
lab_229a:	ld	a,c
		and	a
		jr	nz,lab_2257
		ret
		
; ---------------------------------------------------------
; 0x229f
CALL_CHRCOL:	call	fun_225a
		pop	de
		call	fun_225a
		pop	hl
		ld	a,l
		and	$0f
		rlca
		rlca
		rlca
		rlca
		ld	d,a
		ld	a,e
		and	$0f
		or	d
		call	fun_225a
		pop	de
		ld	d,a
		ld	a,e
		and	$1f
		ld	e,a
		ld	a,d
		ld	d,$00
		ld	hl,(dat_3ee8)
		add	hl,de
		call	FUN_VRAMWR
		jr	lab_229a

; ---------------------------------------------------------
		
fun_22c8:	push	ix
		push	hl
		push	de
		push	bc
		call	FUN_INT
		pop	bc
		pop	de
		pop	hl
		pop	ix
		ret
		
; ---------------------------------------------------------
; Get parameter (2)
; 0x22d6
param_get_2:	push	bc
		ld	ix,var_71bc
		call	fun_0ab8
		jp	z,parse_exp
		call	fun_22f6
		pop	bc
		ret

; ---------------------------------------------------------
		
fun_22e6:	call	fun_1a69
		jr	nz,fun_22f6
		ld	de,(var_71be)
		scf
		rl	b
		scf
		rl	c
		ret
		
fun_22f6:	push	bc
		call	fun_22c8
		ld	a,(var_71bc)
		and	$3f
		jr	nz,@r_2305
		ld	d,a
		ld	e,a
		jr	@r_231d
@r_2305:	ld	b,a
		ld	a,$10
		sub	b
		jp	c,lab_257c
		ld	b,a
		ld	a,(var_71bd)
		ld	d,a
		ld	a,(var_71be)
		ld	e,a
		jr	z,@r_231d
@r_2317:	srl	d
		rr	e
		djnz	@r_2317
@r_231d:	push	hl
		ld	hl,var_71bc
		bit	7,(hl)
		jr	z,@r_232d
		ld	hl,$0000
		scf
		sbc	hl,de
		ld	e,l
		ld	d,h
@r_232d:	pop	hl
		pop	bc
		scf
		rl	c
		sla	b
		ret
		
fun_2335:	ld	d,$00
		ld	e,a
		sla	e
		rl	d
		sla	e
		rl	d
		sla	e
		rl	d
		ret
		
fun_2345:	push	hl
		ld	hl,var_71ac
		call	fun_235b
		jr	c,@r_2359
		rld
		call	fun_235b
		jr	c,@r_2359
		rld
		ld	a,(hl)
		and	a
@r_2359:	pop	hl
		ret

fun_235b:	ld	a,(de)
		cp	$3a
		jr	c,@r_236c
		cp	$41
		ret	c
		cp	$47
		jr	nc,@r_2371
		sub	$07
@r_2369:	inc	de
		and	a
		ret
@r_236c:	cp	$30
		ret	c
		jr	@r_2369
@r_2371:	scf
		ret

; ---------------------------------------------------------
; 0x2373
CALL_SPRITE:	call	fun_225a
		pop	hl
		ld	h,$00
		ld	a,l
		and	$1f
		rla
		rla
		or	$03
		ld	l,a
		ld	de,(dat_3eec)
		add	hl,de
		srl	c
		jr	nc,@r_23aa
		srl	b
		jp	nz,parse_exp
		pop	de
		ld	a,e
		and	$8f
		jp	p,@r_23a5
		xor	$0f
		jr	@r_23a5
@r_239a:	srl	c
		jr	nc,@r_23aa
		srl	b
		jp	nz,parse_exp
		pop	de
		ld	a,e
@r_23a5:	call	FUN_VRAMWR
		jr	@r_23ac
@r_23aa:	srl	b
@r_23ac:	dec	hl
		ld	a,l
		and	$03
		xor	$03
		ret	z
		jr	@r_239a

; ---------------------------------------------------------
; 0x23b5
CALL_HCHAR:	ld	ix,lab_23bb
		jr	lab_23fa
		
lab_23bb:	call	fun_2426
@r_23be:	call	FUN_SCRNWR
		cpi
		jp	po,lab_23d1		; ret po
		ex	af,af'
		ld	a,h
		cp	$03
		jr	nz,@r_23ce
		ld	h,$00
@r_23ce:	ex	af,af'
		jr	@r_23be
		
lab_23d1:	ret

; ---------------------------------------------------------
; 0x23d2
CALL_VCHAR:	ld	ix,lab_23d8
		jr	lab_23fa

lab_23d8:	push	hl
		call	fun_2426
		call	FUN_SCRNWR
		pop	hl
		cpi
		jp	po,lab_23d1		; ret po
		dec	hl
		ex	af,af'
		inc	h
		ld	a,h
		cp	$18
		jr	c,@r_23f7
		ld	h,$00
		inc	l
		ld	a,l
		cp	$20
		jr	c,@r_23f7
		ld	l,$00
@r_23f7:	ex	af,af'
		jr	lab_23d8
		
; ---------------------------------------------------------
; common hchar and vchar subroutine
lab_23fa:	ld	de,$0001
		ld	a,c
		and	$08
		jr	z,@r_2406
		call	fun_225a
		pop	de
@r_2406:	call	fun_225a
		pop	hl
		call	fun_225a
		ld	a,l
		pop	hl
		ex	de,hl
		ex	(sp),hl
		ld	h,l
		ld	l,e
		ex	af,af'
		ld	a,l
		and	$1f
		ld	l,a
		ld	a,h
		and	$1f
		cp	$18
		jr	c,@r_2421
		sub	$18
@r_2421:	ld	h,a
		ex	af,af'
		pop	bc
		jp	(ix)
		
fun_2426:	ex	af,af'
		xor	a
		srl	h
		rr	a
		srl	h
		rr	a
		srl	h
		rr	a
		or	l
		ld	l,a
		ex	af,af'
		ret

; ---------------------------------------------------------
; call statement table
dat_2438:	db	"CHAR",$80
		dw	CALL_CHAR		; 0x2263
		db	"CHRCOL",$80
		dw	CALL_CHRCOL		; 0x229f
		db	"HCHAR",$80
		dw	CALL_HCHAR		; 0x23b5
		db	"SCREEN",$80
		dw	CALL_SCREEN		; 0x2474
		db	"SPRITE",$80
		dw	CALL_SPRITE		; 0x2373
		db	"SPRPTN",$80
		dw	CALL_SPRPTN		; 0x2269
		db	"VCHAR",$80
		dw	CALL_VCHAR		; 0x23d2
		db	$ff
		
; ---------------------------------------------------------
; 0x2474
CALL_SCREEN:	call	screen_disable
		jr	z,@r_248f
		call	fun_225a
		pop	de
		ld	a,e
		and	$03
		ld	(var_733b),a
		and	a
		jr	z,@r_24a2
		cp	$01
		jr	z,@r_24b5
		cp	$02
		jr	z,@r_24e8
		nop
		;
; set screen color
@r_248f:	call	fun_225a
		pop	de
		ld	a,e
		and	$1f
		out	(IOVDP1),a
		ld	a,$87
		out	(IOVDP1),a
		ld	a,c
		and	a
		jp	screen_enable
		db	$00
		;
; screen 0: text mode 32x24
@r_24a2:	push	bc
		ld	hl,VDPR0
		res	1,(hl)
		inc	hl
		res	3,(hl)
		res	4,(hl)
		call	fun_0059
		pop	bc
		jr	@r_248f
		nop
		nop
		;
; screen 1: highres graphics 256x192
@r_24b5:	push	bc
		ld	hl,VDPR0
		set	1,(hl)
		inc	hl
		res	3,(hl)
		res	4,(hl)
		call	FUN_SETMOD
		ld	bc,6*256+IOVDP1
		ld	hl,dat_3efe
		otir
		ld	bc,$3800
		ld	de,(dat_3ee0)
		xor	a
		call	vdp_block_write
		ld	bc,$0300
		ld	hl,(dat_3ee4)
@r_24dc:	ld	a,l
		call	FUN_VRAMWR
		cpi
		jp	pe,@r_24dc
		pop	bc
		jr	@r_248f
		;
; screen 2: lowres graphics 64x48
@r_24e8:	push	bc
		ld	hl,VDPR0
		res	1,(hl)
		inc	hl
		res	4,(hl)
		set	3,(hl)
		call	FUN_SETMOD
		ld	bc,6*256+IOVDP1
		ld	hl,dat_3f04
		otir
		ld	de,(dat_3ee2)
		ld	bc,$0800
		xor	a
		call	vdp_block_write
		ld	hl,(dat_3ee6)
		ld	bc,$0600
@r_250f:	push	bc
		ld	b,$04
@r_2512:	ld	a,c
		push	bc
		ld	b,$20
@r_2516:	call	FUN_VRAMWR
		inc	a
		inc	hl
		djnz	@r_2516
		pop	bc
		djnz	@r_2512
		pop	bc
		ld	a,c
		add	a,$20
		ld	c,a
		djnz	@r_250f
		pop	bc
		jp	@r_248f

; ---------------------------------------------------------
; Transfer VDPR0 and VDPR1 into VDP registers
; 0x252b		
FUN_SETMOD:	in	a,(IOVDP1)
		ld	a,(VDPR0)
		out	(IOVDP1),a
		ld	a,$80
		out	(IOVDP1),a
		ld	a,(VDPR1)
		out	(IOVDP1),a
		ld	a,$81
		out	(IOVDP1),a
		ret

; ---------------------------------------------------------
		
fun_2540:	call	param_get_1

fun_2543:	push	bc
		call	fun_191a
		jr	z,lab_257c
		jr	lab_2552
		
fun_254b:	push	bc
		call	fun_1a69
		jp	z,parse_exp
		
lab_2552:	call	fun_22c8
		ld	a,(var_71bc)
		and	$3f
		jr	z,@r_2570
		cp	$09
		ld	b,a
		jr	nc,lab_257c
		ld	a,$08
		sub	b
		jr	z,@r_2567
		ld	b,a
@r_2567:	ld	a,(var_71bd)
		jr	z,@r_257a
@r_256c:	srl	a
		djnz	@r_256c
@r_2570:	push	hl
		ld	hl,var_71bc
		bit	7,(hl)
		jr	z,@r_2579
		cpl
@r_2579:	pop	hl
@r_257a:	pop	bc
		ret
		
lab_257c:	ld	a,ERR_SYNTAX		; syntax error
		rst	RST2

; ---------------------------------------------------------
; 0x257f
FUN_HOME:	ld	a,$20
		ld	de,(dat_3ee4)
		ld	bc,$0300
		and	a
		call	vdp_block_write
		xor	a
		ld	(CURPOS),a
		ld	(var_7010),a
		ret

; ---------------------------------------------------------
; 0x2594
FUN_NEW:	push	ix
		ld	a,(LOMEM)
		ld	ix,(LOMEM)
		add	a,$04
		ld	(ix+$00),a
		ld	(ADDR),a
		jr	nc,@r_25ad
		ld	a,(LOMEM+1)
		inc	a
		jr	@r_25b0
@r_25ad:	ld	a,(LOMEM+1)
@r_25b0:	ld	(ix+$01),a
		ld	(ADDR+1),a
		xor	a
		ld	(ix+$02),a
		ld	(ix+$03),a
		ld	(ix+$04),a
		ld	(ix+$05),a
		ld	(LINEH+1),a
		ld	(LINEH),a
		call	init_memvec
		pop	ix
		ret

; ---------------------------------------------------------
; 0x25cf
FUN_AUTO:	ld	a,(var_71e1)
		set	4,a
		ld	(var_71e1),a

fun_25d7:	push	de
		push	hl
		ld	hl,$0010
		ld	(var_719c),hl
		ld	(var_719e),hl
		pop	hl
		call	fun_0621
		jr	nz,@r_260d
		ld	a,(hl)
		cp	$2c
		jr	z,@r_25f8
		call	parse_endofcmd
		jr	nz,@r_2617
		ld	(var_719c),de
		jr	@r_260b
@r_25f8:	ld	(var_719c),de
@r_25fc:	inc	hl
		call	fun_0621
		jr	nz,@r_2612
		call	parse_endofcmd
		jr	nz,@r_2617
		ld	(var_719e),de
@r_260b:	pop	de
		ret
@r_260d:	ld	a,(hl)
		cp	$2c
		jr	z,@r_25fc
@r_2612:	call	parse_endofcmd
		jr	z,@r_260b
@r_2617:	ld	a,ERR_BL		; bad line number
		rst	RST2

; ---------------------------------------------------------
; Parser: check end of command
; 0x261a
parse_endofcmd:	ld	a,(hl)
		and	a
		ret	z
		cp	$3a
		ret	z
		cp	$95
		ret

; ---------------------------------------------------------
; 0x2623
FUN_RENUM:	push	hl
		xor	a
		ld	(var_71ad),a
		call	fun_25d7
		ld	de,(ADDR)
		ld	ix,(LOMEM)
@r_2633:	ld	l,(ix+$00)
		ld	h,(ix+$01)
		push	hl
		xor	a
		sbc	hl,de
		jr	z,@r_2656
		pop	ix
		ld	a,(var_71ad)
		and	a
		jr	nz,@r_264e
		ld	a,$02
		ld	(var_71ad),a
		jr	@r_2633
@r_264e:	call	fun_363c
		jp	c,lab_0667
		jr	@r_2633
@r_2656:	pop	hl
		pop	hl
		ld	a,$76
		ld	(var_71ad),a
@r_265d:	ld	(var_71ac),a
		push	hl
		call	fun_25d7
		ld	de,(ADDR)
		ld	ix,(LOMEM)
@r_266c:	ld	l,(ix+$00)
		ld	h,(ix+$01)
		push	hl
		xor	a
		sbc	hl,de
		jr	z,@r_26ae
		pop	hl
		push	hl
		inc	hl
		inc	hl
		ld	a,(var_71ac)
		and	a
		jr	z,@r_2688
		xor	a
		ld	(var_71ac),a
		jr	@r_268b
@r_2688:	call	fun_363c
@r_268b:	ld	a,(var_71ad)
		and	a
		jr	z,@r_2696
		call	fun_2714
		jr	@r_269f
@r_2696:	ld	a,(var_719c)
		ld	(hl),a
		inc	hl
		ld	a,(var_719d)
		ld	(hl),a
@r_269f:	pop	ix
		ld	a,(var_71ab)
		cp	$36
		jr	nz,@r_266c
		xor	a
		ld	(var_71ab),a
		jr	@r_26b9
@r_26ae:	ld	a,(var_71ad)
		and	a
		jr	z,@r_26bf
		xor	a
		ld	(var_71ad),a
		pop	hl
@r_26b9:	pop	hl
		ld	a,$76
		jp	@r_265d
@r_26bf:	ld	de,(ADDR)
		ld	ix,(LOMEM)
@r_26c7:	ld	l,(ix+$00)
		ld	h,(ix+$01)
		push	hl
		xor	a
		sbc	hl,de
		pop	hl
		jr	z,@r_26ec
		push	hl
		call	fun_274c
		jr	z,@r_26de
@r_26da:	pop	ix
		jr	@r_26c7
@r_26de:	inc	hl
		ld	a,(hl)
		and	a
		jr	z,@r_26da
		cp	$1a
		jr	nc,@r_26de
		add	a,$20
		ld	(hl),a
		jr	@r_26de
@r_26ec:	pop	hl
		pop	hl
		call	fun_25d7
		
fun_26f1:	exx
		ld	hl,(ADDR)
		ld	ix,(ADDR)
		call	fun_2930
		xor	a
		ld	hl,(LINEH)
		sbc	hl,de
		jr	nc,lab_2712
		
fun_2704:	ld	(LINEH),de
		push	ix
		pop	hl
		call	fun_2930
		ld	(var_71ef),de
		
lab_2712:	exx
		ret

fun_2714:	ld	a,(hl)
		ld	(var_71a8),a
		inc	hl
		ld	a,(hl)
		ld	(var_71a9),a
		ld	ix,(LOMEM)
lab_2721:	ld	l,(ix+$00)
		ld	h,(ix+$01)
		
lab_2727:	push	hl
		xor	a
		sbc	hl,de
		pop	hl
		jp	z,lab_27b8		; ret z
		push	hl
@r_2730:	call	fun_274c
		jr	z,@r_2739
		pop	ix
		jr	lab_2721
@r_2739:	call	fun_27bd
		jr	z,lab_276a
		push	ix
		pop	hl
		ld	a,(hl)
		cp	$2c
		jr	z,@r_2739
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		jr	@r_2730
		
fun_274c:	inc	hl
		inc	hl
		inc	hl
		inc	hl
@r_2750:	ld	a,(hl)
		cp	$22
		jr	nz,@r_275a
		call	fun_0874
		jr	@r_2750
@r_275a:	cp	$92
		ret	z
		cp	$97
		ret	z
		cp	$a1
		ret	z
		inc	hl
		and	a
		jr	nz,@r_2750
		or	$01
		ret
		
lab_276a:	pop	de
		push	de
		dec	hl
		dec	hl
		xor	a
		sbc	hl,de
		push	hl
		pop	bc
		ex	de,hl
		push	hl
		inc	hl
		inc	hl
		ld	de,IOBUF
		ldir
		push	de
		pop	iy
		ld	hl,var_719d
		ld	a,$76
		ld	(var_71b5),a
		call	fun_066a
		xor	a
		ld	(var_71b5),a
		ld	a,(de)
		sub	$20
		ld	(de),a
@r_2792:	ld	a,(ix+$00)
		and	a
		jr	z,@r_27a1
		ld	(iy+$00),a
		inc	ix
		inc	iy
		jr	@r_2792
@r_27a1:	ld	(iy+$00),a
		ld	a,$36
		ld	(var_71ab),a
		call	fun_0614
		pop	hl
		call	fun_27b9
		ld	de,(ADDR)
		pop	hl
		jp	lab_2727

lab_27b8:	ret

fun_27b9:	push	bc
		jp	lab_0594

fun_27bd:	inc	hl
		push	hl
		call	fun_0621
		jr	z,@r_27cd
		inc	hl
		call	fun_0621
		push	hl
		or	$09
		jr	@r_27d8
@r_27cd:	push	hl
		ld	a,(var_71a8)
		sub	e
		jr	nz,@r_27d8
		ld	a,(var_71a9)
		sub	d
@r_27d8:	pop	ix
		pop	hl
		ld	de,(ADDR)
		ret

; ---------------------------------------------------------
; 0x27e0
FUN_ON:		call	param_get_1
		push	hl
		ld	hl,var_71a0
		ld	(hl),$00
		ld	a,(var_71bc)
		ld	b,a
		cp	$09
		jr	nc,@r_2800
		and	a
		jr	z,@r_2800
		ld	a,(var_71bd)
@r_27f7:	sla	a
		rl	(hl)
		djnz	@r_27f7
		ld	b,(hl)
		jr	@r_2802
@r_2800:	ld	b,$ff
@r_2802:	dec	b
		pop	hl
		ld	a,(hl)
		cp	$92
		jr	z,@r_280e
		cp	$97
		jp	nz,parse_exp
@r_280e:	ld	(var_71a5),a
		ld	a,b
		and	a
		jr	z,lab_2821
		
lab_2815:	inc	hl

lab_2816:	call	parse_endofcmd
		jr	z,lab_2835		; ret z
		cp	$2c
		jr	nz,lab_2815
		djnz	lab_2815
lab_2821:	inc	hl
		ld	a,(var_71a5)
		cp	$92
		jr	nz,@r_282e
		call	FUN_GOSUB
		jr	lab_2831
@r_282e:	call	FUN_GOTO

lab_2831:	ld	b,$20
		jr	lab_2816
		
lab_2835:	ret

; ---------------------------------------------------------

fun_2836:	xor	a
		ld	(var_71ee),a
		push	hl
		ld	hl,(LOMEM)
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	a,d
		or	e
		jr	z,lab_288b
		ld	(var_7345),de
		ld	de,(ADDR)
		ld	(var_7347),de
		pop	hl
		call	parse_endofcmd
		jr	z,@r_2889
		call	fun_0621
		jr	nz,@r_2870
		call	FUN_LONUMB
		jr	nc,lab_288e
		ld	(var_7345),de
		call	parse_endofcmd
		jr	nz,@r_2870
		ld	(var_7347),de
		jr	@r_2889
@r_2870:	ld	a,(hl)
		cp	$2d
		jr	nz,lab_288e
		inc	hl
		call	parse_endofcmd
		jr	z,@r_2889
		call	fun_0621
		jr	nz,lab_288e
		call	FUN_LONUMB
		jr	nc,lab_288e
		ld	(var_7347),de
@r_2889:	scf
		ret
		
lab_288b:	and	a
		pop	hl
		ret
		
lab_288e:	ld	a,ERR_BL		; bad line number
		rst	RST2

; ---------------------------------------------------------
; 0x2891
FUN_LIST:	call	fun_2836
		ret	nc
		push	hl
@r_2896:	ld	hl,(var_7347)
		ld	de,(var_7345)
		and	a
		sbc	hl,de
		jr	c,lab_288b
		ex	de,hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	a,d
		or	e
		jr	z,lab_288b
		ld	(var_7345),de
		inc	hl
		call	DSPLIN
		rst	RST1
@r_28b3:	call	GETKEY
		jr	nc,@r_28cd
		cp	$1b
		jr	z,lab_288b
	IF V30 || V31
		cp	'?'
	ELSE
		; press space to pause listing
		cp	$20
	ENDIF
		jr	nz,@r_28cd
@r_28c0:	call	GETKEY
		jr	c,@r_28c0
		ld	a,(var_71ee)
		add	a,$80
		ld	(var_71ee),a
@r_28cd:	ld	a,(var_71ee)		
		and	a
		jr	z,@r_2896
		jr	@r_28b3

; ---------------------------------------------------------
; 0x28d5
FUN_DEL:	call	fun_2927
		call	parse_endofcmd
		jp	z,parse_exp
		call	fun_2836
		ret	nc
		
fun_28e2:	push	hl
		ld	hl,(var_7347)
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	a,d
		or	e
		jr	nz,@r_28ef
		dec	hl
		ex	de,hl
@r_28ef:	ld	hl,(ADDR)
		and	a
		sbc	hl,de
		inc	hl
		inc	hl
		ld	b,h
		ld	c,l
		ld	hl,(var_7345)
		ex	de,hl
		ldir
		ld	hl,(var_7345)
		call	fun_2907
		pop	hl
		ret
		
fun_2907:	ld	a,(hl)
		inc	hl
		or	(hl)
		dec	hl
		jr	z,@r_291e
		push	hl
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		call	fun_21bb
		inc	hl
		ex	de,hl
		pop	hl
		ld	(hl),e
		inc	hl
		ld	(hl),d
		ex	de,hl
		jr	fun_2907
@r_291e:	ld	(ADDR),hl
		call	fun_26f1
		jp	init_memvec
		
fun_2927:	ld	a,(var_71e1)
		bit	7,a
		ret	z
		ld	a,ERR_IS		; incorrect statement
		rst	RST2
		
fun_2930:	dec	ix
		ld	e,(ix+$00)
		ld	d,(ix+$01)
		push	hl
		xor	a
		sbc	hl,de
		pop	hl
		jr	nz,fun_2930
		ld	e,(ix+$02)
		ld	d,(ix+$03)
		ret

; ---------------------------------------------------------
; 0x2946
FUN_EDIT:	call	fun_2927
		push	hl
		call	FUN_LSTCHR
		ld	(CURPOS),hl
		rst	RST1
		ld	de,(CURPOS)
		ld	(var_71f7),de
		pop	hl
		call	fun_0621
		push	hl
		jr	nz,@r_2985
		call	FUN_LONUMB
		jr	nc,@r_2985
		inc	de
		inc	de
		ex	de,hl
		call	DSPLIN
		ld	de,(var_71f7)
		ld	(CURPOS),de
		call	GETLIN
		call	buf_to_bas
		ld	a,(var_71e0)
		and	a
		jp	nz,parse_exp
		call	fun_051d
		pop	hl
		ret
@r_2985:	ld	a,ERR_BL		; bad line number
		rst	RST2

; ---------------------------------------------------------

fun_2988:	ld	a,(hl)
		rra
		rra
		rra
		rra
		and	$0f
		and	a
		jr	nz,@r_29a3
		ld	a,b
		cp	$01
		jr	z,@r_29a2
		ld	a,(var_71b5)
		cp	$76
		jr	z,@r_29ac
		ld	a,$20
		jr	@r_29a7
@r_29a2:	xor	a
@r_29a3:	ld	b,$01
		add	a,$30
@r_29a7:	ld	(iy+$00),a
		inc	iy
@r_29ac:	ld	a,(hl)
		and	$0f
		jr	nz,@r_29c1
		ld	a,b
		cp	$01
		jr	z,@r_29c0
		ld	a,(var_71b5)
		cp	$76
		ret	z
		ld	a,$20
		jr	@r_29c5
@r_29c0:	xor	a
@r_29c1:	ld	b,$01
		add	a,$30
@r_29c5:	ld	(iy+$00),a
		inc	iy
		ret
		
; ---------------------------------------------------------
; 0x29cb unused
		call	fun_0621
		jr	nz,@x_2a00
		call	FUN_LONUMB
		ld	a,d
		or	e
		jr	nz,@x_29de
		ld	a,$ff
		ld	(var_71e0),a
		jr	@x_2a00
@x_29de:	push	hl
		ld	iy,IOBUF
		push	de
		pop	hl
		inc	hl
		inc	hl
		ld	a,(hl)
		ld	(iy+$00),a
		inc	iy
		inc	hl
		ld	a,(hl)
		ld	(iy+$00),a
		inc	hl
		inc	iy
@x_29f5:	ld	a,(hl)
		ld	(iy+$00),a
		inc	hl
		inc	iy
		and	a
		jr	nz,@x_29f5
		pop	hl
@x_2a00:	ret

; ---------------------------------------------------------
; 0x2a01
FUN_GOTO:	push	de
		call	fun_0621
		jr	nz,lab_2a12
		call	FUN_LONUMB
		jr	nc,lab_2a12
		ld	(CURLIN),de
		pop	de
		ret
		
lab_2a12:	pop	de
		ld	a,ERR_BL		; bad line number
		rst	RST2

; ---------------------------------------------------------
; 0x2a16
FUN_ONERRGOTO:	push	de
		ld	a,(var_71e1)
		set	3,a
		ld	(var_71e1),a
		call	fun_0621
		jr	nz,lab_2a12
		ld	(var_723b),de
		call	FUN_LONUMB
		jr	nc,lab_2a12
		pop	de
		ret

; ---------------------------------------------------------
; 0x2a2f
FUN_PRINT:	push	bc
		push	de
@r_2a31:	call	parse_endofcmd
		jr	z,lab_2a7e
		cp	$2c
		jr	z,@r_2a43
		cp	$3b
		jr	z,@r_2a48
		call	fun_2a50
		jr	@r_2a31
@r_2a43:	ld	a,$09
		call	DSPCHR
@r_2a48:	inc	hl
		call	parse_endofcmd
		jr	z,lab_2a7f
		jr	@r_2a31

fun_2a50:	call	fun_15f4
		jr	z,lab_2a67
		
fun_2a55:	push	hl
		ld	hl,var_71a0
		call	fun_12b0
		ld	de,var_71a0
		xor	a
		sbc	hl,de
		ld	b,l
		ld	h,d
		ld	l,e
		jr	lab_2a71
		
lab_2a67:	ld	a,(var_71bc)
		and	a
		ret	z
		push	hl
		ld	b,a
		ld	hl,(var_71be)
		
lab_2a71:	call	fun_2a76
		pop	hl
		ret

; print string, length in register b
fun_2a76:	ld	a,(hl)
		call	DSPCHR
		inc	hl
		djnz	fun_2a76
		ret
		
lab_2a7e:	rst	RST1

lab_2a7f:	pop	de
		pop	bc
		ret

; ---------------------------------------------------------
; 0x2a82
FUN_COPY:
	IFDEF V30
		; Hardcopy characters printed to screen to the printer
		; for printer connected to the centronics interface
		push	de
		push	bc
		call	parse_endofcmd
		jr	z,@r_2aa0
		cp	$9f
		jr	z,@r_2a9f
		ld	de,dat_2ad6
		ld	a,(de)
		ld	b,$03
@r_2a93:	cp	(hl)
		jp	nz,parse_exp
		inc	de
		inc	hl
		ld	a,(de)
		djnz	@r_2a93
		xor	a
		jr	@r_2aae
@r_2a9f:	inc	hl
@r_2aa0:	ld	a,$03
		out	(IOLPT0),a
		ld	a,$01
		out	(IOLPT0),a
		ld	a,$03
		out	(IOLPT0),a
		ld	a,$ff
@r_2aae:	ld	(var_733f),a
		pop	bc
		pop	de
		ret
	ELSE
		; Hardcopy characters printed to screen to the printer
		; for BIT90 printer 90201
		call	parse_endofcmd
		jr	z,ext_call_7800
		cp	$9f
		jr	z,@r_2a9f
		ld	de,dat_2ad6
		ld	a,(de)
		ld	b,$03
@r_2a91:	cp	(hl)
		jp	nz,parse_exp
		inc	de
		inc	hl
		ld	a,(de)
		djnz	@r_2a91
		ld	a,$1b
		jp	DSPCHR
@r_2a9f:	inc	hl

; Call routine in (printer) extension rom at 0x7800-0x7fff
; first check rom presence by validating signature "$aa 55" at address 0x7ffa, 
; if the signature is valid then call routine at address 0x7800
; 0x2aa0
ext_call_7800:	push	hl
		ld	a,$aa
		ld	hl,$7ffa		; rom signature addres
		cp	(hl)			; valid sig 1?
		jr	nz,@r_2ab1		; nz=no
		inc	hl
		cpl				; $55
		cp	(hl)			; valid sig 2?
		jr	nz,@r_2ab1		; nz=no
		call	$7800			; yes, call rom address
@r_2ab1:	pop	hl
		ret
		db	$00			; unused
	ENDIF ; V30
	
; ---------------------------------------------------------
; 0x2ab4
FUN_RESUME:	ld	hl,var_71e1
		bit	1,(hl)
		ld	a,$0f
		jp	z,BREAK2
		res	1,(hl)
		ld	hl,(var_71ff)
		ld	(var_71f9),hl
		ld	hl,(var_71fd)
		ld	(CURLIN),hl
		ld	hl,(var_7201)
		exx
		pop	hl
		exx
		jp	lab_0338
		
		db	$c9			; unused

; ---------------------------------------------------------

; function 'COPY' lookup table
dat_2ad6:	db	"OFF"

; function 'MUSIC' lookup table
dat_2ad9:	db	$00,$01,$02,$03,$05,$07,$0b,$0f,$17,$1f

; ---------------------------------------------------------

lab_2ae3:	ld	a,ERR_IS		; incorrect statement
		rst	RST2

; ---------------------------------------------------------
		
fun_2ae6:	ld	hl,(DIMA)
@r_2ae9:	ld	a,(DIMED)
		cp	l
		jp	nz,@r_2af7
		ld	a,(DIMED+1)
		cp	h
		jr	nz,@r_2af7
		ret
@r_2af7:	ld	a,(hl)
		cp	d
		jr	nz,@r_2b04
		inc	hl
		ld	a,(hl)
		cp	e
		jr	nz,@r_2b03
		or	$01
		ret
@r_2b03:	dec	hl
@r_2b04:	ld	b,h
		ld	c,l
		inc	bc
		inc	bc
		ld	a,(bc)
		add	a,l
		ld	l,a
		inc	bc
		ld	a,(bc)
		adc	a,h
		ld	h,a
		jr	@r_2ae9
		
fun_2b11:	xor	a
		ld	(var_71f1),a
		ld	iy,var_7198
		call	fun_2ae6
		jr	nz,@r_2b24
		ld	a,$25
		ld	(var_71f1),a
		ret
@r_2b24:	ld	de,$0003
		add	hl,de
		ld	a,(iy+$00)
		cp	(hl)
		jr	z,@r_2b33
@r_2b2e:	xor	a
		ret	z
@r_2b30:	pop	de
		jr	@r_2b2e
@r_2b33:	ld	a,$04
		sub	(iy+$00)
		ld	b,$00
		ld	c,a
		add	iy,bc
		ld	a,(hl)
		inc	hl
		ld	c,a
		ld	de,var_719c
		ldir
		ld	c,a
		ld	b,a
		push	hl
		ld	a,(var_7230)
		and	a
		jr	z,@r_2b59
		push	iy
		pop	hl
@r_2b51:	dec	(hl)
		jr	c,@r_2b2e
		inc	hl
		djnz	@r_2b51
		jr	@r_2b65
@r_2b59:	ld	hl,var_719c
@r_2b5c:	inc	(hl)
		ld	a,(hl)
		and	a
		jp	z,lab_2d46
		inc	hl
		djnz	@r_2b5c
@r_2b65:	ld	ix,var_719c
		ld	hl,$0000
@r_2b6c:	ld	d,$00
		ld	b,(ix+$00)
		ld	e,(iy+$00)
		ld	a,b
		cp	e
		jr	c,@r_2b30
		jr	z,@r_2b30
		add	hl,de
		dec	c
		jr	z,@r_2b8e
		ex	de,hl
		inc	ix
		ld	b,(ix+$00)
		ld	hl,$0000
@r_2b87:	add	hl,de
		djnz	@r_2b87
		inc	iy
		jr	@r_2b6c
@r_2b8e:	pop	de
		sla	l
		rl	h
		sla	l
		rl	h
		add	hl,de
		or	$01
		ret
		
; ---------------------------------------------------------
; 0x2b9b
FUN_LET:	call	fun_0a5d
		jr	nz,@r_2c0b
		bit	7,d
		jr	nz,@r_2bd2
		ld	a,(hl)
		cp	$3d
		jr	nz,@r_2c0b
		inc	hl
		push	de
		call	param_get_1
		pop	de
@r_2baf:	bit	7,e
		jr	z,@r_2bfb
		push	hl
		push	de
		call	fun_191a
		jr	nz,@r_2c0e
		ld	de,(var_71be)
		ld	hl,IOBUF
		xor	a
		sbc	hl,de
		jr	c,@r_2bce
		ex	de,hl
		ld	bc,(var_71bc)
		call	fun_2c1c
@r_2bce:	pop	de
		pop	hl
		jr	@r_2bfb
@r_2bd2:	call	fun_2e1f
		push	de
		ld	ix,(var_7198)
		push	ix
		ld	ix,(var_719a)
		push	ix
		inc	hl
		ld	a,(hl)
		cp	$3d
		jr	nz,@r_2c0b
		inc	hl
		call	param_get_1
		pop	ix
		ld	(var_719a),ix
		pop	ix
		ld	(var_7198),ix
		pop	de
		jr	@r_2baf
@r_2bfb:	ld	ix,var_71bc
		bit	7,e
		jr	z,@r_2c11
		call	fun_0ab8
		jr	nz,@r_2c0e
		jp	fun_2ca5
@r_2c0b:	jp	parse_exp
@r_2c0e:	ld	a,ERR_TM		; type mismatch
		rst	RST2
@r_2c11:	call	fun_0ab8
		jr	z,@r_2c0e
		jp	fun_2ca5
		
		ld	hl,IOBUF		; unused
		
fun_2c1c:	push	hl
		ld	hl,(HIMEM)
		and	a
		sbc	hl,bc
		call	fun_2f89
		pop	hl
		ld	de,(HIMEM)
		add	hl,bc
		dec	hl
		lddr
		ld	(HIMEM),de
		inc	de
		ld	(var_71be),de
		ret

; ---------------------------------------------------------
		
fun_2c39:	push	bc
		push	ix
		bit	7,d
		jr	z,@r_2c4e
		call	fun_2e1f
		inc	hl
		push	hl
		push	de
		call	fun_2b11
		pop	de
		jr	z,@r_2c6f
		jr	@r_2c67
@r_2c4e:	push	hl
		ld	a,d
		cp	'P'
		jr	nz,@r_2c5e
		ld	a,e
		cp	'I'
		jr	nz,@r_2c5e
		ld	hl,dat_140a		; pi value
		jr	@r_2c67
@r_2c5e:	call	fun_2c84
		jr	nz,@r_2c65
		jr	@r_2c6f
@r_2c65:	inc	hl
		inc	hl
@r_2c67:	push	de
		rst	RST5
		pop	de
@r_2c6a:	pop	hl
		pop	ix
		pop	bc
		ret
@r_2c6f:	ld	b,$04
		bit	7,e
		jr	z,@r_2c7c
		ld	b,$02
		ld	a,$03
		ld	(var_71be),a
@r_2c7c:	ld	hl,var_71bc
		call	fun_0e4a
		jr	@r_2c6a
		
fun_2c84:	ld	hl,(DTAD)
		ld	bc,$0006
@r_2c8a:	ld	a,(DIMA)
		cp	l
		jr	nz,@r_2c95
		ld	a,(DIMA+1)
		cp	h
		ret	z
@r_2c95:	ld	a,(hl)
		cp	d
		jr	nz,@r_2c9f
		inc	hl
		ld	a,(hl)
		dec	hl
		cp	e
		jr	z,@r_2ca2
@r_2c9f:	add	hl,bc
		jr	@r_2c8a
@r_2ca2:	or	$01
		ret
		
fun_2ca5:	push	hl
		push	bc
		push	de
		bit	7,d
		jr	nz,@r_2cb1
		call	fun_2c84
		jr	@r_2d07
@r_2cb1:	push	hl
		push	de
		call	fun_2b11
		pop	de
		pop	bc
		jp	nz,@r_2d36
		push	de
		push	bc
		ld	iy,var_7198
		call	fun_2ae6
		jp	nz,lab_2ae3
		pop	bc
		pop	de
		push	bc
		pop	hl
		exx
		ld	de,var_71bc
		ld	hl,var_71b8
		call	fun_001b
		ld	de,var_7198
		ld	hl,var_71b0
		call	fun_001b
		ld	de,@dat_2d03
		ld	hl,var_7198
		call	fun_001b
		exx
		push	hl
		push	de
		call	fun_2d53
		ld	de,var_71b0
		ld	hl,var_7198
		call	fun_001b
		ld	de,var_71b8
		ld	hl,var_71bc
		call	fun_001b
		pop	de
		pop	hl
		jr	@r_2cb1
@dat_2d03:	db	$01,$00,$00,$0a
@r_2d07:	jr	nz,@r_2d30
		ld	de,(DIMA)
		push	de
		ld	hl,(DIMED)
		push	hl
		xor	a
		sbc	hl,de
		push	hl
		ld	hl,(DIMA)
		add	hl,bc
		ld	(DIMA),hl
		ld	hl,(DIMED)
		add	hl,bc
		ld	(DIMED),hl
		pop	bc
		pop	de
		dec	de
		dec	hl
		ex	de,hl
		ld	a,b
		or	c
		jr	z,@r_2d2f
		lddr
@r_2d2f:	pop	hl
@r_2d30:	pop	de
		push	de
		ld	(hl),d
		inc	hl
		ld	(hl),e
		inc	hl
@r_2d36:	ld	bc,$0004
		ld	de,var_71bc
		ex	de,hl
		ldir
		pop	de
		pop	bc
		pop	hl
		ret

; ---------------------------------------------------------
; 0x2d43 unused
		ld	a,ERR_UF		; undefined function
		rst	RST2

; ---------------------------------------------------------
	
lab_2d46:	ld	a,ERR_BS		; bad subscript
		rst	RST2

; ---------------------------------------------------------
; 0x2d49
FUN_DIM:	call	fun_0a5d
		jp	nz,parse_exp
		call	fun_2e1f
		inc	hl

fun_2d53:	push	hl
		ld	ix,(DIMED)
		ld	b,$04
		ld	c,$ff
		ld	hl,var_7198
@r_2d5f:	ld	a,(hl)
		and	a
		jr	z,@r_2d69
		ld	(ix+$04),a
		inc	c
		inc	ix
@r_2d69:	inc	hl
		djnz	@r_2d5f
		ld	a,(var_7198)
		sub	c
		jp	nz,lab_2d46
		push	de
		push	ix
		call	fun_2ae6
		jp	nz,lab_2de7
		ld	hl,(DIMED)
		ld	(hl),d
		inc	hl
		ld	(hl),e
		inc	hl
		ld	(DIMED),hl
		call	FUN_FREA
		call	fun_2b11
		pop	ix
		ld	de,(DIMED)
		ld	bc,$04
		add	ix,bc
		add	hl,bc
		ld	(DIMED),hl
		call	FUN_FREA
		xor	a
		sbc	hl,de
		inc	hl
		inc	hl
		ld	a,l
		ld	(de),a
		inc	de
		ld	a,h
		ld	(de),a
		xor	a
		sbc	hl,bc
		push	hl
		pop	bc
		srl	b
		rr	c
		srl	b
		rr	c
		push	ix
		pop	hl
		pop	de
		bit	7,e
		jr	z,@r_2dbe
		cpl
@r_2dbe:	ld	d,a
@r_2dbf:	ld	(hl),$00
		inc	hl
		ld	(hl),$00
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),d
		inc	hl
		dec	bc
		ld	a,b
		or	c
		jr	nz,@r_2dbf
		pop	hl
		ld	a,(hl)
		cp	$2c
		ret	nz
		inc	hl
		jp	FUN_DIM

; ---------------------------------------------------------
; 0x2dd7
FUN_OPTIONBASE:	ld	a,(hl)
		inc	hl
		cp	$30
		jr	z,@r_2de1
		cp	$31
		jr	nz,lab_2dff
@r_2de1:	sub	$30
		ld	(var_7230),a
		ret
		
lab_2de7:	ld	a,ERR_RD		; redimensioned array
		rst	RST2

; ---------------------------------------------------------
; 0x2dea
FUN_DEF:	ld	a,(hl)
		cp	$da
		jr	nz,lab_2dff
		inc	hl
		call	fun_0a32
		jr	nz,lab_2dff
		ld	a,(hl)
		cp	$28
		jr	nz,lab_2dff
		inc	hl
		push	de
		call	fun_0a5d
		
lab_2dff:	jp	nz,parse_exp
		ld	(var_71be),de
		pop	de
		ld	a,(hl)
		cp	$29
		jr	nz,lab_2dff
		inc	hl
		ld	a,(hl)
		cp	$3d
		jr	nz,lab_2dff
		inc	hl
		ld	(var_71bc),hl
@r_2e16:	inc	hl
		call	parse_endofcmd
		jp	z,fun_2ca5
		jr	@r_2e16

fun_2e1f:	push	ix
		push	bc
		xor	a
		ld	(var_7199),a
		ld	(var_719a),a
		ld	ix,var_719b
		ld	b,$01
@r_2e2f:	push	ix
		push	de
		push	bc
		call	fun_2e76
		push	hl
		ld	hl,var_7142
		ld	ix,(var_7198)
		push	ix
		ld	ix,(var_719a)
		push	ix
		call	param_get_1
		call	param_get_2
		pop	ix
		ld	(var_719a),ix
		pop	ix
		ld	(var_7198),ix
		ld	a,d
		and	a
		jp	nz,lab_2d46
		ld	a,e
		pop	hl
		pop	bc
		pop	de
		pop	ix
		ld	(ix+$00),a
		ld	a,(hl)
		cp	$29
		jp	z,lab_2ef0
		cp	$2c
		jr	nz,lab_2dff
		inc	hl
		inc	b
		dec	ix
		jr	@r_2e2f

fun_2e76:	push	de
		ld	de,var_7142
		jr	lab_2e80

fun_2e7c:	push	de
		ld	de,var_70ed
		
lab_2e80:	xor	a
		ld	(var_71f1),a
		push	bc
		ld	b,a
@r_2e86:	ld	a,(hl)
		cp	$22
		jr	nz,@r_2ea6
@r_2e8b:	and	a
		jp	z,parse_exp
		ld	(de),a
		inc	hl
		inc	de
		inc	b
		ld	a,b
		cp	$55
		jr	c,@r_2e9b
		ld	a,ERR_EC		; expression too complex
		rst	RST2
@r_2e9b:	ld	a,(hl)
		cp	$22
		jr	nz,@r_2e8b
		ld	(de),a
		inc	hl
		inc	de
		jp	@r_2e86
@r_2ea6:	cp	$8b
		jr	z,@r_2eba
		cp	$8f
		jr	z,@r_2eba
		cp	$bf
		jr	c,@r_2eb6
		cp	$d7
		jr	c,@r_2eba
@r_2eb6:	cp	$28
		jr	nz,@r_2ec2
@r_2eba:	ld	a,(var_71f1)
		inc	a
		ld	(var_71f1),a
		ld	a,(hl)
@r_2ec2:	cp	$2c
		jr	nz,@r_2ecd
		ld	a,(var_71f1)
		and	a
		jr	z,@r_2eec
		ld	a,(hl)
@r_2ecd:	cp	$29
		jr	nz,@r_2edc
		ld	a,(var_71f1)
		and	a
		jr	z,@r_2eec
		dec	a
		ld	(var_71f1),a
		ld	a,(hl)
@r_2edc:	and	a
		jp	z,parse_exp
		ld	(de),a
		inc	hl
		inc	de
		inc	b
		ld	a,b
		cp	$55
		jr	c,@r_2e86
		ld	a,ERR_EC		; expression too complex
		rst	RST2
@r_2eec:	ld	(de),a
		pop	bc
		pop	de
		ret
		
lab_2ef0:	ld	a,b
		cp	$04
		jp	nc,parse_exp
		ld	(var_7198),a
		pop	bc
		pop	ix
		ret
		
; ---------------------------------------------------------
; 0x2efd
FUN_CLEAR:	push	de
		ld	de,(MEMT)
		ld	(HIMEM),de
		ld	de,(DTAD)
		ld	(DIMA),de
		ld	(DIMED),de
		pop	de
		ret

; ---------------------------------------------------------
; 0x2f14
FUN_IF:		ld	a,$01
		ld	(var_722f),a
		call	param_get_1
		push	hl
		ld	hl,var_71bc
		call	fun_0b4a
		pop	hl
		jr	z,@r_2f3c
		ld	ix,var_71bc
		call	fun_0ab8
		jp	z,lab_0b0f
		push	hl
		ld	hl,var_71bc
		call	fun_0b51
		pop	hl
		jr	z,@r_2f49
		jr	@r_2f43
@r_2f3c:	ld	a,(var_71bc)
		cp	$81
		jr	nz,@r_2f49
@r_2f43:	ld	a,(hl)
		cp	$a4			; "THEN"
		ret	nz
@r_2f47:	inc	hl
		ret
@r_2f49:	ld	a,(hl)
		and	a
		jr	nz,@r_2f51
		ld	(var_722f),a
		ret
@r_2f51:	cp	$a9			; "IF"
		jr	nz,@r_2f5f
		ld	a,(var_722f)
		inc	a
		ld	(var_722f),a
@r_2f5c:	inc	hl
		jr	@r_2f49
@r_2f5f:	cp	$95			; "ELSE"
		jr	nz,@r_2f5c
		ld	a,(var_722f)
		cp	$01
		jr	z,@r_2f47
		dec	a
		ld	(var_722f),a
		jr	@r_2f5c

; ---------------------------------------------------------
; 0x2f70
FUN_FRE:	push	hl
		push	de
		call	fun_2f86
		ex	de,hl
		call	fun_10de
		rst	RST1
		call	fun_2a55
		pop	de
		pop	hl
		ret

; ---------------------------------------------------------
; Check free RAM and display error if memory is insufficient
; 0x2f80
FUN_FREA:	exx
		call	fun_2f86
		exx
		ret
		
fun_2f86:	ld	hl,(HIMEM)
		
fun_2f89:	ld	de,(DIMED)
		xor	a
		sbc	hl,de
		jr	c,lab_2f93
		ret
		
lab_2f93:	ld	a,ERR_NOMEM		; out of memory
		rst	RST2

; ---------------------------------------------------------
; 0x2f96
FUN_INPUT:	xor	a
		ld	(var_71ec),a
@r_2f9a:	ld	a,(hl)
		cp	$2a
		jr	nz,@r_2fab
		ld	a,$76
		ld	(var_71ec),a
		inc	hl
		call	FUN_PRINT
		inc	hl
		jr	@r_2fc7
@r_2fab:	cp	$22
		jr	nz,@r_2fca
		call	fun_0874
		push	hl
		ld	a,(var_71bc)
		and	a
	IFDEF V30
		jr	z,@r_2fca
	ELSE
		jr	z,@r_2fc0
	ENDIF
		ld	b,a
		ld	hl,(var_71be)
		call	fun_2a76
@r_2fc0:	pop	hl
		ld	a,(hl)
		cp	$2c
		jr	nz,lab_3024
		inc	hl
@r_2fc7:	xor	a
		jr	@r_2fcc
@r_2fca:	ld	a,$3f
@r_2fcc:	ld	(PROMPT),a
		call	GETLIN
		cp	$1b			; [esc] key?
		jr	nz,@r_2fdb		; nz=no
		call	FUN_DATA
		xor	a			; break
		rst	RST2
@r_2fdb:	call	fun_2feb
		rst	RST1
		call	parse_endofcmd
		ret	z
		ld	a,(hl)
		cp	$2c
		jr	nz,lab_3024
		inc	hl
		jr	@r_2f9a
		
fun_2feb:	push	hl
		ld	(var_71cc),sp
		pop	hl
		ld	iy,IOBUF
		
lab_2ff5:	call	fun_0a5d
		jr	nz,lab_3024
		bit	7,d
		jr	z,@r_3006
		push	iy
		call	fun_2e1f
		pop	iy
		inc	hl
@r_3006:	push	hl
		push	iy
		pop	hl
		call	fun_303f
		call	fun_2ca5
		ld	a,(hl)
		cp	$2c
		jr	nz,lab_302f
		inc	hl
		ld	a,(hl)
		and	a
		jr	z,lab_302f
		
lab_301a:	push	hl
		pop	iy
		pop	hl
		call	parse_endofcmd
		ret	z
		cp	$2c

lab_3024:	jp	nz,parse_exp
		inc	hl
		ld	a,(hl)
		cp	$22
		jr	nz,lab_2ff5
		dec	hl
		ret

lab_302f:	ld	a,(var_71ec)
		cp	$76
		jr	nz,@r_303d
		ld	sp,(var_71cc)
		jp	lab_30ad
@r_303d:	pop	hl
		ret

fun_303f:	push	de
		bit	7,e
		jr	z,@r_3073
		ld	de,(HIMEM)
		ld	c,$00
@r_304a:	ld	a,(hl)
		and	a
		jr	z,@r_3056
		cp	$2c
		jr	z,@r_3056
		inc	c
		inc	hl
		jr	@r_304a
	IFDEF V30
@r_3056:	ld	a,c
		and	a
		jr	z,@r_3073
		ld	(var_71bc),a
		ld	b,$00
		xor	a
		ld	(var_71bd),a
		push	hl
		dec	hl
		lddr
		ld	(var_71e8),de
		inc	de
		ld	(var_71be),de
		pop	hl
		jr	lab_30c9
	ELSE
@r_3056:	ld	b,$00
		ld	(var_71bc),bc
		push	hl
		ld	a,c
		and	a
		jr	z,@r_3069
		dec	hl
		lddr
		ld	(HIMEM),de
		inc	de
@r_3069:	ld	(var_71be),de
		pop	hl
		jr	lab_30c9
		ds	3,$ff
	ENDIF
@r_3073:	ld	a,(hl)
		and	a
		jr	z,@r_30a3
		cp	$2c
		jr	z,@r_30a3
		call	skip_space
		call	fun_0c56
		call	skip_space
		ld	a,(hl)
		and	a
		jr	z,lab_30c9
		cp	$2c
		jr	nz,@r_3093
		inc	hl
		ld	a,(hl)
		dec	hl
		cp	$2c
	IFDEF V30
		jr	nz,lab_30c9
		ld	a,(var_71ec)
		cp	$76
		jr	z,lab_30c9
	ELSE
		jr	lab_30c9
	ENDIF
	
; V30 0x309a
@r_3093:	rst	RST1
		ld	hl,dat_30b3		; "REENTER"
		call	print_string
		call	GETLIN
		ld	hl,IOBUF
		pop	de
		jr	fun_303f
		
; V30 0x30aa
@r_30a3:
	IFDEF V30
		ld	a,(var_71ec)
		cp	$76
		jr	nz,@r_3093
	ENDIF
		ld	sp,(var_71cc)
		ld	a,(hl)
		inc	hl
		and	a
		jp	nz,lab_301a

;V30 0x30bb
lab_30ad:	rst	RST1
		pop	hl
		pop	bc
		jp	lab_2831

; V30 0x30c1
dat_30b3:	db	"REENTER",0

	IFNDEF V30
dat_30bb:	db	" BYTES FREE",0
		ds	2,$ff
	ENDIF

lab_30c9:	pop	de
		ret

; ---------------------------------------------------------
; 0x30cb		
load_set_memvec:
		exx
		ld	hl,(LOMEM)
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		call	fun_2907
		ld	de,(ADDR)
		inc	de
		inc	de
		ld	(DIMED),de
		exx
		ret

; ---------------------------------------------------------
; Read a byte from VRAM
; Input:  HL = VRAM address
; Output: A  = value
; 0x30e2
FUN_VRAMRD:	ld	a,$55			; read flag
		ld	(var_735d),a		; set vdp rw-flag for nmi isr
		ld	a,l
		out	(IOVDP1),a
		ld	a,h
		out	(IOVDP1),a
		ld	(var_738f),hl
		in	a,(IOVDP0)
		ex	af,af'
		xor	a
		ld	(var_735d),a		; clear vdp rw-flag
		ex	af,af'
		ret

; ---------------------------------------------------------
; Write a byte to VRAM
; Input:  HL = VRAM address
;         A  = value
; 0x30f9
FUN_VRAMWR:	ld	(var_738f),a		; save value to write to vdp ram
		ld	a,$aa			; write flag
		ld	(var_735d),a		; set vdp rw-flag for nmi isr
		ld	a,l
		out	(IOVDP1),a
		ld	a,h
		or	$40
		out	(IOVDP1),a
		ld	a,(var_738f)
		out	(IOVDP0),a
		xor	a
		ld	(var_735d),a		; clear vdp rw-flag
		ld	a,(var_738f)
		ret

; ---------------------------------------------------------
; 0x3116
print_line_number:
		push	bc
		push	hl
		push	iy
		ld	hl,var_71fa
		;
lab_311d:	ld	iy,var_7198
		call	fun_066a
		ld	b,$04
		ld	iy,var_7198
@r_312a:	ld	a,(iy+$00)
		cp	$20
		jr	nz,@r_3135
		inc	iy
		djnz	@r_312a
@r_3135:	ld	a,(iy+$00)
		call	DSPCHR
		inc	iy
		djnz	@r_3135
		pop	iy
		pop	hl
		pop	bc
		ret
		
fun_3144:	push	bc
		push	hl
		push	iy
		jr	lab_311d

; ---------------------------------------------------------
; 0x314a		
print_string:	ld	a,(hl)
		and	a
		ret	z
		call	DSPCHR
		inc	hl
		jr	print_string

; ---------------------------------------------------------
; 0x3153
buf_to_bas:	push	bc
		push	de
		push	hl
		push	iy
		ld	hl,IOBUF
		call	skip_space
		call	fun_0621
		ld	bc,$ffff
		ld	(var_7118),de
		ld	de,var_711a
		jr	z,lab_316f
		dec	de
		dec	de
		
lab_316f:	call	skip_space
@r_3172:	and	a
		jr	z,lab_31bc
		cp	$22
		jr	nz,@r_3184
		ldi
		ld	a,b
		xor	$ff
		ld	b,a
		ld	a,(hl)
		jr	z,@r_3172
		jr	lab_316f
@r_3184:	and	b
		jr	nz,@r_318c
		ldi
		ld	a,(hl)
		jr	@r_3172
@r_318c:	bit	7,a
		jr	z,param_exp
		
lab_3190:	ldi
		jr	lab_316f

; ---------------------------------------------------------
; Get parameter expression
; 0x3194		
param_exp:	push	de
		ld	de,(TOKENE)
		call	token_get_id
		jr	c,@r_31a4
		ld	de,dat_3a06
		call	token_get_id
@r_31a4:	pop	de
		jr	nc,lab_3190
		ld	(de),a
		cp	$9d
		inc	de
		jr	nz,lab_316f
		ld	a,$4d
@r_31af:	dec	hl
		cp	(hl)
		jr	nz,@r_31af
		inc	hl
@r_31b4:	ld	a,(hl)
		and	a
		jr	z,lab_31bc
		ldi
		jr	@r_31b4
		
lab_31bc:	ldi
		ld	hl,var_7118
		ld	de,IOBUF
		ld	bc,$0080
		ldir
		pop	iy
		pop	hl
		pop	de
		pop	bc
		ret
	
; ---------------------------------------------------------
; 0x31cf
skip_space:	ld	a,(hl)
		cp	$20
		ret	nz
		inc	hl
		jr	skip_space

; ---------------------------------------------------------
; 0x31d6
token_get_id:	push	hl
@r_31d7:	call	skip_space
		ld	a,(de)
		cp	(hl)
		inc	de
		jr	nz,@r_31e2
		inc	hl
		jr	@r_31d7
@r_31e2:	bit	7,a
		jr	nz,@r_31f4
		pop	hl
@r_31e7:	ld	a,(de)
		bit	7,a
		jr	nz,@r_31ef
		inc	de
		jr	@r_31e7
@r_31ef:	inc	de
		inc	de
		inc	de
		jr	token_get_id
@r_31f4:	cp	$ff
		jr	z,@r_31fc
		pop	iy
		scf
		ret
@r_31fc:	pop	hl
		and	a
		ret

; ---------------------------------------------------------
; 0x31ff
FUN_STOP:	ld	(var_7239),hl
		ld	a,(var_71e1)
		bit	7,a
		jr	z,@r_320b
		set	5,a
@r_320b:	ld	(var_71e1),a
		xor	a			; break
		rst	RST2

; ---------------------------------------------------------
; 0x3210
FUN_END:	push	hl
		ld	hl,(ADDR)
		ld	(CURLIN),hl
		pop	hl
		ret
; ---------------------------------------------------------
; 0x3219
FUN_REM:	ld	a,(hl)
		and	a
		ret	z
		inc	hl
		jr	FUN_REM
		
; ---------------------------------------------------------
; 0x321f
FUN_CONT:	ld	a,(var_71e1)
		bit	7,a
		ret	nz
		push	hl
		bit	5,a
		jr	z,@r_323d
		res	5,a
		set	7,a
		ld	(var_71e1),a
		ld	hl,(var_7237)
		ld	(CURLIN),hl
		ld	hl,(var_7239)
	IFDEF V30
		jp	lab_02a8
	ELSE
		jp	lab_02af
	ENDIF
@r_323d:	ld	a,ERR_CONT		; can't continue
		rst	RST2

; ---------------------------------------------------------
; 0x3240
FUN_TRACE:	push	hl
		ld	hl,var_71e1
		set	0,(hl)
		pop	hl
		ret

FUN_UNTRACE:	push	hl
		ld	hl,var_71e1
		res	0,(hl)
		pop	hl
		ret
		
; ---------------------------------------------------------

dat_3250:	db	"BIT90 BASIC 3."
		; 0x325e
	IFDEF V30
		db	"0\r\n",0
	ELIFDEF V31
		db	"1\r\n",0
	ELSE
		db	"2",0,0,0		
	ENDIF

lab_3262:	ldir
		ld	a,$c3
		ld	(BREAK2),a
		ld	hl,FUN_BREAK2
		jp	lab_32a6
		db	0

	IF V30 || V31
dat_3270:	db	"READY\n\r",0
	ELSE
		; shorter prompt
dat_3270:	ds	8,0
	ENDIF

; ---------------------------------------------------------
; Initialize vdp,psg and reset system flags
; 0x3278
FUN_INITIAL:	ld	de,var_7198
		ld	b,$1c
		xor	a
@r_327e:	ld	(de),a
		inc	de
		djnz	@r_327e
		ld	(var_7363),a
		ld	(var_736e),a
		ld	(var_7379),a
		ld	(var_7384),a
		ld	(var_733d),a
		ld	(var_71e0),a
		ld	a,(var_71e1)
		and	$21
		ld	(var_71e1),a
		ld	a,$05
		ld	(var_7360),a
		ld	(var_7361),a
	IFDEF V30
		ld	a,$3e
		ld	(PROMPT),a
	ENDIF
		jr	init_screen
	
; V30 0x32ab
lab_32a6:	ld	(BREAK2+1),hl
		jp	FUN_INITIAL
		ds	3,$ff

; V30 0x32b4 / V31 0x32af
init_screen:	
	IFNDEF V30
		ld	a,$3e
		ld	(PROMPT),a		; set prompt
	ENDIF
		ld	a,$9f			
		out	(IOPSG0),a		; silence sound channels
		ld	a,$bf
		out	(IOPSG0),a
		ld	a,$df
		out	(IOPSG0),a
		ld	a,$ff
		out	(IOPSG0),a
		in	a,(IOVDP1)
		ld	a,(dat_vdp0)
		ld	(VDPR0),a
		ld	a,(dat_vdp1)
		ld	(VDPR1),a
		ld	a,(var_733b)
fun_32d5:	ld	bc,$10*256+IOVDP1	; initialize vdp registers
		ld	hl,dat_vdp0
		otir
		cp	$00
		call	nz,FUN_HOME
		xor	a
		ld	(var_733b),a
		in	a,(IOROM0)		; select game rom
		ld	bc,$0108
		ld	de,$0000
		xor	a
		call	vdp_block_write
		ld	bc,$02f0
		ld	de,$0108
		ld	hl,$15ab		; address font definitions in game rom
		scf
		call	vdp_block_write
		in	a,(IOROM1)		; select BASIC rom
		ld	bc,$0260
		ld	de,$03f8
		ld	hl,dat_3c80
		scf
		call	vdp_block_write
		ld	bc,$01a8
		ld	de,$0658
		xor	a
		call	vdp_block_write
		ld	bc,$0400
		ld	de,(dat_3eec)
		xor	a
		call	vdp_block_write
		ld	bc,$0020
		ld	a,$10
		ld	de,$2000
		and	a
		call	vdp_block_write
		ret

; ---------------------------------------------------------
; Get console input
; Output: A  = character
;         Cx = set: key pressed, reset: no key pressed
; 0x3330
FUN_CIN:	push	bc
		push	de
		push	hl
		ld	hl,FLSCUR
		inc	(hl)
		call	key_scan
		ld	b,e
		ld	c,a
		call	delay
		call	key_scan
		jr	nc,lab_337f
		cp	c
		jr	nz,lab_337f
		ld	hl,dat_36a0		; keyboard scancodes
		ld	b,$00
		ld	c,a
		add	hl,bc
		ld	b,(hl)
		ld	a,b
		cp	$7f
		jr	nc,lab_3382
		ld	a,e
		cp	$02			; [BASIC] key pressed?
		jr	z,lab_33b9
		cp	$05			; [CTRL] key pressed?
		jr	z,lab_33cc
		cp	$07			; [FCTN] key pressed?
		jr	z,key_fctn
		and	a
		ld	a,c
		jr	nz,@r_3376
		cp	$25			; [CAPS LOWER] key pressed?
		jr	nz,@r_336f
		xor	a
		ld	(var_7016),a
		jr	lab_337f
@r_336f:	call	key_testalpha
		jr	nc,lab_33a3
		jr	lab_33d5
@r_3376:	cp	$25
		jr	nz,lab_3382
		ld	a,$20
		ld	(var_7016),a
		
lab_337f:	and	a			; clear cf-flag (inkey $ff)
		jr	lab_33d6
		
lab_3382:	call	key_testalpha
		jr	nc,lab_33d5
		ld	hl,var_7016
		or	(hl)
		ld	hl,var_7017
		bit	6,(hl)
		jr	z,lab_33d5
		or	$20
		jr	lab_33d5

; 0x3396
key_testalpha:	ld	a,b
		cp	'A'
		jr	c,@r_33a1
		cp	'Z'+1
		jr	nc,@r_33a1
		scf
		ret
@r_33a1:	and	a
		ret
		
lab_33a3:	cp	'A'
		jr	nc,@r_33b1
		cp	'A'-1
		jr	c,@r_33b5
		jr	nz,lab_337f
		ld	a,'_'
		jr	lab_33d5
@r_33b1:	xor	$20
		jr	lab_33d5
@r_33b5:	xor	$10
		jr	lab_33d5
		
lab_33b9:	ld	a,b
		cp	$2c
		jr	c,lab_33d5
		cp	$60
		jr	nc,lab_33d5
		cp	$30
		jr	nc,@r_33c8
		xor	$10
@r_33c8:	add	a,$50
		jr	lab_33d5
	
lab_33cc:	call	key_testalpha
		jr	nc,lab_33d5
		res	6,a
		jr	lab_33d5

lab_33d5:	scf
lab_33d6:	pop	hl
		pop	de
		pop	bc
		ret

; 0x33da
key_fctn:	ld	a,b
		cp	$30
		jr	c,lab_33d5
		cp	$3a
		jr	nc,lab_33d5
		add	a,$b0
		cp	$e0			; [FCTN]+[0] pressed ?
		jr	z,ext_call_4000
		jr	lab_33d5

; Call routine in extension rom at 0x4000
; first check rom presence by validating signature "$aa 55" at address 0x4000, 
; if the signature is valid then call routine at address 0x4002
; 0x33eb
ext_call_4000:	push	af
		ld	a,($4000)
		cp	$aa			; valid sig 1?
		jr	nz,@r_3402		; nz=no
		ld	a,($4001)
		cp	$55			; valid sig 2?
		jr	nz,@r_3402		; nz=no
		ld	hl,@r_3402
		push	hl			; set return address
		ld	hl,($4002)
		jp	(hl)			; call extension rom routine
@r_3402:	pop	af
		jr	lab_33d5

; ---------------------------------------------------------
; BASIC: keyboard scan
; 0x3405
key_scan:	push	bc
		ld	e,$0f
		ld	b,$07
@r_340a:	ld	a,b
		rlca
		rlca
		rlca
		rlca
		out	(IOKEY0),a
		in	a,(IOKEY1)
		cp	$ff
		jr	nz,@r_341d
@r_3417:	dec	b
		jp	p,@r_340a
		jr	lab_3423
@r_341d:	ld	d,a
		call	fun_3428
		jr	@r_3417
		
lab_3423:	ld	a,$ff
		and	a
		pop	bc
		ret
		
fun_3428:	ld	c,$07
		ld	a,d
@r_342b:	rla
		jr	nc,@r_3435
		dec	c
		jp	p,@r_342b
		pop	hl
		jr	lab_3423
@r_3435:	ld	a,b
		cp	$07
		jr	nz,@r_344d
		ld	a,c
		cp	$01
		jr	z,@r_344d
		cp	$03
		jr	z,@r_344d
		cp	$04
		jr	z,@r_344d
		cp	$06
		jr	z,@r_344d
		ld	e,a
		ret
@r_344d:	pop	hl
		ld	a,b
		and	$07
		rlca
		rlca
		rlca
		ld	b,a
		ld	a,c
		and	$07
		or	b
		scf
		pop	bc
		ret


; ---------------------------------------------------------
; 0x345c
delay:		push	bc
		push	hl
		push	af
		ld	bc,$0300
@r_3462:	cpi
		jp	pe,@r_3462
		pop	af
		pop	hl
		pop	bc
		ret
	
; ---------------------------------------------------------
; Get a line from console into 'IOBUF'
; 0x346b
FUN_CLIN:	push	bc
		push	de
		push	hl
		push	iy
		push	ix
		ld	a,(PROMPT)
		call	DSPCHR
		ld	de,(CURPOS)
		ld	(var_71f7),de
		ld	a,(var_71e1)
		bit	4,a
		jr	z,@r_348d
		ld	hl,var_719d
		call	fun_3144
@r_348d:	xor	a
		ld	(var_7017),a
		;
		; fill buffer with spaces
		ld	a,$20
		ld	ix,IOBUF
		ld	b,$ff
@r_3499:	ld	(ix+$00),a
		inc	ix
		djnz	@r_3499
		;
		; get console key input, debounce and/or repeat
@r_34a0:	call	GETKEY			
		jr	c,@r_34a0
@r_34a5:	ld	b,$ff
		ld	d,b
@r_34a8:	call	GETKEY
		call	FUN_CURSOR
		jr	nc,@r_34a5
		cp	d
		jr	nz,@r_34bc
		djnz	@r_34a8
		call	fun_34c2
		ld	b,$08
		jr	@r_34a8
@r_34bc:	ld	d,a
		call	fun_34c2
		jr	@r_34a8

; process key
fun_34c2:	; keyclick sound
		push	af
		ld	a,$87
		out	(IOPSG0),a
		ld	a,$02
		out	(IOPSG0),a
		ld	a,$93
		out	(IOPSG0),a
		ld	bc,$1000
@r_34d2:	dec	bc
		ld	a,b
		or	c
		jr	nz,@r_34d2
		ld	a,$9f
		out	(IOPSG0),a
		pop	af
		;
		push	bc
		push	de
		push	hl
		cp	$1b
		jr	z,@r_34e9
		cp	$0a
		jr	z,@r_34e9
		cp	$0d
@r_34e9:	jp	z,lab_35d3
		cp	$7f
		jp	z,lab_35a2
		cp	$f7
		jp	z,lab_3598
		ld	hl,var_7017
		bit	6,(hl)
		jr	z,@r_3518
		cp	$2c
		jr	c,@r_3518
		cp	$30
		jr	c,@r_350f
		cp	$40
		jr	nc,@r_3511
		cp	$3c
		jr	nc,@r_3518
		jr	@r_3511
@r_350f:	xor	$10
@r_3511:	cp	$7b
		jr	nc,@r_3518
		add	a,(hl)
		jr	@r_3532
@r_3518:	bit	7,a
		jr	z,@r_3532
		ld	d,a
		and	$f0
		cp	$f0
		ld	a,d
		jr	z,@r_3532
		call	token_get_keyword
		jr	nc,@r_3532
@r_3529:	ld	a,(hl)
		call	fun_3539
		inc	hl
		djnz	@r_3529
		jr	lab_3535
@r_3532:	call	fun_3539

lab_3535:	pop	hl
		pop	de
		pop	bc
		ret
		
; print key
fun_3539:	push	hl
		ld	de,(CURPOS)
		ld	(var_7012),de
		push	af
		ld	a,(var_700d)
		and	a
		jr	z,@r_3565
		call	FUN_LSTCHR
		ld	de,(var_71f7)
		and	a
		sbc	hl,de
		jr	c,@r_3565
		ld	de,$007e
		xor	a
		sbc	hl,de
		jr	c,@r_3565
		ld	(var_700d),a
		ld	b,$01
		pop	af
		jr	@r_3591
@r_3565:	pop	af
		call	DSPCHR
		ld	de,(var_71f7)
		ld	hl,(CURPOS)
		and	a
		sbc	hl,de
		jr	nc,@r_357e
		ld	(CURPOS),de
@r_3579:	call	FUN_CURSOR
		pop	hl
		ret
@r_357e:	ld	de,$007f
		and	a
		sbc	hl,de
		ld	a,$40
		ld	(FLSCUR),a
		jr	c,@r_3579
		ld	hl,(var_7012)
		ld	(CURPOS),hl
@r_3591:	ld	a,$07
		call	DSPCHR
		pop	hl
		ret

lab_3598:	ld	a,(var_7017)
		xor	$50
		ld	(var_7017),a
		jr	lab_3535

lab_35a2:	ld	de,(var_71f7)
		ld	(CURPOS),de
		ld	hl,$0300
		and	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	hl,(dat_3ee4)
		add	hl,de
		ld	d,h
		ld	e,l
		ld	a,$20
		and	a
		call	vdp_block_write
		call	FUN_CURSOR
		jp	lab_3535

; ---------------------------------------------------------
; Find position of last (non space) character
; Output: HL = last character position
; 0x35c4
FUN_LSTCHR:	ld	hl,$02ff
@r_35c7:	call	FUN_SCRNRD
		cp	$20
		ret	nz
		dec	hl
		ld	a,h
		and	a
		ret	m
		jr	@r_35c7

; ---------------------------------------------------------
		
lab_35d3:	ld	(var_71a8),a
		xor	a
		ld	(var_700d),a
		ld	b,$7f
		ld	hl,(var_71f7)
		ld	ix,IOBUF
@r_35e3:	
	IFDEF V30
		call	FUN_SCRNRD
	ELSE
		call	fun_3ff0
	ENDIF
		ld	(ix+$00),a
		inc	ix
		inc	hl
		ld	a,h
		cp	$03
		jr	z,@r_35f3
		djnz	@r_35e3
@r_35f3:	ld	a,$20
		dec	ix
		dec	hl
		ld	d,h
		ld	e,l
@r_35fa:	cp	(ix+$00)
		jr	nz,@r_360c
		ld	hl,(CURPOS)
		and	a
		sbc	hl,de
		jr	z,@r_360e
		dec	ix
		dec	de
		jr	@r_35fa
@r_360c:	inc	ix
@r_360e:	xor	a
		ld	(ix+$00),a
		ld	a,(var_71e1)
		bit	4,a
		call	nz,fun_363c
		jr	nc,@r_3621
		ld	hl,var_71e1
		res	4,(hl)
@r_3621:	exx
		pop	hl
		pop	de
		pop	bc
		pop	hl
		exx
		ld	hl,(dat_3eec)
		inc	hl
		inc	hl
		inc	hl
		xor	a
		call	FUN_VRAMWR
		pop	ix
		pop	iy
		pop	hl
		pop	de
		pop	bc
		ld	a,(var_71a8)
		ret
		
; ---------------------------------------------------------

fun_363c:	exx
		ld	hl,(var_719c)
		ld	de,(var_719e)
		ld	a,l
		add	a,e
		daa
		ld	c,a
		ld	a,h
		adc	a,d
		daa
		ld	b,a
		ld	(var_719c),bc
		exx
		ret

; ---------------------------------------------------------
; Display cursor on 'CURPOS' if bit 6 of 'FLSCUR' is set
; 0x3652
FUN_CURSOR:	push	af
		push	bc
		push	de
		push	hl
		ld	de,(dat_3eea)
		ld	bc,$0008
		xor	a
		cpl
		call	vdp_block_write
		ld	a,(FLSCUR)
		bit	6,a
		jr	nz,@r_366d
		ld	c,$00
		jr	@r_366f
@r_366d:	ld	c,$49
@r_366f:	ld	de,(CURPOS)
	IF V30 || V31
		sla	e
		rl	d
		sla	e
		rl	d
		sla	e
		rl	d
		sla	d
		sla	d
		sla	d
		ld	hl,(dat_3eec)
		ld	a,d
	ELSE
		; Align the cursor sprite with the v32 font.
		ld	a,d
		sla	e
		rla
		sla	e
		rla
		sla	e
		rla
		sla	a
		sla	a
		sla	a
		dec	a
		ld	hl,(dat_3eec)
		nop
		nop
	ENDIF
		call	FUN_VRAMWR
		inc	hl
		ld	a,e
		call	FUN_VRAMWR
		inc	hl
		xor	a
		call	FUN_VRAMWR
		inc	hl
		ld	a,c
		call	FUN_VRAMWR
		pop	hl
		pop	de
		pop	bc
		pop	af
		ret

; ---------------------------------------------------------
; 0x36a0 keyboard scancodes
dat_36a0:	db	$2d,$37,$33,$5c,$f5,$31,$35,$39
		; 00	  -   7   3   \ INS   1   5   9
		db	$5e,$38,$34,$08,$f4,$32,$36,$30
		; 08	  ^   8   4  BS DEL   2   6   0
		db	$50,$59,$57,$5d,$f0,$1b,$52,$49
		; 10	  P   Y   W   ] CUP ESC   R   I
		db	$5b,$55,$45,$7f,$f3,$51,$54,$4f
		; 18	  [   U   E RUB CUF   Q   T   O
		db	$3b,$48,$53,$40,$2f,$00,$46,$4b
		; 20	  ;   H   S   @   / CAP   F   K  
		db	$3a,$4a,$44,$0d,$2e,$41,$47,$4c
		; 28	  :   J   D  CR   .   A   G   L 
		db	$4e,$56,$58,$4d,$2c,$5a,$43,$42
		; 30	  N   V   X   M   ,   Z   C   B
		db	$00,$f7,$00,$f2,$f1,$00,$20,$00
		; 38	SHI BIT BAS CUB CUD CTL SPC FCT

; ---------------------------------------------------------
; Output (control) character to console
; 0x36e0
FUN_COUT:	push	af
		push	hl
		push	de
		push	bc
	IFDEF V30
		ld	b,a
		ld	a,(var_733f)
		and	a			; printer copy on?
		ld	a,b
		jr	z,@r_36ef		; z=no
		call	fun_3967		; output character to printer
@r_36ef:	ld	hl,(CURPOS)
	ELSE
		ld	hl,(CURPOS)
		call	cursor_skip2
	ENDIF
		cp	$20
		jr	nc,@r_3705
		cp	$07
		jp	z,lab_38a6
		cp	$08
		jr	z,lab_373d
		cp	$09
		jr	z,lab_3753
		cp	$0a
		jr	z,lab_375d
		cp	$0d
		jr	z,lab_376e
		jr	lab_3735
@r_3705:	cp	$e0
		jp	c,lab_37b1
		cp	$f0
		jp	c,lab_38a3
		cp	$f0
		jr	z,lab_3776
		cp	$f1
		jr	z,lab_3789
		cp	$f2
		jp	z,lab_379d
		cp	$f3
		jp	z,lab_37ad
		cp	$f4
		jp	z,lab_380a
		cp	$f5
		jr	nz,lab_3735
		ld	a,$ff
		ld	(var_700d),a
		jr	lab_3735

lab_3731:	xor	a
		ld	(var_700d),a

lab_3735:	ld	(CURPOS),hl
		pop	bc
		pop	de
		pop	hl
		pop	af
		ret

lab_373d:	ld	de,(var_71f7)
		and	a
		ex	de,hl
		sbc	hl,de
		ex	de,hl
		jr	z,lab_3731
		dec	hl
	IFNDEF V30
		call	cursor_back2
	ENDIF
		ld	a,$20
		call	FUN_SCRNWR
		jr	lab_3731

lab_3753:	ld	de,$0008
		add	hl,de
		ld	a,l
		and	$f8
		ld	l,a
	IFDEF V30
		ld	a,h
		cp	$03
		jr	c,lab_3731
		call	fun_38c1
		jr	lab_3731
lab_375d:	ld	de,$0020
		add	hl,de
lab_3761:
	ELSE
		jr	lab_3761
lab_375d:	ld	de,$0020
		add	hl,de
lab_3761:	call	cursor_skip2
	ENDIF
		ld	a,h
		cp	$03
		jr	c,lab_3731
		call	fun_38c1
		jr	lab_3731

lab_376e:	ld	a,l
		and	$e0
	IFDEF V31
		or	$02
	ELIFNDEF V30
		; for [cr] set cursor X-position to 0
		or	$00
	ENDIF
		ld	l,a
		jr	lab_3731

lab_3776:	ld	de,$0020
		and	a
		sbc	hl,de
		jr	nc,lab_3731
		ld	hl,(CURPOS)
		ld	a,l
		or	$e0
		ld	l,a
		ld	h,$02
		jr	lab_3731

lab_3789:	ld	de,$0020
		add	hl,de
	IFNDEF V30
		call	cursor_skip2
	ENDIF
		ld	a,h
		cp	$03
		jr	c,lab_3731
		ld	h,$00
		ld	a,l
		and	$18
		ld	l,a
		jr	lab_3731

lab_379d:	ld	de,$0001
		and	a
		sbc	hl,de
	IFNDEF V30
		call	cursor_back2
	ENDIF
		jr	nc,lab_3731
		ld	hl,$02ff
		jr	lab_3731

lab_37ad:	inc	hl
	IFDEF V30
		ld	a,h
		cp	$03
		jr	c,lab_3731
		call	fun_38c1
		jp	lab_3731
	ELSE
		jp	lab_3761
	ENDIF

lab_37b1:	ld	d,a
		ld	a,(var_700d)
		cp	$ff
		jr	z,lab_37cd

lab_37b9:	ld	a,d
		call	FUN_SCRNWR
		inc	hl
	IFNDEF V30
		call	cursor_skip2
	ENDIF
		ld	a,h
		cp	$03
		jp	c,lab_3735
		call	fun_38c1

lab_37ca:	jp	lab_3735

lab_37cd:	push	de
		push	hl
		ld	d,h
		ld	e,l
		ld	hl,$02ff
		push	hl
		call	FUN_LSTCHR
		pop	bc
		push	hl
		and	a
		sbc	hl,bc
		pop	hl
		jr	nz,@r_37f1
		ex	(sp),hl
		call	fun_38c1
		ld	bc,$0020
		and	a
		ex	de,hl
		sbc	hl,bc
		ex	de,hl
		ld	(CURPOS),de
		ex	(sp),hl
		;
@r_37f1:	and	a
		sbc	hl,de
		jr	c,@r_3800
		ld	b,h
		ld	c,l
		inc	de
		pop	hl
		call	fun_382b
	IFDEF V30
		ld	hl,(CURPOS)
		pop	de
		jr	lab_37b9
	ELSE
		pop	de
		jr	@r_3802
	ENDIF
@r_3800:	pop	hl
		pop	de
@r_3802:	ld	hl,(CURPOS)
	IFNDEF V30
		call	cursor_skip2
	ENDIF
		jr	lab_37b9

lab_380a:	ld	d,h
		ld	e,l
		ld	hl,$02ff
		and	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	h,d
		ld	l,e
		inc	hl
		call	fun_382b
		ld	hl,(CURPOS)
	IFDEF V30
		jp	lab_3735
		
		; 0x3827
		xor	a
		ld	(var_700d),a
		
fun_382b:	push	hl
		push	de
		and	a
		sbc	hl,de
		pop	de
		pop	hl
		jr	nc,@r_3848
		add	hl,bc
		ex	de,hl
		add	hl,bc
		ex	de,hl
		inc	bc
@r_3839:	call	FUN_SCRNRD
		ex	de,hl
		call	FUN_SCRNWR
		ex	de,hl
		dec	de
		cpd
		jp	pe,@r_3839
		ret	
		
@r_3848:	ret	z
		push	ix
@r_384b:	call	FUN_SCRNRD
		ex	de,hl
		call	FUN_SCRNWR
		ex	de,hl
		inc	de
		cpi
		jp	pe,@r_384b
		and	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	a,$20
		ld	ix,(dat_3ee4)
		add	ix,de
		push	ix
		pop	de
		and	a
		call	vdp_block_write
		pop	ix
		ret
	
	ELSE ; NOT V30
		jr	lab_37ca

; Move cursor back, skip leftmost 2 positions
; workaround for PAL RF video issue
; 0x381f
cursor_back2:	
	  IFDEF	V31
		ex	af,af'
		ld	a,l
		and	$1f
		cp	$01
		jr	nz,@r_3829
		dec	hl
		dec	hl
@r_3829:	ex	af,af'
		ret
	  ELSE	
		ret
		ds	11,$00
	  ENDIF

fun_382b:	push	hl
		and	a
		sbc	hl,de
		pop	hl
		jp	nc,lab_3967
		push	hl
		add	hl,bc
		ex	de,hl
		add	hl,bc
		call	cursor_skip2
		ex	de,hl
		pop	bc
@r_383c:	call	cursor_back2
		call	FUN_SCRNRD
		ex	de,hl
		call	cursor_back2
		call	FUN_SCRNWR
		ex	de,hl
		push	hl
		and	a
		sbc	hl,bc
		pop	hl
		ret	z
		dec	de
		dec	hl
		jr	@r_383c

; Move cursor forward, skip leftmost 2 positions
; workaround for PAL RF video issue
; 0x3854
cursor_skip2:	
	  IFDEF V31
		ex	af,af'
		ld	a,l
		and	$1f
		jr	nz,@r_385c
		inc	hl
		inc	hl
@r_385c:	ex	af,af'
		ret
	  ELSE	  
		ret
		ds	9,$00
	  ENDIF

; ---------------------------------------------------------

; print free expansion ram memory
fun_385e:	ld	a,(MEMT+1)
		cp	$80			; expansion ram used?
		ret	c			; c=no, quit
		call	FUN_FRE
		ld	hl,dat_30bb		; " BYTES FREE"
		call	print_string
		ret
		ds	2,$ff

	ENDIF ; V30
		
; ---------------------------------------------------------
; Write character to screen
; Input:  A = character
; 0x3870
FUN_SCRNWR:	ex	af,af'
		push	hl
		ld	a,(dat_3ee4+1)
		add	a,h
		ld	h,a
		ex	af,af'
		call	FUN_VRAMWR
		pop	hl
		ret

; ---------------------------------------------------------
; Read character from screen
; Input:  HL = screen position
; Output: A  = character
; 0x387d
FUN_SCRNRD:	push	hl
		ld	a,(dat_3ee4+1)
		add	a,h
		ld	h,a
		call	FUN_VRAMRD
		pop	hl
		ret

; ---------------------------------------------------------
; Write data block to vdp ram
; Note: interference with PLAY command (interrupt routine)
; 0x3888
vdp_block_write:
		push	bc
		push	de
		push	hl
		ex	af,af'
		ld	a,e
		out	(IOVDP1),a
		ld	a,d
		or	$40
		out	(IOVDP1),a
		ex	af,af'
@r_3895:	jr	nc,@r_3898
		ld	a,(hl)
@r_3898:	out	(IOVDP0),a
		cpi
		jp	pe,@r_3895
		pop	hl
		pop	de
		pop	bc
		ret
		
; ---------------------------------------------------------

lab_38a3:	jp	lab_3735

; ---------------------------------------------------------
; BELL sound
lab_38a6:	ld	a,$87
		out	(IOPSG0),a
		ld	a,$03
		out	(IOPSG0),a
		ld	a,$90
		out	(IOPSG0),a
		ld	bc,$7000
@r_38b5:	dec	bc
		ld	a,b
		or	c
		jr	nz,@r_38b5
		ld	a,$9f
		out	(IOPSG0),a
		jp	lab_3735

; ---------------------------------------------------------

fun_38c1:	push	bc
		push	de
		push	hl
		ld	hl,$0020
		ld	de,$0000
		ld	bc,$02e0
		call	fun_382b
		ld	hl,(var_71f7)
		ld	de,$0020
		and	a
		sbc	hl,de
		ld	(var_71f7),hl
		ld	hl,(var_7012)
		and	a
		sbc	hl,de
		ld	(var_7012),hl
		pop	hl
		and	a
		sbc	hl,de
		pop	de
		pop	bc
		ret

; ---------------------------------------------------------
; Output line in 'IOBUF' to console, converts tokens to ASCII
; 0x38ec
FUN_CLOUT:	push	ix
		push	bc
		push	hl
		push	de
		xor	a
		ld	(var_71a4),a
		inc	hl
		ld	iy,var_7198
		call	fun_066a
		ld	a,$20
		call	DSPCHR
		ld	b,$04
		push	hl
		ld	hl,var_7198
		call	fun_2a76
		pop	hl
		ld	iy,var_7198
	IF V30 || V31
		ld	a,$09
	ELSE
		; Print space between line number and line content
		ld	a,$20
	ENDIF
		call	DSPCHR
@r_3915:	inc	hl
		ld	a,(hl)
		bit	7,a
		jr	z,@r_3925
		ld	d,a
		ld	a,(var_71a4)
		and	a
		ld	a,d
		jr	z,@r_393b
		jr	@r_3936
@r_3925:	and	a
		jr	z,@r_3956
		cp	$22
		ld	d,a
		jr	nz,@r_3936
		ld	a,(var_71a4)
		xor	$ff
		ld	(var_71a4),a
		ld	a,d
@r_3936:	call	DSPCHR
		jr	@r_3915
		;
@r_393b:	push	hl
		call	token_get_keyword
		jr	c,@r_3946
		call	DSPCHR
		jr	@r_3953
		;
@r_3946:	call	fun_2a76
		ld	a,d
		cp	$9d
		jr	z,@r_3953
		ld	a,$20
		call	DSPCHR
@r_3953:	pop	hl
		jr	@r_3915
		;
@r_3956:	pop	de
		pop	hl
		pop	bc
		pop	ix
		ret

; ---------------------------------------------------------
; 0x395c
print_crlf:	ld	a,$0d
		call	DSPCHR
		ld	a,$0a
		call	DSPCHR
		ret

; ------------------------------------------------------------------------------
	
	IFDEF V30
	
; Output character to printer
fun_3967:	push	af
		ld	hl,var_700e
		ld	a,(var_7340)
		cp	(hl)
		jr	nc,@r_3978
		xor	a
		ld	(hl),a
		ld	a,$0d
		call	fun_39d2
@r_3978:	pop	af
		push	af
		cp	$0d
		jr	nz,@r_3984
		ex	af,af'
		xor	a
		ld	(hl),a
		ex	af,af'
		jr	@r_39cd
@r_3984:	cp	$0a
		jr	nz,@r_398a
		pop	af
		ret
@r_398a:	cp	$f1
		jr	nz,@r_3992
		ld	a,$0a
		jr	@r_39cd
@r_3992:	cp	$f2
		jr	nz,@r_39a1
		ex	af,af'
		ld	a,(hl)
		and	a
		jr	z,@r_39a0
		dec	(hl)
		ld	a,$08
		jr	@r_39cd
@r_39a0:	ex	af,af'
@r_39a1:	cp	$08
		jr	nz,@r_39a8
		dec	(hl)
		jr	@r_39cd
@r_39a8:	cp	$f3
		jr	nz,@r_39b0
		ld	a,$20
		jr	@r_39cc
@r_39b0:	cp	$09
		jr	nz,@r_39c6
		ld	a,(hl)
		ld	b,a
		add	a,$08
		and	$f8
		ld	(hl),a
		sub	b
		ld	b,a
		ld	a,$20
@r_39bf:	call	$39d2
		djnz	@r_39bf
		pop	af
		ret
		
@r_39c6:	bit	7,a
		jr	z,@r_39cc
		pop	af
		ret
@r_39cc:	inc	(hl)
@r_39cd:	call	fun_39d2
		pop	af
		ret
		
fun_39d2:	ex	af,af'
@r_39d3:	in	a,(IOLPT1)
		bit	0,a
		jr	nz,@r_39d3
		ex	af,af'
		cp	$0a
		ret	z
		out	(IOLPT1),a
		ex	af,af'
		ld	a,$02
		out	(IOLPT0),a
		inc	a
		out	(IOLPT0),a
		ex	af,af'
		ret
		
	ELSE ; NOT V30

; Output character subroutine
lab_3967:	ret	z
		push	hl
		add	hl,bc
		ld	b,h
		ld	c,l
		pop	hl
		push	ix
@r_396f:	
		call	cursor_skip2
		call	FUN_SCRNRD
		ex	de,hl
		call	cursor_skip2
		call	FUN_SCRNWR
		ex	de,hl
		inc	de
		inc	hl
		push	hl
		and	a
		sbc	hl,bc
		pop	hl
		jr	nz,@r_396f
		and	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	a,$20
		ld	ix,(dat_3ee4)
		add	ix,de
		push	ix
		pop	de
		and	a
		call	vdp_block_write
		pop	ix
		ret

; ---------------------------------------------------------
; 0x399d Initialize memory and expansion card (printer)
init_new:	push	af
		push	hl
		call	FUN_NEW
		ld	b,$08			; number of i/o ports
		ld	c,IOEXT0		; extension rom i/o port
@r_39a6:	push	bc
		in	a,(c)			; enable extension rom
		ld	hl,$67fa		; extension rom address
		call	ext_init
		pop	bc
		dec	c			; decrease i/o port
		djnz	@r_39a6
		in	a,(IOEXT1)		; enable extension rom
		ld	hl,$6ffa		; extension rom address
		call	ext_init
		ld	hl,$7ffa		; extension rom address (bit90 printer)
		call	ext_init
		call	fun_385e		; print bytes free
		pop	hl
		pop	af
		ret

; if extension rom signature is present then call subroutine and display return message
ext_init:	ld	a,$aa
		cp	(hl)
		jr	nz,@r_39e4
		inc	hl
		rrca
		cp	(hl)
		jr	nz,@r_39e4
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	bc,@r_39dc		; return address
		push	bc
		push	de			; extension rom subroutine
		ret
@r_39dc:	ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		rst	RST1
		call	print_string
@r_39e4:	ret
		
		ds	4,$ff			; unused

	ENDIF ; V30

; ------------------------------------------------------------------------------
	
; music tables
dat_39e9:	db	"C",$00
		db	"D",$02
		db	"E",$04
		db	"F",$05
		db	"G",$07
		db	"A",$09
		db	"B",$0b
		db	"R",$0c
dat_39f9:	db	$d6,$ca,$be,$b4,$aa,$a0,$97,$8f
		db	$87,$7f,$78,$71,$00

; ---------------------------------------------------------
; Internal token table
;
; Tokencode-0x50 is BASIC key e.g. 0x9e-0x50=0x4e=[N] [BASIC]+[N] --> NEXT
;
; Following tokens/keywords are reserved:
; 0x84 DELETE
; 0x8D OPEN
; 0xAE CLOSE
; 0xCF EOF(
; 0xDC RESERVED
; 0xDE RESERVED
; 0xDF RESERVED
;
dat_3a06:	db	"NEXT",$9e		; [N]
		dw	FUN_NEXT
		db	"LET",$b3
		dw	FUN_LET
		db	"PLOT",$a5		; [U]
		dw	FUN_PLOT
		db	"GOSUB",$92		; [B]
		dw	FUN_GOSUB
		db	"GOTO",$97		; [G]
		dw	FUN_GOTO
		db	"RETURN",$a6		; [R]
		dw	FUN_RETURN
		db	"INKEY$",$d7
		dw	FUN_INKEYS
		db	"FOR",$96		; [F]
		dw	FUN_FOR
		db	"FN",$da
		dw	FUN_FN
		db	"JOYST(",$ce
		dw	FUN_JOYST
		db	"SIN(",$c8
		dw	FUN_SIN
		db	"COS(",$c2
		dw	FUN_COS
		db	"CALL",$93		; [C]
		dw	FUN_CALL
		db	"IF",$a9		; [Y]
		dw	FUN_IF
		db	"RND(",$8f		; [?]
		dw	FUN_RND
		db	"DATA",$94		; [D]
		dw	FUN_DATA
	IFDEF V30
		db	"ON",$9f		; [O]
		dw	FUN_ON
	ENDIF
		db	"READ",$a2		; [R]
		dw	FUN_READ
		db	"PRINT",$a0		; [P]
		dw	FUN_PRINT
		db	"HOME",$98		; [H]
		dw	FUN_HOME
		db	"POKE",$8a		; [:]
		dw	FUN_POKE
		db	"OUT",$b4
		dw	FUN_OUT
		db	"ABS(",$c0
		dw	FUN_ABS
		db	"ASC(",$d2
		dw	FUN_ASC
		db	"ATN(",$c1
		dw	FUN_ATN
		db	"AUTO",$91		; [A]
		dw	FUN_AUTO
		db	"BLOAD",$d9
		dw	FUN_BLOAD
		db	"BSAVE",$db
		dw	FUN_BSAVE
		db	"BYE",$b0
		dw	FUN_BYE
		db	"CHR$(",$cc
		dw	FUN_CHRS
		db	"CLEAR",$9b		; [K]
		dw	FUN_CLEAR
		db	"CONT",$87		; [C]
		dw	FUN_CONT
		db	"COPY",$ab		; [[]
		dw	FUN_COPY
		db	"DEF",$8c		; [<]
		dw	FUN_DEF
		db	"DEL",$dd
		dw	FUN_DEL
		db	"DIM",$8e		; [>]
		dw	FUN_DIM
		db	"EDIT",$83		; [3]
		dw	FUN_EDIT
		db	"ELSE",$95		; [E]
		dw	parse_exp
		db	"END",$b1
		dw	FUN_END
		db	"EXP(",$c3
		dw	FUN_EXP
		db	"FRE",$af
		dw	FUN_FRE
		db	"HEX$(",$bf
		dw	FUN_HEXS
		db	"INT(",$c4
		dw	FUN_INT
		db	"IN(",$cd
		dw	FUN_IN
		db	"LEFT$(",$d4
		dw	FUN_LEFTS
		db	"LEN(",$d6
		dw	FUN_LEN
		db	"LIST",$9c		; [L]
		dw	FUN_LIST
		db	"LOAD",$82		; [2]
		dw	FUN_LOAD
		db	"LN(",$c6
		dw	FUN_LN
		db	"LOG(",$c5
		dw	FUN_LOG
		db	"MID$(",$d5
		dw	FUN_MIDS
		db	"MUSIC",$88		; [8]
		dw	FUN_MUSIC
		db	"NEW",$80		; [0]
		dw	FUN_NEW
		db	"NOT",$be
		dw	parse_exp
		db	"INPUT",$99		; [I]
		dw	FUN_INPUT
		db	"ONERRGOTO",$b5
		dw	FUN_ONERRGOTO
	IFNDEF V30
		db	"ON",$9f		; [O]
		dw	FUN_ON
	ENDIF
		db	"OPTIONBASE",$b2
		dw	FUN_OPTIONBASE
		db	"OR",$bd
		dw	parse_exp
		db	"PEEK(",$8b		; [;]
		dw	FUN_PEEK
		db	"PLAY",$ad		; []]
		dw	FUN_PLAY
		db	"POS",$d8
		dw	FUN_POS
		db	"RANDOMIZE",$9a		; [J]
		dw	FUN_RANDOMIZE
		db	"REM",$9d		; [M]
		dw	FUN_REM
		db	"RENUM",$ac		; [\]
		dw	FUN_RENUM
		db	"RESTORE",$a1		; [Q]
		dw	FUN_RESTORE
		db	"RESUME",$b6
		dw	FUN_RESUME
		db	"RIGHT$(",$d1
		dw	FUN_RIGHTS
		db	"RUN",$85		; [5]
		dw	FUN_RUN
		db	"SAVE",$81		; [1]
		dw	FUN_SAVE
		db	"SGN(",$c7
		dw	FUN_SGN
		db	"SPC(",$d0
		dw	FUN_SPC
		db	"SQR(",$c9
		dw	FUN_SQR
		db	"STEP",$a3		; [S]
		dw	parse_exp
		db	"STR$(",$cb
		dw	FUN_STRS
		db	"STOP",$86		; [6]
		dw	FUN_STOP
		db	"TAB(",$90		; [@]
		dw	FUN_TAB
		db	"TAN(",$ca
		dw	FUN_TAN
		db	"TEMPO",$89		; [9]
		dw	FUN_TEMPO
		db	"THEN",$a4		; [T]
		dw	parse_exp
		db	"TO",$a7		; [W]
		dw	parse_exp
		db	"TRACE",$aa		; [Z]
		dw	FUN_TRACE
		db	"UNTRACE",$a8		; [X]
		dw	FUN_UNTRACE
		db	"VAL(",$d3
		dw	FUN_VAL
		db	"WAIT",$b7
		dw	FUN_WAIT
		db	"AND",$bc
		dw	parse_exp
		db	">=",$b9
		dw	parse_exp
		db	"<=",$ba
		dw	parse_exp
		db	"<>",$bb
		dw	parse_exp
		db	$ff

; ---------------------------------------------------------
; graphics character definitions
dat_3c80:	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$1c,$3e,$7f,$7f,$1c,$3e
		db	$81,$c3,$e7,$ff,$ff,$e7,$c3,$81,$0f,$0f,$0f,$0f,$f0,$f0,$f0,$f0
		db	$f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f,$cc,$cc,$33,$33,$cc,$cc,$33,$33
		db	$aa,$55,$aa,$55,$aa,$55,$aa,$55,$00,$08,$1c,$2a,$08,$08,$08,$00
		db	$00,$08,$08,$08,$2a,$1c,$08,$00,$00,$10,$20,$7e,$20,$10,$00,$00
		db	$00,$08,$04,$7e,$04,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$00,$3c,$42,$42,$42,$42,$3c,$00
		db	$00,$36,$77,$7f,$7f,$3e,$1c,$08,$00,$3c,$7e,$7e,$7e,$7e,$3c,$00
		db	$00,$00,$01,$3e,$54,$14,$14,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$ff,$00,$00,$00,$ff,$80,$80,$80,$80,$80,$80,$80
		db	$80,$80,$80,$80,$80,$80,$80,$ff,$00,$00,$00,$00,$ff,$08,$08,$08
		db	$08,$08,$08,$08,$0f,$00,$00,$00,$08,$08,$08,$08,$ff,$00,$00,$00
		db	$08,$08,$08,$08,$0f,$08,$08,$08,$08,$08,$08,$08,$f8,$08,$08,$08
		db	$00,$00,$00,$00,$ff,$ff,$ff,$ff,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
		db	$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
		db	$80,$40,$20,$10,$08,$04,$02,$01,$ff,$01,$01,$01,$01,$01,$01,$01
		db	$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$0f,$08,$08,$08,$08,$08,$08,$08,$f8,$00,$00,$00
		db	$08,$08,$08,$08,$08,$08,$08,$08,$80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
		db	$00,$00,$00,$00,$00,$00,$ff,$ff,$01,$01,$01,$01,$01,$01,$01,$ff
		db	$00,$00,$00,$00,$f8,$08,$08,$08,$08,$08,$08,$ff,$ff,$08,$08,$08
		db	$01,$03,$07,$0f,$1f,$3f,$7f,$ff,$08,$08,$08,$08,$ff,$08,$08,$08
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$1c,$1c,$6b,$7f,$6b,$08,$1c
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$1c,$3e,$7f,$3e,$1c,$08
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$ff,$ff,$00,$00,$00,$08,$08,$04,$03,$00,$00,$00,$00
		db	$00,$00,$00,$00,$03,$04,$08,$08,$00,$00,$00,$00,$ff,$18,$18,$18
		db	$f0,$f0,$f0,$f0,$ff,$ff,$ff,$ff,$18,$18,$18,$18,$ff,$00,$00,$00
		db	$08,$08,$08,$0f,$0f,$08,$08,$08,$08,$08,$08,$f8,$f8,$08,$08,$08
		db	$00,$00,$00,$00,$00,$ff,$ff,$ff,$80,$80,$80,$80,$80,$80,$80,$80
		db	$e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
		db	$81,$42,$24,$18,$18,$24,$42,$81,$10,$10,$20,$c0,$00,$00,$00,$00
		db	$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f,$ff,$ff,$ff,$ff
		db	$18,$18,$18,$18,$18,$18,$18,$18,$ff,$7f,$3f,$1f,$0f,$07,$03,$01
		db	$00,$00,$00,$00,$00,$00,$00,$ff,$00,$00,$00,$00,$c0,$20,$10,$10
		db	$ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f,$18,$18,$18,$18,$ff,$18,$18,$18
		db	$ff,$fe,$fc,$f8,$f0,$e0,$c0,$80,$18,$18,$18,$ff,$ff,$18,$18,$18

; ---------------------------------------------------------
; vdp ram offset values
dat_3ee0:	dw	$0000
dat_3ee2:	dw	$0800
dat_3ee4:	dw	$1800
dat_3ee6:	dw	$1c00
dat_3ee8:	dw	$2000
dat_3eea:	dw	$3800
dat_3eec:	dw	$3c00

; VDP register values
dat_vdp0:	db	$00,$80
dat_vdp1:	db	$c0,$81
		db	$06,$82			; Name table 0x1800
		db	$80,$83			; Color table 0x2000
		db	$00,$84			; Patterns 0x0000
		db	$78,$85			; Sprite attributes 0x3C00
		db	$07,$86			; Sprite patterns 0x3800
		db	$0c,$87			; Text color (transparant) / backdrop color (green)
dat_3efe:	db	$06,$82
		db	$ff,$83
		db	$03,$84
dat_3f04:	db	$07,$82
		db	$80,$83
		db	$01,$84

		db	$0a,$0d,$1b		; unused

; Error codes
dat_3f0d:	db	"FC","OV","UN","ST","EC","UF","RD","/0"
		db	"TM","NR","RE","NF","FN","RG","OD","BL"
		db	"BS","IS","ID","TP","LS"

	IFDEF V30
		; 0x3f37
		db	"* BREAK IN ",0
	ELSE
		; cursor skip2 patch
fun_3f37:	call	fun_2543
		add	a,$02
		ret
		ds	6,$ff			; unused
	ENDIF

dat_3f43:	db	"SYNTAX ERROR",0
dat_3f50:	db	"OUT OF MEMORY",0
dat_3f5e:	db	"CAN'T CONTINUE",0
dat_3f6d:	db	"LINE BUFFER OVERFLOW",0
dat_3f82:	db	" ERROR",0
dat_3f89:	db	" IN ",0
dat_3f8e:	db	"BREAK",0

; Console jump table
dat_3f94:	jp	FUN_CIN
		jp	FUN_CLIN
		jp	FUN_COUT
		jp	FUN_CLOUT
		jp	FUN_BREAK

; Warm boot flag
dat_3fa3:	db	"BIT90"

; System ram variables
dat_3fa8:	dw	dat_3a06		; TOKENE
		db	$c9,$00,$00		; INTVEC
		db	$c9,$00,$00		; NMTVEC
		db	$00

; ---------------------------------------------------------
; 0x3fb1
FUN_BYE:	xor	a
		ld	(WARM),a		; reset warm boot flag
		in	a,(IOROM0)		; select Coleco game rom
		rst	RST0			; reboot

; ---------------------------------------------------------
; Set ROM bank 0 to BASIC
; 0x3fb8
bank_to_basic:	in	a,(IOROM1)		; select BASIC rom
		rst	RST0			; reboot

fun_3fbb:	push	hl
		call	init_screen
		pop	hl
		ret

fun_3fc1:	ld	(ix+$00),a
		and	a
		ret	nz
		ld	a,c
		rrca
		rrca
		rrca
		or	$9f
		out	(IOPSG0),a
		call	FUN_DATA
		inc	sp
		inc	sp
		ret

; 0x3fd4 enable screen
screen_enable:	in	a,(IOVDP1)
		ld	a,(VDPR1)
		or	$40
		jr	lab_3fe4

; 0x3fdd disable screen
screen_disable:	in	a,(IOVDP1)
		ld	a,(VDPR1)
		and	$bf

lab_3fe4:	ld	(VDPR1),a
		out	(IOVDP1),a
		ld	a,$81
		out	(IOVDP1),a
		bit	1,c
		ret

	IFDEF V30
		ds	7,$ff
	ELSE
fun_3ff0:	call	cursor_skip2
		jp	FUN_SCRNRD
		db	$ff
	ENDIF

; Jump table for BIT90 GAME rom
fun_3ff7:	jp	key_scan		; get keyboard input
fun_3ffa:	jp	fun_3fbb		; init screen
fun_3ffd:	jp	bank_to_basic		; select BASIC rom and reboot

