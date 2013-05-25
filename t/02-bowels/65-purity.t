#!perl

use strict;
use warnings;

use Test::More;

use lib 'tlib';
use Pinto::Tester;

#------------------------------------------------------------------------------

{

  # When a stack is not pure then any overlapping packages from
  # an existing distribution should remain.  In this case it is PkgA

  my $t = Pinto::Tester->new;
  $t->get_stack->set_property(prohibit_partial_distributions => 1);

  $t->populate('AUTHOR/Dist-1 = PkgA~1, PkgB~1');
  $t->registration_ok('AUTHOR/Dist-1/PkgA~1');
  $t->registration_ok('AUTHOR/Dist-1/PkgB~1');

  $t->populate('AUTHOR/Dist-2 = PkgB~2, PkgC~2');
  $t->registration_not_ok('AUTHOR/Dist-1/PkgA-1');
  $t->registration_ok('AUTHOR/Dist-2/PkgB~2');
  $t->registration_ok('AUTHOR/Dist-2/PkgC~2');

}

#------------------------------------------------------------------------------

{

  # When a stack is pure (the default) then any overlapping packages from
  # an existing distribution should be removed.  In this case it is PkgA

  my $t = Pinto::Tester->new;

  $t->populate('AUTHOR/Dist-1 = PkgA~1, PkgB~1');
  $t->registration_ok('AUTHOR/Dist-1/PkgA~1');
  $t->registration_ok('AUTHOR/Dist-1/PkgB~1');

  $t->populate('AUTHOR/Dist-2 = PkgB~2, PkgC~2');
  $t->registration_ok('AUTHOR/Dist-1/PkgA~1');
  $t->registration_ok('AUTHOR/Dist-2/PkgB~2');
  $t->registration_ok('AUTHOR/Dist-2/PkgC~2');

}

#------------------------------------------------------------------------------
done_testing;
