
VIPS=vips
#VIPS=vips-7.26

CC=gcc
CFLAGS=-Wall -O -g `pkg-config $(VIPS) --cflags` `pkg-config gdlib --cflags`

LD=gcc
LDFLAGS=-g
VIPSLIBS=`pkg-config $(VIPS) --libs` -lrt
GDLIBS=`pkg-config gdlib --libs` -lm -lrt


all: vips_shrink stats benchmark gd_scale

vips_shrink: vips_shrink2.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(VIPSLIBS)  

stats: stats.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(VIPSLIBS)

benchmark: benchmark.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(VIPSLIBS)

gd_scale: gd_scale.o timer.o util.o
	$(LD) $(LDFLAGS) -o $@ $^ $(GDLIBS)


timer.o: timer.c
util.o: util.c


clean:
	-rm *.o vips_shrink stats benchmark gd_scale
