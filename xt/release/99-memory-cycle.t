#!perl

use strict;
use warnings;

use Test::More;
use Test::Memory::Cycle;

use lib 'tlib';
use Pinto::Tester;

#------------------------------------------------------------------------------
note("This test requires a live internet connection to pull stuff from CPAN");
#------------------------------------------------------------------------------

{
  my $t = Pinto::Tester->new;

  my $result = $t->run_ok(Pull => {targets => 'Perl::Critic'});
  memory_cycle_ok($t->pinto);
  memory_cycle_ok($result);
}

#------------------------------------------------------------------------------

{

  # Throwable::Error has a memory leak.  I've submitted a patch (and patched
  # my own installation) but it hasn't been released yet.

  my $t = Pinto::Tester->new;

  no warnings qw(once redefine);
  local *Pinto::ArchiveExtractor::requires = sub {die 'FAKE ERROR'};

  my $result = $t->run_ok(Pull => {targets => 'Perl::Critic'});
  memory_cycle_ok($t->pinto);
  memory_cycle_ok($result);
}

#------------------------------------------------------------------------------

done_testing;
