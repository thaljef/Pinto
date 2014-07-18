#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('AUTHOR/Dist-1 = PkgA~1');
$source->populate('AUTHOR/Dist-2 = PkgB~2');

#------------------------------------------------------------------------------

subtest 'exact version' => sub {

    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_ok( Pull => {targets => 'PkgA@1'} );
    $local->registration_ok('AUTHOR/Dist-1/PkgA~1');

    $local->run_ok( Pull => {targets => 'PkgB==2'} );
    $local->registration_ok('AUTHOR/Dist-2/PkgB~2');
};

#------------------------------------------------------------------------------

subtest 'not version' => sub {

    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_ok( Pull => {targets => 'PkgA!=2'} );
    $local->registration_ok('AUTHOR/Dist-1/PkgA~1');

    $local->run_throws_ok( Pull => {targets => 'PkgB!=2'}, qr/Cannot find PkgB!=2/ );

};

#------------------------------------------------------------------------------

subtest 'complex' => sub {

    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_ok( Pull => {targets => 'PkgA>0.5,!=2,<=4'} );
    $local->registration_ok('AUTHOR/Dist-1/PkgA~1');

    $local->run_throws_ok( Pull => {targets => 'PkgB>=1,<5,!=2,!=3'}, qr/Cannot find PkgB>=1,<5,!=2,!=3/ );

};
#------------------------------------------------------------------------------
done_testing;
