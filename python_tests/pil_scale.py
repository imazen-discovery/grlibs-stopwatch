#!/usr/bin/env python

# Program to resize images using Pillow (with the PIL interface
# layer).

import os, sys
from PIL import Image

from timer import TimerContext, printResults


def main(imgfile, widths):
    with TimerContext("# " + imgfile, "Loading"):
        im = Image.open(imgfile)

    iw, ih = im.size

    count = 1
    for width in widths:
        if width <= 0:
            print "Illegal width: ", width
            exit(1)

        height = int(round( float(ih * width) / iw))

        outfile = "%d-pil-%d-%s" % (width, count, os.path.basename(imgfile))
        count = count + 1

        with TimerContext(imgfile, str(width)):
            result = im.resize( (width, height), Image.BICUBIC)

        with TimerContext(outfile, "saving..."):
            result.save(outfile, "JPEG")

    printResults()
                                


if len(sys.argv) < 3:
    print "Usage: shrink.py <filename> <percentage> ..."
    exit(1)

fname = sys.argv[1]
widths = map(lambda(x): int(x), sys.argv[2:])
main(fname, widths)

