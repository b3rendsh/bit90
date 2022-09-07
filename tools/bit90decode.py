# Python 3
# BIT90 WAV file decoder v1.2
# The input file should be a raw file type PCM 8-bit unsiged 44100Hz mono
#
# The BIT90 saves data to tape in blocks of 256 bytes
# Every second there's a sync signal (followed by 8 bits) and then 19 bytes of control data.
# Each byte is saved with least significant bit first and followed by 2 stop/sync bits.
# The stop bits are:
#     0 0 = init tape
#     1 0 = sync data
#     1 1 = user data
# The data is saved with FSK modulation. A 0 bit wave has lower frequency than a 1 bit.
# The difference between 0 and 1 is recognized by counting the number of samples in 1 complete sine-wave.


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
        blockdta = []           # each data block should contain 256 bytes
        blocks   = 0            # total number of blocks written to file

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
                    if syncbyte > 18:
                      print('sync: '+ str(syncs+1) + '  bytes: ' + str(syncbyte-19))
                      syncs += 1
                    syncbyte = 0
                    blockdta = []
                else:
                    if total >= 10 and total <= 13:
                        bit = 1
                    elif total >= 16 and total <= 19:
                        bit = 0
                    else:
                        bit = -1
                        noise += 1
                if bit >= 0:
                    bits += 1
                    if bits > 0 and bits <= 8:
                        bytehex += pow(2, (bits -1) % 8) * bit
                    elif bits == 10:
                        if bit == 1:
                            if syncbyte > 18:
                                blockdta.append(bytehex)
                                if len(blockdta) == 256:
                                    for i in blockdta:
                                        w.write(i.to_bytes(1,'big'))
                                    blockdta = []
                                    blocks += 1
                            syncbyte += 1
                        bytehex = 0
                        bits = 0 
                else:
                    # reset bitcount after sync
                    bits = -8       # after sync start byte after next 8 bits
                    bytehex = 0
                    
                countLo = 1
                countHi = 0
                wave = 0
            byte = int.from_bytes(f.read(1),'big')
            bytenr += 1
        print('\nSyncs : ' + str(syncs))
        print('Blocks: ' + str(blocks) + ' (' + str(blocks*256) + ' bytes)')
        print('Noise : ' + str(noise))
except IOError:
	print('Error decoding file:' + filename + '.raw')
	





