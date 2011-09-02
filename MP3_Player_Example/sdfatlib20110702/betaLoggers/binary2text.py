import struct
f = file('LOGFILE.BIN', 'rb')
i = 0;
while 1:
    s = f.read(2)
    if not s:
        break
    n = struct.unpack("<H", s)[0]
    if i % 256 == 0:
        if n == 0:
            break
        over = n & 0X7FFF
        if over != 0:
            print 'Overrun,%d' % over
    else:
        print n
    i = i + 1

