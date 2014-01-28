#!perl

use strict;
use warnings;

use Test::More;
use URI;

use lib 't/lib';
use Pinto::Tester;

use Pinto::Constants qw(:stratopan);

#------------------------------------------------------------------------------

note("This test requires a live internet connection to contact stratopan");

#------------------------------------------------------------------------------

my $stratopan_host = $PINTO_STRATOPAN_CPAN_URI->host;

#------------------------------------------------------------------------------

subtest 'Pull precise version' => sub {

    my $t = Pinto::Tester->new(init_args => {recurse => 0});
    $t->run_ok( Pull => { targets => 'Pinto==0.094'} );
    $t->registration_ok('THALJEF/Pinto-0.094/Pinto~0.094');

    my $target = Pinto::Target->new('THALJEF/Pinto-0.094.tar.gz');
    my $dist = $t->get_distribution(target => $target);
    my $uri  = URI->new($dist->source);
    is $uri->host, $stratopan_host, 'Dist came from Stratopan';
};

#------------------------------------------------------------------------------

subtest 'Pull version range' => sub {

    my $t = Pinto::Tester->new(init_args => {recurse => 0});
    $t->run_ok( Pull => { targets => 'Pinto>=0.084,!=0.085,<0.087'} );
    $t->registration_ok('THALJEF/Pinto-0.086/Pinto~0.086');

    my $target = Pinto::Target->new('THALJEF/Pinto-0.086.tar.gz');
    my $dist = $t->get_distribution(target => $target);
    my $uri  = URI->new($dist->source);
    is $uri->host, $stratopan_host, 'Dist came from Stratopan';
};

#------------------------------------------------------------------------------

subtest 'Pull development version' => sub {

    my $t = Pinto::Tester->new(init_args => {recurse => 0});
    $t->run_ok( Pull => { targets => 'Pinto==0.097_01'} );
    $t->registration_ok('THALJEF/Pinto-0.097_01/Pinto~0.097_01');

    my $target = Pinto::Target->new('THALJEF/Pinto-0.097_01.tar.gz');
    my $dist = $t->get_distribution(target => $target);
    my $uri  = URI->new($dist->source);
    is $uri->host, $stratopan_host, 'Dist came from Stratopan';
};

#------------------------------------------------------------------------------

subtest 'Pull distribution' => sub {

    my $t = Pinto::Tester->new(init_args => {recurse => 0});
    $t->run_ok( Pull => { targets => 'THALJEF/Pinto-0.065'} );
    $t->registration_ok('THALJEF/Pinto-0.065/Pinto~0.065');

    my $target = Pinto::Target->new('THALJEF/Pinto-0.065.tar.gz');
    my $dist = $t->get_distribution(target => $target);
    my $uri  = URI->new($dist->source);
    is $uri->host, $stratopan_host, 'Dist came from Stratopan';
};

#------------------------------------------------------------------------------
done_testing;
