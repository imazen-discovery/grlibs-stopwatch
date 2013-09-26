#!/bin/bash

set -e

URL=http://z.zr.io/ri/
WIDTHS="160 320 480 640 800 1200 1600 2048"

if [ -d cfg_scripts/ ] ; then
    true
else
    echo "This script must be run from the project root directory."
    exit 1
fi

[ -d data ] || mkdir data
cd data/

[ -d shrunk ] || mkdir shrunk
cd shrunk/


for w in $WIDTHS; do
    [ -d $w ] || mkdir $w

    for img in $*; do
        fn=$w/${img%.jpg}.png
        if [ -f $fn ]; then
            echo "Already have $w/$fn; skipping."
        else
            echo "Fetching $w/$fn."
            wget "$URL$img?width=$w&format=png" -O $fn
        fi
    done
done


