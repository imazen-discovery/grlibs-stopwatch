# vips-stopwatch #

This is a small collection of programs which use the Vips library to
do some simple image manipulation, times how long various stages take
and outputs the results.

The goal is to get a basic idea of just how fast Vips is.

For consistency, we use Vagrant to create a development VM and build
everything there.  The script 'setup.sh' does everything.

Note that the scripts here will checkout and build ORC and Vips from
sources.  If you do not specify an external directory in which to do
this, setup.sh will select a default (../vips-build/).

