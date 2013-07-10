
CC=gcc
CFLAGS=-Wall -O -g `pkg-config vips --cflags`

LD=gcc
LDFLAGS=-g
LIBS=`pkg-config vips --libs`

all: shrink stats benchmark

shrink: shrink.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)  

stats: stats.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

benchmark: benchmark.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

timer.o: timer.c
util.o: util.c

clean:
	-rm *.o shrink stats benchmark
