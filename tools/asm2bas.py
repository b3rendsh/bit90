#!/usr/bin/env python3
# Assembly to BASIC loader v0.1
# Create BASIC DATA statements to load an assembly program
# Input is an assembly binary file

import sys	# needed for the commandline parameter

try:
    if len(sys.argv) != 2:
        print('Usage: asm2bas.py <filename-without-extension>')
        quit()
    filename = sys.argv[1]
    with open(filename + '.bin', 'rb') as f, open(filename + '.bas', 'w') as w:

        # Write Loader
        w.write('9000 REM LOAD ASSEMBLY PROGRAM / DATA\n')
        w.write('9010 REM ME=memory address NN=bytes\n')
        w.write('9020 RESTORE 9100\n')
        w.write('9030 FOR I=0TO NN-1\n')
        w.write('9040 READ A\n')
        w.write('9050 POKE ME+I,A\n')
        w.write('9060 NEXT I\n')
        w.write('9070 RETURN\n')
        
        # Write data
        i          = 0
        basline    = ''
        pos        = f.tell()
        byte       = int.from_bytes(f.read(1),'big')
        basline    = '9100 DATA ' + str(byte)
        byte       = int.from_bytes(f.read(1),'big')
        linenumber = 9100
        while pos < f.tell():
            pos = f.tell()
            if i == 15:
                print(basline)
                w.write(basline)
                w.write('\n')                
                linenumber += 10
                basline = str(linenumber)+ ' DATA ' + str(byte)                                
                i = 0
            else:
                basline += "," + str(byte)
                i += 1
            byte = int.from_bytes(f.read(1),'big')
        if i > 0:
            print(basline)
            w.write(basline)
         
except IOError:
        print('Error processing file:' + filename + '.bin')
	





