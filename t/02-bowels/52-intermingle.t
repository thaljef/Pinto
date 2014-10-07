#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

subtest 'Not intermingled' => sub {

    my $t = Pinto::Tester->new;
    $t->populate('AUTHOR/Dist-1 = PkgA~1; PkgB~1');
    $t->populate('AUTHOR/Dist-2 = PkgB~2; PkgC~2');

    # When intermingling is not allowed (which is the default)
    # distributions may not overlap.  Adding a distribution
    # with the same package as an existing one causes all
    # packages from the existing distribution to be removed.

    $t->registration_not_ok('AUTHOR/Dist-1/PkgA~1');
    $t->registration_not_ok('AUTHOR/Dist-1/PkgB~1');

    $t->registration_ok('AUTHOR/Dist-2/PkgB~2');
    $t->registration_ok('AUTHOR/Dist-2/PkgC~2');

};

#------------------------------------------------------------------------------

subtest 'Interminged' => sub {

    my $t = Pinto::Tester->new(init_args => {intermingle => 1});
    $t->populate('AUTHOR/Dist-1 = PkgA~1; PkgB~1');
    $t->populate('AUTHOR/Dist-2 = PkgB~2; PkgC~2');

    # When intermingling is allowed, distributions can overlap.
    # This means the stack may contain only some of the packages
    # in the dist. This is how PAUSE acutally behaves.

    $t->registration_ok('AUTHOR/Dist-1/PkgA~1');
    $t->registration_not_ok('AUTHOR/Dist-1/PkgB~1');
    
    $t->registration_ok('AUTHOR/Dist-2/PkgB~2');
    $t->registration_ok('AUTHOR/Dist-2/PkgC~2');

};

#------------------------------------------------------------------------------
done_testing;
