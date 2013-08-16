#!/bin/bash

# Compile libraries.

set -e

cd /vagrant-extra/

echo "Building orc:"
cd orc-4-hax
[ -f configure ] || ./autogen.sh
./configure --prefix=/usr/local/
make
sudo make install
sudo ldconfig
cd ..

echo "Building vips:"
cd libvips
[ -f configure ] || ./bootstrap.sh 
./configure --prefix=/usr/local/ 
make
sudo make install
sudo ldconfig
cd ..

echo "Building LibGD"
cd gd-libgd/
[ -f configure ] || ./bootstrap.sh
./configure --prefix=/usr/local/ --with-tiff=/usr/lib/ --with-xpm=/usr/lib/
make
sudo make install
sudo ldconfig
cd ..

echo "Installing vips gem:"
sudo gem install ffi -v 1.9.0
sudo gem install ruby-vips -v 0.3.6




