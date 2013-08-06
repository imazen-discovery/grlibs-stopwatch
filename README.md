# grlibs-stopwatch #

This is a small collection of programs which use two graphics
libraries (libvips and LibGD) to do some simple image manipulation,
times how long various stages take and outputs the results.

The goal is to get a basic idea of just how fast the libraries are.

For consistency, we use Vagrant to create a development VM and build
everything there.  The script 'setup.sh' does everything.

Note that the scripts here will checkout and build the libraries from
sources.  If you do not specify an external directory in which to do
this, setup.sh will select a default (../vips-build/).

Output is a text file with each line (after the first 3) a series of
tab-delimited fields.  Gnumeric and Google Docs Spreadsheet both
import it easily.  In addition, the tools `tabsort.rb` and
`tabcluster.rb` can be used to manipulate the results a little.

## To Use ##

1) Checkout this repository and `cd` to it:

    git clone git@github.com:imazen-discovery/grlibs-stopwatch.git
    cd vips-stopwatch

2) Pick the path to the lib checkout directory:

    ./cfg_scripts/mk_builddir.sh ../stuff/

3) Set up the environment:

    ./setup.sh

4) Wait.

5) Run the test:

    vagrant ssh -c 'cd /vagrant/; ./stats_tools/all_benchmarks.rb '

6) Examine the results in `timings.tab`.


