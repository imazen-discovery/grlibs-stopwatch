#!/bin/bash

# Compile libraries.

set -e

CORES=1
if [ -f /vagrant/NUM_CORES ]; then
    CORES=`cat /vagrant/NUM_CORES`
fi

cd /vagrant-extra/

echo "Building orc:"
cd orc-4-hax
if [ ! -f Makefile ]; then
    ./autogen.sh
    ./configure --prefix=/usr/local/
fi
make -j $CORES
sudo make install
sudo ldconfig
cd ..

echo "Building vips:"
cd libvips
if [ ! -f Makefile ]; then
    ./bootstrap.sh
    ./configure --prefix=/usr/local/ 
fi
make -j $CORES
sudo make install
sudo ldconfig
cd ..

echo "Building LibGD"
cd gd-libgd/
if [ ! -f Makefile ]; then
    ./bootstrap.sh
    ./configure --prefix=/usr/local/ --with-tiff=/usr/lib/ --with-xpm=/usr/lib/
fi
make -j $CORES
sudo make install
sudo ldconfig
cd ..

echo "Installing vips gem:"
sudo gem install ffi -v 1.9.0
sudo gem install ruby-vips -v 0.3.6




