; ------------------------------------------------------------------------------
; game.asm
; BIT90 GAME ROM V3.X (8KB)
;
; Disassembled and commented sources by H.J. Berends. 
; Named function labels are based on the ColecoVision Coding Guide.
;
; The source code is shared for educational and non commercial purposes only. 
; It is considered fair use of orphaned software.
;
; Customization of the source code is indicated by build directives, and is
; copyright (c) 2026 H.J. Berends. All rights reserved.
; ------------------------------------------------------------------------------

		INCLUDE	"game.inc"

		SECTION GAME
		ORG	$0000

	IFDEF BIT90
		; Direct/indirect function call deviations
		a1h	equ	$1f		; 0x1fbe (jump to 0x1c27)
		a1l	equ	$be
		a2h	equ	$1d		; 0x1de3 (jump from 0x1fe2)
		a2l	equ	$3e
		a3h	equ	$1d		; 0x1d01 (jump from 0x1fdf)
		a3l	equ	$01
		a4h	equ	$1b		; 0x1ba3 (jump from 0x1fbb)
		a4l	equ	$a3
		a5h	equ	$06		; 0x06d8 (jump from 0x1ffa)
		a5l	equ	$d8
	ELSE ; Coleco
		a1h	equ	$1c		; 0x1c27
		a1l	equ	$27
		a2h	equ	$1f		; 0x1fe2
		a2l	equ	$e2
		a3h	equ	$1f		; 0x1fdf
		a3l	equ	$df
		a4h	equ	$1f		; 0x1fbb
		a4l	equ	$bb
		a5h	equ	$1f		; 0x1ffa
		a5l	equ	$fa
	ENDIF
		
; ----------------------------------------------------------------------------------------------
; 0x0000
BOOT_UP:
	IFDEF V31
		ld	sp,var_63b9
	ELSE
		ld	sp,STACK
	ENDIF

	IFDEF BIT90
		; POWER_UP redirect
		jp	lab_1acc
		db	$00,$00
RST_8H:		jp	RST_08H_RAM
		db	$00
		;
		; cursor key scancodes
dat_000c:	db	$3b,$3c,$1c,$14
		;	CUB,CUD,CUF,CUP
		;
RST_10H:	jp	RST_10H_RAM
		db	$31,$32,$33,$34,$35
RST_18H:	jp	RST_18H_RAM
		db	$31,$32,$33,$34,$35
RST_20H:	jp	RST_20H_RAM
		db	$31,$32,$33,$34,$35
RST_28H:	jp	RST_28H_RAM
		db	$31,$32,$33,$34,$35
RST_30H:	jp	RST_30H_RAM
		db	$31,$32,$33,$34,$35
	ELSE
		jp	lab_006e
		db	                        $ff,$ff,$c3,$0c,$80,$ff,$ff,$ff,$ff,$ff	; 0x0006
		db	$c3,$0f,$80,$ff,$ff,$ff,$ff,$ff,$c3,$12,$80,$ff,$ff,$ff,$ff,$ff	; 0x0010
		db	$c3,$15,$80,$ff,$ff,$ff,$ff,$ff,$c3,$18,$80,$ff,$ff,$ff,$ff,$ff	; 0x0020
		db	$c3,$1b,$80,$ff,$ff,$ff,$ff,$ff                                	; 0x0030
	ENDIF		

; ----------------------------------------------------------------------------------------------
	
; 0x0038
IRQ_INTERRUPT:	jp	IRQ_INT_VECTOR

; 0x003b <-- RAND_GEN
RAND_GEN_:	ld	hl,(var_63c8)
		bit	7,h
		jr	z,@r_0048
		bit	0,h
		jr	z,@r_004c
		jr	@r_004f
@r_0048:	bit	0,h
		jr	z,@r_004f
@r_004c:	scf
		jr	@r_0050
@r_004f:	or	a
@r_0050:	rl	l
		rl	h
		ld	(var_63c8),hl
		ld	a,l
		ret
	
; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
		db	$00
		;
		; keyboard key scancodes
dat_005a:	db	$02,$28,$07,$09,$01,$0e,$06,$0a,$02,$0d,$05,$0f
		;	  #   *   9   8   7   6   5   4   3   2   1   0
	ELSE	
		ds	13,$ff
	ENDIF

; ----------------------------------------------------------------------------------------------
	
; 0x0066
NMI_INTERRUPT:	jp	NMI_INT_VECTOR

; 0x0069 
AMERICA:	db	60			; 60: NTSC/USA	50: PAL/EUROPE (not used)

; 0x006a
ASCII_TABLE:	dw	$16ab			; ASCII characer pattern table 'A'..'Z'

; 0x006c
NUMBER_TABLE:	dw	$1623			; ASCII number pattern table '0'..'9'

; ----------------------------------------------------------------------------------------------
		
	IFDEF BIT90
; POWER_UP
lab_006e:	call	ALL_OFF			; turn off sound
		ld	hl,$0033		; random seed
		ld	(var_63c8),hl
		call	lab_1105		; controller init
		ld	hl,$0000
		ld	(var_63c6),hl		; clear flags
		jp	lab_1319		; display logo

; Subroutine
lab_0083:	xor	a
		cp	h
		jr	nz,@r_0090
		ld	a,$0f
		cp	l
		jr	nz,@r_0090
		pop	hl
		jp	lab_0199
@r_0090:	pop	bc
		ret
		db	$31,$32,$33,$34,$35,$36

; Common Pascal parameter passing routine, deviates from Coleco.
; 0x0098
PARAM_:		pop	hl
		ex	(sp),ix
		push	bc
		ex	(sp),hl
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		inc	hl
		push	hl
		ex	(sp),iy
		push	bc
@r_00a5:	ld	l,(ix+$00)
		inc	ix
		ld	h,(ix+$00)
		inc	ix
		ld	a,h
		or	l
		jr	nz,@r_00c1
		ld	l,(ix+$00)
		inc	ix
		ld	h,(ix+$00)
		inc	ix
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
@r_00c1:	ld	c,(iy+$00)
		inc	iy
		ld	b,(iy+$00)
		inc	iy
		bit	7,b
		jr	nz,@r_00d3
		ldir
		jr	@r_00d9
@r_00d3:	ld	a,l
		ld	(de),a
		inc	de
		ld	a,h
		ld	(de),a
		inc	de
@r_00d9:	pop	bc
		dec	bc
		push	bc
		ld	a,b
		or	c
		jr	nz,@r_00a5
		pop	bc
		ex	(sp),iy
		pop	bc
		pop	hl
		ex	(sp),ix
		jp	(hl)
		db	$31,$32,$33
		
; Subroutine
lab_00eb:	call	fun_092e
		bit	6,a
		jr	nz,@r_00f6
		ld	h,$00
		jr	@r_00f8
@r_00f6:	ld	h,$40
@r_00f8:	and	$0f
		ld	l,a
		ret

; Note: sound utility routines are functional the same as Coleco.

; 0x00fc Frequency sweep
FREQ_SWEEP:	ld	a,(ix+$07)
		add	a,a			; cp $00
		jr	nz,@r_010c
		ld	a,(ix+$05)
		dec	a
		ret	z
		ld	(ix+$05),a
		ret
		db	$00
@r_010c:	push	ix
		pop	hl
		ld	de,$0006		; ld e,$06 : ld d,$00
		add	hl,de
		call	DECLSN
		jr	nz,@r_012d
		call	MSNTOLSN
		dec	hl
		ld	a,(hl)
		dec	a
		ret	z
		ld	(hl),a
		dec	hl
		dec	hl
		ld	a,(ix+$07)
		call	ADD816
		inc	hl
		res	2,(hl)
		or	$ff
@r_012d:	ret
		db	$00

; 0x012f Attenuation sweep
ATN_SWEEP:	ld	a,(ix+$08)
		add	a,a			; cp $00
		ret	z
		push	ix
		pop	hl
		ld	de,$0009		; ld e, $09 : ld d,$00
		add	hl,de
		call	DECLSN
		jr	nz,@r_0161
		call	MSNTOLSN
		dec	hl
		call	DECLSN
		jr	z,@r_015f
		ld	a,(hl)
		and	$f0
		ld	e,a
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		ld	a,(hl)
		and	$f0
		add	a,e
		ld	e,a
		ld	a,(hl)
		and	$0f
		or	e
		ld	(hl),a
		or	$ff
		jr	@r_0161
@r_015f:	ld	(hl),$00
@r_0161:	ret
		db	$00,$00
	ELSE
		; 0x006e Coleco
lab_006e	equ	$006e
PARAM_		equ	$0098
		ALIGN	$0164
	ENDIF
		
; ----------------------------------------------------------------------------------------------

	IFDEF V30
; UPATNCTRL
fun_0164:	ld	a,(iy+$04)
		bit	4,c
		jr	z,@r_016f
		rrca
		rrca
		rrca
		rrca
@r_016f:	and	$0f
		or	c
		out	(SOUND_PORT),a
		ret

; 0x0175
UPFREQ:		ld	a,(iy+$03)
		and	$0f
		or	d
		out	(SOUND_PORT),a
		ld	a,(iy+$03)
		and	$f0
		ld	d,a
		ld	a,(iy+$04)
		and	$0f
		or	d
		rrca
		rrca
		rrca
		rrca
		out	(SOUND_PORT),a
		ret

; 0x0190
DECLSN:		xor	a
		rrd	
		dec	a
		push	af
		rld	
		pop	af
		ret
		
; Subroutine
lab_0199:	ld	a,l
		cp	$01
		jp	nz,lab_00eb
		jp	lab_1131

		; 0x01a2
		rrca
		rrca
		rrca
		ret
		
; 0x01a6
MSNTOLSN:	ld	a,(hl)
		and	$f0
		ld	b,a
	  	rrca
	  	rrca
	  	rrca
	  	rrca
	  	or	b
	  	ld	(hl),a
	  	ret
	
	ELIFDEF BIT90
	
; UPATNCTRL
fun_0164:	ld	a,(ix+$04)
		bit	4,c
		jr	z,@r_016e
		call	fun_01a2		; swap nibbles
@r_016e:	and	$0f
		or	c
		out	(SOUND_PORT),a
		ret

; 0x0174
UPFREQ:		ld	a,(ix+$03)
		and	$0f
		or	d
		out	(SOUND_PORT),a
		ld	a,(ix+$03)
		and	$f0
		ld	d,a
		ld	a,(ix+$04)
		and	$0f
		or	d
		call	fun_01a2		; swap nibbles
		out	(SOUND_PORT),a
		ret

; Note: some Coleco utility routines are not implemented or at a different address.

; 0x018e
DECLSN:		xor	a
		rrd	
		dec	a
		push	af
		rld	
		pop	af
		ret
		db	$00,$00
		
; Subroutine
lab_0199:	ld	a,l
		cp	$01
		jp	nz,lab_00eb
		jp	fun_0230

; Subroutine: swap nibbles
fun_01a2:	rrca
		rrca
		rrca
		rrca
		ret
		
; 0x01a7
MSNTOLSN:	ld	a,(hl)
		and	$f0
		ld	b,a
		call	fun_01a2		; swap nibbles
		or	b
		ld	(hl),a
		ret
	ELSE
		; 0x0164 Coleco
		ALIGN	0x01b1
	ENDIF

; ----------------------------------------------------------------------------------------------

; 0x01b1
ADD816:		ld	b,$00
		bit	7,a
		jr	z,@r_01b9
		ld	b,$ff
@r_01b9:	add	a,(hl)
		ld	(hl),a
		inc	hl
		ld	a,(hl)
		adc	a,b
		ld	(hl),a
		dec	hl
		ret

; PT_IX_TO_SxDATA
fun_01c1:	ld	hl,(var_7020)
		dec	hl
		dec	hl
		ld	c,b
		ld	b,$00
		rlc	c
		rlc	c
		add	hl,bc
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		push	de
		pop	ix
		ret

; ----------------------------------------------------------------------------------------------
		
; 0x1d5 
LEAVE_EFFECT:
	IFDEF BIT90
		; not supported
		ret
		db	$31,$32,$33

; Subroutine
fun_01d9:	ld	hl,dat_024c
		ld	(var_7022),hl
		ld	(var_7024),hl
		ld	(var_7026),hl
		ld	(var_7028),hl
		ret
	ELSE
		ld	(ix+$01),l
		ld	(ix+$02),h
		ld	a,(de)
		and	$3f
		ld	b,a
		ld	a,(ix+$00)
		and	$c0
		or	b
		ld	(ix+$00),a
		ret
	ENDIF

; ----------------------------------------------------------------------------------------------

; AREA_SONG_IS
fun_01e9:	ld	a,(ix+$00)
		cp	$ff
		ret	z
		and	$3f
		cp	$3e
		ret	nz
		push	ix
		pop	hl
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		ret

dat_01fd:	dw	$0002,$0001,$0002		
; 0x0203 <-- SOUND_INITP
INIT_SOUNDQ:	ld	bc,dat_01fd
		ld	de,var_63ba
		call	PARAM_
		ld	a,(var_63ba)
		ld	b,a
		ld	hl,(var_63bb)

; 0x0213 <-- SOUND_INIT
INIT_SOUND:
	IFDEF BIT90
		ld	(var_7020),hl
		inc	hl
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		ld	de,$000a		; ld e,$00 : ld d,$0a
@r_021f:	ld	(hl),$ff
		add	hl,de
		djnz	@r_021f
		ld	(hl),$00
	  IFDEF V30
		ld	hl,dat_024c
		ld	(var_7022),hl
		ld	(var_7024),hl
		ld	(var_7026),hl
		ld	(var_7028),hl
		ld	a,$ff
		ld	(var_702a),a
		nop
		; fall through to ALL_OFF		
	  ELSE
		call	fun_01d9
		ld	a,$ff
		ld	(var_702a),a
		jr	ALL_OFF			; turn off sound

fun_0230:	call	fun_1aa9
		ld	a,l
		cp	$75
		ret	nz
		ld	l,$0f
		ret
		db	$31
	  ENDIF
	ELSE ; Coleco
		db	            $22,$20,$70,$23,$23,$5e,$23,$56,$eb,$1e,$0a,$16,$00	; 0x0213
		db	$36,$ff,$19,$10,$fb,$36,$00,$21,$4c,$02,$22,$22,$70,$22,$24,$70	; 0x0220
		db	$22,$26,$70,$22,$28,$70,$3e,$ff,$32,$2a,$70                     ; 0x0230
	ENDIF

; ----------------------------------------------------------------------------------------------

; 0x023b <-- TURN_OFF_SOUND
ALL_OFF:	ld	a,$9f
		out	(SOUND_PORT),a
		ld	a,$bf
		out	(SOUND_PORT),a
		ld	a,$df
		out	(SOUND_PORT),a
		ld	a,$ff
		out	(SOUND_PORT),a
		ret
dat_024c:	db	$ff
		
dat_024d:	dw	$0001,$0001
; 0x0251 <-- PLAY_ITP
JUKE_BOXQ:	ld	bc,dat_024d
		ld	de,var_63ba
		call	PARAM_
		ld	a,(var_63ba)
		ld	b,a
		
; 0x25e <-- PLAY_IT
JUKE_BOX:	push	bc
		call	fun_01c1
		ld	a,(ix+$00)
		and	$3f
		pop	bc
		cp	b
		ret	z
		ld	(ix+$00),b
		dec	hl
		dec	hl
		ld	d,(hl)
		dec	hl
		ld	e,(hl)
		ld	(ix+$01),e
		ld	(ix+$02),d
		call	fun_035f
	
	IFDEF BIT90
		call	fun_0294
		ret
	
; 0x027f <-- SOUND_MAN
SND_MANAGER:	ld	b,$01
		call	fun_01c1
@r_0284:	ld	a,$00
		cp	(ix+$00)
		ret	z
		call	fun_02d6
		ld	de,$000a		; ld e,$00 : ld d,$0a
		add	ix,de
		jr	@r_0284

; UP_CH_DATA_PTRS
fun_0294:	push	ix
		call	fun_01d9
		ld	b,$01
		call	fun_01c1
@r_029e:	ld	a,(ix+$00)
		cp	$00
		jr	z,@r_02c5
		cp	$ff
		jr	z,@r_02be
		ld	a,(ix+$00)
		and	$c0
		rlca
		rlca
		rlca
		ld	e,a
		ld	d,$00
		ld	hl,var_7022
		add	hl,de
		push	ix
		pop	de
		ld	(hl),e
		inc	hl
		ld	(hl),d
@r_02be:	ld	de,$000a		; ld e,$0a : ld d,$00
		add	ix,de
		jr	@r_029e
@r_02c5:	pop	ix
		ret
		db	$00,$00
		
dat_02ca:	db	$05,$02,$08,$03,$0d,$0c
		db	$01,$0a,$0e,$04,$06,$09
		
; PROCESS_DATA_AREA
fun_02d6:	call	fun_01e9
		cp	$ff
		ret	z
		cp	$3e
		jr	nz,@r_02e5
		ld	de,$0007		; ld e,$07 : ld d,$00
		add	hl,de
		jp	(hl)
@r_02e5:	call	ATN_SWEEP
		call	FREQ_SWEEP
		jr	nz,@r_02fe
; 0x02ec
; EFXOVER
		ld	a,(ix+$00)
		push	af
		call	fun_035f
		pop	bc
		ld	a,(ix+$00)
		cp	b
		jr	z,@r_02fe
		call	fun_0294
@r_02fe:	ret
		db	$00

	  IFDEF V30
		; uses iy instead of ix
; 0x0300 <-- PLAY_SONGS
PLAY_SONGS_:	ld	a,$9f
		ld	c,$90
		ld	d,$80
		ld	iy,(var_7024)
		call	fun_034c
		ld	a,$bf
		ld	c,$b0
		ld	d,$a0
		ld	iy,(var_7026)
		call	fun_034c
		ld	a,$df
		ld	c,$d0
		ld	d,$c0
		ld	iy,(var_7028)
		call	fun_034c
		ld	a,$ff
		ld	c,$f0
		ld	iy,(var_7022)
		ld	e,(iy+$00)
		inc	e
		jr	nz,@r_0338
		out	(SOUND_PORT),a
		ret
@r_0338:	call	fun_0164
		ld	a,(iy+$04)
		and	$0f
		ld	hl,var_702a
		cp	(hl)
		ret	z
		ld	(hl),a
		ld	c,$e0
		call	fun_0164
		ret
		
; TONE_OUT		
fun_034c:	ld	e,(iy+$00)
		inc	e
		jr	nz,@r_0355
		out	(SOUND_PORT),a
		ret
@r_0355:	call	fun_0164
		call	UPFREQ
		ret
		db	$31,$32,$33
	  ELSE ; BIT90
; 0x0300 <-- PLAY_SONGS
PLAY_SONGS_:	ld	a,$9f
		ld	c,$90
		ld	d,$80
		ld	ix,(var_7024)
		call	fun_034c
		ld	a,$bf
		ld	c,$b0
		ld	d,$a0
		ld	ix,(var_7026)
		call	fun_034c
		ld	a,$df
		ld	c,$d0
		ld	d,$c0
		ld	ix,(var_7028)
		call	fun_034c
		ld	a,$ff
		ld	c,$f0
		ld	ix,(var_7022)
		ld	e,(ix+$00)
		inc	e
		jr	nz,@r_0338
		out	(SOUND_PORT),a
		ret
@r_0338:	call	fun_0164
		ld	a,(ix+$04)
		and	$0f
		ld	hl,var_702a
		cp	(hl)
		ret	z
		ld	(hl),a
		ld	c,$e0
		call	fun_0164
		ret
		
; TONE_OUT		
fun_034c:	ld	e,(ix+$00)
		inc	e
		jr	nz,@r_0355
		out	(SOUND_PORT),a
		ret
@r_0355:	call	fun_0164
		call	UPFREQ
		ret
		db	$31,$32,$33
	  ENDIF ; V30

; LOAD_NEXT_NOTE
fun_035f:	ld	a,(ix+$00)
		and	$3f
		push	af
		ld	(ix+$00),$ff
		ld	l,(ix+$01)
		ld	h,(ix+$02)
		ld	a,(hl)
		ld	b,a
		bit	5,a
		jr	z,@r_0391
		push	bc
		and	$1f
		inc	hl
	  IFDEF V30
	  	ld	(ix+$01),l
	  	ld	(ix+$02),h
	  ELSE
		call	fun_0947
	  ENDIF
		ld	(ix+$04),$f0
		ld	(ix+$05),a
		ld	(ix+$07),$00
		ld	(ix+$08),$00
		jp	lab_045e
	  IFNDEF V30
		db	$31,$32,$33
	  ENDIF
	  
@r_0391:	bit	4,a
		jr	z,@r_03a4
		bit	3,a
		jr	z,@r_039e
		pop	bc
		call	JUKE_BOX
		ret
@r_039e:	ld	a,$ff
		push	af
		jp	lab_045e
@r_03a4:	
	ELSE
		; 0x027b Coleco
		db	                                            $cd,$95,$02,$c9,$06	; 0x027b
		db	$01,$cd,$c1,$01,$3e,$00,$dd,$be,$00,$c8,$cd,$d6,$02,$1e,$0a,$16	; 0x0280
		db	$00,$dd,$19,$18,$ef,$dd,$e5,$21,$4c,$02,$22,$22,$70,$22,$24,$70	; 0x0290
		db	$22,$26,$70,$22,$28,$70,$06,$01,$cd,$c1,$01,$dd,$7e,$00,$fe,$00	; 0x02a0
		db	$28,$21,$fe,$ff,$28,$15,$dd,$7e,$00,$e6,$c0,$07,$07,$07,$5f,$16	; 0x02b0
		db	$00,$21,$22,$70,$19,$dd,$e5,$d1,$73,$23,$72,$1e,$0a,$16,$00,$dd	; 0x02c0
		db	$19,$18,$d8,$dd,$e1,$c9,$cd,$e9,$01,$fe,$ff,$c8,$fe,$3e,$20,$06	; 0x02d0
		db	$1e,$07,$16,$00,$19,$e9,$cd,$2f,$01,$cd,$fc,$00,$20,$11,$dd,$7e	; 0x02e0
		db	$00,$f5,$cd,$5f,$03,$c1,$dd,$7e,$00,$b8,$28,$03,$cd,$95,$02,$c9	; 0x02f0
		db	$3e,$9f,$0e,$90,$16,$80,$dd,$2a,$24,$70,$cd,$4e,$03,$3e,$bf,$0e	; 0x0300
		db	$b0,$16,$a0,$dd,$2a,$26,$70,$cd,$4e,$03,$3e,$df,$0e,$d0,$16,$c0	; 0x0310
		db	$dd,$2a,$28,$70,$cd,$4e,$03,$3e,$ff,$0e,$f0,$dd,$2a,$22,$70,$dd	; 0x0320
		db	$5e,$00,$1c,$20,$04,$d3,$ff,$18,$14,$cd,$64,$01,$dd,$7e,$04,$e6	; 0x0330
		db	$0f,$21,$2a,$70,$be,$28,$06,$77,$0e,$e0,$cd,$64,$01,$c9,$dd,$5e	; 0x0340
		db	$00,$1c,$20,$04,$d3,$ff,$18,$06,$cd,$64,$01,$cd,$75,$01,$c9,$dd	; 0x0350
		db	$7e,$00,$e6,$3f,$f5,$dd,$36,$00,$ff,$dd,$6e,$01,$dd,$66,$02,$7e	; 0x0360
		db	$47,$cb,$6f,$28,$1c,$c5,$e6,$1f,$23,$dd,$75,$01,$dd,$74,$02,$dd	; 0x0370
		db	$36,$04,$f0,$dd,$77,$05,$dd,$36,$07,$00,$dd,$36,$08,$00,$c3,$61	; 0x0380
		db	$04,$cb,$67,$28,$0f,$cb,$5f,$28,$05,$c1,$cd,$5e,$02,$c9,$3e,$ff	; 0x0390
		db	$f5,$c3,$61,$04                                                	; 0x03a0
		
SND_MANAGER	equ	$027f	
PLAY_SONGS_	equ	$0300
fun_035f	equ	$035f
	ENDIF

; ----------------------------------------------------------------------------------------------
	
		db	                $e6,$3c,$fe,$04,$20,$28,$fd,$e1,$fd,$e5,$c5,$23	; 0x03a4
		db	$5e,$dd,$73,$01,$23,$56,$dd,$72,$02,$23,$fd,$e5,$f1,$d5,$fd,$e1	; 0x03b0
		db	$11,$c6,$03,$d5,$fd,$e9,$16,$00,$1e,$07,$fd,$19,$11,$61,$04,$d5	; 0x03c0
		db	$fd,$e9,$c5,$78,$e6,$03,$fe,$00,$20,$20,$23,$23,$23,$23        	; 0x03d0

; ----------------------------------------------------------------------------------------------
		
	IF BIT90 && !V30
		;0x03de
		call	fun_0947
		dec	hl
		ld	de,$0005
		call	fun_0478
		ld	bc,$0003
		lddr
		ld	(ix+$07),$00
		ld	(ix+$08),00
		jr	$045e
		db	$31,$32,$33
		
		;0x03fa
		cp	$01
		jr	nz,@r_0419
		ld	e,$06
		ld	d,$00
		add	hl,de
		call	fun_0947
		dec	hl
		inc	e
		call	fun_0478
		ld	bc,$0005
		lddr
		ld	(ix+$08),$00
		jr	lab_045e
		db	$31,$32,$33
		;		
@r_0419:	cp	$02
		jr	nz,@r_0445
		ld	e,$06
		ld	d,$00
		add	hl,de
		pop	af
		push	af
		and	$c0
		jr	nz,@r_0429
		dec	hl
@r_0429:	call	fun_0947
		dec	hl
		ld	e,$09
		call	fun_0478
		ld	bc,$0002
		lddr
		ld	a,$00
		ld	(de),a
		dec	de
		dec	de
		ld	c,$03
		lddr
		jr	lab_045e
		db	$31,$32,$33
		;
@r_0445:	ld	e,$08
		ld	d,$00
		add	hl,de
		call	fun_0947
		dec	hl
		push	ix
		pop	iy
		ld	e,$09
		add	iy,de
		push	iy
		pop	de
		ld	bc,$0007
		lddr
		
lab_045e:	push	ix
		pop	hl
		pop	af
		pop	bc
		cp	$ff
		ret	z
		ld	d,a
		and	$3f
		cp	$04
		jr	nz,@r_046f
		ld	b,$3e
@r_046f:	ld	a,d
		and	$c0
		or	b
		ld	(hl),a
		ret
		db	$31,$32,$33
	ELSE
		; V30 / Coleco
		db	                                                        $dd,$75	; 0x03de
		db	$01,$dd,$74,$02,$2b,$11,$05,$00,$cd,$78,$04,$01,$03,$00,$ed,$b8	; 0x03e0
		db	$dd,$36,$07,$00,$dd,$36,$08,$00,$18,$67,$fe,$01,$20,$1b,$1e,$06	; 0x03f0
		db	$16,$00,$19,$dd,$75,$01,$dd,$74,$02,$2b,$1c,$cd,$78,$04,$01,$05	; 0x0400
		db	$00,$ed,$b8,$dd,$36,$08,$00,$18,$48,$fe,$02,$20,$28,$1e,$06,$16	; 0x0410
		db	$00,$19,$f1,$f5,$e6,$c0,$20,$01,$2b,$dd,$75,$01,$dd,$74,$02,$2b	; 0x0420
		db	$1e,$09,$cd,$78,$04,$01,$02,$00,$ed,$b8,$3e,$00,$12,$1b,$1b,$0e	; 0x0430
		db	$03,$ed,$b8,$18,$1c,$1e,$08,$16,$00,$19,$dd,$75,$01,$dd,$74,$02	; 0x0440
		db	$2b,$dd,$e5,$fd,$e1,$1e,$09,$fd,$19,$fd,$e5,$d1,$01,$07,$00,$ed	; 0x0450
		db	$b8,$dd,$e5,$e1,$f1,$c1,$fe,$ff,$c8,$57,$e6,$3f,$fe,$04,$20,$02	; 0x0460
		db	$06,$3e,$7a,$e6,$c0,$b0,$77,$c9                                	; 0x0470
lab_045e	equ	$0461	; V30!
	ENDIF

; ----------------------------------------------------------------------------------------------
	
fun_0478:	push	ix
		pop	iy
		add	iy,de
		push	iy
		pop	de
		ret

; ACTIVATE_P
dat_0482:	dw	$0002,$fffe,$0001
		
; 0x0488 <-- ACTIVATEP
ACTIVATEQ:	ld	bc,dat_0482
		ld	de,var_63ba
		call	PARAM_
		ld	hl,(var_63ba)
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		ld	a,(var_63bc)
		cp	$00
		jr	z,@r_04a2
		scf
		jr	ACTIVATE_
@r_04a2:	or	a		

	IF BIT90 && !V30
; 0x04a3 <-- ACTIVATE
ACTIVATE_:	call	fun_0942
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		inc	hl
		ld	a,$00
		ld	(bc),a
		ld	a,(de)
		push	af
		and	$0f
		jp	z,lab_04e7
		dec	a
		jp	z,lab_05f1
		dec	a
		jp	z,lab_0600
		dec	a
		jp	z,lab_0600
		dec	a
		jr	z,lab_04c6
		pop	af
		ret
		db	$00
	ELSE ; V30 / Coleco
		db	            $5e,$23,$56,$23,$4e,$23,$46,$23,$3e,$00,$02,$1a,$f5	; 0x04a3
		db	$e6,$0f,$ca,$e7,$04,$3d,$ca,$f1,$05,$3d,$ca,$00,$06,$3d,$ca,$00	; 0x04b0
		db	$06,$3d,$28,$02,$f1,$c9                                        	; 0x04c0
ACTIVATE_	equ	$04a3
	ENDIF
	
	IFDEF BIT90
; ACT_CMPLX		
lab_04c6:	ld	a,(de)
		rra
		rra
		rra
		rra
		and	$0f
		ld	b,a
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		or	a
		jr	z,@r_04e4
@r_04d5:	pop	af
		push	af
		push	hl
		push	bc
		ex	de,hl
		call	ACTIVATE_
		pop	bc
		pop	hl
	  IFDEF V30
	  	ld	e,(hl)
	  	inc	hl
	  	ld	d,(hl)
	  	inc	hl
		djnz	@r_04d5
@r_04e4:	pop	af
		ret
	  ELSE
		call	fun_0942
		djnz	@r_04d5
@r_04e4:	pop	af
		ret
		db	$00
	  ENDIF
	ELSE
		; 0x04c6 Coleco
		ALIGN	$04e7
	ENDIF
	
	IF BIT90 && !V30
; ACT_SEMI
lab_04e7:	call	fun_0572
		ld	a,(de)
		ld	l,a
		inc	de
		ld	a,(de)
		add	a,l
		ld	(iy+$05),a
		ld	h,$00
		pop	af
		ret	nc
		push	af
		ld	a,(var_63c3)
		bit	1,a
		jr	z,lab_0530
		ex	de,hl
		ld	b,h
		ld	c,l
		ld	l,(hl)
		ld	h,$00
		push	hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
		push	hl
		inc	bc
		ld	a,(bc)
		ld	l,a
		inc	bc
		ld	a,(bc)
		ld	h,a
		pop	bc
		pop	iy
		pop	af
		bit	7,a
		jr	z,@r_051a
		call	fun_0594
@r_051a:	call	fun_05e8
		bit	6,a
		jr	z,@r_0524
		call	fun_0594
@r_0524:	call	fun_05e8
		bit	5,a
		ret	z
		call	fun_0594
		ret
		db	$00,$00
	ELSE
		; 0x04e7 V30 / Coleco
		db	                            $cd,$72,$05,$1a,$6f,$13,$1a,$85,$fd	; 0x04e7
		db	$77,$05,$26,$00,$f1,$30,$38,$f5,$3a,$c3,$73,$cb,$4f,$28,$31,$eb	; 0x04f0
		db	$44,$4d,$6e,$26,$00,$e5,$29,$29,$29,$e5,$03,$0a,$6f,$03,$0a,$67	; 0x0500
		db	$c1,$fd,$e1,$f1,$cb,$7f,$28,$03,$cd,$94,$05,$cd,$e8,$05,$cb,$77	; 0x0510
		db	$28,$03,$cd,$94,$05,$cd,$e8,$05,$cb,$6f,$28,$03,$cd,$94,$05,$c9	; 0x0520
	ENDIF

; ----------------------------------------------------------------------------------------------
	
lab_0530:	db	$eb,$4e,$06,$00,$c5,$fd,$e1,$23,$7e,$23,$66,$6f,$e5,$c5,$d5,$fd	; 0x0530
		db	$e5,$3e,$03,$cd,a1l,a1h,$c1,$e1,$5d,$54,$09,$2b,$cb,$3c,$cb,$1d	; 0x0540
		db	$cb,$3c,$cb,$1d,$cb,$3c,$cb,$1d,$cb,$2b,$cb,$2b,$cb,$2b,$b7,$ed	; 0x0550
		db	$52,$23,$e5,$fd,$e1,$e1,$29,$29,$29,$c1,$09,$3e,$04,$cd,a1l,a1h	; 0x0560
		db	$f1,$c9,$c5,$fd,$e1,$d5,$5e,$23,$56,$cb,$7a,$20,$14,$7a,$fe,$70	; 0x0570
		db	$38,$06,$3e,$80,$12,$18,$0a,$80,$21,$87,$05,$01,$01,$00,$cd,$01	; 0x0580
		db	$1d,$d1,$13,$c9,$f5,$c5,$fd,$e5,$d5,$e5,$3e,$03,$cd,a1l,a1h,$e1	; 0x0590
		db	$d1,$fd,$e1,$c1,$f1,$f5,$c5,$fd,$e5,$d5,$e5,$cb,$67,$20,$0d,$09	; 0x05a0
		db	$3e,$04,$cd,a1l,a1h,$e1,$d1,$fd,$e1,$c1,$f1,$c9,$09,$4d,$44,$fd	; 0x05b0
		db	$e5,$e1,$e5,$0a,$c5,$01,$08,$00,$2a,$06,$80,$09,$06,$08,$2b,$77	; 0x05c0
		db	$10,$fc,$d5,$fd,$21,$01,$00,$3e,$04,$cd,a1l,a1h,$d1,$c1,$13,$03	; 0x05d0
		db	$e1,$2b,$7c,$b5,$20,$dc,$18,$cd,$c5,$01,$00,$01,$eb,$09,$eb,$c1	; 0x05e0
		db	$c9,$cd,$72,$05,$13,$1a,$fd,$77,$05,$13,$1a,$fd,$77,$06,$f1,$c9	; 0x05f0
		db	$03,$03,$03,$03,$03,$eb,$23,$7e,$5f,$16,$00,$d5                	; 0x0600
fun_0572	equ	$0572
fun_0594	equ	$0594
fun_05e8	equ	$05e8
lab_05f1	equ	$05f1
lab_0600	equ	$0600
	
; ----------------------------------------------------------------------------------------------

	IF BIT90 && !V30
		; 0x060c
		inc	hl
		add	a,(hl)
		call	fun_0942
		ld	(bc),a
		ld	c,(hl)
		ld	b,$00
		push	bc
		pop	iy
		ex	de,hl
		pop	de
		pop	af
		ret	nc
		ld	a,$01
		call	PUT_VRAM
		ret
		db	$00

; SET_UP_WRITE
fun_0623:	push	ix
		ld	hl,(var_63cd)
		pop	de
		ld	(hl),e
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),b
		inc	hl
		ex	de,hl
		ld	a,(var_63cb)
		inc	a
		ld	hl,var_63ca
		cp	(hl)
		jr	nz,@r_0646
		ld	a,$00
		ld	(var_63cb),a
		ld	hl,(var_63d1)
		ld	(var_63cd),hl
		ret
@r_0646:	ld	(var_63cb),a
		ld	(var_63cd),de
		ret
		db	$00
	ELSE
		; 0x060c V30 / Coleco
		db	                                                $23,$5e,$23,$56	; 0x060c
		db	$23,$86,$02,$4e,$06,$00,$c5,$fd,$e1,$eb,$d1,$f1,$d0,$3e,$01,$cd	; 0x0610
		db	a1l,a1h,$c9,$dd,$e5,$2a,$cd,$73,$d1,$73,$23,$72,$23,$70,$23,$eb	; 0x0622
		db	$3a,$cb,$73,$3c,$21,$ca,$73,$be,$20,$0d,$3e,$00,$32,$cb,$73,$2a	; 0x0630
		db	$d1,$73,$22,$cd,$73,$18,$07,$32,$cb,$73,$ed,$53,$cd,$73,$c9    	; 0x0640
fun_0623	equ	$0623
	ENDIF

; ----------------------------------------------------------------------------------------------
	
	IFDEF BIT90

; INIT_QUEUE_P
dat_064f:	dw	$0002,$0001,$fffe
		
; 0x0655 <-- INIT_WRITERP
INIT_QUEUEQ:	ld	bc,dat_064f
		ld	de,var_63ba
		call	PARAM_
		ld	a,(var_63ba)
		ld	hl,(var_63bb)

; 0x0664 <-- INIT_WRITER
INIT_QUEUE:	ld	(var_63ca),a
		ld	a,$00
		ld	(var_63cb),a
		ld	(var_63cc),a
		ld	(var_63d1),hl
		ld	(var_63cd),hl
		ld	(var_63cf),hl
		ret

; 0x0679 <-- WRITER
WRITER_:	ld	a,(var_63c6)
		push	af
		ld	a,$00
		ld	(var_63c6),a
@r_0682:	ld	a,(var_63cc)
		ld	hl,var_63cb
		cp	(hl)
		jr	z,@r_06bc
		ld	hl,(var_63cf)
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	b,(hl)
		inc	hl
		push	de
		pop	ix
		push	hl
		call	fun_06e3
		ld	a,(var_63cc)
		inc	a
		ld	hl,var_63ca
		cp	(hl)
		jr	nz,@r_06b3
		ld	a,$00
		ld	(var_63cc),a
		ld	hl,(var_63d1)
		ld	(var_63cf),hl
		pop	hl
		jr	@r_06ba
@r_06b3:	ld	(var_63cc),a
		pop	hl
		ld	(var_63cf),hl
@r_06ba:	jr	@r_0682
@r_06bc:	pop	af
		ld	(var_63c6),a
		ret
		
; PUTOBJ_PAR
dat_06c1:	dw	$0002,$0002,$0001
		
; 0x06c7 <-- PUTOBJP
PUTOBJQ:	ld	bc,dat_06c1
		ld	de,var_63ba
		call	PARAM_
		ld	ix,(var_63ba)
		ld	a,(var_63bc)
		ld	b,a

; 0x06d8 <-- PUTOBJ
PUTOBJ_:	ld	a,(var_63c6)
		cp	$01
		jr	nz,fun_06e3
		call	fun_0623
		ret
	ELSE
		; 0x064f Coleco
INIT_QUEUEQ	equ	$0655
INIT_QUEUE	equ	$0664
WRITER_		equ	$0679
PUTOBJQ		equ	$06c7
PUTOBJ_		equ	$06d8
		ALIGN	$06e3
	ENDIF
	
	IF BIT90 && !V30
fun_06e3:	ld	h,(ix+$01)
		ld	l,(ix+$00)
		ld	a,(hl)
		ld	c,a
		and	$0f
		jr	z,@r_06fe
		dec	a
		jp	z,fun_0a87
		dec	a
		jp	z,fun_08df
		dec	a
		jp	z,fun_0955
		jp	lab_0ea2
		
; PUTSEMI		
@r_06fe:	ld	d,(ix+$03)
		ld	e,(ix+$02)
		push	de
		pop	iy
		ld	d,(iy+$02)
		ld	e,(iy+$01)
		call	PX_TO_PTRN_POS
		ld	c,e
		ld	d,(iy+$04)
		ld	e,(iy+$03)
		call	PX_TO_PTRN_POS
		ld	b,e
		ld	e,(iy+$00)
		ld	d,$00
		add	hl,de
		add	hl,de
		ld	e,$05
		add	hl,de
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		push	bc
		pop	de
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		inc	hl
		ld	a,(ix+$05)
		bit	7,a
		jr	z,@r_073b
		call	PUT_FRAME
		ret
		db	$00
; S_OLD_SCRN
@r_073b:
	ELSE
		; 0x06e3 V30 / Coleco
		db	            $dd,$66,$01,$dd,$6e,$00,$7e,$4f,$e6,$0f,$ca,$ff,$06	; 0x06e3
		db	$3d,$ca,$87,$0a,$3d,$ca,$df,$08,$3d,$ca,$55,$09,$c3,$a2,$0e,$dd	; 0x06f0
		db	$56,$03,$dd,$5e,$02,$d5,$fd,$e1,$fd,$56,$02,$fd,$5e,$01,$cd,$e8	; 0x0700
		db	$07,$4b,$fd,$56,$04,$fd,$5e,$03,$cd,$e8,$07,$43,$fd,$5e,$00,$16	; 0x0710
		db	$00,$19,$19,$1e,$05,$19,$5e,$23,$56,$eb,$c5,$d1,$4e,$23,$46,$23	; 0x0720
		db	$dd,$7e,$05,$cb,$7f,$28,$04,$cd,$0b,$08,$c9                    	; 0x0730		
fun_06e3	equ	$06e3		
	ENDIF
		
; ----------------------------------------------------------------------------------------------
;
		db	                                            $c5,$d5,$e5,$fe,$70	; 0x073b
		db	$28,$02,$38,$07,$67,$dd,$6e,$04,$7e,$18,$35,$2a,$06,$80,$dd,$56	; 0x0740
		db	$05,$dd,$5e,$04,$e5,$d5,$e5,$01,$04,$00,$cd,$3e,$1d,$e1,$7e,$fe	; 0x0750
		db	$80,$20,$03,$d1,$18,$19,$23,$23,$46,$23,$5e,$16,$00,$23,$eb,$18	; 0x0760
		db	$01,$29,$10,$fd,$e5,$c1,$eb,$d1,$13,$13,$13,$13,$cd,$3e,$1d,$e1	; 0x0770
		db	$7e,$fe,$80                                                    	; 0x0780

; ----------------------------------------------------------------------------------------------

	IF BIT90 && !V30
		; 0x0783
		jr	z,@r_0793
		call	fun_0942
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		inc	hl
		push	ix
		call	PUT_FRAME
		pop	ix
@r_0793:	pop	hl
		pop	de
		pop	bc
		push	bc
		push	de
		push	hl
		ld	h,(ix+$05)
		ld	l,(ix+$04)
		ld	a,$70
		cp	h
		jr	c,@r_07a7
		ld	hl,(WORK_BUFFER)
@r_07a7:	ld	(hl),e
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),c
		inc	hl
		ld	(hl),b
		inc	hl
		push	ix
		call	GET_BKGRND
		pop	ix
		pop	hl
		pop	de
		pop	bc
		push	ix
		call	PUT_FRAME
		pop	ix
		ld	d,(ix+$05)
		ld	a,$70
		cp	d
		jr	z,@r_07e6
		jr	c,@r_07e6
		ld	e,(ix+$04)
		exx
		ld	hl,(WORK_BUFFER)
		push	hl
		inc	hl
		inc	hl
		ld	e,(hl)
		ld	d,$00
		inc	hl
		ld	b,(hl)
		ex	de,hl
		jr	@r_07dd
@r_07dc:	add	hl,hl
@r_07dd:	djnz	@r_07dc
		push	hl
		exx
		pop	bc
		pop	hl
		call	VRAM_WRITE
@r_07e6:	ret
		db	$00
	ELSE
		; 0x0783 V30 / Coleco
		db	            $28,$0f,$5e,$23,$56,$23,$4e,$23,$46,$23,$dd,$e5,$cd	; 0x0783
		db	$0b,$08,$dd,$e1,$e1,$d1,$c1,$c5,$d5,$e5,$dd,$66,$05,$dd,$6e,$04	; 0x0790
		db	$3e,$70,$bc,$38,$03,$2a,$06,$80,$73,$23,$72,$23,$71,$23,$70,$23	; 0x07a0
		db	$dd,$e5,$cd,$98,$08,$dd,$e1,$e1,$d1,$c1,$dd,$e5,$cd,$0b,$08,$dd	; 0x07b0
		db	$e1,$dd,$56,$05,$3e,$70,$ba,$28,$1e,$38,$1c,$dd,$5e,$04,$d9,$2a	; 0x07c0
		db	$06,$80,$e5,$23,$23,$5e,$16,$00,$23,$46,$eb,$18,$01,$29,$10,$fd	; 0x07d0
		db	$e5,$d9,$c1,$e1,$cd,$01,$1d,$c9                                	; 0x07e0		
	ENDIF
		
; ----------------------------------------------------------------------------------------------
;
; 0x07e8
PX_TO_PTRN_POS:	db	                                $e5,$cb,$2a,$cb,$1b,$cb,$2a,$cb	; 0x07e8
		db	$1b,$cb,$2a,$cb,$1b,$cb,$7a,$20,$09,$21,$80,$ff,$19,$e1,$d0,$1e	; 0x07f0
		db	$7f,$c9,$21,$80,$00,$19,$e1,$d8,$1e,$80,$c9,$c5,$d5,$e5,$d9,$e1	; 0x0800
		db	$d1,$c1,$cd,$c0,$08,$d9,$7b,$cb,$7f,$20,$03,$fe,$20,$d0,$81,$cb	; 0x0810
		db	$7f,$c0,$b7,$c8,$cb,$7b,$28,$20,$79,$83,$d5,$fe,$21,$38,$02,$3e	; 0x0820
		db	$20,$5f,$16,$00,$d5,$fd,$e1,$d1,$7b,$d9,$c5,$ed,$44,$4f,$06,$00	; 0x0830
		db	$09,$eb,$09,$eb,$c1,$d9,$18,$1c,$7b,$81,$fe,$1f,$28,$0f,$38,$0d	; 0x0840
		db	$3e,$20,$93,$d5,$5f,$16,$00,$d5,$fd,$e1,$d1,$18,$07,$c5,$06,$00	; 0x0850
		db	$c5,$fd,$e1,$c1,$1e,$00,$7a,$83,$cb,$7f,$20,$19,$fe,$18,$30,$15	; 0x0860
		db	$c5,$d5,$d9,$c5,$d5,$e5,$fd,$e5,$3e,$02,$cd,a1l,a1h,$fd,$e1,$e1	; 0x0870
		db	$d1,$c1,$d9,$d1,$c1,$d9,$c5,$06,$00,$09,$eb,$01,$20,$00,$09,$eb	; 0x0880
		db	$c1,$d9,$1c,$7b,$b8,$20,$cf,$c9,$cd,$c0,$08,$c5,$06,$00,$c5,$fd	; 0x0890
		db	$e1,$c1,$c5,$d5,$e5,$fd,$e5,$3e,$02,$cd,$a3,$1b,$fd,$e1,$e1,$d1	; 0x08a0
		db	$c1,$c5,$06,$00,$09,$01,$20,$00,$eb,$09,$eb,$c1,$05,$20,$e3,$c9	; 0x08b0
		db	$e5,$cb,$7a,$28,$04,$26,$ff,$18,$02,$26,$00,$6a,$29,$29,$29,$29	; 0x08c0
		db	$29,$cb,$7b,$28,$04,$16,$ff,$18,$02,$16,$00,$19,$eb,$e1,$c9    	; 0x08d0
PUT_FRAME	equ	$080b
GET_BKGRND	equ	$0898
CALC_OFFSET	equ	$08c0

; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
fun_08df:	call	fun_0911
		jr	z,@r_08ef
		cp	$ff
		jp	nz,lab_0a53
		ld	a,c
		cp	$f9
		jp	m,lab_0a53
@r_08ef:	call	fun_0926
		jr	z,@r_08ff
		cp	$ff
		jp	nz,lab_0a53
		ld	a,c
		cp	$f9
		jp	m,lab_0a53
@r_08ff:	dec	hl
		dec	hl
		ld	a,(hl)
		cp	$00
		jp	z,lab_09ca
		dec	hl
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		ld	hl,$0008
		jp	lab_0999

fun_0911:	ld	iy,(WORK_BUFFER)
		ld	l,(ix+$02)
		ld	h,(ix+$03)
		ld	de,$0001
		add	hl,de
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		ld	a,b
		cp	$00
		ret
		
fun_0926:	inc	hl
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		ld	a,b
		cp	$00
		ret
		
; get cursor / ctrl key pressed and convert to controller joystick / left fire code
fun_092e:	call	lab_3ff7		; get keyboard input
		ld	hl,dat_000c		; cursor key scancodes
		ld	bc,$0004
		cpir
		ld	b,c
		jr	nz,lab_0981		; nz=no cursor key pressed
		inc	b
		xor	a
		scf
		jp	lab_097d

; Subroutine
fun_0942:	ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		ret
		
fun_0947:	ld	(ix+$01),l
		ld	(ix+$02),h
		ret
		; 0x094d
		ld	l,(ix+$01)
		ld	h,(ix+$02)
		ret
		
fun_0955:	call	fun_0911
		jr	z,@r_0965
		cp	$ff
		jp	nz,lab_0a53
		ld	a,c
		cp	$e1
		jp	m,lab_0a53
@r_0965:	call	fun_0926
		jr	z,lab_098a
		cp	$ff
		jp	nz,lab_0a53
		ld	a,c
		cp	$e1
		jp	m,lab_0a53
		inc	(hl)
		dec	(hl)
		ld	(hl),$37
		jr	c,lab_09b4
		jr	nc,lab_09ae

; convert cursor key scancode
lab_097d:	rla
		djnz	lab_097d
		ld	b,a
lab_0981:	ld	a,e
		cp	$05			; [CTRL] key pressed?
		jr	nz,lab_0988
		set	6,b			; yes,flag fire button pressed
lab_0988:	ld	a,b
		ret
	ELSE
		; 0x08df Coleco
		ALIGN	$098a
	ENDIF	
		
; ----------------------------------------------------------------------------------------------

lab_098a:	db	                                        $2b,$2b,$7e,$fe,$00,$ca	; 0x098a
		db	$ca,$09,$2b,$4e,$23,$46,$21,$20,$00,$09,$7d,$fd,$77,$01,$dd,$6e	; 0x0990
		db	$00,$dd,$66,$01,$11,$05,$00,$19,$eb,$1a,$6f,$13,$1a,$67,$e5,$dd	; 0x09a0
		db	$6e,$02,$dd,$66,$03,$11,$00,$00,$19,$7e,$cb,$27,$01,$00,$00,$4f	; 0x09b0
		db	$e1,$09,$7e,$f6,$80,$fd,$77,$03,$18,$36,$dd,$6e,$02,$dd,$66,$03	; 0x09c0
		db	$11,$01,$00,$19,$7e,$fd,$77,$01,$dd,$6e,$00,$dd,$66,$01,$11,$05	; 0x09d0
		db	$00,$19,$eb,$1a,$6f,$13,$1a,$67,$e5,$dd,$6e,$02,$dd,$66,$03,$11	; 0x09e0
		db	$00,$00,$19,$7e,$cb,$27,$01,$00,$00,$4f,$e1,$09,$7e,$fd,$77,$03	; 0x09f0
		db	$dd,$6e,$02,$dd,$66,$03,$11,$03,$00,$19,$7e,$fd,$77,$00,$dd,$6e	; 0x0a00
		db	$00,$dd,$66,$01,$11,$05,$00,$19,$eb,$1a,$6f,$13,$1a,$67,$e5,$dd	; 0x0a10
		db	$6e,$02,$dd,$66,$03,$11,$00,$00,$19,$7e,$cb,$27,$01,$00,$00,$4f	; 0x0a20
		db	$e1,$09,$23,$7e,$dd,$6e,$00,$dd,$66,$01,$11,$01,$00,$19,$86,$fd	; 0x0a30
		db	$77,$02,$af,$16,$00,$dd,$5e,$04,$fd,$e5,$e1,$fd,$21,$01,$00,$cd	; 0x0a40
		db	$be,$1f                                                    	; 0x0a50
lab_0999	equ	$0999
lab_09ae	equ	$09ae
lab_09b4	equ	$09b4
lab_09ca	equ	$09ca

; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
		; 0x0a52
		ret

lab_0a53:	push	iy
		push	ix
		push	iy
		push	iy
		xor	a
		ld	d,$00
		ld	e,(ix+$04)
		pop	hl
		ld	iy,$0001
		call	GET_VRAM_
		ld	a,$00
		pop	iy
		ld	(iy+$01),a
		ld	a,$80
		ld	(iy+$03),a
		xor	a
		ld	d,$00
		pop	ix
		ld	e,(ix+$04)
		pop	hl
		ld	iy,$0001
		call	PUT_VRAM
		ret
		db	$00
	ELSE
		db	        $18,$32,$fd,$e5,$dd,$e5,$fd,$e5,$fd,$e5,$af,$16,$00,$dd	; 0x0a52
		db	$5e,$04,$e1,$fd,$21,$01,$00,$cd,$bb,$1f,$3e,$00,$fd,$e1,$fd,$77	; 0x0a60
		db	$01,$3e,$80,$fd,$77,$03,$af,$16,$00,$dd,$e1,$dd,$5e,$04,$e1,$fd	; 0x0a70
		db	$21,$01,$00,$cd,$be,$1f,$c9                                    	; 0x0a80
	ENDIF
		
; ----------------------------------------------------------------------------------------------

fun_0a87:	db	                            $fd,$2a,$06,$80,$3a,$c3,v63,$cb,$4f	; 0x0a87
		db	$20,$04,$cb,$b8,$18,$02,$cb,$f8,$fd,$70,$03,$e5,$dd,$66,$03,$dd	; 0x0a90
		db	$6e,$02,$7e,$fd,$77,$04,$ee,$80,$77,$23,$5e,$7b,$e6,$07,$ed,$44	; 0x0aa0
		db	$c6,$08,$fd,$77,$01,$23,$56,$cd,$e8,$07,$fd,$73,$11,$23,$5e,$7b	; 0x0ab0
		db	$e6,$07,$fd,$77,$00,$23,$56,$cd,$e8,$07,$fd,$73,$12,$2a,$06,$80	; 0x0ac0
		db	$11,$13,$00,$19,$fd,$56,$12,$fd,$5e,$11,$01,$03,$03,$cd,$98,$08	; 0x0ad0
		db	$dd,$56,$05,$dd,$5e,$04,$dd,$7e,$06,$dd,$e1,$fd,$2a,$06,$80,$fd	; 0x0ae0
		db	$77,$05,$d5,$2a,$06,$80,$01,$06,$00,$09,$01,$0b,$00,$7a,$fe,$70	; 0x0af0
		db	$30,$05,$cd,a2l,a2h,$18,$03,$eb,$ed,$b0,$2a,$06,$80,$11,$13,$00	; 0x0b00
		db	$19,$d9,$ed,$5b,$06,$80,$21,$08,$00,$19,$eb,$d9,$fd,$2a,$06,$80	; 0x0b10
		db	$fd,$4e,$05,$06,$09,$7e,$91,$fe,$12,$30,$0e,$fe,$09,$38,$02,$d6	; 0x0b20
		db	$09,$d9,$6f,$26,$00,$19,$7e,$d9,$77,$23,$10,$e9,$d1,$2a,$06,$80	; 0x0b30
		db	$01,$11,$00,$09,$01,$0b,$00,$7a,$fe,$70,$30,$05,$cd,a3l,a3h,$18	; 0x0b40
		db	$02,$ed,$b0,$dd,$e5,$ed,$5b,$06,$80,$21,$13,$00,$19,$eb,$01,$14	; 0x0b50
		db	$00,$09,$06,$09,$1a,$13,$d5,$11,$08,$00,$19,$e5,$5f,$16,$00,$4f	; 0x0b60
		db	$c5,$3e,$09,$90,$06,$00,$d6,$03,$38,$03,$04,$18,$f9,$78,$fd,$2a	; 0x0b70
		db	$06,$80,$fd,$86,$12,$fd,$cb,$03,$7e,$fd,$21,$01,$00,$20,$29,$3e	; 0x0b80
		db	$03,$cd,a4l,a4h,$c1,$2a,$06,$80,$c5,$11,$84,$00,$19,$59,$cb,$3b	; 0x0b90
		db	$cb,$3b,$cb,$3b,$16,$00,$3e,$09,$90,$4f,$06,$00,$09,$fd,$21,$01	; 0x0ba0
		db	$00,$3e,$04,$cd,a4l,a4h,$18,$21,$cb,$2f,$cb,$2f,$cb,$2f,$fe,$03	; 0x0bb0
		db	$30,$17,$57,$d5,$e5,$3e,$03,$cd,a4l,a4h,$e1,$11,$68,$00,$19,$d1	; 0x0bc0
		db	$fd,$21,$01,$00,$3e,$04,$cd,a4l,a4h,$c1,$e1,$d1,$10,$86,$dd,$e1	; 0x0bd0
		db	$d9,$dd,$56,$03,$dd,$5e,$02,$dd,$46,$05,$dd,$4e,$04,$d9,$dd,$e5	; 0x0be0
		db	$e1,$fd,$2a,$06,$80,$fd,$7e,$04,$87,$4f,$06,$00,$11,$06,$00,$19	; 0x0bf0
		db	$09,$5e,$23,$56,$2a,$06,$80,$01,$7c,$00,$09,$e5,$c5,$01,$05,$00	; 0x0c00
		db	$7a,$fe,$70,$30,$05,$cd,a2l,a2h,$18,$03,$eb,$ed,$b0,$fd,$2a,$06	; 0x0c10
		db	$80,$c1,$fd,$09,$fd,$7e,$04,$fd,$2a,$06,$80,$fd,$77,$02,$d1,$2a	; 0x0c20
		db	$06,$80,$01,$64,$00,$09,$06,$04,$1a,$dd,$be,$01,$d5,$30,$16,$d9	; 0x0c30
		db	$87,$87,$87,$6f,$26,$00,$09,$e5,$d9,$d1,$eb,$c5,$01,$08,$00,$ed	; 0x0c40
		db	$b0,$c1,$eb,$18,$30,$dd,$96,$01,$d9,$87,$87,$87,$6f,$26,$00,$19	; 0x0c50
		db	$e5,$d9,$d1,$7a,$fe,$70,$30,$14,$c5,$e5,$d5,$01,$08,$00,$cd,a2l	; 0x0c60
		db	a2h,$01,$08,$00,$e1,$09,$eb,$e1,$09,$c1,$18,$09,$eb,$c5,$01,$08	; 0x0c70
		db	$00,$ed,$b0,$c1,$eb,$d1,$13,$10,$af,$fd,$2a,$06,$80,$ed,$5b,$06	; 0x0c80
		db	$80,$21,$1c,$00,$19,$fd,$4e,$00,$06,$00,$09,$e5,$dd,$e1,$21,$64	; 0x0c90
		db	$00,$19,$e5,$3e,$10,$08,$e1,$56,$23,$e5,$01,$0f,$00,$09,$5e,$eb	; 0x0ca0
		db	$fd,$46,$01,$af,$05,$fa,$bc,$0c,$29,$17,$18,$f8,$5f,$cd,$2f,$0e	; 0x0cb0
		db	$fd,$7e,$00,$3c,$fd,$77,$00,$fe,$08,$28,$04,$fe,$10,$20,$05,$01	; 0x0cc0
		db	$10,$00,$dd,$09,$dd,$23,$08,$3d,$28,$03,$08,$18,$c9,$e1,$fd,$cb	; 0x0cd0
		db	$03,$7e,$20,$1f,$2a,$06,$80,$01,$84,$00,$09,$fd,$56,$02,$fd,$cb	; 0x0ce0
		db	$03,$4e,$20,$04,$0e,$0f,$18,$02,$0e,$00,$06,$09,$7e,$a1,$b2,$77	; 0x0cf0
		db	$23,$10,$f9,$fd,$7e,$05,$fd,$cb,$04,$7e,$28,$02,$c6,$09,$4f,$2a	; 0x0d00
		db	$06,$80,$11,$13,$00,$19,$06,$09,$77,$3c,$23,$10,$fb,$fd,$cb,$03	; 0x0d10
		db	$7e,$20,$73,$59,$16,$00,$2a,$06,$80,$01,$1c,$00,$09,$fd,$21,$09	; 0x0d20
		db	$00,$3e,$03,$cd,$be,$1f,$fd,$2a,$06,$80,$2a,$06,$80,$01,$84,$00	; 0x0d30
		db	$09,$dd,$2a,$06,$80,$01,$13,$00,$dd,$09,$06,$09,$dd,$7e,$00,$dd	; 0x0d40
		db	$23,$cb,$3f,$cb,$3f,$cb,$3f,$5f,$16,$00,$c5,$3e,$09,$90,$06,$00	; 0x0d50
		db	$fe,$03,$38,$05,$d6,$03,$04,$18,$f7,$fd,$86,$11,$fe,$20,$30,$17	; 0x0d60
		db	$78,$fd,$86,$12,$fe,$18,$30,$0f,$dd,$e5,$e5,$3e,$04,$fd,$21,$01	; 0x0d70
		db	$00,$cd,$be,$1f,$e1,$dd,$e1,$c1,$23,$13,$05,$78,$fe,$00,$20,$bc	; 0x0d80
		db	$fd,$2a,$06,$80,$18,$54,$06,$00,$c5,$79,$80,$80,$80,$4f,$21,$00	; 0x0d90
		db	$00,$11,$18,$00,$78,$3d,$fa,$ac,$0d,$19,$18,$f9,$fd,$2a,$06,$80	; 0x0da0
		db	$fd,$7e,$12,$80,$fe,$18,$30,$2b,$cb,$3f,$cb,$3f,$cb,$3f,$57,$59	; 0x0db0
		db	$d5,$01,$1c,$00,$09,$ed,$4b,$06,$80,$09,$e5,$fd,$21,$03,$00,$3e	; 0x0dc0
		db	$03,$cd,$be,$1f,$e1,$11,$68,$00,$19,$d1,$fd,$21,$03,$00,$3e,$04	; 0x0dd0
		db	$cd,$be,$1f,$c1,$04,$78,$fe,$03,$20,$ae,$fd,$2a,$06,$80,$fd,$46	; 0x0de0
		db	$06,$78,$fe,$80,$28,$21,$fd,$4e,$07,$fd,$66,$11,$fd,$6e,$12,$b7	; 0x0df0
		db	$ed,$42,$28,$13,$2a,$06,$80,$11,$08,$00,$19,$fd,$5e,$06,$fd,$56	; 0x0e00
		db	$07,$01,$03,$03,$cd,$0b,$08,$fd,$2a,$06,$80,$2a,$06,$80,$11,$13	; 0x0e10
		db	$00,$19,$fd,$5e,$11,$fd,$56,$12,$01,$03,$03,$cd,$0b,$08,$c9,$fd	; 0x0e20
		db	$cb,$03,$46,$20,$16,$dd,$b6,$00,$dd,$77,$00,$7c,$dd,$b6,$08,$dd	; 0x0e30
		db	$77,$08,$7d,$dd,$b6,$10,$dd,$77,$10,$18,$14,$b7,$28,$03,$dd,$77	; 0x0e40
		db	$00,$7c,$b7,$28,$03,$dd,$77,$08,$7d,$b7,$28,$03,$dd,$77,$10,$fd	; 0x0e50
		db	$cb,$03,$7e                                                    	; 0x0e60

; ----------------------------------------------------------------------------------------------

	IF BIT90 && !V30
		; 0x0e63
		ret	z
		push	ix
		ld	bc,$0068
		add	ix,bc
		ld	b,(iy+$02)
		bit	1,(iy+$03)
		jr	nz,@r_0e78
		ld	c,$0f
		jr	@r_0e7a
@r_0e78:	ld	c,$00
@r_0e7a:	ld	a,e
		or	a
		jr	z,@r_0e86
		ld	a,(ix+$00)
		and	c
		or	b
		ld	(ix+$00),a
@r_0e86:	ld	a,h
		or	a
		jr	z,@r_0e92
		ld	a,(ix+$08)
		and	c
		or	b
		ld	(ix+$08),a
@r_0e92:	ld	a,l
		or	a
		jr	z,@r_0e9e
		ld	a,(ix+$10)
		and	c
		or	b
		ld	(ix+$10),a
@r_0e9e:	pop	ix
		ret
		db	$00
	ELSE ; V30 / Coleco
		db	            $28,$3c,$dd,$e5,$01,$68,$00,$dd,$09,$fd,$46,$02,$fd	; 0x0e63
		db	$cb,$03,$4e,$20,$04,$0e,$0f,$18,$02,$0e,$00,$7b,$b7,$28,$08,$dd	; 0x0e70
		db	$7e,$00,$a1,$b0,$dd,$77,$00,$7c,$b7,$28,$08,$dd,$7e,$08,$a1,$b0	; 0x0e80
		db	$dd,$77,$08,$7d,$b7,$28,$08,$dd,$7e,$10,$a1,$b0,$dd,$77,$10,$dd	; 0x0e90
		db	$e1,$c9                                                        	; 0x0ea0
	ENDIF	
		
; ----------------------------------------------------------------------------------------------

lab_0ea2:	db	        $c5,$d9,$dd,$66,$03,$dd,$6e,$02,$7e,$23,$4e,$23,$46,$23	; 0x0ea2
		db	$5e,$23,$56,$d9,$87,$87,$5f,$16,$00,$23,$19,$4e,$23,$46,$23,$5e	; 0x0eb0
		db	$23,$56,$60,$69,$c1,$79,$48,$cb,$3f,$cb,$3f,$cb,$3f,$cb,$3f,$47	; 0x0ec0
		db	$c5,$dd,$e5,$e5,$d5,$dd,$6e,$04,$dd,$66,$05,$dd,$23,$dd,$23,$23	; 0x0ed0
		db	$23,$5e,$23,$56,$d5,$fd,$e1,$d1,$e1,$7e,$fd,$cb,$00,$7e,$28,$02	; 0x0ee0
		db	$cb,$ff,$fd,$77,$00,$23,$1a,$d9,$6f,$26,$00,$09,$fd,$75,$01,$fd	; 0x0ef0
		db	$74,$02,$d9,$13,$1a,$d9,$6f,$26,$00,$19,$fd,$75,$03,$fd,$74,$04	; 0x0f00
		db	$d9,$13,$10,$bf,$fd,$e1,$01,$04,$00,$fd,$09,$d1,$fd,$6e,$00,$fd	; 0x0f10
		db	$66,$01,$fd,$23,$fd,$23,$e5,$dd,$e1,$fd,$e5,$d5,$43,$cd,a5l,a5h	; 0x0f20
		db	$d1,$fd,$e1,$15,$20,$e6,$c9,$2a,$d3,v63,$cb,$6e,$cc,$49,$0f,$cb	; 0x0f30
		db	$66                                                            	; 0x0f40
TIME_MGR_	equ	$0f37	; <-- TIME_MGR
		
	IF BIT90 && !V30
		; optimized code
		ret	nz
		inc	hl
		inc	hl
		inc	hl
		jr	$0f3a
		ret
		db	$00
	ELSE
		jr	nz,@r_0f48
		inc	hl
		inc	hl
		inc	hl
		jr	$0f3a
@r_0f48:	ret
	ENDIF
		
; ----------------------------------------------------------------------------------------------
	
		db	                                    $e5,$cb,$5e,$28,$2b,$cb,$76	; 0x0f49
		db	$20,$0d,$23,$5e,$23,$56,$1b,$7b,$b2,$20,$34,$e1,$e5,$18,$2c,$23	; 0x0f50
		db	$5e,$23,$56,$eb,$5e,$23,$56,$1b,$7b,$b2,$20,$23,$23,$5e,$23,$56	; 0x0f60
		db	$2b,$2b,$72,$2b,$73,$e1,$e5,$18,$12,$23,$35,$20,$10,$e1,$e5,$cb	; 0x0f70
		db	$76,$28,$08,$23,$23,$7e,$2b,$77,$2b,$e1,$e5,$cb,$fe,$e1,$c9,$72	; 0x0f80
		db	$2b,$73,$18,$f9,$02,$00,$02,$00,$02,$00,$01,$94,$0f,$11,$ba,v63	; 0x0f90
		db	$cd,$98,$00,$2a,$ba,v63,$ed,$5b,$bc,v63,$22,$d3,v63,$36,$30,$eb	; 0x0fa0
		db	$22,$d5,v63,$c9,$01,$00,$01,$00,$01,$b4,$0f,$11,$be,v63,$cd,$98	; 0x0fb0
		db	$00,$3a,$be,v63,$4f,$2a,$d3,v63,$47,$11,$03,$00,$b7            	; 0x0fc0
INIT_TIMERQ	equ	$0f9a	; <-- INIT_TIMERP
INIT_TIMER_	equ	$0faa	; <-- INIT_TIMER
FREE_SIGNALQ	equ	$0fb8	; <-- FREE_SIGNALP
FREE_SIGNAL_	equ	$0fc4	; <-- FREE_SIGNAL

; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
		; FREE_SIGNAL
		; ..
		; 0x0fcd optimized code
		jr	z,@r_0fd6
@r_0fcf:	bit	4,(hl)
		ret	nz
		add	hl,de
		dec	c
		jr	nz,@r_0fcf
@r_0fd6:	bit	5,(hl)
		ret	nz
		set	5,(hl)
		bit	6,(hl)
		ret	z
		bit	3,(hl)
		ret	z
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		push	de
		ld	hl,(var_63d3)
		push	hl
@r_0fea:	bit	4,(hl)
		jr	nz,@r_101b
		bit	5,(hl)
		jr	nz,@r_1014
		ld	a,(hl)
		and	$48
		cp	$48
		jr	nz,@r_1014
		inc	hl
		inc	hl
		ld	a,(hl)
		cp	d
		jr	c,@r_1014
		jr	nz,@r_1008
		dec	hl
		ld	a,(hl)
		cp	e
		jr	c,@r_1014
		ret	z
		inc	hl
@r_1008:	ld	d,(hl)
		dec	hl
		ld	e,(hl)
		dec	de
		dec	de
		dec	de
		dec	de
		ld	(hl),e
		inc	hl
		ld	(hl),d
		jr	@r_1014
@r_1014:	pop	hl
		inc	hl
		inc	hl
		inc	hl
		push	hl
		jr	@r_0fea
@r_101b:	ld	b,$00
		or	a
		pop	hl
		pop	de
		push	hl
		ld	hl,(var_63d5)
		sbc	hl,de
		ld	c,l
		ld	l,e
		ld	h,d
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		ldir
		ld	bc,$0008
		sbc	hl,bc
		ld	(var_63d5),hl
		pop	hl
		ret
		db	$31,$32,$33,$34,$35
	ELSE
		; 0x0fcd Coleco
		ALIGN	$103e
	ENDIF
		
; ----------------------------------------------------------------------------------------------

	IF V30 || V31
		; bug: keyboard key 6 mapped to keypad 7
		kp6	equ	$07
	ELSE
		kp6	equ	$06
	ENDIF
		db	                                                        $02,$00	; 0x103e
		db	$01,$00,$02,$00,$01,$3e,$10,$11,$bf,v63,$cd,$98,$00,$2a,$c0,v63	; 0x1040
		db	$3a,$bf,v63,$4f,$eb,$2a,$d3,v63,$af,$47,$cb,$6e,$28,$3e,$e5,$7e	; 0x1050
		db	$e6,$10,$f6,$20,$77,$af,$b2,$20,$0b,$b1,$28,$02,$cb,$f6,$23,$73	; 0x1060
		db	$23,$73,$18,$42,$cb,$de,$79,$b7,$28,$1b,$d5,$eb,$2a,$d5,v63,$eb	; 0x1070
		db	$cb,$f6,$23,$73,$23,$72,$eb,$d1,$73,$23,$72,$23,$73,$23,$72,$23	; 0x1080
		db	$22,$d5,v63,$18,$21,$23,$73,$23,$72,$23,$18,$1a,$cb,$66,$20,$06	; 0x1090
		db	$23,$23,$23,$04,$18,$b4,$d5,$e5,$23,$23,$23,$04,$36,$30,$eb,$e1	; 0x10a0
		db	$cb,$a6,$eb,$d1,$18,$a4,$e1,$cb,$ae,$78,$c9,$01,$00,$01,$00,$01	; 0x10b0
		db	$bb,$10,$11,$c2,v63,$cd,$98,$00,$3a,$c2,v63,$4f,$2a,$d3,v63,$47	; 0x10c0
		db	$11,$03,$00,$b7,$28,$08,$cb,$66,$20,$0c,$19,$0d,$20,$f8,$cb,$6e	; 0x10d0
		db	$20,$04,$cb,$7e,$20,$03,$af,$18,$0a,$cb,$76,$20,$02,$cb,$ee,$cb	; 0x10e0
		db	$be,$3e,$01,$b7,$c9,$0f,kp6,$01,$03,$09,$00,$0a,$0f,$02,$0b,$07	; 0x10f0
		db	$0f,$05,$04,$08,$0f                                            	; 0x1100
REQUEST_SIGNALQ	equ	$1044	; <-- REQUEST_SIGNALP
REQUEST_SIGNAL_	equ	$1053	; <-- REQUEST_SIGNAL
dat_10f5	equ	$10f5
TEST_SIGNALQ	equ	$10bf	; <-- TEST_SIGNALP
TEST_SIGNAL_	equ	$10cb	; <-- TEST_SIGNAL

; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
; optimized code uses hl instead of ix/iy
; CONTROLLER_INIT
lab_1105:	out	(STRB_RST_PORT),a
		ld	hl,(CONTROLLER_MAP)
		inc	hl
		inc	hl
		ld	b,$0a
		xor	a
@r_110f:	ld	(hl),a
		inc	hl
		djnz	@r_110f
		ld	hl,var_63d7
		ld	b,$16
@r_1118:	ld	(hl),a
		inc	hl
		djnz	@r_1118
		inc	hl
		ld	b,$04
@r_111f:	ld	(hl),a
		inc	hl
		djnz	@r_111f
		ret
		; filler
		db	$31,$32,$33,$34,$35,$36,$37,$38,$39,$30
		db	$31,$32,$33
	  IFDEF V30
lab_1131:	call	fun_1aa9
		ld	a,l
		cp	$75
		ret	nz
		ld	l,$0f
		ret
	  ELSE
		db	$34,$35,$36,$37,$38,$39,$30,$31,$32,$33
	  ENDIF
	ELSE
		; 0x1105 Coleco
		db	                    $d3,$c0,$af,$dd,$2a,$08,$80,$dd,$23,$dd,$23	; 0x1105
		db	$fd,$21,$d7,$73,$06,$0a,$dd,$77,$00,$dd,$23,$fd,$77,$00,$fd,$23	; 0x1110
		db	$fd,$77,$00,$fd,$23,$05,$20,$ee,$32,$eb,$73,$32,$ec,$73,$32,$ee	; 0x1120
		db	$73,$32,$ef,$73,$32,$f0,$73,$32,$f1,$73,$c9                    	; 0x1130
	ENDIF

; ----------------------------------------------------------------------------------------------

; delay
fun_113b:	nop
		ret

fun_113d:	ld	a,h
		cp	$00
		jr	nz,@r_1146
		in	a,(CTRL_0_PORT)
		jr	@r_1148
@r_1146:	in	a,(CTRL_1_PORT)
@r_1148:	cpl
		ret

; ----------------------------------------------------------------------------------------------
; 0x114a <-- CONTROLLER_SCAN
CONT_SCAN:	
		in	a,(CTRL_0_PORT)		; read segment 0, both players (joystick)
		cpl
		ld	(var_63ee),a		; segment 0 data, controller port #1
		in	a,(CTRL_1_PORT)
		cpl
		ld	(var_63ef),a		; segment 0 data, controller port #2
		out	(STRB_SET_PORT),a	; strobe segment 1
		call	fun_113b		; delay
		in	a,(CTRL_0_PORT)		; read segment 1, both players (keypad)
		cpl
		ld	(var_63f0),a		; segment 1 data, controller port #1
		in	a,(CTRL_1_PORT)
		cpl
		ld	(var_63f1),a		; segment 1 data, controller port #2
		out	(STRB_RST_PORT),a
	IFDEF BIT90
		; extra code for keyboard input
		ld	hl,var_73ee		
		ld	a,(hl)
		inc	hl
		add	a,(hl)
		inc	hl
		add	a,(hl)
		inc	hl
		add	a,(hl)
		and	$7f			; controller input?
		jp	z,lab_1946		; z=no, check keyboard input
		ret
		db	$00,$00

; Subroutine
lab_117b:	ld	hl,dat_10f5
		ld	b,$00
		ld	c,a
		add	hl,bc
		ld	l,(hl)
		ld	a,d
		and	$40
		ld	h,a
		jp	lab_0083
		ret
	ELSE
		; 0x1169 Coleco
		ret
		
; 0x116a <-- UPDATE_SPINNER		
UPDATE_SPINNER_:
		in	a,(CTRL_0_PORT)
		ld	hl,var_73eb
		bit	4,a
		jr	nz,@r_117b
		bit	5,a
		jr	nz,@r_117a
		dec	(hl)
		jr	@r_117b
@r_117a:	inc	(hl)
@r_117b:	in	a,(CTRL_1_PORT)
		bit	4,a
		jr	nz,@r_118a
		inc	hl
		bit	5,a
		jr	nz,@r_1189
		dec	(hl)
		jr	@r_118a
@r_1189:	inc	(hl)
@r_118a:	ret
	ENDIF	

; ----------------------------------------------------------------------------------------------

; 0x118b <-- DECODER
; Input  H: 0=left, 1=right
;        L: 0=left fire, 1=right fire
; Output H: fire button status in bit 5
;        L: joystick directions or keycode
;        E: old pulse counter (only if L=0)
DECODER_:
	IFDEF BIT90
		push	hl
		ld	a,$01
		cp	l
		jr	z,@r_11b5
		ld	bc,var_63eb
		xor	a
		cp	h
		jr	z,@r_1199
		inc	bc
@r_1199:	ld	a,(bc)
		ld	e,a
		xor	a
		ld	(bc),a
		call	fun_113d
		ld	d,a
		and	$0f
		ld	l,a
		ld	a,d
		and	$40
		ld	h,a
		xor	a
		cp	l
		jr	nz,@r_11b3
		cp	h
		jr	nz,@r_11b3
		pop	hl
		jp	lab_0199	; check keyboard for keypad keys
@r_11b3:	pop	bc
		ret
@r_11b5:	out	(STRB_SET_PORT),a
		call	fun_113d
		ld	d,a
		out	(STRB_RST_PORT),a
		and	$0f
		jr	lab_117b	; check keyboard for joystick keys
	ELSE ; Coleco
		ld	a,l
		cp	$01
		jr	z,@r_11aa
		ld	bc,var_63eb
		ld	a,h
		cp	$00
		jr	z,@r_1199
		inc	bc
@r_1199:	ld	a,(bc)
		ld	e,a
		xor	a
		ld	(bc),a
		call	fun_113d
		ld	d,a
		and	$0f
		ld	l,a
		ld	a,d
		and	$40
		ld	h,a
		jr	@r_11c0
		;
@r_11aa:	out	(STRB_SET_PORT),a
		call	fun_113d
		ld	d,a
		out	(STRB_RST_PORT),a
		and	$0f
		ld	hl,dat_10f5
		ld	b,$00
		ld	c,a
		add	hl,bc
		ld	l,(hl)
		ld	a,d
		and	$40
		ld	h,a
@r_11c0:	ret
	ENDIF

; ----------------------------------------------------------------------------------------------
; 0x11c1 <-- POLLER
POLLER_:	call	CONT_SCAN
		ld	iy,var_63d7
		ld	ix,(CONTROLLER_MAP)
		push	ix
		ld	a,(ix+$00)
		bit	7,a
		jr	z,@r_11f3
		ld	b,a
		ld	de,$0002
		add	ix,de
		and	$07
		jr	z,@r_11e8
		ld	a,(var_63ee)
		ld	hl,var_63eb
		call	fun_1220
@r_11e8:	ld	a,b
		and	$18
		jr	z,@r_11f3
		ld	a,(var_63f0)
		call	fun_123f
@r_11f3:	pop	ix
		ld	a,(ix+$01)
		bit	7,a
	IFDEF BIT90
		; 0x11fa Optimized code
		ret	z
		ld	b,a
		ld	de,$000a
		add	iy,de
		ld	de,$0007
		add	ix,de
		and	$07
		jr	z,@r_1213
		ld	a,(var_63ef)
		ld	hl,var_63ec
		call	fun_1220
@r_1213:	ld	a,b
		and	$18
		ret	z
		ld	a,(var_63f1)
		call	fun_123f
		ret
		db	$00,$00
	ELSE
		; 0x11fa Coleco
		jr	z,@r_121f
		ld	b,a
		ld	de,$000a
		add	iy,de
		ld	de,$0007
		add	ix,de
		and	$07
		jr	z,@r_1214
		ld	a,(var_63ef)
		ld	hl,var_63ec
		call	fun_1220
@r_1214:	ld	a,b
		and	$18
		jr	z,@r_121f
		ld	a,(var_63f1)
		call	fun_123f
@r_121f:	ret
	ENDIF
	
; ----------------------------------------------------------------------------------------------

; DECODE_0
fun_1220:	ld	c,a
		bit	1,b
		jr	z,@r_1229
		call	fun_12b9
		ld	a,c
@r_1229:	bit	0,b
		jr	z,@r_1231
		call	fun_1289
		ld	a,c
@r_1231:	bit	2,b
	IFDEF BIT90
		ret	z
		ld	a,(hL)
		add	a,(ix+$02)
		ld	(ix+$02),a
		xor	a
		ld	(hl),a
		ret
		db	$00
		
fun_123f:	ld	c,a
		bit	3,b
		jr	z,@r_1248
		call	fun_12e9
		ld	a,c
@r_1248:	bit	4,b
		ret	z
		call	fun_1250
		ret
		db	$00
	ELSE
		jr	z,@r_123e
		ld	a,(hl)
		add	a,(ix+$02)
		ld	(ix+$02),a
		xor	a
		ld	(hl),a
@r_123e:	ret

; DECODE_1
fun_123f:	ld	c,a
		bit	3,b
		jr	z,@r_1248
		call	fun_12e9
		ld	a,c
@r_1248:	bit	4,b
		jr	z,@r_124f
		call	fun_1250
@r_124f:	ret
	ENDIF
	
; ----------------------------------------------------------------------------------------------
		
fun_1250:	db	$c5,$d5,$e5,$e6,$0f,$5f,$fd,$46,$08,$fd,$7e,$09,$fe,$00,$20,$1a	; 0x1250
		db	$7b,$b8,$28,$05,$fd,$73,$08,$18,$1c,$3e,$01,$fd,$77,$09,$21,$f5	; 0x1260
		db	$10,$16,$00,$19,$7e,$dd,$77,$04,$18,$0b,$7b,$b8,$28,$07,$fd,$73	; 0x1270
		db	$08,$af,$fd,$77,$09,$e1,$d1,$c1,$c9,$c5,$d5,$e6,$40,$5f,$fd,$46	; 0x1280
		db	$00,$fd,$7e,$01,$fe,$00,$20,$13,$7b,$b8,$28,$05,$fd,$73,$00,$18	; 0x1290
		db	$15,$3e,$01,$fd,$77,$01,$dd,$73,$00,$18,$0b,$7b,$b8,$28,$07,$fd	; 0x12a0
		db	$73,$00,$af,$fd,$77,$01,$d1,$c1,$c9,$c5,$d5,$e6,$0f,$5f,$fd,$46	; 0x12b0
		db	$02,$fd,$7e,$03,$fe,$00,$20,$13,$7b,$b8,$28,$05,$fd,$73,$02,$18	; 0x12c0
		db	$15,$3e,$01,$fd,$77,$03,$dd,$73,$01,$18,$0b,$7b,$b8,$28,$07,$fd	; 0x12d0
		db	$73,$02,$af,$fd,$77,$03,$d1,$c1,$c9,$c5,$d5,$e6,$40,$5f,$fd,$46	; 0x12e0
		db	$06,$fd,$7e,$07,$fe,$00,$20,$13,$7b,$b8,$28,$05,$fd,$73,$06,$18	; 0x12f0
		db	$15,$3e,$01,$fd,$77,$07,$dd,$73,$03,$18,$0b,$7b,$b8,$28,$07,$fd	; 0x1300
		db	$73,$06,$af,$fd,$77,$07,$d1,$c1,$c9                            	; 0x1310
fun_1289	equ	$1289
fun_12b9	equ	$12b9
fun_12e9	equ	$12e9	
	
; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
; POWER_UP continued
lab_1319:	xor	a
		ld	hl,$0000
		ld	de,$4000
		call	FILL_VRAM_
		call	MODE_1_
		call	LOAD_ASCII_
		; Display "BIT90" logo
		ld	hl,dat_14e2
		ld	de,$0300
		ld	bc,$0018
		call	VRAM_WRITE
		ld	hl,dat_14ca
		ld	de,$0340
		ld	bc,$0018
		call	VRAM_WRITE
		ld	hl,dat_14e2
		ld	de,$0380
		ld	bc,$0018
		call	VRAM_WRITE
		ld	hl,dat_14f2
		ld	de,$03c0
		ld	bc,$0030
		call	VRAM_WRITE
		ld	hl,dat_1522
		ld	de,$0400
		ld	bc,$0030
		call	VRAM_WRITE
		ld	hl,dat_1552
		ld	de,$0440
		ld	bc,$0030
		call	VRAM_WRITE
		ld	hl,dat_1490
		ld	de,$1889
		ld	bc,$0010
		call	VRAM_WRITE
		ld	hl,dat_14a0
		ld	de,$18a9
		ld	bc,$000d
		call	VRAM_WRITE
		ld	hl,dat_14ad
		ld	de,$18c9
		ld	bc,$000d
		call	VRAM_WRITE
		ld	hl,dat_1438
		ld	de,$190c
		ld	bc,$0008
		call	VRAM_WRITE
		ld	hl,dat_147e
		ld	de,$2000
		ld	bc,$0012
		call	VRAM_WRITE
		ld	b,$01
		ld	c,$c0
		call	REG_WRITE
		ld	b,$02
		; Detect rom cartridge
		ld	hl,CARTRIDGE
		ld	a,$55
@r_13bb:	cp	(hl)
		jr	z,@r_13fb
		ld	a,$aa
		djnz	@r_13bb
		;
		; Cartridge not detected, display BASIC title and start BASIC
		ld	hl,dat_1440		; text
		ld	de,$19a4		; vram position
		ld	bc,$0019		; length
		call	VRAM_WRITE
		ld	hl,dat_1459
		ld	de,$19e7
		ld	bc,$0012
		call	VRAM_WRITE
		ld	hl,dat_146b
		ld	de,$1a29
		ld	bc,$000c
		call	VRAM_WRITE
		ld	hl,dat_1911
		ld	de,$1aa8
		ld	bc,$0010
		call	VRAM_WRITE
	IF V30 || V31
		ld	hl,$1000		; set delay to appr. 12 seconds
	ELSE ; V32
		ld	hl,$0800		; set delay to appr. 6 seconds
	ENDIF	
		call	fun_196b		; delay loop
		jp	lab_3ffd		; select BASIC rom and reboot
		;
		; Cartridge detected, display cartridge title and start game
@r_13fb:	ld	hl,GAME_NAME
		push	hl
		call	fun_1422
		pop	hl
		ld	de,$1a01
		call	fun_142d
		ld	hl,GAME_NAME
		call	fun_1422
		inc	hl
		push	hl
		call	fun_1422
		pop	hl
		ld	de,$19c1
		call	fun_142d
		call	fun_1968
		ld	hl,(START_GAME)
		jp	(hl)			; start game
		
fun_1422:	ld	bc,$0000
@r_1425:	ld	a,(hl)
		cp	$2f
		ret	z
		inc	hl
		inc	bc
		jr	@r_1425
		
fun_142d:	ld	a,$20
		sub	c
		srl	a
		add	a,e
		ld	e,a
		call	VRAM_WRITE
		ret
		
		; BASIC title
dat_1438:	db	"COMPUTER"
dat_1440:	db	"WAIT FOR A MOMENT PLEASE,"
dat_1459:	db	"YOU CAN ENJOY WITH"
dat_146b:	db	"BIT90 BASIC."
		
dat_1477:	db	$00,$07,$36,$00,$80,$06,$80

		; vram data including "BIT90" color logo 
dat_147e:	db	                                                        $00,$00	; 0x147e
		db	$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$40,$70,$c0,$a0,$90,$60	; 0x1480
		db	$60,$68,$20,$70,$20,$78,$7b,$20,$80,$83,$20,$88,$8b,$20,$1e,$1f	; 0x1490
		db	$60,$69,$20,$70,$20,$79,$7c,$20,$81,$84,$20,$89,$8c,$61,$6a,$20	; 0x14a0
		db	$71,$20,$7a,$7d,$20,$82,$85,$20,$8a,$8d,$ff,$ff,$ff,$ff,$ff,$ff	; 0x14b0
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$70,$7c,$7e,$7f,$7f,$7f	; 0x14c0
		db	$7f,$7e,$7c,$70,$00,$70,$7c,$7e,$7f,$7f,$7f,$7f,$7e,$7c,$70,$00	; 0x14d0
		db	$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00	; 0x14e0
		db	$00,$00,$ef,$ef,$ef,$cf,$cf,$cf,$cf,$cf,$cf,$cf,$0f,$0f,$0f,$0f	; 0x14f0
		db	$0f,$0f,$0f,$0f,$0f,$0f,$0f,$00,$00,$00,$f7,$f7,$f7,$f3,$f3,$f3	; 0x1500
		db	$f3,$f3,$f3,$f3,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$00	; 0x1510
		db	$00,$00,$06,$1e,$3e,$7e,$fe,$fe,$fe,$fe,$7e,$3e,$1e,$06,$00,$10	; 0x1520
		db	$38,$7c,$fe,$fe,$7c,$39,$13,$00,$00,$00,$c0,$f0,$f8,$fc,$fe,$fe	; 0x1530
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fc,$f8,$f0,$c0,$00	; 0x1540
		db	$00,$00,$02,$0e,$1e,$3e,$7e,$7e,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe	; 0x1550
		db	$fe,$7e,$7e,$3e,$1e,$0e,$02,$00,$00,$00,$80,$e0,$f0,$f8,$fc,$fc	; 0x1560
		db	$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fc,$fc,$f8,$f0,$e0,$80,$00	; 0x1570
		db	$00,$00,$31,$32,$33,$34,$35,$36,$37,$38,$39,$7e,$81,$bd,$a1,$a1	; 0x1580
		db	$bd,$81,$7e,$1f,$04,$04,$04,$00,$00,$00,$00,$44,$6c,$54,$54,$00	; 0x1590
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                    	; 0x15a0
dat_1490	equ	$1490
dat_14a0	equ	$14a0
dat_14ad	equ	$14ad
dat_14ca	equ	$14ca
dat_14e2	equ	$14e2		
dat_14f2	equ	$14f2		
dat_1522	equ	$1522
dat_1552	equ	$1552
dat_158b	equ	$158b
dat_15a3	equ	$15a3

		; Font definitions (ASCII 33 to 127)
		; Different font than Coleco, also used in BASIC mode
	  IF V30 || V31
		db	                                            $00,$20,$20,$20,$20	; 0x15ab 33
		db	$20,$00,$20,$00,$50,$50,$50,$00,$00,$00,$00,$00,$50,$50,$f8,$50	; 0x15b0 35
		db	$f8,$50,$50,$00,$20,$78,$a0,$70,$28,$f0,$20,$00,$c0,$c8,$10,$20	; 0x15c0 37
		db	$40,$98,$18,$00,$40,$a0,$a0,$40,$a8,$90,$68,$00,$60,$60,$20,$40	; 0x15d0 39
		db	$00,$00,$00,$00,$20,$40,$80,$80,$80,$40,$20,$00,$20,$10,$08,$08	; 0x15e0 41
		db	$08,$10,$20,$00,$20,$a8,$70,$20,$70,$a8,$20,$00,$00,$20,$20,$f8	; 0x15f0 43
		db	$20,$20,$00,$00,$00,$00,$00,$00,$60,$60,$20,$00,$00,$00,$00,$f8	; 0x1600 45
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$60,$00,$00,$08,$10,$20	; 0x1610 47
		db	$40,$80,$00,$00,$70,$88,$98,$a8,$c8,$88,$70,$00,$20,$60,$20,$20	; 0x1620 49
		db	$20,$20,$70,$00,$70,$88,$08,$30,$40,$80,$f8,$00,$f8,$08,$10,$30	; 0x1630 51
		db	$08,$88,$70,$00,$10,$30,$50,$90,$f8,$10,$10,$00,$f8,$80,$f0,$08	; 0x1640 53
		db	$08,$88,$70,$00,$30,$40,$80,$f0,$88,$88,$70,$00,$f8,$08,$10,$20	; 0x1650 55 
		db	$40,$40,$40,$00,$70,$88,$88,$70,$88,$88,$70,$00,$70,$88,$88,$78	; 0x1660 57
		db	$08,$10,$e0,$00,$00,$30,$30,$00,$30,$30,$00,$00,$00,$30,$30,$00	; 0x1670 59
		db	$30,$30,$10,$00,$10,$20,$40,$80,$40,$20,$10,$00,$00,$00,$f8,$00	; 0x1680 61
		db	$f8,$00,$00,$00,$80,$40,$20,$10,$20,$40,$80,$00,$70,$88,$10,$20	; 0x1690 63
		db	$20,$00,$20,$00,$70,$88,$88,$b8,$b8,$80,$78,$00,$20,$50,$88,$88	; 0x16a0 65
		db	$f8,$88,$88,$00,$f0,$88,$88,$f0,$88,$88,$f0,$00,$70,$88,$80,$80	; 0x16b0 67
		db	$80,$88,$70,$00,$f0,$88,$88,$88,$88,$88,$f0,$00,$f8,$80,$80,$f0	; 0x16c0 69
		db	$80,$80,$f8,$00,$f8,$80,$80,$f0,$80,$80,$80,$00,$78,$80,$80,$b8	; 0x16d0 71
		db	$88,$88,$78,$00,$88,$88,$88,$f8,$88,$88,$88,$00,$70,$20,$20,$20	; 0x16e0 73
		db	$20,$20,$70,$00,$08,$08,$08,$08,$08,$88,$70,$00,$88,$90,$a0,$c0	; 0x16f0 75
		db	$a0,$90,$88,$00,$80,$80,$80,$80,$80,$80,$f8,$00,$88,$d8,$a8,$88	; 0x1700 77
		db	$88,$88,$88,$00,$88,$88,$c8,$a8,$98,$88,$88,$00,$70,$88,$88,$88	; 0x1710 79
		db	$88,$88,$70,$00,$f0,$88,$88,$f0,$80,$80,$80,$00,$70,$88,$88,$88	; 0x1720 81
		db	$a8,$90,$68,$00,$f0,$88,$88,$f0,$a0,$90,$88,$00,$70,$88,$80,$70	; 0x1730 83
		db	$08,$88,$70,$00,$f8,$20,$20,$20,$20,$20,$20,$00,$88,$88,$88,$88	; 0x1740 85
		db	$88,$88,$70,$00,$88,$88,$88,$88,$88,$50,$20,$00,$88,$88,$88,$a8	; 0x1750 87
		db	$a8,$d8,$88,$00,$88,$88,$50,$20,$50,$88,$88,$00,$88,$88,$50,$20	; 0x1760 89
		db	$20,$20,$20,$00,$f8,$08,$10,$20,$40,$80,$f8,$00,$f8,$80,$80,$80	; 0x1770 91
		db	$80,$80,$f8,$00,$00,$80,$40,$20,$10,$08,$00,$00,$f8,$08,$08,$08	; 0x1780 93
		db	$08,$08,$f8,$00,$00,$00,$20,$50,$88,$00,$00,$00,$00,$00,$00,$00	; 0x1790 95
		db	$00,$00,$f8,$00,$60,$60,$40,$20,$00,$00,$00,$00,$00,$00,$68,$98	; 0x17a0 97
		db	$88,$98,$69,$00,$80,$80,$b0,$c8,$88,$c8,$b0,$00,$00,$00,$78,$80	; 0x17b0 99
		db	$80,$80,$78,$00,$08,$08,$68,$98,$88,$98,$68,$00,$00,$00,$70,$88	; 0x17c0 101
		db	$f8,$80,$70,$00,$10,$28,$20,$f8,$20,$20,$20,$00,$68,$98,$98,$68	; 0x17d0 103
		db	$08,$08,$78,$00,$80,$80,$b0,$c8,$88,$88,$88,$00,$20,$00,$60,$20	; 0x17e0 105
		db	$20,$20,$70,$00,$10,$00,$10,$10,$10,$10,$60,$00,$80,$88,$90,$a0	; 0x17f0 107
		db	$e0,$90,$88,$00,$60,$20,$20,$20,$20,$20,$70,$00,$00,$00,$d0,$a8	; 0x1800 109
		db	$a8,$a8,$a8,$00,$00,$00,$f0,$88,$88,$88,$88,$00,$00,$00,$70,$88	; 0x1810 111
		db	$88,$88,$70,$00,$00,$b0,$c8,$c8,$b0,$80,$80,$00,$00,$68,$98,$98	; 0x1820 113
		db	$68,$08,$08,$00,$00,$00,$90,$a0,$c0,$80,$80,$00,$00,$00,$78,$80	; 0x1830 115
		db	$70,$08,$f0,$00,$20,$20,$70,$20,$20,$20,$30,$00,$00,$00,$88,$88	; 0x1840 117
		db	$88,$88,$78,$00,$00,$00,$88,$88,$88,$50,$20,$00,$00,$00,$88,$88	; 0x1850 119
		db	$a8,$a8,$50,$00,$00,$00,$88,$50,$20,$50,$88,$00,$00,$00,$90,$90	; 0x1860 121
		db	$f0,$10,$f0,$00,$00,$00,$f8,$10,$20,$40,$f8,$00,$20,$40,$40,$80	; 0x1870 123
		db	$40,$40,$20,$00,$20,$20,$20,$00,$20,$20,$20,$00,$20,$10,$10,$08	; 0x1880 125
		db	$10,$10,$20,$00,$00,$00,$08,$70,$80,$00,$00,$00,$00,$00,$00,$00	; 0x1890 127
		db	$00,$00,$00                                                    	; 0x18a0
	  ELSE ; V32
	  	; Align font to top, redefine some lowercase chars
		db	                                            $20,$20,$20,$20,$20	; 0x15ab
		db	$00,$20,$00,$50,$50,$50,$00,$00,$00,$00,$00,$50,$50,$f8,$50,$f8	; 0x15b0
		db	$50,$50,$00,$20,$78,$a0,$70,$28,$f0,$20,$00,$c0,$c8,$10,$20,$40	; 0x15c0
		db	$98,$18,$00,$40,$a0,$a0,$40,$a8,$90,$68,$00,$60,$60,$20,$40,$00	; 0x15d0
		db	$00,$00,$00,$20,$40,$80,$80,$80,$40,$20,$00,$20,$10,$08,$08,$08	; 0x15e0
		db	$10,$20,$00,$20,$a8,$70,$20,$70,$a8,$20,$00,$00,$20,$20,$f8,$20	; 0x15f0
		db	$20,$00,$00,$00,$00,$00,$00,$60,$60,$20,$00,$00,$00,$00,$f8,$00	; 0x1600
		db	$00,$00,$00,$00,$00,$00,$00,$00,$60,$60,$00,$00,$08,$10,$20,$40	; 0x1610
		db	$80,$00,$00,$70,$88,$98,$a8,$c8,$88,$70,$00,$20,$60,$20,$20,$20	; 0x1620
		db	$20,$70,$00,$70,$88,$08,$30,$40,$80,$f8,$00,$f8,$08,$10,$30,$08	; 0x1630
		db	$88,$70,$00,$10,$30,$50,$90,$f8,$10,$10,$00,$f8,$80,$f0,$08,$08	; 0x1640
		db	$88,$70,$00,$30,$40,$80,$f0,$88,$88,$70,$00,$f8,$08,$10,$20,$40	; 0x1650
		db	$40,$40,$00,$70,$88,$88,$70,$88,$88,$70,$00,$70,$88,$88,$78,$08	; 0x1660
		db	$10,$e0,$00,$00,$30,$30,$00,$30,$30,$00,$00,$00,$30,$30,$00,$30	; 0x1670
		db	$30,$10,$00,$10,$20,$40,$80,$40,$20,$10,$00,$00,$00,$f8,$00,$f8	; 0x1680
		db	$00,$00,$00,$80,$40,$20,$10,$20,$40,$80,$00,$70,$88,$10,$20,$20	; 0x1690
		db	$00,$20,$00,$70,$88,$88,$b8,$b8,$80,$78,$00,$20,$50,$88,$88,$f8	; 0x16a0
		db	$88,$88,$00,$f0,$88,$88,$f0,$88,$88,$f0,$00,$70,$88,$80,$80,$80	; 0x16b0
		db	$88,$70,$00,$f0,$88,$88,$88,$88,$88,$f0,$00,$f8,$80,$80,$f0,$80	; 0x16c0
		db	$80,$f8,$00,$f8,$80,$80,$f0,$80,$80,$80,$00,$78,$80,$80,$b8,$88	; 0x16d0
		db	$88,$78,$00,$88,$88,$88,$f8,$88,$88,$88,$00,$70,$20,$20,$20,$20	; 0x16e0
		db	$20,$70,$00,$08,$08,$08,$08,$08,$88,$70,$00,$88,$90,$a0,$c0,$a0	; 0x16f0
		db	$90,$88,$00,$80,$80,$80,$80,$80,$80,$f8,$00,$88,$d8,$a8,$88,$88	; 0x1700
		db	$88,$88,$00,$88,$88,$c8,$a8,$98,$88,$88,$00,$70,$88,$88,$88,$88	; 0x1710
		db	$88,$70,$00,$f0,$88,$88,$f0,$80,$80,$80,$00,$70,$88,$88,$88,$a8	; 0x1720
		db	$90,$68,$00,$f0,$88,$88,$f0,$a0,$90,$88,$00,$70,$88,$80,$70,$08	; 0x1730
		db	$88,$70,$00,$f8,$20,$20,$20,$20,$20,$20,$00,$88,$88,$88,$88,$88	; 0x1740
		db	$88,$70,$00,$88,$88,$88,$88,$88,$50,$20,$00,$88,$88,$88,$a8,$a8	; 0x1750
		db	$d8,$88,$00,$88,$88,$50,$20,$50,$88,$88,$00,$88,$88,$50,$20,$20	; 0x1760
		db	$20,$20,$00,$f8,$08,$10,$20,$40,$80,$f8,$00,$f8,$80,$80,$80,$80	; 0x1770
		db	$80,$f8,$00,$00,$80,$40,$20,$10,$08,$00,$00,$f8,$08,$08,$08,$08	; 0x1780
		db	$08,$f8,$00,$00,$00,$20,$50,$88,$00,$00,$00,$00,$00,$00,$00,$00	; 0x1790
		db	$00,$f8,$00,$60,$60,$40,$20,$00,$00,$00,$00,$00,$00,$70,$08,$78	; 0x17a0
		db	$88,$78,$00,$80,$80,$b0,$c8,$88,$c8,$b0,$00,$00,$00,$78,$80,$80	; 0x17b0
		db	$80,$78,$00,$08,$08,$68,$98,$88,$98,$68,$00,$00,$00,$70,$88,$f8	; 0x17c0
		db	$80,$70,$00,$10,$28,$20,$f8,$20,$20,$20,$00,$00,$00,$68,$98,$98	; 0x17d0
		db	$68,$08,$70,$80,$80,$b0,$c8,$88,$88,$88,$00,$20,$00,$60,$20,$20	; 0x17e0
		db	$20,$70,$00,$10,$00,$30,$10,$10,$10,$90,$60,$80,$80,$90,$a0,$c0	; 0x17f0
		db	$a0,$90,$00,$60,$20,$20,$20,$20,$20,$70,$00,$00,$00,$d0,$a8,$a8	; 0x1800
		db	$a8,$a8,$00,$00,$00,$b0,$c8,$88,$88,$88,$00,$00,$00,$70,$88,$88	; 0x1810
		db	$88,$70,$00,$00,$00,$b0,$c8,$c8,$b0,$80,$80,$00,$00,$68,$98,$98	; 0x1820
		db	$68,$08,$08,$00,$00,$b0,$c8,$80,$80,$80,$00,$00,$00,$78,$80,$70	; 0x1830
		db	$08,$f0,$00,$40,$40,$f0,$40,$40,$48,$30,$00,$00,$00,$90,$90,$90	; 0x1840
		db	$90,$68,$00,$00,$00,$88,$88,$88,$50,$20,$00,$00,$00,$88,$88,$a8	; 0x1850
		db	$a8,$50,$00,$00,$00,$88,$50,$20,$50,$88,$00,$00,$00,$88,$88,$98	; 0x1860
		db	$68,$08,$70,$00,$00,$f8,$10,$20,$40,$f8,$00,$20,$40,$40,$80,$40	; 0x1870
		db	$40,$20,$00,$20,$20,$20,$00,$20,$20,$20,$00,$20,$10,$10,$08,$10	; 0x1880
		db	$10,$20,$00,$00,$00,$08,$70,$80,$00,$00,$00,$00,$00,$00,$00,$00	; 0x1890
		db	$00,$00,$00                                                    	; 0x18a0
	  ENDIF
	ELSE 
		; 0x1319 Coleco
		ALIGN	$18a3
	ENDIF
		
; ----------------------------------------------------------------------------------------------

		db	            $01,$02,$0e,$0f,$08,$09,$12,$13,$03,$04,$0e,$0f,$05	; 0x18a3
		db	$14,$00,$00,$05,$00,$10,$11,$0a,$0b,$15,$16,$06,$07,$10,$11,$05	; 0x18b0
		db	$14,$00,$00,$01,$02,$0e,$0f,$03,$04,$0e,$0f,$03,$04,$0e,$0f,$0c	; 0x18c0
		db	$0d,$17,$18,$ff                                                	; 0x18d0

; 0x18d4 <-- FILL_VRAM
FILL_VRAM_:	ld	c,a
		ld	a,l
		out	(CTRL_PORT),a
		ld	a,h
		or	$40
		out	(CTRL_PORT),a
@r_18dd:	ld	a,c
		out	(DATA_PORT),a
		dec	de
		ld	a,d
		or	e
		jr	nz,@r_18dd
		call	READ_REGISTER
		ret
		
; ----------------------------------------------------------------------------------------------
		
; 0x18e9 <-- MODE_1
MODE_1_:
	IFDEF BIT90
		ld	hl,dat_1477
		ld	b,$07
		ld	e,$08
@r_18f0:	ld	c,(hl)
		call	REG_WRITE
		inc	hl
		dec	b
		dec	e
		nop
		nop
		jr	nz,@r_18f0
		ld	bc,$000c
		ld	hl,dat_1907
		ld	de,var_63f2
		ldir
		ret
		; vram data
dat_1907:	db	$00,$1b,$00,$38,$00,$18,$00,$00,$00,$20
dat_1911:	db	$1d,$20,$31,$39,$38,$33,$20,$42
		db	$49,$54,$20,$43,$4f,$52,$50,$2e
		; filler
		db	$31,$32,$33,$34,$35,$36

; 0x1927 <-- LOAD_ASCII
LOAD_ASCII_:	ld	hl,dat_158b
	IF V30 || V31
		ld	de,$00e8
		ld	bc,$0300
		call	VRAM_WRITE
		ld	hl,dat_15a3
		ld	de,$0000
		ld	bc,$0008
		call	VRAM_WRITE
		ret
		; filler
		db	$31,$32,$33,$34,$35,$36
	ELSE ; V32
		ld	de,$001d
		ld	iy,$0060
		ld	a,$03
		call	PUT_VRAM
		ld	hl,dat_15a3
		ld	de,$0000
		ld	iy,$0001
		ld	a,$03
		call	PUT_VRAM
		ret
	ENDIF

; check keyboard input	
lab_1946:	call	fun_092e
		ld	(var_73ee),a		; segment 0 data, controller port #1 (joystick) 
		ld	(var_73ef),a		; segment 0 data, controller port #2 (joystick)
		call	fun_1aa9
		ld	d,h
		ld	c,l
		ld	b,$00
		ld	hl,dat_02ca
		add	hl,bc
		ld	a,(hl)
		bit	6,d
		jr	z,@r_1961
		set	6,a
@r_1961:	ld	(var_73f0),a		; segment 1 data, controller port #1 (keypad)
		ld	(var_73f1),a		; segment 1 data, controller port #2 (keypad)
		ret
		
fun_1968:
	IF V30 || V31
		ld	hl,$1000		; set delay to appr. 12 seconds
	ELSE ; V32
		ld	hl,$0800		; set delay to appr. 6 seconds
	ENDIF	
; delay loop
fun_196b:	ld	bc,$00ff
@r_196e:	dec	bc
		ld	a,b
		or	c
		jr	nz,@r_196e
		dec	hl
		ld	a,h
		or	l
		jr	nz,fun_196b
		ret
		
; 0x1979 <-- GAME_OPT
GAME_OPT_:	xor	a
		ld	de,$4000
		ld	hl,$0000
		call	FILL_VRAM_
		call	MODE_1_
		ld	b,$07
		ld	c,$0b
		call	REG_WRITE
		call	LOAD_ASCII_
		ld	hl,dat_1a21
		ld	de,$1825
		ld	bc,$0016
		call	VRAM_WRITE
		ld	hl,dat_1a37
		ld	de,$1865
		ld	bc,$0017
		call	VRAM_WRITE
		ld	a,$04
		ld	de,$18c5
		call	fun_1a72
		ld	a,$04
		ld	de,$19e5
		call	fun_1a72
		ld	iy,dat_1a64
		ld	hl,$1905
		ld	b,$03
		call	fun_1a88
		ld	iy,dat_1a64
		ld	hl,$190f
		ld	b,$03
		call	fun_1a88
		ld	iy,dat_1a64
		ld	hl,$1a2f
		ld	b,$03
		call	fun_1a88
		ld	iy,dat_1a67
		ld	hl,$19e5
		ld	b,$04
		call	fun_1a88
		ld	hl,$19fb
		ld	iy,dat_1a6e
		ld	b,$04
		call	fun_1a88
		ld	a,$04
		ld	de,$19f1
@r_19f9:	push	de
		push	af
		ld	bc,$0003
		ld	hl,dat_1a6b
		call	VRAM_WRITE
		pop	af
		pop	hl
		ld	de,$0040
		add	hl,de
		ex	de,hl
		dec	a
		jr	nz,@r_19f9
		ld	hl,$2000
		ld	de,$0020
		ld	a,$1b
		call	FILL_VRAM_
		ld	b,$01
		ld	c,$c0
		call	REG_WRITE
		ret
		
dat_1a21:	db	"TO SELECT GAME OPTION,"
dat_1a37:	db	"PRESS BUTTON ON KEYPAD."
dat_1a4e:	db	"1 = LEVEL 1/ONE PLAYER"
dat_1a64:	db	"234"
dat_1a67:	db	"5678"
dat_1a6b:	db	"TWO"
dat_1a6e:	db	"SSSS"
		
fun_1a72:	push	de
		push	af
		ld	bc,$0016
		ld	hl,dat_1a4e
		call	VRAM_WRITE
		pop	af
		pop	hl
		ld	de,$0040
		add	hl,de
		ex	de,hl
		dec	a
		jr	nz,fun_1a72
		ret
		
fun_1a88:	ld	a,(iy+$00)
		ld	de,$0001
		call	FILL_VRAM_
		ld	de,$0040
		add	hl,de
		inc	iy
		djnz	fun_1a88
		ret
		; filler
		db	$31,$32,$33,$34,$35,$36,$37,$38,$39,$30
		db	$31,$32,$33,$34,$35

; get keyboard key and convert to controller keypad / right fire code
fun_1aa9:	call	lab_3ff7		; get keyboard input
		ld	hl,dat_005a
		ld	bc,$000c
		cpir
		ld	l,$75
		jr	nz,@r_1ac3
		cp	$02
		jr	nz,@r_1ac2
		ld	a,e
		and	a
		jr	z,@r_1ac2
		ld	c,$03
@r_1ac2:	ld	l,c
@r_1ac3:	ld	h,$00
		ld	a,e
		cp	$02			; [BASIC] key pressed?
		ret	nz
		ld	h,$40			; yes, set right fire flag
		ret

; POWER_UP (BIT90)
lab_1acc:	ld	hl,var_7000		; warm boot flag "BIT90"
		ld	a,'B'
		cpi
	  IF V30 || V31
		jp	nz,lab_006e
		ld	a,'I'
		cpi
		jp	nz,lab_006e
		ld	a,'T'
		cpi
		jp	nz,lab_006e
		ld	a,'9'
		cpi
		jp	nz,lab_006e
		ld	a,'0'
		cpi
		jp	nz,lab_006e
		jp	lab_3ffd		; select BASIC rom and reboot
		; filler
		db	$31,$32,$33,$34,$35,$36,$37,$38,$39,$30
		db	$31,$32,$33,$34,$35,$36,$37,$38,$39
	  ELSE ; V32
		jr	nz,@r_1af0
		ld	a,'I'
		cpi
		jr	nz,@r_1af0
		ld	a,'T'
		cpi
		jr	nz,@r_1af0
		ld	a,'9'
		cpi
		jr	nz,@r_1af0
		ld	a,'0'
		cpi
		jr	nz,@r_1af0
		jp	lab_3ffd		; select BASIC rom and reboot
		; no warm boot flag, check for cartridge sig '55 AA' to directly play a game
@r_1af0:	ld	hl,(CARTRIDGE)
		ld	a,l
		cp	$55
		jp	nz,lab_006e
		ld	a,h
		cp	$aa
		jp	nz,lab_006e
		ld	hl,(START_GAME)
		jp	(hl)
		; filler
		db	$35,$36,$37,$38,$39
	  ENDIF	
	ELSE
		; 0x18e9 Coleco
LOAD_ASCII_	equ	$1927
GAME_OPT_	equ	$1979
		ALIGN	$1b08
	ENDIF
	
		
; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
		ixy	equ	$dd	; ix (swapped with iy)
		iyx	equ	$fd	; iy (swapped with ix)
	ELSE
		ixy	equ	$fd	; iy
		iyx	equ	$dd	; ix
	ENDIF

		db	                                $02,$00,$01,$00,$02,$00,$01,$08	; 0x1b08
		db	$1b,$11,$ba,v63,$cd,$98,$00,$3a,$ba,v63,$2a,$bb,v63,$4f,$06,$00	; 0x1b10
		db	iyx,$21,$f2,v63,iyx,$09,iyx,$09,iyx,$75,$00,iyx,$74,$01,$3a,$c3	; 0x1b20
		db	v63,$cb,$4f,$28,$27,$79,$fe,$03,$28,$06,$fe,$04,$28,$10,$18,$1c	; 0x1b30
		db	$06,$04,$7d,$b4,$20,$04,$0e,$03,$18,$28,$0e,$07,$18,$24,$06,$03	; 0x1b40
		db	$7d,$b4,$20,$04,$0e,$7f,$18,$1a,$0e,$ff,$18,$16,ixy,$21,$76,$1b	; 0x1b50
		db	ixy,$09,ixy,$09,ixy,$7e,$00,ixy,$46,$01,$cb,$3c,$cb,$1d,$3d,$20	; 0x1b60
		db	$f9,$4d,$cd,$ca,$1c,$c9,$07,$05,$0b,$06,$0a,$02,$0b,$04,$06,$03	; 0x1b70
		db	$05,$00,$01,$00,$01,$00,$01,$00,$fe,$ff,$02,$00,$01,$80,$1b,$11	; 0x1b80
		db	$ba,v63,$cd,$98,$00,$3a,$ba,v63,$ed,$5b,$bb,v63,$fd,$2a,$bf,v63	; 0x1b90
		db	$2a,$bd,v63,$cd,$aa,$1b,$cd,$3e,$1d,$c9                        	; 0x1ba0
INIT_TABLEQ	equ	$1b0e	; <-- INIT_TABLEP
INIT_TABLE_	equ	$1b1d	; <-- INIT_TABLE
GET_VRAMQ	equ	$1b8c	; <-- GET_VRAMP
GET_VRAM_	equ	$1ba3	; <-- GET_VRAM
		
; ----------------------------------------------------------------------------------------------

	IFDEF BIT90
fun_1baa:	push	hl
		ld	(var_63fe),iy
		ld	ix,var_63f2
		ld	c,a
		ld	b,$00
		cp	$04
		jr	nz,@r_1bc1
		ld	a,(var_63c3)
		bit	1,a
		jr	z,@r_1be7
@r_1bc1:	ld	hl,dat_1bf9
		add	hl,bc
		ld	a,(hl)
		cp	$00
		jr	z,@r_1be7
@r_1bca:	sla	e
		rl	d
		dec	a
		jr	nz,@r_1bca
		push	bc
		ld	bc,(var_63fe)
		ld	a,(hl)
		cp	$00
		jr	z,@r_1be6
@r_1bdb:	sla	c
		rl	b
		dec	a
		jr	nz,@r_1bdb
		ld	(var_63fe),bc
@r_1be6:	pop	bc
@r_1be7:	add	ix,bc
		add	ix,bc
		ld	l,(ix+$00)
		ld	h,(ix+$01)
		add	hl,de
		ex	de,hl
		pop	hl
		ld	bc,(var_63fe)
		ret
dat_1bf9:	db	$02,$03,$00,$03,$03
		; filler
		db	$31,$32,$33,$34,$35,$36
	ELSE
		; 0x1baa Coleco
		ALIGN	$1c04
	ENDIF

; ----------------------------------------------------------------------------------------------

dat_1c04:	dw	$0005,$0001,$0001,$0001,$fffe,$0002
; 0x1c10 <-- PUT_VRAMP
PUT_VRAMQ:	ld	bc,dat_1c04
		ld	de,var_63ba
		call	PARAM_
		ld	a,(var_63ba)
		ld	de,(var_63bb)
		ld	iy,(var_63bf)
		ld	hl,(var_63bd)
		
; 0x1c27 <-- PUT_VRAM
PUT_VRAM_:
	IFDEF BIT90
		push	af
		cp	$00
		jr	nz,@r_1c4a
		ld	a,(var_63c7)
		cp	$01
		jr	nz,@r_1c4a
		pop	af
		push	hl
		ld	hl,(LOCAL_SPR_TABLE)
		sla	e			; ld a,e : sla a : sla a : ld e,a
		sla	e			; ..
		add	hl,de	
		ex	de,hl
		push	iy
		pop	bc
		sla	c			; ld a,c : sla a : sla a : ld c,a
		sla	c			; ..
		pop	hl
		ldir
		jr	@r_1c51
@r_1c4a:	pop	af
		call	fun_1baa
		call	VRAM_WRITE
@r_1c51:	ret
		; filler
		db	$31,$32,$33,$34
	ELSE ; Coleco
		db	                            $f5,$fe,$00,$20,$22,$3a,$c7,v63,$fe	; 0x1c27
		db	$01,$20,$1b,$f1,$e5,$2a,$02,$80,$7b,$cb,$27,$cb,$27,$5f,$19,$eb	; 0x1c30
		db	$fd,$e5,$c1,$79,$cb,$27,$cb,$27,$4f,$e1,$ed,$b0,$18,$07,$f1,$cd	; 0x1c40
		db	$aa,$1b,$cd,$01,$1d,$c9                                        	; 0x1c50
	ENDIF

; ----------------------------------------------------------------------------------------------

dat_1c56:	dw	$0001,$0001
; 0x1c5a <-- INIT_SPR_ORDERP
INIT_SPR_ORDERQ:
		ld	bc,dat_1c56
		ld	de,var_63ba
		call	PARAM_
		ld	a,(var_63ba)
	
; 0x1c66 <-- INIT_SPR_ORDER
INIT_SPR_ORDER_:
	IF V30 || V31
		ld	c,a
	ELSE
		ld	b,a
	ENDIF
		xor	a
		ld	hl,(SPRITE_ORDER)
@r_1c6b:	ld	(hl),a
		inc	hl
		inc	a
	IF V30 || V31
		cp	c
	ELSE
		cp	b
	ENDIF
		jr	nz,@r_1c6b
		ret
		
; ----------------------------------------------------------------------------------------------

dat_1c72:	dw	$0001,$0001
; 0x1c76 <-- WR_SPR_NM_TBLP
WR_SPR_NM_TBLQ:	ld	bc,dat_1c72
		ld	de,var_63ba
		call	PARAM_
		ld	a,(var_63ba)

; 0x1c82 <-- WR_SPR_NM_TBL
WR_SPR_NM_TBL_:	ld	ix,(SPRITE_ORDER)
		push	af
		ld	iy,var_63f2
		ld	e,(iy+$00)
		ld	d,(iy+$01)
		ld	a,e
		out	(CTRL_PORT),a
		ld	a,d
		or	$40
		out	(CTRL_PORT),a
		pop	af
@r_1:		ld	hl,(LOCAL_SPR_TABLE)
		ld	c,(ix+$00)
		inc	ix
		ld	b,$00
		add	hl,bc
		add	hl,bc
		add	hl,bc
		add	hl,bc
		ld	b,$04
		ld	c,DATA_PORT
@r_2:		outi
		nop
		nop		
		jr	nz,@r_2
		dec	a
		jr	nz,@r_1
		ret

; ----------------------------------------------------------------------------------------------

dat_1cb6:	dw	$0002,$0001,$0001
; 0x1cbc <-- WRITE_REGISTERP
REG_WRITEQ:	ld	bc,dat_1cb6
		ld	de,var_63ba
		call	PARAM_
		ld	hl,(var_63ba)
		ld	c,h
		ld	b,l

; 0x1cca <-- WRITE_REGISTER
REG_WRITE:	ld	a,c
		out	(CTRL_PORT),a
		ld	a,b
	IFDEF BIT90
		or	$80
	ELSE ; Coleco
		add	a,$80
	ENDIF
		out	(CTRL_PORT),a
		ld	a,b
		cp	$00
		jr	nz,@r_1
		ld	a,c
		ld	(var_63c3),a
@r_1:		ld	a,b
		cp	$01
		jr	nz,@r_2
		ld	a,c
		ld	(var_63c4),a
@r_2:		ret

; ----------------------------------------------------------------------------------------------

dat_1ce5:	dw	$0003,$fffe,$0002,$0002
; 0x1ced <-- WRITE_VRAMP
WRITE_VRAMQ:	ld	bc,dat_1ce5
		ld	de,var_63ba
		call	PARAM_
		ld	hl,(var_63ba)
		ld	de,(var_63ba+2)
		ld	bc,(var_63ba+4)

; 0x1d01 <-- WRITE_VRAM
VRAM_WRITE:
	IF V30 || V31
		; Code optimized / incompatible
		ld	a,e
		out	(CTRL_PORT),a
		ld	a,$40
		add	a,d
		out	(CTRL_PORT),a
		xor	a
		cp	c
		jr	z,@r_1d11
		cp	b
		jr	z,@r_1d11
		dec	b
@r_1d11:	ld	a,(hl)
		out	(DATA_PORT),a
		cpi
		nop
		nop
		jp	pe,@r_1d11
		ret
		; filler
		db	$31,$32,$33,$34,$35,$36
	ELSE ; V32 / Coleco
		push	hl
		push	de
		pop	hl
		ld	de,$4000
		add	hl,de
		ld	a,l
		out	(CTRL_PORT),a
		ld	a,h
		out	(CTRL_PORT),a
		push	bc
		pop	de
		pop	hl
		ld	c,DATA_PORT
		ld	b,e
OUTPUT_LOOP:	outi
		nop
		nop
		jp	nz,OUTPUT_LOOP
		dec	d
		jp	m,END_OUTPUT
		jr	nz,OUTPUT_LOOP
END_OUTPUT:	ret
	ENDIF

; ----------------------------------------------------------------------------------------------
		
dat_1d22:	dw	$0003,$fffe,$0002,$0002
; 0x1d2a <-- READ_VRAMP
READ_VRAMQ:	ld	bc,dat_1d22
		ld	de,var_63ba
		call	PARAM_
		ld	hl,(var_63ba)
		ld	de,(var_63ba+2)
		ld	bc,(var_63ba+4)

; 0x1d3e <-- READ_VRAM
VRAM_READ:	
		ld	a,e
		out	(CTRL_PORT),a
		ld	a,d
		out	(CTRL_PORT),a		; 0x1d43: CTRL_PORT_PTR
		push	bc
		pop	de
		ld	c,DATA_PORT		; 0x1d47: DATA_PORT_PTR
		ld	b,e
@r_1:		ini
		nop
		nop
		jp	nz,@r_1
		dec	d
		jp	m,@r_2
		jr	nz,@r_1
@r_2:		ret

; ----------------------------------------------------------------------------------------------

		db	                            $db,$bf,$c9,$dd,$21,$96,$1d,$18,$10	; 0x1d57
		db	$dd,$21,$b7,$1d,$18,$0a,$dd,$21,$e5,$1d,$18,$04,$dd,$21,$07,$1e	; 0x1d60
		db	$d9,$08,$dd,$e5,$08,$f5,$08,$f1,$d9,$d5,$d9,$d1,$fd,$21,$01,$00	; 0x1d70
		db	$2a,$06,$80,$cd,$a3,$1b,$dd,$e1,$dd,$e5,$dd,$e9,$13,$0b,$78,$b1	; 0x1d80
		db	$d9,$20,$e1,$dd,$e1,$c9,$2a,$06,$80,$01,$08,$00,$e5,$d1,$09,$eb	; 0x1d90
		db	$cd,$00,$1f,$cd,$72,$1e,$cd,$5d,$1e,$fe,$01,$20,$06,$cd,$89,$1e	; 0x1da0
		db	$cd,$9a,$1e,$d9,$23,$18,$d5,$2a,$06,$80,$01,$08,$00,$e5,$d1,$09	; 0x1db0
		db	$eb,$cd,$4e,$1f,$cd,$72,$1e,$cd,$5d,$1e,$fe,$01,$20,$13,$cd,$89	; 0x1dc0
		db	$1e,$2a,$06,$80,$01,$08,$00,$e5,$d1,$09,$eb,$cd,$4e,$1f,$cd,$9a	; 0x1dd0
		db	$1e,$d9,$23,$18,$a7,$2a,$06,$80,$01,$08,$00,$e5,$d1,$09,$eb,$cd	; 0x1de0
		db	$12,$1f,$cd,$72,$1e,$cd,$5d,$1e,$fe,$01,$20,$06,$cd,$89,$1e,$cd	; 0x1df0
		db	$9a,$1e,$d9,$23,$c3,$8c,$1d,$2a,$06,$80,$01,$08,$00,$e5,$d1,$09	; 0x1e00
		db	$eb,$cd,$ab,$1e,$08,$f5,$08,$f1,$d9,$e5,$d9,$d1,$2a,$06,$80,$01	; 0x1e10
		db	$08,$00,$09,$fd,$21,$04,$00,$cd,a1l,a1h,$cd,$5d,$1e,$fe,$01,$20	; 0x1e20
		db	$24,$cd,$89,$1e,$2a,$06,$80,$01,$08,$00,$e5,$d1,$09,$eb,$cd,$ea	; 0x1e30
		db	$1e,$3e,$04,$d9,$e5,$d9,$d1,$2a,$06,$80,$01,$08,$00,$09,$fd,$21	; 0x1e40
		db	$04,$00,$cd,a1l,a1h,$d9,$23,$23,$23,$23,$c3,$8c,$1d,$08,$f5,$08	; 0x1e50
		db	$f1,$fe,$03,$20,$0a,$21,$c3,v63,$cb,$4e,$28,$03,$3e,$01,$c9,$3e	; 0x1e60
		db	$00,$c9,$08,$f5,$08,$f1,$d9,$e5,$d9,$d1,$2a,$06,$80,$01,$08,$00	; 0x1e70
		db	$09,$fd,$21,$01,$00,$cd,a1l,a1h,$c9,$3e,$04,$d9,$d5,$d9,$d1,$2a	; 0x1e80
		db	$06,$80,$fd,$21,$01,$00,$cd,$a3,$1b,$c9,$3e,$04,$d9,$e5,$d9,$d1	; 0x1e90
		db	$2a,$06,$80,$fd,$21,$01,$00,$cd,a1l,a1h,$c9,$e5,$dd,$e1,$d5,$fd	; 0x1ea0
		db	$e1,$01,$08,$00,$dd,$7e,$00,$dd,$23,$57,$1e,$04,$cb,$17,$cb,$14	; 0x1eb0
		db	$cb,$12,$cb,$14,$1d,$20,$f5,$1e,$04,$cb,$17,$cb,$15,$cb,$12,$cb	; 0x1ec0
		db	$15,$1d,$20,$f5,$fd,$74,$00,$fd,$75,$10,$fd,$23,$fd,$74,$00,$fd	; 0x1ed0
		db	$75,$10,$fd,$23,$0b,$79,$b0,$20,$cb,$c9,$01,$10,$00,$e5,$7e,$23	; 0x1ee0
		db	$12,$13,$12,$13,$0b,$79,$fe,$08,$20,$01,$e1,$79,$b0,$20,$ef,$c9	; 0x1ef0
		db	$01,$08,$00,$46,$3e,$80,$cb,$10,$1f,$30,$fb,$12,$23,$13,$0d,$20	; 0x1f00
		db	$f2,$c9,$e5,$dd,$e1,$eb,$01,$08,$00,$dd,$cb,$00,$16,$cb,$1e,$dd	; 0x1f10
		db	$cb,$01,$16,$cb,$1e,$dd,$cb,$02,$16,$cb,$1e,$dd,$cb,$03,$16,$cb	; 0x1f20
		db	$1e,$dd,$cb,$04,$16,$cb,$1e,$dd,$cb,$05,$16,$cb,$1e,$dd,$cb,$06	; 0x1f30
		db	$16,$cb,$1e,$dd,$cb,$07,$16,$cb,$1e,$23,$0d,$20,$cc,$c9,$01,$07	; 0x1f40
		db	$00,$09,$03,$7e,$12,$13,$2b,$0b,$78,$b1,$20,$f7,$c9,$ff,$ff,$ff	; 0x1f50
		db	$ff                                                            	; 0x1f60
REG_READ	equ	$1d57	; <-- READ_REGISTER
RFLCT_VERT	equ	$1d5a	; <-- REFLECT_VERTICAL
RFLCT_HOR	equ	$1d60	; <-- REFLECT_HORIZONTAL
ROT_90		equ	$1d66	; <-- ROTATE_90
ENLRG		equ	$1d6c	; <-- ENLARGE
	
; ----------------------------------------------------------------------------------------------
; OS7 jump table					 BIT90?

PLAY_SONGS:		jp	PLAY_SONGS_	; 0x1f61
ACTIVATEP:		jp	ACTIVATEQ	; 0x1f64
PUTOBJP:		jp	PUTOBJQ		; 0x1f67
REFLECT_VERTICAL:	jp	RFLCT_VERT	; 0x1f6a
REFLECT_HORIZONTAL:	jp	RFLCT_HOR	; 0x1f6d
ROTATE_90:		jp	ROT_90		; 0x1f70
ENLARGE:		jp	ENLRG		; 0x1f73
CONTROLLER_SCAN:	jp	CONT_SCAN	; 0x1f76 with keyboard input (basic rom call 0x3ff7)
DECODER:		jp	DECODER_	; 0x1f79 with keyboard input
GAME_OPT:		jp	GAME_OPT_	; 0x1f7c
LOAD_ASCII:		jp	LOAD_ASCII_	; 0x1f7f
FILL_VRAM:		jp	FILL_VRAM_	; 0x1f82 
MODE_1:			jp	MODE_1_		; 0x1f85
UPDATE_SPINNER:
	IFDEF BIT90
			ret			; 0x1f88 not supported
			db	$c9,$c9		; filler
	ELSE
			jp	UPDATE_SPINNER_	; 0x1f88
	ENDIF
INIT_TABLEP:		jp	INIT_TABLEQ	; 0x1f8b reg ix/iy swapped
GET_VRAMP:		jp	GET_VRAMQ	; 0x1f8e reg ix/iy swapped
PUT_VRAMP:		jp	PUT_VRAMQ	; 0x1f91
INIT_SPR_ORDERP:	jp	INIT_SPR_ORDERQ	; 0x1f94
WR_SPR_NM_TBLP:		jp	WR_SPR_NM_TBLQ	; 0x1f97
INIT_TIMERP:		jp	INIT_TIMERQ	; 0x1f9a
FREE_SIGNALP:		jp	FREE_SIGNALQ	; 0x1f9d
REQUEST_SIGNALP:	jp	REQUEST_SIGNALQ	; 0x1fa0
TEST_SIGNALP:		jp	TEST_SIGNALQ	; 0x1fa3
WRITE_REGISTERP:	jp	REG_WRITEQ	; 0x1fa6
WRITE_VRAMP:		jp	WRITE_VRAMQ	; 0x1fa9
READ_VRAMP:		jp	READ_VRAMQ	; 0x1fac
INIT_WRITERP:		jp	INIT_QUEUEQ	; 0x1faf
SOUND_INITP:		jp	INIT_SOUNDQ	; 0x1fb2
PLAY_ITP:		jp	JUKE_BOXQ	; 0x1fb5
INIT_TABLE:		jp	INIT_TABLE_	; 0x1fb8
GET_VRAM:		jp	GET_VRAM_	; 0x1fbb
PUT_VRAM:		jp	PUT_VRAM_	; 0x1fbe
INIT_SPR_ORDER:		jp	INIT_SPR_ORDER_	; 0x1fc1
WR_SPR_NM_TBL:		jp	WR_SPR_NM_TBL_	; 0x1fc4
INIT_TIMER:		jp	INIT_TIMER_	; 0x1fc7
FREE_SIGNAL:		jp	FREE_SIGNAL_	; 0x1fca
REQUEST_SIGNAL:		jp	REQUEST_SIGNAL_	; 0x1fcd
TEST_SIGNAL:		jp	TEST_SIGNAL_	; 0x1fd0
TIME_MGR:		jp	TIME_MGR_	; 0x1fd3
TURN_OFF_SOUND:		jp	ALL_OFF		; 0x1fd6
WRITE_REGISTER:		jp	REG_WRITE	; 0x1fd9
READ_REGISTER:		jp	REG_READ	; 0x1fdc
WRITE_VRAM:		jp	VRAM_WRITE	; 0x1fdf
READ_VRAM:		jp	VRAM_READ	; 0x1fe2
INIT_WRITER:		jp	INIT_QUEUE	; 0x1fe5
WRITER:			jp	WRITER_		; 0x1fe8
POLLER:			jp	POLLER_		; 0x1feb
SOUND_INIT:		jp	INIT_SOUND	; 0x1fee
PLAY_IT:		jp	JUKE_BOX	; 0x1ff1
SOUND_MAN:		jp	SND_MANAGER	; 0x1ff4
ACTIVATE:		jp	ACTIVATE_	; 0x1ff7
PUTOBJ:			jp	PUTOBJ_		; 0x1ffa
RAND_GEN:		jp	RAND_GEN_	; 0x1ffd

; ----------------------------------------------------------------------------------------------
; Global symbols                                                                BIT90?
; 
; 0069  AMERICA         60 = NTSC, 50 = PAL                                     ok
; 006A  ASCII_TABLE     Pointer to uppercase ASCII pattern                      ok
; 006C  NUMBER_TABLE    Pointer to numbers 0-9 pattern                          ok
; 00FC  FREQ_SWEEP      Frequency sweep                                         ok
; 012F  ATN_SWEEP       Attenuation sweep                                       ok
; 0190  DECLSN          Decrement low nibble (in UTILITY)                       V30:ok / V31:018E
; 019B  DECMSN          Decrement high nibble (in (UTILITY)                     not available
; 01A6  MSNTOLSN        Copy high nibble to low nibble (in UTILITY)             V30:ok / V31:01A7
; 01B1  ADD816          Add signed 8bit value A to 16bit [HL]                   ok        
; 01D5  LEAVE_EFFECT    Called by a special sound effect function when done	not supported
; 02EE  EFXOVER         (in PROCESS_DATA_AREA to get next note)                 02EC
; 07E8  PX_TO_PTRN_POS  Pixel to pattern plane position                         ok
; 080B  PUT_FRAME       Copy a block of names to VRAM                           ok
; 0898  GET_BKGRND      Copy a block of names from VRAM to RAM                  ok
; 08C0  CALC_OFFSET     Returns DE := offset for the coordinates (E,D)          ok
; 1D43  CTRL_PORT_PTR   (in READ_VRAM, equal I/O port# BF)                      ok
; 1D47  DATA_PORT_PTR   (in READ_VRAM, equal I/O port# BE)                      ok
; 1D6C  ENLRG           It's the local name of the ENLARGE routine              ok
