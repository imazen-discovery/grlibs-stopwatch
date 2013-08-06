
VIPS=vips
#VIPS=vips-7.26

CC=gcc
CFLAGS=-Wall -O -g `pkg-config $(VIPS) --cflags`

LD=gcc
LDFLAGS=-g
LIBS=`pkg-config $(VIPS) --libs`

all: vips_shrink stats benchmark

vips_shrink: vips_shrink.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)  

stats: stats.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

benchmark: benchmark.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

timer.o: timer.c
util.o: util.c

clean:
	-rm *.o vips_shrink stats benchmark
