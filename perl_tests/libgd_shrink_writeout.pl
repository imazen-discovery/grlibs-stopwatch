#!/usr/bin/env perl

# Read in a file, then write out multiple copies shrunk by the
# percentages given on the command line and print out the timings.
#
# This version reads in one file and times shrinking and writing
# separately.

use strict;
use warnings;

use File::Basename;
use GD;
use ActionTimer;

{
  my $filename = shift @ARGV;
  my @percentages = @ARGV;

  my ($name, $path, $ext) = fileparse($filename, qr/\.[^.]*/);
  $ext =~ s/^\.//;

  my $type = lc($ext);
  $type = 'jpeg' if $type eq 'jpg';
  die "Unknown suffix: '$type'\n"
    unless $type =~ /^(gif|png|jpeg)/;

  my ($src, $srcWidth, $srcHeight);
  actiontimer "# $name", "Reading src" => sub {
    $src = GD::Image->new($filename)
      or die "Unable to create new GD::Image($filename)\n";
  };

  actiontimer "# $name", "getBounds()" => sub {
    ($srcWidth, $srcHeight) = $src->getBounds();
  };

  for my $percent (@percentages) {
    $percent += 0;
    die "Invalid percentage '$percent'\n"
      unless $percent > 0 && $percent <= 100;
    my $ratio = $percent / 100.0;

    my $dest;
    my ($destWidth, $destHeight) = (int($srcWidth*$ratio), int($srcHeight*$ratio));
    actiontimer $name, $percent => sub {
      $dest = GD::Image->new($destWidth, $destHeight);
      $dest->copyResized($src, 0, 0, 0, 0, $destWidth, $destHeight,
                         $srcWidth, $srcHeight);
    };

    actiontimer $name, "$percent writing" => sub {
      my $oname = "$percent-$name.$ext";
      open my $fh, ">", $oname
        or die "Unable to open '$oname' for writing.\n";
      print $fh $dest->$type
        or die "Error writing data to file '$oname'.\n";
      close $fh;
    };
  }

  print_timings();
}
