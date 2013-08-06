#!/bin/perl

# Generate resize timings for everything in the given directory using
# shrink.

use strict;
use warnings;

my $dir = shift;

my $first = 1;

for my $fname (glob ("$dir/*.jpg"), glob("$dir/*.png")) {
  my @lines = split("\n", `./shrink $fname 90 80 70 50 40 20`);
  chomp @lines;

  # Unused stuff
  shift @lines;
  pop @lines;

  my ($hash, $width, $height, $depth) = split(/\s+/, shift @lines);


  if ($first) {
    my @percentages = map {(split(/\t/, $_))[1]} @lines;
    print join("\t", qw{File Dimensions Pixels}, @percentages), "\n";
    $first = 0;
  }

  print join("\t", $fname, "$width,$height,$depth", $width*$height,
             map {(split(/\t/, $_))[2]} @lines), "\n";
}





