#!/bin/bash

# Download the test images

set -e

URL=http://s3.amazonaws.com/resizer-images

if [ -d cfg_scripts/ ] ; then
    true
else
    echo "This script must be run from the project root directory."
    exit 1
fi

[ -d data ] || mkdir data
cd data/

for file in \
    11s.jpg 11.jpg 12s.jpg 12.jpg 8.jpg 8.jpg 8s.jpg 15.jpg 15s.jpg \
    22s.jpg 22.jpg 13.jpg 13s.jpg
do
    if [ -f $file ]; then
        echo "Already have '$file'.  Skipping."
    else
        wget --no-verbose "$URL/$file"
    fi
done

cp 8s.jpg pic1.jpg

