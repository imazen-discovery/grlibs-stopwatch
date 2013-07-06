
CC=gcc
CFLAGS=-Wall -O -g `pkg-config vips-7.26 --cflags`

LD=gcc
LDFLAGS=-g

all: shrink stats benchmark

shrink: shrink.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^  `pkg-config vips-7.26 --libs`

stats: stats.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^  `pkg-config vips-7.26 --libs`

benchmark: benchmark.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^  `pkg-config vips-7.26 --libs`

timer.o: timer.c
util.o: util.c

clean:
	-rm *.o shrink stats benchmark
