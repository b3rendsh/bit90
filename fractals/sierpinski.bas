0010 REM SIERPINSKI TRIANGLE
0020 CALL SCREEN(1,1)
0030 H=0.5
0040 P=190
0050 RANDOMIZE
0060 FOR I=1TO 9^6
0070 N=RND(3)
0080 IF N> 2THEN X=H+X*H:Y=Y*H:GOTO 110
0090 IF N> 1THEN X=H^2+X*H:Y=H+Y*H:GOTO 110
0100 X=X*H:Y=Y*H
0110 PLOT P-INT(X*P),P-INT(Y*P),RND(13)+2
0120 NEXT I
0130 IF ASC( INKEY$)=255GOTO 130
