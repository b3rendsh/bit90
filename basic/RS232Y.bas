0010 GOSUB 9000
0011 TOKEN[224] 15,1
0012 ?"MENU :":?"------":?
0013 ?" 1. Conversation"
0014 ?" 2. Terminal take over"
0016 ?:?"Your choise ? "
0017 TOKEN[226] 7,14,2,A$:A=VAL( A$):IF A<1OR A>2GOTO 17
0018 TOKEN[225] :IF A=2GOTO 2000
0020 TOKEN[224] 7,1
0030 POKE 30209,22:?"mode : TRANSMISSION "
0040 ?"enter empty line to receive a messsage";
0050 POKE 30213,21:POKE 30208,0:POKE 30209,0
0060 TOKEN[226] ,50,A$
0070 T=0:FOR I=1TO 50:A=ASC( MID$( A$,I,1)):IF T=0THEN T=(A<> 32)
0080 WAIT 69,1,0:OUT 68,A
0082 NEXT I
0085 WAIT 69,1,0:OUT 68,13
0090 IF T=0GOTO 200
0100 GOTO 60
0200 TOKEN[224] 7,1
0210 POKE 30209,22:?"mode : RECEIVE"
0220 ?"press any key to transmit a messsage";
0230 POKE 30213,21:POKE 30208,0:POKE 30209,0
0240 A=ASC( INKEY$ ):IF A<> 255GOTO 20
0250 WAIT 69,2,0:A=IN( 68):?CHR$( A);:OUT 68,A
0260 GOTO 240
1000 CALL SPRPTN(5,"00000000F8000000")
1030 REM  WAIT 69,2,0:A=IN( 68):?CHR$( A);
1040 REM  IF A<255GOTO 1030
1050 CALL SPRITE(PEEK( 30209)*8,PEEK( 30208)*5+6,5,15,0)
1060 A=ASC( INKEY$ )
1065 IF A=255GOTO 1080
1070 REM  WAIT 69,1,0:OUT 68,A
1071 ?CHR$( A);
1080 CALL SPRITE(0,0,0,0,0):GOTO 1030
9000 POKE 29160,255:POKE 29161,159
9010 POKE 29162,255:POKE 29163,159
9020 IF PEEK( 28677)+PEEK( 28678)*256<> 63232THEN BLOAD "TEKST.CODE"
9030 POKE 28677,0:POKE 28678,247
9040 TOKEN[224] 15,1
9050 ?"     BIT 90 TERMINAL INTERFACE PROGRAM"
9060 ?
9070 ?"The interface is set at : ":?
9080 ?"- 2400 BAUD"
9090 ?"- 8 BITS"
9100 ?"- NO PARITY"
9110 ?"- 2 STOP BITS"
9120 ?"- NO HANDSHAKE"
9130 ?"- PRINTER OFF"
9132 POKE 30208,0:POKE 30209,12:?"Do you wish to change settings (y/n) ?":TOKEN[226] 12,40,2,A$:A$=LEFT$( A$,1)
9134 IF A$<> "Y"AND A$<> "y"AND A$<> "N"AND A$<> "n"GOTO 9132
9136 IF A$="Y"OR A$="y"THEN STOP 
9140 OUT 70,0:REM  SPEED
9150 OUT 69,0:OUT 69,0:OUT 69,0
9160 OUT 69,64
9170 OUT 69,206
9180 OUT 69,55
9190 RETURN 
