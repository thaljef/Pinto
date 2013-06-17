#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2 = Baz~1.2 & Nuts-2.3');
$source->populate('PAUL/Nuts-2.3 = Nuts~2.3');

#------------------------------------------------------------------------------
{

  # Non-recursive pull
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  $local->run_ok('Pull', {targets => 'Baz~1.2', no_recurse => 1});
  $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
  $local->registration_not_ok('PAUL/Nuts-2.3/Nuts~2.3');
}

#------------------------------------------------------------------------------
{

  # Recursive pull by package
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  my $result = $local->run_ok('Pull', {targets => 'Baz~1.2'});
  $local->result_changed_ok($result);
  
  $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
  $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');

  # Re-pulling
  $result = $local->run_ok('Pull', {targets => 'Baz~1.2'});
  $local->result_not_changed_ok($result);
}

#------------------------------------------------------------------------------
{
  # Recursive pull by distribution
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  my $result = $local->run_ok('Pull', {targets => 'JOHN/Baz-1.2.tar.gz'});
  $local->result_changed_ok($result);
  $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
  $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');

  # Re-pulling
  $result = $local->run_ok('Pull', {targets => 'JOHN/Baz-1.2.tar.gz'});
  $local->result_not_changed_ok($result);
}

#------------------------------------------------------------------------------
{

  # Pull non-existant package
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  $local->run_throws_ok('Pull', {targets => 'Nowhere~1.2'},
                         qr/Cannot find Nowhere~1.2 anywhere/);

}

#------------------------------------------------------------------------------
{

  # Pull non-existant dist
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  $local->run_throws_ok('Pull', {targets => 'JOHN/Nowhere-1.2.tar.gz'},
                         qr{Cannot find JOHN/Nowhere-1.2.tar.gz anywhere});

}

#------------------------------------------------------------------------------
{

  # Pull a core-only module (should be ignored)
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  $local->run_ok(Pull => {targets => 'IPC::Open3'});
  $local->stderr_like(qr/Skipping IPC::Open3~0: included in perl/);
  $local->repository_clean_ok;

}

#------------------------------------------------------------------------------
done_testing;
