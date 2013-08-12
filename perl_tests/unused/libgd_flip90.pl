#!/usr/bin/env perl

# Read in a file, then write out multiple copies rotated 90, 180 and
# 270 degrees.


use strict;
use warnings;

use File::Basename;
use GD;

BEGIN {
  unshift @INC, dirname(__FILE__);
};

use ActionTimer;

{
  my $filename = shift @ARGV;

  my ($name, $path, $ext) = fileparse($filename, qr/\.[^.]*/);
  $ext =~ s/^\.//;

  my $type = lc($ext);
  $type = 'jpeg' if $type eq 'jpg';
  die "Unknown suffix: '$type'\n"
    unless $type =~ /^(gif|png|jpeg|tiff)/;

  my ($src, $srcWidth, $srcHeight);
  actiontimer "# $name", "Reading src" => sub {
    $src = GD::Image->new($filename)
      or die "Unable to create new GD::Image($filename)\n";
  };

  for my $angle (qw{90 180 270}) {
    my $mth = "copyRotate$angle";

    actiontimer $name, $angle => sub {
      my $dest = $src->$mth();
      writeImg($dest, $type, "rotate-$angle-$name", $ext);
    };
  }

  actiontimer $name, "180-inplace" => sub {
    $src->rotate180();  # Modifies $src in place.
    writeImg($src, $type, "rotate-180-$name", $ext);
  };

  print_timings();
}


sub writeImg {
  my ($img, $type, $filename, $ext) = @_;

  $filename = "$filename.$ext";
  open my $fh, ">", $filename
    or die "Unable to open '$filename' for writing.\n";
  print $fh $img->$type
    or die "Error writing data to file '$filename'.\n";
  close $fh;
}
