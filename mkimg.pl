#!/usr/bin/perl

# Create an image of a specified size (usually) consisting of random pixels.
# Args: width height output-filename [max-colours]

use strict;
use warnings;

use GD;

my ($width, $height, $name, $limit) = @ARGV;
$width += 0;
$height += 0;
die "Invalid args!\n" unless $width && $height;

die "Invalid limit value!\n"
  unless !defined($limit) || $limit eq $limit+0;

die "No name.\n" unless $name;
$name .= ".png" unless $name =~ /.\.png$/;


my $Img = GD::Image->new($width, $height);

{
  my @colours;
  my $count = 0;

  # Allocate all available colours
  for (0 .. 1000000) {
    my @rgb = map { int(rand(256)) } (0, 0, 0);

    my $nc = $Img->colorAllocate(@rgb);
    last if $nc == -1;

    push @colours, $nc;

    ++$count;
    last if $limit && $count >= $limit;
  }

  # Pick one.
  sub rndclr {
    return $colours[int(rand(scalar @colours))];
  }
}

my @wheel = qw{- / | \ };
for my $y (0 .. $height-1) {
  do {local $| = 1; print "\r", $wheel[$y % scalar(@wheel)]};
  for my $x (0 .. $width-1) {
    $Img->setPixel($x, $y, rndclr());
  }
}

print "\nSaving...\n";
open my $out, ">", $name
  or die "Unable to open '$name' for writing.\n";
binmode $out;
print $out $Img->png
  or die "Error writing to file '$name'.";

close $out;


