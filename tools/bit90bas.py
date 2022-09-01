# Python 3
# BIT90 Binary to Basic decoder v1.0
#
# Each BASIC line consists of:
# POS VALUE
# 00   Position of next line low byte
# 01   Position of next line high byte 
# 02   Line number low byte
# 03   Line number high byte
# 04   Tokencode of BASIC command or ascii characters
# ..
# NN   0x00 indicates end of line
#
# Extended Tokencodes will be written as TOKEN[nn]
# Graphics characters (non ascii) that are used within quotes will be written as CHR$(nnn)

import sys	# needed for the commandline parameter

try:
    if len(sys.argv) != 2:
        print('Usage: bit90bas.py <filename-without-extension>')
        quit()
    filename = sys.argv[1]
    with open(filename + '.bin', 'rb') as f, open(filename + '.bas', 'w') as w:
        byte1    = int.from_bytes(f.read(1),'big')
        byte2    = int.from_bytes(f.read(1),'big')
        basline  = ''
        tokentab = ['NEW','SAVE','LOAD','EDIT','DELETE','RUN','STOP','CONT','MUSIC','TEMPO','POKE','PEEK(','DEF','OPEN','DIM','RND(','TAB(','AUTO',\
                    'GOSUB','CALL','DATA','ELSE','FOR','GOTO','HOME','INPUT','RANDOMIZE','CLEAR','LIST','REM','NEXT','ON','PRINT','RESTORE','READ',\
                    'STEP','THEN','PLOT','RETURN','TO','UNTRACE','IF','TRACE','COPY','RENUM','PLAY','RESERVED-174','FRE','BYE','END','OPTIONBASE','LET',\
                    'OUT','RESERVED-181','RESERVED-182','WAIT','REC','>=','<=','<>','AND','OR','NOT','HEX$(','ABS{','ATN{','COS(','EXP(','INT(','LOG(','LN(',\
                    'SGN(','SIN(','SQR(','TAN(','STR$(','CHR$(','IN(','JOYST(','EOF(','SPC(','RIGHT$','ASC(','VAL(','LEFT$(','MID$(','LEN(','INKEY$',\
                    'POS','BLOAD','FN','BSAVE','RESERVED-220','DEL','RESERVED-222','RESERVED-223']
        startbas  = False  # Start of basic program dete
        quoted    = False  # Detect if a special character is quoted instead of tokencode for values > 0x80
        while byte1 > 0 or byte2 > 0:
            if byte2 == 0x80 or startbas == True:      #(first value of 0x80 assume as the start of the basic program because programs start at 0x8000 memory location
                startbas = True
                # Start of new line
                
                #read linenumber
                byte1    = int.from_bytes(f.read(1),'big')
                byte2    = int.from_bytes(f.read(1),'big')
                
                if byte1 + byte2 > 0:   # The beginning of the program may contain an empty basic line with linenumber 0000, to be ignored

                    if byte2 <= 9:
                        basline += '0'
                    basline += str(hex(byte2))[2:]   # remove the 0x
                    if byte1 <= 9:
                        basline += '0'
                    basline += str(hex(byte1))[2:]   # remove the 0x
                    basline += ' '
                    
                    #read rest of the line until 00
                    byte2 = int.from_bytes(f.read(1),'big')
                    quoted = False
                    while byte2 != 0x00:
                        if byte2 == 0x22:
                            quoted =  not quoted
                        if byte2 > 0x80 and quoted == False:
                            # replace token with command
                            if byte2 > 128 and byte2 < 224:
                                basline += tokentab[byte2 - 128]+' ' 
                            else:
                                basline += 'TOKEN['+str(byte2)+'] '
                        elif byte2 >= 32 and byte2 < 127:
                            basline += chr(byte2)
                        else:
                            basline += '\";CHR$('+str(byte2)+');\"'
                        byte2 = int.from_bytes(f.read(1),'big')
                    
                    # print basic line to screen and save to file
                    print(basline)
                    w.write(basline)
                    w.write('\n')
                    basline = ''
                byte2 = int.from_bytes(f.read(1),'big')
                byte1 = byte2
            byte2 = int.from_bytes(f.read(1),'big')
                    
except IOError:
        print('Error decoding file:' + filename + '.bin')
	





