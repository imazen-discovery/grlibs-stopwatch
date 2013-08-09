#!/usr/bin/python

import sys
from timer import TimerContext, printResults

# Add the path to vipsCC by hand so I don't have to mess around with environment variables.
sys.path += ['/usr/local/lib/python2.7/site-packages/']

from vipsCC import *


def main(imgfile, percentages):
    with TimerContext("# " + imgfile, "Loading"):
        im = VImage.VImage(imgfile, "r")

    for pc in percentages:
        if pc <= 0 or pc > 100:
            print "Illegal percentage: ", pc
            exit(1)

        outfile = "%d-vips-py-%s" % (pc, imgfile)
        sz = round(100.0/pc)
        with TimerContext(imgfile, str(pc)):
            im.shrink(sz, sz).write(outfile)

    printResults()
                                


if len(sys.argv) < 3:
    print "Usage: shrink.py <filename> <percentage> ..."
    exit(1)

fname = sys.argv[1]
percentages = map(lambda(x): int(x), sys.argv[2:])
main(fname, percentages)



