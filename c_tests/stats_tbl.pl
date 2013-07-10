#!/bin/perl

use strict;
use warnings;

my $items = {};
my %types;
while (<>) {
  chomp;
  next if /^#/ || /^\(/;
  my ($name, $type, $time) = split(/\t/);

  $items->{$name}->{$type} = $time;
  $types{$type} = 1;
}

my @types = qw{avg max min deviate};

print join("\t", "Name", @types), "\n";

for my $f (sort keys %{$items}) {
  print join("\t", $f, map { $items->{$f}->{$_} } @types), "\n";
}

