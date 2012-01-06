#!perl

use strict;
use warnings;

use Test::More (tests => 12);
use Test::Exception;

use Path::Class;
use File::HomeDir;
use File::Temp;
use URI;

use Pinto::Config;


#------------------------------------------------------------------------------

{
    my %default_cases = (
        root      => 'nowhere',
        sources   => 'http://cpan.perl.org',
        store     => 'Pinto::Store::File',
        noinit    => 0,
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
        store     => 'Pinto::Store::VCS::Git',
        noinit    => 1,
        devel     => 1,
    );

    $cfg = Pinto::Config->new(%custom_cases);
    while ( my ($method, $expect) = each %custom_cases ) {
        my $msg = "Got custom value for '$method'";
        is($cfg->$method(), $expect, $msg);
    }

    $cfg = Pinto::Config->new(root => '~/nowhere');
    my $home = dir( File::HomeDir->my_home() );
    is($cfg->root(), $home->file('nowhere'), 'Expanded ~/ to home directory');

    my $expect = [ map {URI->new($_)} qw(here there) ];
    $cfg = Pinto::Config->new(root => 'anywhere', sources => 'here there');
    is_deeply([$cfg->sources_list()], $expect, 'Parsed sources list');
}


#------------------------------------------------------------------------------
