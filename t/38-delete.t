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

  # Put archive on the init stack.
  $t->run_ok(Add => {archives => $archive, author => 'JOHN', norecurse => 1});
  $t->registration_ok('JOHN/Dist-1/PkgA~1/init');

  # Copy the "init" stack to "dev" and make it the default
  $t->run_ok(Copy => {from_stack => 'init', to_stack => 'dev', default => 1});
  $t->registration_ok('JOHN/Dist-1/PkgA~1/dev');

  # Make sure "dev" is now the default
  ok($t->pinto->repo->get_stack('dev')->is_default, 'dev stack is default');

  # Delete the "init" stack.
  $t->run_ok(Delete => {stack => 'init'});
  throws_ok { $t->pinto->repo->get_stack('init') } qr/does not exist/;
  
  # Check the filesystem
  $t->path_not_exists_ok( [qw(init)] );

}

#------------------------------------------------------------------------------
{

  my $t = Pinto::Tester->new;

  # Make sure "init" is the default
  ok($t->pinto->repo->get_stack('init')->is_default, 'init stack is default');

  # Try to delete the "init" stack.
  throws_ok { $t->run_ok(Delete => {stack => 'init'}) } qr/cannot remove the default stack/;

}

#------------------------------------------------------------------------------

done_testing;
