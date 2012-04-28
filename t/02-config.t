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

{
    my %default_cases = (
        root      => 'nowhere',
        sources   => 'http://cpan.perl.org',
        devel     => 0,
    );

    my $cfg = Pinto::Config->new(root => 'nowhere');
    while ( my ($method, $expect) = each %default_cases ) {
        my $msg = "Got default value for '$method'";
        is($cfg->$method(), $expect, $msg);
    }

   my %custom_cases = (
        root      => 'nowhere',
        sources   => 'http://cpan.pair.com  http://metacpan.org',
        devel     => 1
    );

    $cfg = Pinto::Config->new(%custom_cases);
    while ( my ($method, $expect) = each %custom_cases ) {
        my $msg = "Got custom value for '$method'";
        is($cfg->$method(), $expect, $msg);
    }

    my $expect = [ map {URI->new($_)} qw(here there) ];
    $cfg = Pinto::Config->new(root => 'anywhere', sources => 'here there');
    is_deeply([$cfg->sources_list()], $expect, 'Parsed sources list');
}


#------------------------------------------------------------------------------

done_testing;
