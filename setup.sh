#!/bin/bash

# Setup everything and start everything

DEFAULT_BUILD_DIR=../grlibs-sw-build
DELAY=5

set -e          # Exit on failure

# Sanity check: are we in the root directory?
if [ ! -f Vagrantfile ]; then
    echo "This script must be run from the project root."
    exit 1
fi

# Setup the build dir. if needed.
if [ ! -f BUILD_DIR ]; then
    echo "About to setup build directory in $DEFAULT_BUILD_DIR"
    echo "Press CTRL-C in $DELAY seconds to cancel."
    echo "(You can set a different path with cfg_scripts/mk_builddir.sh)"
    sleep $DELAY
    cfg_scripts/mk_builddir.sh $DEFAULT_BUILD_DIR
else
    BD=`cat BUILD_DIR`
    echo -n "Using BUILD_DIR: $BD"

    # Build dir. could have been removed while the file BUILD_DIR
    # stayed behind.
    if [ ! -d "$BD" ]; then
        echo "Creating '$BD':"
        cfg_scripts/mk_builddir.sh "$BD"
    fi
fi

echo "Checking out liborc:"
cfg_scripts/checkout.sh orc-4-hax tweaks-0.4.17
#cfg_scripts/checkout-liborc.sh

echo "Checking out libvips:"
cfg_scripts/checkout.sh libvips 7.34

echo "Checking out libgd."
cfg_scripts/checkout.sh gd-libgd 2.1.0-stable

#echo "Checking out GD-Perl."
#cfg_scripts/checkout.sh GD-Perl

echo "Checking out gd2-ffij."
cfg_scripts/checkout.sh gd2-ffij

echo "Bringing up vagrant:"
if vagrant status | grep -q '^default *running'; then
    echo "vagrant box is already up."
else
    vagrant up
fi

if vagrant ssh -c 'pkg-config vips'; then
    cat - <<EOF
Found vips installation; assuming all packages are installed.
(If this is not the case, tests will probably fail; try running
build.sh by hand.)
EOF

else
    echo "Building libraries:"
    vagrant ssh -c 'cd /vagrant; cfg_scripts/build.sh'
fi

echo "Building C benchmarks:"
vagrant ssh -c 'cd /vagrant/c_tests/; make'

echo "Done."

