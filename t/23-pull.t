#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2 = Baz~1.2 & Nuts-2.3');
$source->populate('PAUL/Nuts-2.3 = Nuts~2.3');

#------------------------------------------------------------------------------
{

  # Non-recursive pull
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  $local->run_ok('Pull', {targets => 'Baz~1.2', norecurse => 1});
  $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
  $local->registration_not_ok('PAUL/Nuts-2.3/Nuts~2.3');
}

#------------------------------------------------------------------------------
{

  # Recursive pull by package
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  my $result = $local->run_ok('Pull', {targets => 'Baz~1.2'});
  $local->result_changed_ok($result);
  $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
  $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');

  # Re-pulling
  $result = $local->run_ok('Pull', {targets => 'Baz~1.2'});
  $local->result_not_changed_ok($result);
  $local->log_like(qr{Already have package Baz~1.2 or newer});
  $local->log_like(qr{Already have package Nuts~2.3 or newer});
}

#------------------------------------------------------------------------------
{
  # Recursive pull by distribution
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  my $result = $local->run_ok('Pull', {targets => 'JOHN/Baz-1.2.tar.gz'});
  $local->result_changed_ok($result);
  $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
  $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');

  # Re-pulling
  $result = $local->run_ok('Pull', {targets => 'JOHN/Baz-1.2.tar.gz'});
  $local->result_not_changed_ok($result);
  $local->log_like(qr{Already have distribution JOHN/Baz-1.2.tar.gz});
  $local->log_like(qr{Already have package Nuts~2.3 or newer});
}

#------------------------------------------------------------------------------
{

  # Pull non-existant package
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  $local->run_throws_ok('Pull', {targets => 'Nowhere~1.2'},
                         qr/Cannot find prerequisite Nowhere~1.2/);

}

#------------------------------------------------------------------------------
{

  # Pull non-existant dist
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  $local->run_throws_ok('Pull', {targets => 'JOHN/Nowhere-1.2.tar.gz'},
                         qr{Cannot find prerequisite JOHN/Nowhere-1.2.tar.gz});

}
#------------------------------------------------------------------------------

done_testing;
