#!/bin/bash

# Generate multiple shrinks using different interpolation algorithms

set -e

IMG=8s
SZ=800

WORKDIR=tmp-shrink-comparisons
SHRINKCMD='./ruby_tests/gd_resize_simple.rb --force-truecolor'

REF=ref$$.png


if [ ! -d cfg_scripts ]; then
    echo "Must be run in project root directory."
    exit 1
fi

# Create the work dir if not present
[ -d $WORKDIR ] || mkdir $WORKDIR

# Fetch the original reference images
./cfg_scripts/fetch-images.sh

# Fetch the shrunk images from resizer
./cfg_scripts/fetch-shrunk-images.sh $IMG

cp ./data/shrunk/$SZ/$IMG.png $WORKDIR/ref.png

# Compute the image dimensions
width=$SZ
height=`identify -format '%h' $WORKDIR/ref.png`
SRC=./data/$IMG.jpg

# Aaaaaand, shrink:
for mode in `$SHRINKCMD --modes`; do
    echo "$mode:"
    $SHRINKCMD --interp $mode $SRC $width $height $WORKDIR/$IMG-$SZ-$mode.png
done

