#!perl

use strict;
use warnings;

use Test::More (tests => 3);
use Test::Exception;

use Pinto::Config;


#------------------------------------------------------------------------------

local *Pinto::Config::_build_config_file = sub{};

my $cfg = Pinto::Config->new(local => 'nowhere');
is($cfg->mirror(), 'http://cpan.perl.org', 'Got default mirror');

$cfg = Pinto::Config->new(local => 'nowhere', author => 'fooBar');
is($cfg->author(), 'FOOBAR', 'Coerced author to ALL CAPS');

throws_ok { Pinto::Config->new(local => 'nowhere', author => 'foo Bar') }
  qr/only be alphanumeric/, 'Author cannot have funky characters';

#------------------------------------------------------------------------------
