import os
import mmap
import time
import sys

def decode(b: bytearray):
    for ofs in range(0, len(b), 4):
        cmd = int.from_bytes(b[ofs:ofs+4], byteorder='little')

        if (cmd & 0xc0000000) == 0x00000000:
            print( f"Counter: {cmd & 0x3fffffff}" )
        if (cmd & 0xc0000000) == 0x40000000:
            data = cmd & 0xffff
            addr = (cmd >> 16) & 0xfff
            we = (cmd >> 28) & 3
            print( f"CPU Ext Mem: {we} {addr:x} {data:x}" )
        if (cmd & 0xc0000000) == 0x80000000:
            data = cmd & 0xff
            addr = (cmd >> 8 ) & 0xfff
            we = ( (cmd >> 20) & 1 ) == 1
            print( f"MCU Ext Mem: write:{we} {addr:x} {data:x}" )
        if (cmd >> 24) == 0xc0:
            cs = cmd & 0xffff
            print( f"CPU CS: {cs:x}" )
        if (cmd >> 24) == 0xc1:
            ip = cmd & 0xffff
            opcode = (cmd >> 16) & 0xff
            print( f"CPU IP: {ip:x} {opcode:x}" )
        if (cmd >> 24) == 0xc2:
            addr = cmd & 0xffff
            print( f"MCU ROM Read: {addr:x}" )

addr = 0x30000000
write_count_addr = 0x4000000
read_count_addr = write_count_addr + 8
init_count_addr = read_count_addr + 8

def get_write_count(m):
    val = int.from_bytes(m[write_count_addr:write_count_addr+8], byteorder='little')
    return val

def get_read_count(m):
    val = int.from_bytes(m[read_count_addr:read_count_addr+8], byteorder='little')
    return val

def set_read_count(m, count):
    b = count.to_bytes(8, byteorder='little')
    m[read_count_addr:read_count_addr+8] = b

def get_init_count(m):
    val = int.from_bytes(m[init_count_addr:init_count_addr+8], byteorder='little')
    return val

def write_circular(fp, m, start, end):
    SZ = 64 * 1024 * 1024
    start_address = ( start * 1024 ) % SZ
    end_address = ( end * 1024 ) % SZ

    if ( end - start ) > ( 64 * 1024 ):
        print( f"Overrun: {end:x} {start:x}" )

    if end_address < start_address:
        fp.write(m[start_address:SZ])
        fp.write(m[0:end_address])
    else:
        fp.write(m[start_address:end_address])

f = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
m = mmap.mmap(f, 65 * 1024 * 1024, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE, offset=addr)


if len(sys.argv) == 2 and sys.argv[1] == "dumb":
    while True:
        set_read_count(m,get_write_count(m))
        time.sleep(1)

set_read_count(m,0)

init_count = get_init_count(m)
print( f"Init Count = {init_count}, waiting..." )

while init_count == get_init_count(m):
    time.sleep(1)

init_count = get_init_count(m)
print( f"Init Count = {init_count}, startin." )


with open( "/media/fat/m72_trace.bin", "wb" ) as out_fp:
    try:
        while True:
            rc = get_read_count(m)
            wc = get_write_count(m)

            print( f"Write Count: {wc:x} Read Count {rc:x}" )
            
            if wc > rc:
                write_circular(out_fp, m, rc, wc)
                set_read_count(m, wc)
            else:
                time.sleep(1)
    except KeyboardInterrupt:
        pass



