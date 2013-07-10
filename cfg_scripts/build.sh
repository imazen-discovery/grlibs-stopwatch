#!/bin/bash

# Compile orc and vips.  This needs to be run inside the box.

set -e

cd /vagrant-extra/

echo "Building orc:"
cd orc-4-hax
./autogen.sh
./configure --prefix=/usr/local/
make
sudo make install
cd ..

echo "Building vips:"
cd libvips
./bootstrap.sh 
./configure --prefix=/usr/local/ 
make
sudo make install

