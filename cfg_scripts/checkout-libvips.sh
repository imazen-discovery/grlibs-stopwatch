#!/bin/bash

set -e

cd `cat BUILD_DIR`

if [ -d libvips ]; then
    echo "libvips present.  Skipping checkout."
    exit 0
fi

git clone git@github.com:suetanvil/libvips.git
cd libvips/
git checkout 7.34

