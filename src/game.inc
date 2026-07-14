; ------------------------------------------------------------------------------
; game.inc
; 
; Coleco / BIT90 definitions
; ------------------------------------------------------------------------------

; Coleco definitions
DATA_PORT	equ	$be
CTRL_PORT	equ	$bf
CTRL_0_PORT	equ	$fc
CTRL_1_PORT	equ	$ff
STRB_SET_PORT	equ	$80
STRB_RST_PORT	equ	$c0
SOUND_PORT	equ	$ff
;
STACK		equ	$73b9
;
CARTRIDGE	equ	$8000		; cartridge signature 'AA 55' or '55 AA'
LOCAL_SPR_TABLE	equ	$8002		; pointer to the copy of the sprite name table
SPRITE_ORDER	equ	$8004		; pointer to the sprite order table
WORK_BUFFER	equ	$8006		; pointer to a free buffer space in RAM.
CONTROLLER_MAP	equ	$8008		; pointer to the controller memory map
START_GAME	equ	$800a		; pointer to the start of the game.
RST_08H_RAM	equ	$800c		; restart 8 soft vector
RST_10H_RAM	equ	$800f		; restart 10 soft vector
RST_18H_RAM	equ	$8012		; restart 18 soft vector
RST_20H_RAM	equ	$8015		; restart 20 soft vector
RST_28H_RAM	equ	$8018		; restart 20 soft vector
RST_30H_RAM	equ	$801b		; restart 30 soft vector
IRQ_INT_VECTOR	equ	$801e		; maskable interrupt soft vector
NMI_INT_VECTOR	equ	$8021		; non maskable interrupt soft vector
GAME_NAME	equ	$8024		; game name string: name/maker/copyright

; ------------------------------------------------------------------------------
; BIT90 definitions
lab_3ff7	equ	$3ff7		; get keyboard input
lab_3ffd	equ	$3ffd		; select BASIC rom and reboot

; ------------------------------------------------------------------------------
; Variables
IF (V31 || V32)
	var	equ	$6300
	v63	equ	$63		
ELSE
	var	equ	$7300
	v63	equ	$73
ENDIF
var_63b9	equ	var+$b9		; STACK
var_63ba	equ	var+$ba
var_63bb	equ	var+$bb
var_63bc	equ	var+$bc
var_63bd	equ	var+$bd
var_63bf	equ	var+$bf
var_63c3	equ	var+$c3		; VDP R#0
var_63c4	equ	var+$c4		; VDP R#1
var_63c6	equ	var+$c6
var_63c7	equ	var+$c7
var_63c8	equ	var+$c8
var_63ca	equ	var+$ca
var_63cb	equ	var+$cb
var_63cc	equ	var+$cc
var_63cd	equ	var+$cd
var_63cf	equ	var+$cf
var_63d1	equ	var+$d1
var_63d3	equ	var+$d3
var_63d5	equ	var+$d5
var_63d7	equ	var+$d7
var_63eb	equ	var+$eb
var_63ec	equ	var+$ec
var_63ee	equ	var+$ee
var_63ef	equ	var+$ef
var_63f0	equ	var+$f0
var_63f1	equ	var+$f1
var_63f2	equ	var+$f2
var_63fe	equ	var+$fe
;
var_7000	equ	$7000
var_7020	equ	$7020
var_7022	equ	$7022
var_7024	equ	$7024
var_7026	equ	$7026
var_7028	equ	$7028
var_702a	equ	$702a
;
var_73eb	equ	$73eb
var_73ee	equ	$73ee
var_73ef	equ	$73ef
var_73f0	equ	$73f0
var_73f1	equ	$73f1

