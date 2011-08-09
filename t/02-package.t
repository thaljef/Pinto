#!perl

use strict;
use warnings;

use Test::More (tests => 5);
use Test::Exception;

use Pinto::Package;
use Pinto::Distribution;


#------------------------------------------------------------------------------

my $dist = Pinto::Distribution->new( location => 'C/CH/CHAUCER/Foo-1.2.tar.gz');
my $pkg = Pinto::Package->new( name => 'Foo', version => '2.4', dist => $dist );

is($pkg->name(), 'Foo', 'name attribute');
is($pkg->version(), '2.4', 'version attribute');

#------------------------------------------------------------------------------

dies_ok { Pinto::Package->new( dist => $dist, version => '2.4' ) }
  'name is required';

dies_ok { Pinto::Package->new( dist => $dist, name => 'Foo' ) }
  'version is required';

dies_ok { Pinto::Package->new( name => 'Foo', version => '2.4' ) }
  'dist is required';

#------------------------------------------------------------------------------
