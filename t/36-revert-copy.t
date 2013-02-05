#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;

#------------------------------------------------------------------------------

{

  my $t = Pinto::Tester->new;

  # Add first version of a dist...
  $t->populate('AUTHOR/Dist-1 = PkgA~1, PkgB~1');

  # Make a note of the commit id here, so we can revert to it later
  my $commit_1 = $t->pinto->repo->get_stack('master')->last_commit_id;
 
  # Add second version of a dist...
  $t->populate('AUTHOR/Dist-2 = PkgA~2, PkgB~2');

  # Copy the 'master' stack to 'dev', and make it the default
  $t->run_ok(Copy => {from_stack => 'master', to_stack => 'dev', default => 1});

  # Make a note of the commit id here, so we can revert to it later
  my $commit_2 = $t->pinto->repo->get_stack('dev')->last_commit_id;

  # Now blow away the master stack.
  $t->run_ok(Kill => {stack => 'master'});

  # Newer packages should be on the 'dev' stack 
  $t->registration_ok( 'AUTHOR/Dist-2/PkgA~2/dev' );
  $t->registration_ok( 'AUTHOR/Dist-2/PkgB~2/dev' );

  # Pin on stack 'dev' to cause a new commit
  $t->run_ok(Pin => {stack => 'dev', targets => 'PkgA'});

  # Should now be pinned on stack 'dev'
  $t->registration_ok( 'AUTHOR/Dist-2/PkgA~2/dev/*' );
  $t->registration_ok( 'AUTHOR/Dist-2/PkgB~2/dev/*' );

  # Now go back to commit_2 (just after the copy)
  $t->run_ok(Revert => {stack => 'dev', commit => $commit_2});

  # Pins on stack 'dev' should be gone
  $t->registration_ok( 'AUTHOR/Dist-2/PkgA~2/dev/-' );
  $t->registration_ok( 'AUTHOR/Dist-2/PkgB~2/dev/-' );

  # Now go back to commit_1 (before the copy)
  $t->run_ok(Revert => {stack => 'dev', commit => $commit_1});

  # Older packages should now be on the 'dev' stack 
  $t->registration_ok( 'AUTHOR/Dist-1/PkgA~1/dev' );
  $t->registration_ok( 'AUTHOR/Dist-1/PkgB~1/dev' );

}

#------------------------------------------------------------------------------

done_testing;

