#!perl

use strict;
use warnings;

use Test::More;
use Test::Memory::Cycle;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------
{

  my $t = Pinto::Tester->new;
  my $archive = make_dist_archive('Dist-1 = PkgA~1, PkgB~1');
  $t->run_ok(Add => {archives => $archive, author => 'AUHTOR', norecurse => 1});

  memory_cycle_ok($t->pinto);

  my $stack = $t->pinto->repo->get_stack;
  $stack->registry; # To kick lazy attributes

  memory_cycle_ok($stack);
}

#------------------------------------------------------------------------------

done_testing;
