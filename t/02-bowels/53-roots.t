#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

{

	# Typical case

    my $t = Pinto::Tester->new;
    $t->populate('ME/Dist-1 = PkgA~1 & PkgB~1');
    $t->populate('ME/Dist-2 = PkgB~1');
    $t->populate('ME/Dist-3 = PkgC~1');

    $t->run_ok( Roots => {format => '%D'});
    my @lines = split /\n/, ${ $t->outstr };
    is_deeply \@lines, [qw(Dist-1 Dist-3)], 'Got expected roots';
}

#------------------------------------------------------------------------------

{

	# What if there is a circular dependency?

    my $t = Pinto::Tester->new;
    $t->populate('ME/Dist-1 = PkgA~1 & PkgB~1');
    $t->populate('ME/Dist-2 = PkgB~1 & PkgA~1');

    $t->run_ok( Roots => {format => '%D'});
    my @lines = split /\n/, ${ $t->outstr };
    local $TODO = 'Not sure what to do with circular dependencies';
    is_deeply \@lines, [qw(Dist-1 Dist-2)], 'Got expected roots in circular dependency';
}


#-----------------------------------------------------------------------------

done_testing;
