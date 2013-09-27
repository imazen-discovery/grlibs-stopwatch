#!/bin/bash

# Compare a subset of two images with the chunks compared shifted by
# one-pixel increments.  Used to detect off-by-one shifts.

set -e

img1=$1
img2=$2

dim=300x300
xoff=100
yoff=100

ref=ref$$.png
tmp=tmp$$.png
diff=diff$$.png

if [ ! -f $img1 ] || [ ! -f $img2 ]; then
    echo "Missing image file."
    exit 1
fi

convert $img1 -crop $dim+$xoff+$yoff $ref

for x in -3 -2 -1 0 1 2 3; do
    for y in -3 -2 -1 0 1 2 3; do
        xoffn=`expr $xoff + $x`
        yoffn=`expr $yoff + $y`
        geo=$dim+$xoffn+$yoffn

        convert $img2 -crop $geo $tmp
        
        compare $ref $tmp $diff
        echo $geo
        display $diff
    done
done

rm $tmp $ref $diff

