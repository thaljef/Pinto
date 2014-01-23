#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

subtest 'Basic' => sub {

    my $t = Pinto::Tester->new;
    $t->populate('ME/Dist-1 = PkgA~1 & PkgB~1');
    $t->populate('ME/Dist-2 = PkgB~1 & PkgC~1');
    $t->populate('ME/Dist-3 = PkgC~1');
    $t->populate('ME/Dist-4 = PkgD~1');

    $t->run_ok( Roots => {format => '%D'});
    my @lines = split /\n/, ${ $t->outstr };
    is_deeply \@lines, [qw(Dist-1 Dist-4)], 'Got expected roots';
};

#------------------------------------------------------------------------------

subtest 'Circular dependency' => sub {

    my $t = Pinto::Tester->new;
    $t->populate('ME/Dist-1 = PkgA~1 & PkgB~1');
    $t->populate('ME/Dist-2 = PkgB~1 & PkgA~1');

    $t->run_ok( Roots => {format => '%D'});
    my @lines = split /\n/, ${ $t->outstr };

    # TODO: Not sure what to do with circular dependencies;
    # is_deeply \@lines, [qw(Dist-1 Dist-2)], 'Got expected roots in circular dependency';
};

#-----------------------------------------------------------------------------

done_testing;
