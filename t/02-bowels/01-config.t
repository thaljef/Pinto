#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Path::Class;
use File::Temp;
use URI;

use Pinto::Config;

#------------------------------------------------------------------------------

subtest 'Default config' => sub {

    my %cases = (
        root    => 'nowhere',
        sources => 'http://cpan.stratopan.com http://www.cpan.org http://backpan.perl.org',
    );

    my $cfg = Pinto::Config->new( root => 'nowhere' );
    while ( my ( $method, $expect ) = each %cases ) {
        my $msg = "Got default value for '$method'";
        is( $cfg->$method(), $expect, $msg );
    }
};

#------------------------------------------------------------------------------

subtest 'Custom config' => sub {

    my %cases = (
        root    => 'nowhere',
        sources => 'http://cpan.pair.com  http://metacpan.org',
    );

    my $cfg = Pinto::Config->new(%cases);
    while ( my ( $method, $expect ) = each %cases ) {
        my $msg = "Got custom value for '$method'";
        is( $cfg->$method(), $expect, $msg );
    }
};

#------------------------------------------------------------------------------

subtest 'Multiple sources' => sub {

    my $expect = [ map { URI->new($_) } qw(here there) ];

    my $cfg1 = Pinto::Config->new( root => 'anywhere', sources => 'here there' );
    is_deeply( [ $cfg1->sources_list ], $expect, 'Parsed sources list' );

    my $cfg2 = Pinto::Config->new( root => 'anywhere', sources => q{"here there"} );
    is_deeply( [ $cfg2->sources_list ], $expect, 'Parsed sources list, with quotes' );
};

#------------------------------------------------------------------------------

done_testing;
