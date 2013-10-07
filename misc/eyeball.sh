#!/bin/bash

# Display the reference image and all comparisons.
# all_interpolations.sh should have been run first with the same
# values of IMG and SZ.

set -e

IMG=8s
SZ=800

WORKDIR=tmp-shrink-comparisons

REF=ref.png

if [ ! -d cfg_scripts ]; then
    echo "Must be run in project root directory."
    exit 1
fi

display $WORKDIR/$REF &

for img in $WORKDIR/$IMG-$SZ-*.png; do
    echo $img
    display $img
done

