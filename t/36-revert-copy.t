#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;

#------------------------------------------------------------------------------

{

  my $t = Pinto::Tester->new;

  # Add 2 versions of a dist;
  $t->populate('AUTHOR/Dist-1 = PkgA~1, PkgB~1'); # Rev 1
  $t->populate('AUTHOR/Dist-2 = PkgA~2, PkgB~2'); # Rev 2

  # Copy the 'init' stack to 'dev', and make it the default
  $t->run_ok(Copy => {from_stack => 'init', to_stack => 'dev', default => 1});

  # Now blow away the init stack.
  $t->run_ok(Delete => {stack => 'init'});

  # Newer packages should be on the 'dev' stack 
  $t->registration_ok( 'AUTHOR/Dist-2/PkgA~2/dev' );
  $t->registration_ok( 'AUTHOR/Dist-2/PkgB~2/dev' );

  # Pin on stack 'dev' to cause a new revision
  $t->run_ok(Pin => {stack => 'dev', targets => 'PkgA'}); # Rev 3

  # Should now be pinned on stack 'dev'
  $t->registration_ok( 'AUTHOR/Dist-2/PkgA~2/dev/+' );
  $t->registration_ok( 'AUTHOR/Dist-2/PkgB~2/dev/+' );

  # Now go back to revision 2 (just after the copy)
  $t->run_ok(Revert => {stack => 'dev', revision => 2});

  # Pins on stack 'dev' should be gone
  $t->registration_ok( 'AUTHOR/Dist-2/PkgA~2/dev/-' );
  $t->registration_ok( 'AUTHOR/Dist-2/PkgB~2/dev/-' );

  # Now go back to revision 1 (before the copy)
  $t->run_ok(Revert => {stack => 'dev', revision => 1});

  # Older packages should now be on the 'dev' stack 
  $t->registration_ok( 'AUTHOR/Dist-1/PkgA~1/dev' );
  $t->registration_ok( 'AUTHOR/Dist-1/PkgB~1/dev' );

}

#------------------------------------------------------------------------------

done_testing;

