; Z80 Mandelbrot Calculate Iterations for pixels x,y to x+7,y
; Version 0.3b
;
; Calculations from: https://rosettacode.org/wiki/Mandelbrot_set#Z80_Assembly
;
; H.J. Berends:
; added translation from iterations to TMS9929A pattern + colors
; added color spill optimization routine and usage of a color palette (Mandelbrot3a.bas conversion)
; added write to VDP routine
; use BASIC program Mandelbrot3b.bas to initiate and call the asm routines


scale		=	256                     
divergent	=	scale * 4

		ORG	$A000			; 40960

		JP	_start

iteration_max:  BYTE	16                      ; 40963 How many iterations
x:		WORD	0                       ; 40964 x-coordinate
y:		WORD	0		        ; 40966 y-coordinate
x_step:		BYTE	3,3,3,2,3,3,3,2		; 40968 x step sizes (2.75 * 8 = 22) 
iteration_ret:	BYTE	0,0,0,0,0,0,0,0		; 40976 return calculation result
vdp_x:		BYTE	0			; 40984
vdp_y:		BYTE	0			; 40985
vdp_pattern:	BYTE	0			; 40986
vdp_color:	BYTE	0			; 40987
vdp_routine:	JP	vdpWrite		; 40988 write x,y pattern / color to vdp
pc_routine:	JP	patternColor		; 40991 determine patttern and color
palette:	BYTE	0			; 40994 translate iterations to palette color
		BYTE	1,1,6,8,9,10,11,3
		BYTE	2,12,4,5,7,13,14,15
bitSet:		BYTE	128,64,32,16,8,4,2,1	; table to help setting a bit in the pattern

_start:		PUSH	HL
		LD	IX,x_step		; x_step = IX+$00 iteration_ret=IX+$08
		LD	C,8			; h = 8 pixels counter 
		

h_loop:		LD	HL,0
		LD	(z_0),HL
		LD	(z_1),HL
		LD	A,(iteration_max)
		LD	B,A

iteration_loop: PUSH	BC

; z2 = (z_0 * z_0 - z_1 * z_1) / SCALE;

		LD	DE,(z_1)		; Compute DE HL = z_1 * z_1
		LD	BC,DE
		CALL	mul_16
		LD      (z_0_sqr_low),HL	; z_0 ** 2 is needed later again
		LD      (z_0_sqr_high),DE

		LD	DE,(z_0)		; Compute DE HL = z_0 * z_0
		LD	BC,DE
		CALL	mul_16
		LD	(z_1_sqr_low),HL	; z_1 ** 2 will be also needed
		LD	(z_1_sqr_high),DE

		AND	A			; Compute subtraction
		LD	BC,(z_0_sqr_low)
		SBC	HL,BC
		LD	(scratch_0),HL		; Save lower 16 bit of result
		LD	HL,DE
		LD	BC,(z_0_sqr_high)
		SBC	HL,BC
		LD	BC,(scratch_0)		; HL BC = z_0 ** 2 - z_1 ** 2

		LD	C,B			; Divide by scale = 256
		LD	B,L			; Discard the rest
		PUSH	BC			; We need BC later

; z3 = 2 * z0 * z1 / SCALE
; ------------------------
		LD	HL,(z_0)		; Compute DE HL = 2 * z_0 * z_1
		ADD	HL,HL
		LD	DE,HL
		LD	BC,(z_1)
		CALL	mul_16

		LD	B,E			; Divide by scale (= 256)
		LD	C,H			; BC contains now z_3

; z1 = z3 + y
; ------------
		LD	HL,(y)
		ADD	HL,BC
		LD	(z_1),HL

; z_0 = z_2 + x
; -------------
		POP	BC			; Here BC is needed again :-)
		LD	HL,(x)
		ADD	HL,BC
		LD	(z_0),HL

; if (z0 * z0 / SCALE + z1 * z1 / SCALE > 4 * SCALE)
; --------------------------------------------------
		LD	HL,(z_0_sqr_low)	; Use the sqrs computed
		LD	DE,(z_1_sqr_low)	; above
		ADD	HL,DE
		LD	BC,HL			; BC contains lower word of sum

		LD	HL,(z_0_sqr_high)
		LD	DE,(z_1_sqr_high)
		ADC	HL,DE

		LD	H,L			; HL now contains (z_0 ** 2 + 
		LD	L,B			; z_1 ** 2) / scale

		LD	BC, divergent
		AND	A
		SBC	HL,BC

; break
; -----
		JP	C,iteration_dec		; No break
		POP	BC			; Get latest iteration counter
                JR	iteration_end		; Exit loop

; iteration++
; -----------
iteration_dec:	POP	BC			; Get iteration counter
		DJNZ	iteration_loop          ; We might fall through!

iteration_end:	LD	A,(iteration_max)
		SUB	B
		LD	(IX+$08),A		; iteration_ret
		LD	D,0
		LD	E,(IX+$00)		; x_step
		LD	HL,(x)
		ADD	HL,DE			; x = x + x_step
		LD	(x),HL
		INC	IX
		DEC	C			; h = h - 1
		JP	NZ,h_loop

h_loop_end:	POP	HL
		RET


;   Compute DEHL = BC * DE (signed): This routine is not too clever but it 
; works. It is based on a standard 16-by-16 multiplication routine for unsigned
; integers. At the beginning the sign of the result is determined based on the
; signs of the operands which are negated if necessary. Then the unsigned
; multiplication takes place, followed by negating the result if necessary.
;
mul_16:		XOR	A			; Clear carry and A (-> +)
		BIT	7,B			; Is BC negative?
		JR	Z,bc_positive		; No
		SUB	C			; A is still zero, complement
		LD	C,A
		LD	A,0
		SBC	A,B
		LD	B,A
		SCF				; Set carry (-> -)
bc_positive:	BIT	7,D			; Is DE negative?
		JR	Z,de_positive		; No
		PUSH	AF			; Remember carry for later!
                XOR	A
		SUB	E
		LD	E,A
		LD	A,0
		SBC	A,D
		LD	D,A
		POP	AF			; Restore carry for complement
		CCF				; Complement Carry (-> +/-?)
de_positive:	PUSH	AF			; Remember state of carry
		AND	A			; Start multiplication
		SBC	HL,HL
		LD	A,16			; 16 rounds
mul_16_loop:	ADD	HL,HL
		RL	E
		RL	D
		JR	NC,mul_16_exit
		ADD	HL,BC
		JR	NC,mul_16_exit
		INC	DE
mul_16_exit:	DEC	A
		JR	NZ,mul_16_loop
		POP	AF			; Restore carry from beginning
		RET	NC			; No sign inversion necessary
		XOR	A			; Complement DE HL
		SUB	L
		LD	L,A
		LD	A,0
		SBC	A,H
		LD	H,A
		LD	A,0
		SBC	A,E
		LD	E,A
		LD	A,0
		SBC	A,D
		LD	D,A
		RET

; ----------------------------------------------
; Write pattern and color to TMS9929A VDP memory
; ----------------------------------------------

vdpWrite:	PUSH	HL
		LD	A,(vdp_y)		; Convert pixel x,y to VDP address
		RRCA
		RRCA
		RRCA
		AND	$1F
		LD	H,A
		LD	A,(vdp_x)
		AND	$F8
		LD	B,A
		LD	A,(vdp_y)
		AND	$07
		OR	B
		LD	L,A
		LD	A,(vdp_pattern)
		CALL	$30F9			; Write pattern in A to VDP address in HL
		SET	5,H			; Offset Color Table
		LD	A,(vdp_color)
		CALL	$30F9			; Write color in A to VDP address in HL
		POP	HL
		RET

; ------------------------------------------
; Determine pattern and color
; This is a conversion from Mandelbrot3a.bas 
; ------------------------------------------

patternColor:	PUSH	HL
		XOR	A			; BASIC 1030
		LD	C,A			; H = 0		
		LD	(total_color),A		; TC = 0	
		LD	IX,iteration_ret	; Table with previously calculated iterations 

pc_loop:	LD	A,(IX+$00)		; BASIC 1040
		INC	IX
		CP	3			; BASIC 1050 (the asm routine adds 1 more iteration count)
		JR	C,blackColor
		LD	HL,iteration_max
		LD	B,(HL)
		CP	B
		JR	NC,blackColor

		LD	HL,total_color		; BASIC 1060
		ADD	A,(HL)
		LD	(HL),A
		LD	A,C			; BASIC 1070
		CP	3
		JR	NZ,pc_Nibble
		LD	A,(total_color)
		RRCA
		RRCA
		AND	$0F
		LD	(bg_color),A	
pc_Nibble:	INC	C			; BASIC 1080
		LD	A,C
		CP	8
		JR	C,pc_loop

		LD	A,(bg_color)		; BASIC 1090
		LD	B,A
		LD	A,(total_color)
		RRCA
		RRCA
		AND	$1F
		SUB	B			; 2nd nibble color := TC/4 - first nibble_color
		LD	(fg_color),A
		LD	A,$0F			; The first nibble is background color and 2nd nibble foreground color
		LD	(vdp_pattern),A

colorPalette:	LD	HL,palette		; Convert iteration colors to palette colors
		LD	A,(fg_color)
		LD	D,0
		LD	E,A
		ADD	HL,DE
		LD	A,(HL)
		RLCA
		RLCA
		RLCA
		RLCA
		LD	B,A
		LD	HL,palette
		LD	A,(bg_color)
		LD	E,A
		ADD	HL,DE
		LD	A,(HL)
		ADD	A,B
		LD	(vdp_color),A		; vdp_color = Foreground color * 16 + Background color

pc_end:		POP	HL			; BASIC 1100 (Goto next routine)
		RET

; If there's a black pixel then set the pattern and fg_color accordingly. 
; The other colors will be set to the average color number as background color.
blackColor:	LD	A,C			; BASIC 1200
		LD	(n_counter),A		; N = H
		LD	HL,bitSet
		LD	D,0
		LD	E,A
		ADD	HL,DE
		LD	A,(HL)
		LD	(vdp_pattern),A		; P = B(H)
black_loop:	INC	C			; BASIC 1210
		LD	A,C
		CP	8
		JR	Z,black_end
		LD	A,(IX+$00)		; BASIC 1220
		INC	IX
		CP	3			; BASIC 1230
		JR	C,blackPattern
		LD	HL,iteration_max
		LD	B,(HL)
		CP	B
		JR	NC,blackPattern
		LD	B,A			; BASIC 1230:ELSE
		LD	A,(total_color)
		ADD	A,B
		LD	(total_color),A
		LD	HL,n_counter
		INC	(HL)			; N=N+1
		JR	black_loop

blackPattern:	LD	HL,bitSet		; BASIC 1230:THEN
		LD	D,0
		LD	E,C
		ADD	HL,DE
		LD	A,(vdp_pattern)
		ADD	A,(HL)
		LD	(vdp_pattern),A
		JR	black_loop

black_end:	LD	A,(n_counter)		; BASIC 1250
		OR	A
		JR	Z,all_black
		LD	C,A
		LD	A,(total_color)		; BASIC 1260
		LD	H,0
		LD	L,A

; Division HL = HL / C
div8:                            
		XOR	A
		LD	B,16
div8loop:	ADD	HL,HL
		RLA
		CP	C
		JP	C,div8nextbit
		SUB	C
		INC	L
div8nextbit:	DJNZ	div8loop

		LD	A,L
		LD	(bg_color),A		; C = TC / N
		XOR	A
		LD	(fg_color),A		; CC = 0
		JP	colorPalette		

all_black:	XOR	A
		LD	(vdp_pattern),A
		LD	(vdp_color),A
		JP	pc_end			; skip palette conversion

; ------------------------------
; work variables and tables

z_0:		WORD	0
z_1:		WORD	0
scratch_0:	WORD	0
z_0_sqr_high:	WORD	0
z_0_sqr_low:	WORD	0
z_1_sqr_high:	WORD	0
z_1_sqr_low:	WORD	0
total_color:	BYTE	0			; sum of colors
fg_color:	BYTE	0			; color for 2nd nibble or black color
bg_color:	BYTE	0			; color for first nibble or if black then average for byte
n_counter:	BYTE	0