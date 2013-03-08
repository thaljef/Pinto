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
  
  # The dev stack should still be the same
  $t->registration_ok('JOHN/Dist-1/PkgA~1/dev');

  # Check that master stack was removed from filesystem
  $t->path_not_exists_ok( [qw(master)] );

  # TODO: check that branch is gone too

}

#------------------------------------------------------------------------------
{

  my $t = Pinto::Tester->new;

  # Make sure master is the default
  my $stack = $t->pinto->repo->get_stack('master');
  is $stack->is_default, 1, 'Stack master is the default';

  # Try killing the default stack
  $t->run_throws_ok(Kill => {stack => 'master'}, qr/Cannot kill the default stack/, 
    'Killing default stack throws exception');

  # Now make master not the default
  $t->run_ok(Default => {none => 1});
  is $stack->refresh->is_default, 0, 'Stack master is not the default';

  # Try killing locked stack
  $t->run_ok(Lock => {stack => 'master'});
  is $stack->refresh->is_locked, 1, 'Stack master is now locked';

  $t->run_throws_ok(Kill => {stack => 'master'}, qr/is locked/, 
    'Killing locked stack throws exception');

  # Is stack still there?
  ok defined $t->pinto->repo->get_stack('master'), 
    'Stack maser still exists in DB';

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
