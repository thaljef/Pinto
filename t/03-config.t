#!perl

use strict;
use warnings;

use Test::More (tests => 6);
use Test::Exception;
use File::Temp;

use Pinto::Config;


#------------------------------------------------------------------------------

my $cfg;

{
    no warnings 'redefine';
    local *Pinto::Config::_build_config_file = sub{};

    $cfg = Pinto::Config->new(local => 'nowhere');
    is($cfg->mirror(), 'http://cpan.perl.org', 'Got default mirror');

    $cfg = Pinto::Config->new(local => '~/nowhere');
    is($cfg->local(), "$ENV{HOME}/nowhere", 'Coerced ~/ to my home directory');

    $cfg = Pinto::Config->new(local => 'nowhere', author => 'fooBar');
    is($cfg->author(), 'FOOBAR', 'Coerced author to ALL CAPS');

    throws_ok { Pinto::Config->new(local => 'nowhere', author => 'foo Bar') }
        qr/only capital letters/, 'Author cannot have funky characters';

    local $ENV{USERNAME} = 'SpECIaL';
    $cfg = Pinto::Config->new(local => 'nowhere');
    is($cfg->author(), 'SPECIAL', 'Got author from ENV');
}

my $tmp = File::Temp->new();
my $name = $tmp->filename();
local $ENV{PERL_PINTO} = $name;
$cfg = Pinto::Config->new(local => 'nowhere');
is($cfg->config_file(), $name, 'Got config_file from ENV');

#------------------------------------------------------------------------------
