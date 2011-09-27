#!perl

use strict;
use warnings;

use Test::More (tests => 2);

use Pinto::Schema::Result::Package;

#------------------------------------------------------------------------------

my $pkg = Pinto::Schema::Result::Package->new( {name => 'Foo', version => '2.001_02'} );

is($pkg->name(), 'Foo', 'name attribute');
is($pkg->version(), '2.001_02', 'version attribute');

#------------------------------------------------------------------------------
