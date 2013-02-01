#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------
{

  my $t = Pinto::Tester->new;
  my $archive =  make_dist_archive('Dist-1=PkgA~1');

  # Put archive on the master stack.
  $t->run_ok(Add => {archives => $archive, author => 'JOHN', norecurse => 1});
  $t->registration_ok('JOHN/Dist-1/PkgA~1/master');

  # Copy the "master" stack to "dev" and make it the default
  $t->run_ok(Copy => {from_stack => 'master', to_stack => 'dev', default => 1});
  $t->registration_ok('JOHN/Dist-1/PkgA~1/dev');

  # Make sure "dev" is now the default
  ok($t->pinto->repo->get_stack('dev')->is_default, 'dev stack is default');

  # Delete the "master" stack.
  $t->run_ok(Kill => {stack => 'master'});
  throws_ok { $t->pinto->repo->get_stack('master') } qr/does not exist/;
  
  # Check the filesystem
  $t->path_not_exists_ok( [qw(master)] );

  # TODO: check that branch is gone too

}

#------------------------------------------------------------------------------
{

  my $t = Pinto::Tester->new;

  # Make master the default stack
  $t->run_ok(Default => {stack => 'master'});

  # Try killing locked stack
  $t->run_ok(Lock => {});
  $t->run_throws_ok(Kill => {stack => 'master'}, qr/is locked/);

  # Is stack still there?
  ok defined $t->pinto->repo->get_stack, 'Stack still exists in DB';

  # Check the filesystem
  $t->path_exists_ok( [qw(master)] );

  # Try killing locked stack with force
  $t->run_ok(Kill => {stack => 'master', force => 1});
  
  # Is stack still there?
  ok not (defined $t->pinto->repo->get_stack('master', nocroak => 1)), 'Stack is gone from DB';

  # Check the filesystem
  $t->path_not_exists_ok( [qw(master)] );

  # TODO: check that branch is gone too

}
#------------------------------------------------------------------------------

done_testing;
