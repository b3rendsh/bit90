# Python 3
# BIT90 WAV file decoder v1.0
# The input file should be a raw file type PCM 8-bit unsiged 44100Hz mono


import sys	# needed for the commandline parameter

try:
    if len(sys.argv) != 2:
        print('Usage: bit90decode.py <filename-without-extension>')
        quit()
    filename = sys.argv[1]
    with open(filename + '.raw', 'rb') as f, open(filename + '.bin', 'wb') as w:
        countLo  = 0
        countHi  = 0
        wave     = 0            # 0=start wave lower part, 1=startwave high part and 2=start new wave
        bytenr   = 1            # counter for position in the file
        syncs    = 0            # number of synchronisation breaks (begin + end)
        noise    = 0            # number of waves that don't fit in the pattern (usually at start and end of the file)
        bits     = 0            # number of correct bits read from file        
        bytehex  = 0            # hexidecimal byte sum of each 8 bits
        message  = ''           # decoded message
        syncbyte = 0            # counter for number of bytes to skip after sync (total 19)

        byte = int.from_bytes(f.read(1),'big')
        while byte:
            if wave == 0:
                if byte > 0x30 and byte < 0x60:
                    countLo += 1
                else:
                    wave = 1
            if wave == 1:
                if byte > 0xA0 and byte < 0xD0:
                    countHi += 1
                if byte > 0x30 and byte < 0x60:
                    # start new wave
                    wave = 2
            if wave == 2:
                total = countLo + countHi
                if countLo < 4 or countHi < 4 or countLo > 10 or countHi > 10:
                    # Sync detected
                    bit = -2
                    syncbyte = 0
                    syncs += 1
                else:
                    if total >= 10 and total <= 13:
                        bit = 1
                    elif total >= 16 and total <= 19:
                        bit = 0
                    else:
                        bit = -1
                        noise += 1
                # print('Bytenr: ' + str(hex(bytenr)) + '  bit: ' + str(bit) + ' total: ' + str(total))
                if bit >= 0:
                    bits += 1
                    if bits > 0 and bits <= 8:
                        bytehex += pow(2, (bits -1) % 8) * bit
                    elif bits == 10:
                        # probable use of bit 9 and bit 10 after each byte:
                        # 0 0 = init tape data
                        # 1 0 = sync data
                        # 1 1 = user data
                        # message += ' ' + str(hex(bytehex))
                        # print('bytehex: ' + str(hex(bytehex)))
                        if bit == 1:
                            if syncbyte > 18:
                                w.write(bytehex.to_bytes(1,'big'))
                            else:
                                # print('syncbyte:' + str(syncbyte))
                                syncbyte += 1

                        bytehex = 0
                        bits = 0 
                else:
                    # reset bitcount after sync
                    bits = -8       # after sync start byte after next 8 bits (to be improved)
                    bytehex = 0
                    
                countLo = 1
                countHi = 0
                wave = 0
            byte = int.from_bytes(f.read(1),'big')
            bytenr += 1
        print('Syncs : ' + str(syncs))
        print('Noise : ' + str(noise))
        # print('Bits  : ' + str(bits))
        # print('Message : ' + message)
except IOError:
	print('Error decoding file:' + filename + '.raw')
	





