#!/bin/bash

# Checkout or update all of the repos.

set -e

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
