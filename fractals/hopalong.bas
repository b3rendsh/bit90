0010 REM HOPALONG ATTRACTOR
0020 RANDOMIZE
0030 CALL SCREEN(1,1)
0040 A=RND(100)-50:B=RND(100)-50:C=RND(100)-50
0050 Z=RND(0.95)+1:CL=RND(13)+2
0060 X=0:Y=0
0070 XN=Y-SGN( X)*SQR( ABS( B*X-C))
0080 YN=A-X
0090 PLOT 96+Y*Z,128+X*Z,CL
0100 X=XN:Y=YN
0110 IF ASC( INKEY$)=255GOTO 70
0120 GOTO 30
