0001 REM  'SCRN'
0002 RESTORE 6
0003 FOR I=29952TO 29975:READ A:POKE I,A:NEXT I:POKE 28677,0:POKE 28678,117
0004 REM  'DEL-7:RUN'
0005 FOR I=28696TO 28703:READ A:POKE I,A:NEXT I:END 
0006 DATA 83,67,82,78,40,197,9,117,255,213,229,205,214,34,235,205,125,56,205,140,24,225,209,201
0007 DATA 58,58,221,45,55,58,133,0
0010 REM  MEMORY (C)1985
0020 DIM PU(2),S(41,2)
0030 HOME 
0040 CALL SCREEN(1)
0100 ?:?:?:?
0110 ?SPC( 7);"***************"
0115 ?:?SPC( 7);"* M E M O R Y *"
0120 ?:?SPC( 7);"***************"
0125 ?:?:?:?:?:?
0130 ?"PRESS FIREBUTTON FOR BEGINNING"
0140 ?"------------------------------"
0190 FOR A=5TO 11
0200 CALL CHRCOL(A,10,1)
0210 NEXT A
0220 TEMPO 0
0240 J=JOYST( 1)
0250 IF J=255GOTO 240
0260 MUSIC 0,-15,"+F9":PLAY 
0280 CALL HCHAR(0,0,152,768)
0290 RESTORE 4560
0300 FOR A=160TO 165
0310 READ A$
0320 CALL CHAR(A,A$)
0330 NEXT A
0340 FOR A=144TO 158
0345 IF A<148THEN B=A+40ELSE B=A
0350 READ A$
0360 CALL CHAR(B,A$)
0370 NEXT A
0380 RESTORE 4780
0390 FOR A=48TO 54
0400 READ A$
0410 CALL CHAR(A,A$)
0420 NEXT A
0440 CALL CHRCOL(6,1,1)
0450 CALL CHRCOL(17,1,1)
0460 CALL CHRCOL(18,1,1)
0470 CALL CHRCOL(19,1,1)
0480 RESTORE 4600
0490 FOR A=1TO 6
0500 READ B
0510 CALL HCHAR(2,2*A+8,B)
0520 NEXT A
0530 FOR A=1TO 8
0540 READ B,C,D
0550 CALL HCHAR(B,C,D)
0560 NEXT A
0570 CALL CHRCOL(6,8,1)
0580 CALL CHRCOL(20,2,15)
0585 CALL CHRCOL(23,7,1)
0590 CALL CHRCOL(18,10,1)
0600 CALL CHRCOL(19,10,1)
0610 C=0
0620 V=5
0630 IF C<> 0GOTO 680
0640 H=5
0650 D=9
0660 E=3
0670 GOTO 710
0680 H=20
0690 D=16-GE*8
0700 E=2
0710 CALL HCHAR(V,H,158)
0720 J=JOYST( 1)
0740 S=(J=5)-(J=1)
0750 IF J<0GOTO 850
0760 IF J=255GOTO 720
0800 IF (V-S<5)+(V-S>8-7*(E=2)+8*(GE=1))<0GOTO 720
0810 CALL HCHAR(V,H,152)
0820 V=V-S*E
0830 CALL HCHAR(V,H,158)
0840 GOTO 720
0850 MUSIC 0,-15,"+F9":PLAY 
0860 IF C<> 0GOTO 950
0870 GE=ABS{ (V=8))
0880 C=1
0890 FOR A=1TO 6-GE*4
0900 READ B
0910 CALL HCHAR(3+A*2,22,A+48)
0920 CALL HCHAR(3+A*2,24,B)
0930 NEXT A
0940 GOTO 620
0950 LE=(V+1)/2-2+GE*2
0960 CALL HCHAR(0,0,152,768)
0970 FOR A=4TO 17
0980 CALL CHRCOL(A,6,15)
0990 NEXT A
1000 FOR A=32TO 132STEP 5
1010 CALL CHAR(A,"E7C3A51818A5C3E7")
1020 NEXT A
1030 CALL HCHAR(21,4,164,4)
1040 CALL HCHAR(22,4,164,4)
1050 VE=22
1060 HO=10
1070 KA=GE*24+159
1080 GOSUB 4010
1090 HO=22
1100 KA=183
1110 GOSUB 4010
1120 CALL HCHAR(21,24,165,4)
1130 CALL HCHAR(22,24,165,4)
1140 PU(2)=0
1150 GOSUB 4090
1160 PU(1)=0
1170 GOSUB 4240
1180 RESTORE 4620
1190 FOR A=33TO 133STEP 5
1200 FOR B=ATO A+3
1210 READ A$
1220 CALL CHAR(B,A$)
1230 NEXT B
1240 NEXT A
1250 FOR A=156TO 157
1260 READ A$
1270 CALL CHAR(A,A$)
1280 NEXT A
1290 CO=2:F=21
1300 FOR KC=0TO 9-11*(LE>3)
1310 GOSUB 3800:NEXT KC
1320 K$="   %%**//4499>>CCHHMMRRWW\\aaffkkppuuzz||}}"
1330 ON LEGOTO 1340,1340,1340,1360,1360,1360
1340 RESTORE 4760
1350 GOTO 1370
1360 RESTORE 4770
1370 READ X1,X2,Y1,Y2,AN,F
1380 KZ=AN
1390 FOR HR=X1TO X2STEP 3
1400 FOR VR=Y1TO Y2STEP 3
1405 RANDOMIZE 
1410 A=INT( RND( AN))+1
1420 KA$=MID$( K$,A+1,1)
1430 IF AN-A=0THEN K$=MID$( K$,1,A)ELSE K$=MID$( K$,1,A)&MID$( K$,A+2,AN-A)
1440 AN=AN-1
1450 IF KA$<> "|"GOTO 1480
1460 B=127
1470 GOTO 1520
1480 IF KA$<> "}"GOTO 1510
1490 B=132
1500 GOTO 1520
1510 B=ASC( KA$)
1520 CALL VCHAR(VR-1,HR-1,B,2)
1530 CALL VCHAR(VR-1,HR,B,2)
1540 NEXT VR
1550 NEXT HR
1560 CALL CHRCOL(19,CO,1)
1570 CALL HCHAR(Y1-1,X1-3,156)
1580 CALL HCHAR(Y1-3,X1-1,157)
1590 V1=Y1
1600 H1=X1
1610 J=JOYST( INT( CO/10)+1)
1620 IF J=255GOTO 1630
1630 IF J<0GOTO 1840
1640 H=(J=7)-(J=3)
1650 V=(J=1)-(J=5)
1660 ON 2+(V=0)-(H=0)GOTO 1750,1610,1670
1670 V=3*V
1700 IF (V1+V<Y1)+(V1+V>Y2)<0GOTO 1610
1710 CALL HCHAR(V1-1,X1-3,152)
1720 V1=V1+V
1730 CALL HCHAR(V1-1,X1-3,156)
1740 GOTO 1610
1750 H=3*H
1790 IF (H1+H<X1)+(H1+H>X2)<0GOTO 1610
1800 CALL HCHAR(Y1-3,H1-1,152)
1810 H1=H1+H
1820 CALL HCHAR(Y1-3,H1-1,157)
1830 GOTO 1610
1840 MUSIC 0,-15,"+F9":PLAY 
1850 VE=V1
1860 HO=H1
1870 KA=LOG( VE*32+HO-33)
1880 IF KA=152GOTO 1610
1890 IF KR>0GOTO 1950
1900 K1=KA
1910 VP=VE
1920 HP=HO
1930 KR=KR+1
1940 GOTO 1980
1950 IF (VE=VP)+(HO=HP)=-2GOTO 1610
1960 K2=KA
1970 KR=KR+1
1980 GOSUB 4010
1990 IF (LE=3)+(LE=6)=0GOTO 2010
2000 GOSUB 3540
2010 IF KR<2GOTO 1610
2020 KR=0
2030 IF K1<> K2GOTO 2110
2040 ON INT( CO/10)+1GOTO 2050,2070
2050 RESTORE 4810
2060 GOTO 2080
2070 RESTORE 4800
2080 GOSUB 4460
2090 ZU=152
2100 GOTO 2140
2110 FOR A=1TO 400+((INT( LE/3)=LE/3)*200)
2120 NEXT A
2130 ZU=K2
2140 GOSUB 4060
2150 IF K1=K2GOTO 2170
2160 ZU=K1
2170 VE=VP
2180 HO=HP
2190 GOSUB 4060
2200 IF K1<> K2GOTO 2310
2210 KZ=KZ-2
2220 PU(INT( CO/10)+1)=PU(INT( CO/10)+1)+1
2230 IF INT( CO/10)=0GOTO 2260
2240 GOSUB 4090
2250 GOTO 2270
2260 GOSUB 4240
2270 IF KZ=0GOTO 3250
2280 GOSUB 3790
2290 GOSUB 4390
2300 GOTO 1610
2310 CALL VCHAR(Y1-1,X1-3,152,16)
2320 CALL HCHAR(Y1-3,X1-1,152,19)
2330 IF GE=0GOTO 2360
2340 CO=ABS{ CO=2)*13+2
2350 GOTO 1560
2360 IF (LE=1)+(LE=4)<0GOTO 2430
2370 FOR B=0TO F-1
2380 IF S(B,0)=0GOTO 2400
2390 IF S(B,0)=S(B+F,0)THEN B1=B:B=F-1:NEXT B:B=B1:GOTO 2770
2400 NEXT B
2430 Z=0
2435 RANDOMIZE 
2440 VS=Y1+3*INT( RND( Y2+3-Y1)/3)
2450 HS=X1+3*INT( RND( X2+3-X1)/3)
2460 C1=LOG( 32*VS+HS-33)
2470 IF C1<> 152GOTO 2510
2480 Z=Z+1
2490 IF Z<5GOTO 2440
2500 GOSUB 3940
2510 VE=VS
2520 HO=HS
2530 KA=C1
2540 MUSIC 0,-15,"+A9":PLAY :GOSUB 4010
2550 VA=1
2560 IF (LE=1)+(LE=4)<0GOTO 2610
2570 FOR B=0TO F*2
2580 IF S(B,0)<> C1GOTO 2600
2590 B1=B:B=F*2:NEXT B:B=B1:GOTO 2770
2600 NEXT B
2610 IF (LE=1)+(LE=4)<0GOTO 2630
2620 GOSUB 3540
2630 Z=0
2635 RANDOMIZE 
2640 VE=Y1+3*INT( RND( Y2+3-Y1)/3)
2650 HO=X1+3*INT( RND( X2+3-X1)/3)
2660 IF (VE=VS)+(HO=HS)=-2GOTO 2630
2670 C2=LOG( 32*VE+HO-33)
2680 IF C2<> 152GOTO 2720
2690 Z=Z+1
2700 IF Z<5GOTO 2640
2710 GOSUB 3860
2720 KA=C2
2730 MUSIC 0,-15,"+A9":PLAY :GOSUB 4010
2740 IF (LE=1)+(LE=4)<0GOTO 2760
2750 GOSUB 3540
2760 GOTO 2990
2770 VC=S(B,1)
2780 HC=S(B,2)
2790 IF (VS=VC)+(HS=HC)=-2GOTO 2630
2800 IF VA<> 1GOTO 2840
2810 C2=LOG( 32*VC+HC-33)
2820 KA=C2
2821 KC=INT( (KAR-33)/5)
2830 GOTO 2860
2840 C1=LOG( 32*VC+HC-33)
2850 KA=C1
2860 VE=VC
2870 HO=HC
2880 MUSIC 0,-15,"+A9":PLAY :GOSUB 4010
2890 IF (LE=1)+(LE=4)<0GOTO 2910
2900 GOSUB 3540
2910 IF VA=1GOTO 2990
2920 VE=S(B+F,1)
2930 HO=S(B+F,2)
2940 C2=LOG( 32*VE+HO-33)
2950 KA=C2
2960 MUSIC 0,-15,"+A9":PLAY :GOSUB 4010
2970 IF (LE=1)+(LE=4)<0GOTO 2990
2980 GOSUB 3540
2990 IF C1<> C2GOTO 3040
3000 RESTORE 4800
3010 GOSUB 4460
3020 ZU=152
3030 GOTO 3070
3040 FOR A=1TO 400+((INT( LE/3)=LE/3)*200)
3050 NEXT A
3060 ZU=C2
3070 GOSUB 4060
3080 IF C1=C2GOTO 3100
3090 ZU=C1
3100 IF VA=1GOTO 3140
3110 VE=VC
3120 HO=HC
3130 GOTO 3170
3140 VE=VS
3150 HO=HS
3160 VA=0
3170 GOSUB 4060
3180 GOSUB 4390
3190 IF C1<> C2GOTO 1570
3200 GOSUB 3790
3210 KZ=KZ-2
3220 PU(2)=PU(2)+1
3230 GOSUB 4090
3240 IF KZ>0GOTO 2360
3250 CALL HCHAR(Y1-3,X1-1,152,19)
3260 CALL VCHAR(Y1-1,X1-3,152,16)
3270 FOR A=1TO 11
3280 IF PU(1)=PU(2)GOTO 3320
3285 FOR I=0TO 10:NEXT I
3290 CALL CHAR(164-(PU(1)>PU(2)),"")
3295 FOR I=0TO 10:NEXT I
3300 CALL CHAR(164-(PU(1)>PU(2)),"FFFFFFFFFFFFFFFF")
3310 GOTO 3360
3320 CALL CHAR(164,"")
3330 CALL CHAR(165,"")
3335 FOR I=0TO 8:NEXT I
3340 CALL CHAR(164,"FFFFFFFFFFFFFFFF")
3350 CALL CHAR(165,"FFFFFFFFFFFFFFFF")
3355 FOR I=0TO 8:NEXT I
3360 NEXT A
3370 IF PU(1)>PU(2)GOTO 3390
3380 CALL CHAR(164,"")
3390 RESTORE 4820
3400 FOR A=153TO 156
3410 READ A$
3420 CALL CHAR(A,A$)
3430 NEXT A
3440 CALL CHRCOL(19,2,1)
3450 VE=11
3460 HO=16
3470 KA=152
3480 GOSUB 4010
3490 MUSIC 0,-15,"+F9+A9+B9":PLAY 
3500 J=JOYST( 1)
3510 IF NOT J<0GOTO 3500
3520 MUSIC 0,-15,"+F9":PLAY :GOTO 280
3540 GOTO 3700
3550 KC=INT( (KA-33)/5)
3560 S(KC+ZF,0)=KA
3600 S(KC+ZF,1)=VE
3650 S(KC+ZF,2)=HO
3690 RETURN 
3700 Z=0:ZF=0:KC=INT( (KA-33)/5)
3710 IF S(KC+Z,0)=KAGOTO 3750
3720 IF Z=FGOTO 3550
3730 Z=F
3740 GOTO 3720
3750 ZF=F-Z
3760 IF VE=S(KC+Z,1)AND HO=S(KC+Z,2)GOTO 3690
3770 IF Z=0GOTO 3730ELSE GOTO 3550
3790 KC=INT( (KA-33)/5)
3800 FOR A=0TO 2
3810 FOR Z=0TO FSTEP F
3820 S(KC+Z,A)=0
3830 NEXT Z
3840 NEXT A
3850 RETURN 
3860 FOR HO=X1TO X2STEP 3
3870 FOR VE=Y1TO Y2STEP 3
3880 C2=LOG( 32*VE+HO-33)
3890 IF C2=152GOTO 3910
3900 IF (VE=VS)+(HO=HS)>-2GOTO 3930
3910 NEXT VE
3920 NEXT HO
3930 RETURN 
3940 FOR HS=X1TO X2STEP 3
3950 FOR VS=Y1TO Y2STEP 3
3960 C1=LOG( 32*VS+HS-33)
3970 IF C1<> 152GOTO 4000
3980 NEXT VS
3990 NEXT HS
4000 RETURN 
4010 CALL HCHAR(VE-1,HO-1,KA+1)
4020 CALL HCHAR(VE,HO-1,KA+2)
4030 CALL HCHAR(VE-1,HO,KA+3)
4040 CALL HCHAR(VE,HO,KA+4)
4050 RETURN 
4060 CALL VCHAR(VE-1,HO-1,ZU,2)
4070 CALL VCHAR(VE-1,HO,ZU,2)
4080 RETURN 
4090 DE=10
4100 CALL HCHAR(21,12,152,2)
4110 RESTORE 4780
4120 FOR A=0TO INT( PU(2)/DE)-INT( PU(2)/10)*(DE-10)/(-9)*10
4130 READ A$
4140 NEXT A
4150 CALL CHAR(148+INT( DE/10),A$)
4160 IF DE=1GOTO 4190
4170 DE=1
4180 GOTO 4110
4190 IF PU(2)=0GOTO 4210
4200 CALL HCHAR(23-PU(2),1,164,2)
4210 CALL HCHAR(21,12,149)
4220 CALL HCHAR(21,13,148)
4230 RETURN 
4240 DE=10
4250 CALL HCHAR(21,18,152,2)
4260 RESTORE 4780
4270 FOR A=0TO INT( PU(1)/DE)-INT( PU(1)/10)*(DE-10)/(-9)*10
4280 READ A$
4290 NEXT A
4300 CALL CHAR(150+INT( DE/10),A$)
4310 IF DE=1GOTO 4340
4320 DE=1
4330 GOTO 4260
4340 IF PU(1)=0GOTO 4360
4350 CALL HCHAR(23-PU(1),29,165,2)
4360 CALL HCHAR(21,18,151)
4370 CALL HCHAR(21,19,150)
4380 RETURN 
4390 VS=0
4400 HS=0
4410 VC=0
4420 HC=0
4430 VE=0
4440 HO=0
4450 RETURN 
4460 READ A$
4480 MUSIC 0,-15,A$
4490 PLAY 
4500 FOR I=0TO 200
4510 NEXT I
4520 RETURN 
4530 DATA "C0300C03030D31C1","030C30C","0101010101010101","8181818181818181","00000000030C30C","030C30C08080808"
4540 DATA "808080808080808","808080808","838CB0C","C0300C03","00000000C0300C03","030C30C0C0300C03","C0B08C838080808"
4550 DATA "80808080C0300C03","FFFFFFFFFFFFFFFF"
4560 DATA "FFFF80B9A9B9A9B9","80BFB5AAB5BF80FF","FFFF013911111111","01FD55AD55FD01FF","","FFFFFFFFFFFFFFFF"
4570 DATA "001F3F6040C8D4C9","C1C340504F27100F","00F8FC0602132B93","83C3020AF2E408F0","0088D8A8888888D8","00F88880E08088F8"
4580 DATA "0070508888885070","00F08888F0A090C8","","008888F820202070","0000000007020707","000E0E041F1F1F1F","1E1E0C3F3F3F3F3F"
4590 DATA "7E7E18FFFFFFFFFF","0040707C7F7C704",""
4600 DATA 148,149,148,150,151,153,5,7,160,6,7,161,5,8,162,6,8,163,8,7,184,9,7,185,8,8,186
4610 DATA 9,8,187,154,155,156,155,156,157
4620 DATA "FFC0C0C7FEFDFDF3","F3F3CFCF3F00FFF3","FF0303E37FBFBFCF","CFCFF3F3FC00FFCF","003F000F10100F","000F1010100807"
4630 DATA "00C040FC4040F844","44F840404080","001806317DEF7F07","1F7DFBF7EF7E1C","0018608CBEF7FEE0","F8BEDFEFF77E38"
4640 DATA "000C121101433F1D","1F1F3D1F1F6F8301","0030488880C2FCB8","F8F8BCF8F8F6C18","00003C7E7F7F7F3F","1F0F070301"
4650 DATA "00003C7EFEFEFEFC","F8F0E0C080","F0F0F0F00F0F0F0F","F0F0F0F00F0F0F0F","F0F0F0F00F0F0F0F","F0F0F0F00F0F0F0F"
4660 DATA "4040404040407C","42424224242418","38444444444438","7C40407840407C","0040301C0E070103","070D1F1F0F030101"
4670 DATA "0002060E1C38B0F0","F8FCFCFCFCF8F0E0","070A1F323F321F0A","0703010101010101","E050F84CFC4CF850","E0C0808080808080"
4680 DATA "00784478444478","3C24243C04043C","009C8888888888","38444444444438","00547C6C282A3F3F","3F2E2C3D3D3D3D"
4681 DATA "002A3E361454FCFC"
4690 DATA "FC7434BCBCBCBC","00000000070F1D3F","E93F0F03","00000000E0F0B8FC","97FCF0C0","0005236919398543","FF43853919692305"
4700 DATA "0040882C30384284","FE844238302C884","001F101013392F38","7B607F067E3330","00F80808C89CF41C","DE06FE607ECC0C"
4710 DATA "003062E1797F0F0F","0303671B01020C04","000C4687CEFEF0F0","C0C0E6D88040302","001F202728292A2A","2A292827201F"
4720 DATA "00F804E414945494","14E404F800FC","0F10274893A4A9AA","AAAAA9A4934827","F008E412C9259555","9525C912E408F0"
4730 DATA "FEFEFAF2E2C28202","FFFF7F1F0F0E0C18","BF9F8F8783818080","FFFCF0C0","04083010780E0602","37FDFF0707020301"
4740 DATA "20100C081E706040","ECBFFFE0E040C08","1C3E7F7F7F604F0507","0507020302030101","30787C7C7C0CE840C0","40C08080808"
4750 DATA "BBB99CCFE7F3F8FF","FFF8F3E7CF9CB9BB","DD9D39F3E7CF1FFF","FF1FCFE7F3399DDD","0040707C7F7C704","00FE7C7C3838101"
4760 DATA 10,22,6,15,20,10
4770 DATA 7,25,3,18,42,21
4780 DATA "00708898A8C88870","0020602020202070","00708808304080F8","00F8081030088870","0010305090F81010","00F880F008088870"
4790 DATA "00304080F0888870","00F8081020404040","0070888870888870","00708888780810E0"
4800 DATA "+C2+D2+E2+F2+G2+A2+B2C2D2E2F2G2A2B2-C2-D2-E2-F2-G2-A2-B2-G2-E2C2A2F2D2+B2+G2+E2+C2"
4810 DATA "+C2+E2+G2+B2D2F2A2C2-E2-G2-B2-A2-G2-F2-E2-D2-C2B2A2G2F2E2D2C2+B2+A2+G2+F2+E2+D2C"
4820 DATA "0121212121A97121","0377FFFFFFFFFF7F","808080808080808","C0E0FFFFFFFFFFFE"
