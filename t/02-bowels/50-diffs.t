#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Difference;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

$t->populate('AUTHOR/Dist-1 = PkgA~1, PkgB~1');
$t->populate('AUTHOR/Dist-2 = PkgB~2, PkgC~2');

#------------------------------------------------------------------------------
{
    my $right = $t->get_stack->head;
    my $left  = ( $right->parents )[0];

    my $expect_adds = [ 'AUTHOR/Dist-2/PkgB~2/-', 'AUTHOR/Dist-2/PkgC~2/-' ];
    my $expect_dels = ['AUTHOR/Dist-1/PkgB~1/-'];

    my $diff = Pinto::Difference->new( left => $left, right => $right );

    my @adds = map { $_->to_string } $diff->additions;
    my @dels = map { $_->to_string } $diff->deletions;

    is_deeply \@adds, $expect_adds, 'Got expected additions';
    is_deeply \@dels, $expect_dels, 'Got expected deletions';

    # If we reverse the direction of the diff, then
    # we should always get the opposite results...

    ( $right,       $left )        = ( $left,        $right );
    ( $expect_adds, $expect_dels ) = ( $expect_dels, $expect_adds );

    $diff = Pinto::Difference->new( left => $left, right => $right );

    @adds = map { $_->to_string } $diff->additions;
    @dels = map { $_->to_string } $diff->deletions;

    is_deeply \@adds, $expect_adds, 'Got expected additions';
    is_deeply \@dels, $expect_dels, 'Got expected deletions';
}

#------------------------------------------------------------------------------

done_testing;
