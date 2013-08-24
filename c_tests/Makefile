
VIPS=vips
#VIPS=vips-7.26

CC=gcc
#DBG=-pg
DBG=-g
CFLAGS=-Wall -O $(DBG) `pkg-config $(VIPS) --cflags` `pkg-config gdlib --cflags`

LD=gcc
LDFLAGS=$(DBG)
LIBVIPS=`pkg-config $(VIPS) --libs`
LIBGD=`pkg-config gdlib --libs`

all: vips_shrink stats benchmark gd_resize

vips_shrink: vips_shrink.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBVIPS)  

stats: stats.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBVIPS)

benchmark: benchmark.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBVIPS)

gd_resize: gd_resize.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBGD)

timer.o: timer.c
util.o: util.c

clean:
	-rm *.o vips_shrink stats benchmark
