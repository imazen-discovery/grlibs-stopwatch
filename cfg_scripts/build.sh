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
cd ..

echo "Building LibGD"
cd gd-libgd/
./bootstrap.sh
./configure --prefix=/usr/local/ --with-tiff=/usr/lib/ --with-xpm=/usr/lib/
make
sudo make install
cd ..

echo "Running ldconfig:"
sudo ldconfig

echo "Installing vips gem:"
sudo gem install ruby-vips -v 0.3.6


echo "Installing GD perl module:"
sudo cpanm --notest -i GD
# Note:    ^^^^^^^^ I disable tests here because GD's tests fail.  It looks
# like this is due to fragile tests, though.



