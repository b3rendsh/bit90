#!/usr/bin/env python3
# BIT90 Basic to Binary encoder v1.0
# Encoding of BIT90 BASIC Ascii file to a tokenized binary file as stored in BIT90 memory.
#
# Limitations:
# An encoded line should not exceed 128 characters
# Line numbers cannot be higher than 9999 (because they are stored in BCD format in the BIT90)
# Extended Tokencodes are expected to be written as TOKEN[nn]
# Special characters (> 0x80) within quotes are expected to by written as a CHR$(nnn) character
# There is no complete syntax checking, only recogized UPPERCASE tokens are replaced by their code
# The basic program is expected to be stored in memory starting at address 0x8004 (default for 16K/32K RAM memory)
# 
# Each encoded BASIC line consists of:
# POS VALUE
# 00   Position of next line low byte
# 01   Position of next line high byte 
# 02   Line number low byte (as Binary Coded Decimal)
# 03   Line number high byte (as Binary Coded Decimal)
# 04   Tokencode of BASIC command or ascii characters
# ..
# NN   0x00 indicates end of line
# The end of program is indicated by 0x00 0x00
#

import sys	# needed for the commandline parameter

try:
    if len(sys.argv) != 2:
        print('Usage: bit90bin.py <filename-without-extension>')
        quit()
    filename = sys.argv[1]
    with open(filename + '.bas', 'r') as f, open(filename + '.bin', 'wb') as w:
        tokentab  = ['NEW','SAVE','LOAD','EDIT','DELETE','RUN','STOP','CONT','MUSIC','TEMPO','POKE','PEEK(','DEF','OPEN','DIM','RND(','TAB(','AUTO',\
                     'GOSUB','CALL','DATA','ELSE','FOR','GOTO','HOME','INPUT','RANDOMIZE','CLEAR','LIST','REM','NEXT','ON','PRINT','RESTORE','READ',\
                     'STEP','THEN','PLOT','RETURN','TO','UNTRACE','IF','TRACE','COPY','RENUM','PLAY','RESERVED-174','FRE','BYE','END','OPTIONBASE','LET',\
                     'OUT','ONERRGOTO','RESUME','WAIT','REC','>=','<=','<>','AND','OR','NOT','HEX$(','ABS{','ATN{','COS(','EXP(','INT(','LOG(','LN(',\
                     'SGN(','SIN(','SQR(','TAN(','STR$(','CHR$(','IN(','JOYST(','EOF(','SPC(','RIGHT$(','ASC(','VAL(','LEFT$(','MID$(','LEN(','INKEY$',\
                     'POS','BLOAD','FN','BSAVE','RESERVED-220','DEL','RESERVED-222','RESERVED-223']
        count    = 0
        basline  = f.readline().strip() # remove leading and trailing spaces and cr/lf
        binline  = [0,0]
        posline  = 32768+4    # Base address is 0x8004
        linelast = 0
        linecur  = 0
        while len(basline) > 2:
            count += 1
            n = basline.find(' ')
            if n < 1 or n > 4 or not basline[0:n].isnumeric():
                print('Linenumber format error: '+basline)
                quit()
            linenr = basline[0:n].rjust(4,'0')
            binline.append(int(linenr[2])*16 + int(linenr[3]))
            binline.append(int(linenr[0])*16 + int(linenr[1]))
            linecur = int(linenr)
            if linecur <= linelast:
                print('Linenumber sequence error: '+basline)
                quit()
            linelast = linecur
            # print basic line to screen and save to file
            print('Line: ' + linenr)
            
            # parse the contents of the line, assume a space character after the line number
            basline = basline[5:]
            errparse = False
            quoted = False
            rem = False
            while len(basline) > 2: 
                if not (quoted or rem):
                    # check for a command except after a rem statement or when within quotes
                    # if the command is preceeded by a space then remove the space
                    tokencode = 128 
                    for command in tokentab:
                        if basline.lstrip().startswith(command):
                            # print(command)
                            binline.append(tokencode)
                            basline = basline.lstrip()
                            basline = basline[len(command):]
                            # print(basline)
                            if command == 'REM':
                                rem = True     # don't parse the rest of the line                            
                            else:
                                basline = basline.lstrip()
                            break
                        tokencode += 1    
                if (tokencode == 224) or quoted or rem:
                    if basline.startswith('";CHR$(') and len(basline) > 13:   # Special character > 128 is written as ";CHR$(nnn);"
                        binline.append(int(basline[7:10]))
                        basline = basline[13:]
                    elif len(basline) > 0:
                        if basline[0] == '"':
                            quoted = not quoted
                        binline.append(ord(basline[0]))
                        basline = basline[1:]
            
            while len(basline) > 0:
                binline.append(ord(basline[0]))
                basline = basline[1:]
                        
            binline.append(0)
            
            posline += len(binline)
            binline[1] = int(posline/256) 
            binline[0] = posline % 256
            # print(binline)
            for i in binline:
                w.write(i.to_bytes(1,'big'))
             
            basline  = f.readline().strip()
            binline  = [0,0]
        i = 0
        w.write(i.to_bytes(1,'big'))
        w.write(i.to_bytes(1,'big'))
        
except IOError:
        print('Error encoding file: ' + filename + '.bas')
	





