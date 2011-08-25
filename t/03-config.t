#!perl

use strict;
use warnings;

use Test::More (tests => 11);
use Test::Exception;

use Path::Class;
use File::HomeDir;
use File::Temp;

use Pinto::Config;


#------------------------------------------------------------------------------

{
    my %default_cases = (
        repos     => 'nowhere',
        source    => 'http://cpan.perl.org',
        store     => 'Pinto::Store',
        nocleanup => 0,
        noinit    => 0,
    );

    my $cfg = Pinto::Config->new(repos => 'nowhere');
    while ( my ($method, $expect) = each %default_cases ) {
        my $msg = "Got default value for '$method'";
        is($cfg->$method(), $expect, $msg);
    }

   my %custom_cases = (
        repos     => 'nowhere',
        source    => 'http://cpan.pair.com',
        store     => 'Pinto::Store::VCS::Git',
        nocleanup => 1,
        noinit    => 1,
    );

    $cfg = Pinto::Config->new(%custom_cases);
    while ( my ($method, $expect) = each %custom_cases ) {
        my $msg = "Got custom value for '$method'";
        is($cfg->$method(), $expect, $msg);
    }

    $cfg = Pinto::Config->new(repos => '~/nowhere');
    my $home = dir( File::HomeDir->my_home() );
    is($cfg->repos(), $home->file('nowhere'), 'Expanded ~/ to home directory');

}


#------------------------------------------------------------------------------
