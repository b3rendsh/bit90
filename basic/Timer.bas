0010 C=PEEK( 29953)*256+PEEK( 29952)
0020 E=PEEK( 28678)*256+PEEK( 28677)
0030 I=14854:MT=PEEK( 29161)*256+PEEK( 29160)
0040 IF E<> IAND E<> CTHEN GOTO 70
0050 IF E=ITHEN POKE MT,255:MT=MT-1:GOTO 70
0060 GOTO 230
0070 FOR A=29954TO 29994
0080 READ D:POKE A,D
0090 NEXT A
0100 FOR A=MT-8TO MT
0110 READ D:POKE A,D
0120 NEXT A
0130 MT=MT-9
0140 POKE 29161,INT( MT/256):POKE 29160,MT-INT( MT/256)*256
0150 POKE 29163,PEEK( 29161):POKE 29162,PEEK( 29160)
0160 POKE 28677,PEEK( 29160)+1:POKE 28678,PEEK( 29161)
0170 POKE 29952,PEEK( 28677):POKE 29953,PEEK( 28678)
0180 DATA 205,64,37,245,126,254,44,194,243,2
0190 DATA 35,205,64,37,209,60,60,230,31,95
0200 DATA 175,203,26,31,203,26,31,203,26,31
0210 DATA 179,95,122,230,3,87,237,83,15,112,201
0220 DATA 76,79,67,65,84,69,224,2,117
0230 CALL SCREEN(1):FOR Z=0TO 31:CALL CHRCOL(Z,7,1):NEXT Z
0240 HOME :INPUT "INKEY HOUR,MINUTE,SECONDS :   ",HR,MI,SC
0250 IF HR<0OR MI<0OR SC<0GOTO 240
0260 HOME :TOKEN[224] 8,10:?"T I M E :"
0270 MUSIC 1,1,*,"R":PLAY 
0280 IF PEEK( 29532)<50THEN GOTO 280
0290 POKE 29532,0:SC=SC+1:IF SC>59THEN MI=MI+1:SC=0:IF MI>59THEN HR=HR+1:MI=0:IF HR>23THEN HR=0
0300 TOKEN[224] 12,11:PRINT SPC( 10):TOKEN[224] 12,11:PRINT HR;":";MI;":";SC;
0310 GOTO 280