#!/bin/bash

# Generate comparisons between images shrunk using GD and resizer.

set -e

IMG=8s

WORKDIR=tmp-shrink-comparisons
SHRINKCMD='./ruby_tests/gd_resize_simple.rb --interp bicubic --force-truecolor'

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

# We use the dirnames in data/shrink/ to get sizes
for i in ./data/shrunk/[0-9]*; do
    [ -d $i ] || continue

    sz=`basename $i`
    ref=$i/$IMG.png
    shrunk=$WORKDIR/$IMG-$sz.png
    diff=$WORKDIR/$IMG-$sz-cmp.png
    
    # We extract the height from the destination image instead of
    # computing it because Ruby and ImageResizer seem to have
    # different rounding algorithms, leading to off-by-one differences.
    width=$sz
    height=`identify -format '%h' $ref`

    echo $i/$IMG

    $SHRINKCMD data/$IMG.jpg $width $height $shrunk

    compare $ref $shrunk $diff
done
