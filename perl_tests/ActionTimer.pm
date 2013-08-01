
package ActionTimer;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw{actiontimer print_timings};

use Time::HiRes qw{time};

my @times;

sub actiontimer ($$$) {
  my ($file, $desc, $action) = @_;

  my $before = time();
  $action->();
  my $after = time();

  push @times, [$after - $before, $desc, $file];
}

sub print_timings {
  my $total = 0;

  for my $t (@times) {
    my ($elapsed, $desc, $file) = @{$t};
    printf "$file\t$desc\t%.3f\n", $elapsed*1000;
    $total += $elapsed;
  }

  printf "\tTotal\t%3f\n", $total*1000;
}


1;



