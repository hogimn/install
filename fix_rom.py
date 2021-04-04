import sys

rom_size = int(sys.argv[1])

f = open('gpxe/src/bin/1af41000.rom', 'a')
f.write('\0' * (65535-rom_size))
f.close()
