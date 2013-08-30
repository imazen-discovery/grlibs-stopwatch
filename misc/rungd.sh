#!/bin/bash

# Compile and run gd_resize under the local (uninstalled) build of LibGD

set -e

#VG=valgrind tool=callgrind
#VG="gdb --args"

GDDIR=../../gd-libgd/src
GDBLD_DIR=$GDDIR/.libs/

cd `dirname $0`

pushd ../../gd-libgd
if make -q; then
    echo "Lib is up to date."
else
    make clean
    make -j 4

    echo
    echo
    echo "Installing:"
    sudo make install
    sudo ldconfig
fi
popd

cd ../c_tests/

#gcc -g -O -Wall -I$GDDIR  -L$GDBLD_DIR gd_resize.c timer.c util.c -lgd -o gd_resize 
gcc -g -O -Wall `pkg-config gdlib --libs --cflags` gd_resize.c timer.c util.c -lgd -o gd_resize 

#export LD_LIBRARY_PATH=../../
$VG ./gd_resize ../data/pic1.jpg out 2080 # 2080 2080 2080 2080 



