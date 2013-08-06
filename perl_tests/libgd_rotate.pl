#!/usr/bin/env perl

# Read in a file, then write out multiple copies shrunk by the
# percentages given on the command line and print out the timings.

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
  my @angles = @ARGV;

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

  actiontimer "# $name", "getBounds()" => sub {
    ($srcWidth, $srcHeight) = $src->getBounds();
  };

  for my $angle (@angles) {
    $angle += 0;
    die "Invalid percentage '$angle'\n"
      unless $angle > 0 && $angle <= 350;

    my ($centerX, $centerY) = map {int($_/2)} ($srcWidth, $srcHeight);
    actiontimer $name, $angle => sub {
      my $dest = GD::Image->new($srcWidth, $srcHeight);
      $dest->copyRotated($src, $centerX, $centerY, $centerX, $centerY,
                         $srcWidth, $srcHeight, $angle);
      writeImg($dest, $type, "rot-$angle-$name", $ext);
    };
  }

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
