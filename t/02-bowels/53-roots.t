#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

{

    my $t = Pinto::Tester->new;
    $t->populate('ME/Dist-1 = PkgA~1 & PkgB~1');
    $t->populate('ME/Dist-2 = PkgB~1');
    $t->populate('ME/Dist-3 = PkgC~1');

    $t->run_ok( Roots => {format => '%D'});
    my @lines = split /\n/, ${ $t->outstr };
    is_deeply \@lines, [qw(Dist-1 Dist-3)], 'Got expected roots';
}

#-----------------------------------------------------------------------------

done_testing;
