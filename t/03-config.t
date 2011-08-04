#!perl

use strict;
use warnings;

use Test::More (tests => 4);
use Test::Exception;

use Pinto::Config;


#------------------------------------------------------------------------------

no warnings 'redefine';
local *Pinto::Config::_build_config_file = sub{};

my $cfg = Pinto::Config->new(local => 'nowhere');
is($cfg->mirror(), 'http://cpan.perl.org', 'Got default mirror');

$cfg = Pinto::Config->new(local => '~/nowhere');
is($cfg->local(), "$ENV{HOME}/nowhere", 'Coerced ~/ to my home directory');

$cfg = Pinto::Config->new(local => 'nowhere', author => 'fooBar');
is($cfg->author(), 'FOOBAR', 'Coerced author to ALL CAPS');

throws_ok { Pinto::Config->new(local => 'nowhere', author => 'foo Bar') }
  qr/only capital letters/, 'Author cannot have funky characters';


#------------------------------------------------------------------------------
