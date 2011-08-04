#!perl

use strict;
use warnings;

use Test::More (tests => 14);
use Test::Exception;
use File::Temp;

use Pinto::Config;


#------------------------------------------------------------------------------

{
    no warnings 'redefine';
    local *Pinto::Config::_build_config_file = sub{};
    local *Pinto::Config::_build_author = sub{ 'TEST' };

    my %test_cases = (
        local     => 'nowhere',
        mirror    => 'http://cpan.perl.org',
        author    => 'TEST',
        force     => 0,
        verbose   => 0,
        quiet     => 0,
        store     => 'Pinto::Store',
        nocleanup => 0,
        nocommit  => 0,
    );

    my $cfg = Pinto::Config->new(local => 'nowhere');
    while ( my ($method, $expect) = each %test_cases ) {
        my $msg = "Got default for '$method'";
        is($cfg->$method(), $expect, $msg);
    }


    $cfg = Pinto::Config->new(local => '~/nowhere');
    is($cfg->local(), "$ENV{HOME}/nowhere", 'Coerced ~/ to my home directory');

    $cfg = Pinto::Config->new(local => 'nowhere', author => 'fooBar');
    is($cfg->author(), 'FOOBAR', 'Coerced author to ALL CAPS');

    throws_ok { Pinto::Config->new(local => 'nowhere', author => 'foo Bar') }
        qr/only capital letters/, 'Author cannot have funky characters';
}


#------------------------------------------------------------------------------

{

    no warnings 'redefine';
    local *Pinto::Config::_build_config_file = sub{};
    local $ENV{USERNAME} = 'SpECIaL';
    my $cfg = Pinto::Config->new();
    is($cfg->author(), 'SPECIAL', 'Got author from ENV');
}

#------------------------------------------------------------------------------

{
    my $tmp = File::Temp->new();
    my $name = $tmp->filename();
    local $ENV{PERL_PINTO} = $name;
    my $cfg = Pinto::Config->new(local => 'nowhere');
    is($cfg->config_file(), $name, 'Got config_file from ENV');
}

#------------------------------------------------------------------------------
