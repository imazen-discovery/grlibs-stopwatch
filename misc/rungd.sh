#!/bin/bash

# Compile and run gd_resize under the local (uninstalled) build of LibGD

set -e

GDDIR=../../gd-libgd/src
GDBLD_DIR=$GDDIR/.libs/

cd `dirname $0`
cd ../c_tests/

gcc -g -O -Wall -I$GDDIR  -L$GDBLD_DIR gd_resize.c timer.c util.c -lgd -o gd_resize 

export LD_LIBRARY_PATH=../../
./gd_resize ../data/pic1.jpg out 2080 2080 2080 2080 2080 